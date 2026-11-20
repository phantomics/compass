#!/usr/bin/env bash
# release-spike.sh — Build, test, and measure the compass executable on one release target
#
# Read-if: changing what the release spike measures
# See: COMPASS-D23 (portable binary distribution), COMPASS-0004 roadmap step 7
# Invariant: every measurement is attempted; a failure is recorded, not fatal, after the build
#
# The spike that COMPASS-0004 runs before the release workflow: does an unsigned
# SBCL executable build, run, pass the tests, and invoke Git on this target, and
# how large is its archive? Run from the repository root, after SBCL is
# installed, as: scripts/release-spike.sh TARGET. Writes dist/ and a Markdown
# report to $GITHUB_STEP_SUMMARY (or standard output).

set -u
target=${1:?usage: scripts/release-spike.sh TARGET}
summary=${GITHUB_STEP_SUMMARY:-/dev/stdout}
dist=dist
mkdir -p "$dist"
export DEPS=ql

lisp() { sbcl --noinform --non-interactive --no-userinit --load build.lisp "$@"; }
row() { printf '| %s | %s |\n' "$1" "$2" >> "$summary"; }
sha256() { if command -v sha256sum > /dev/null; then sha256sum "$1"; else shasum -a 256 "$1"; fi; }
size() { wc -c < "$1" | tr -d ' '; }

{ printf '## Release spike: %s\n\n' "$target"
  printf 'Table: What the spike measured on %s.\n\n' "$target"
  printf '| Measure | Result |\n|---|---|\n'; } >> "$summary"
row "Runner" "$(uname -srm)"
row "SBCL" "$(sbcl --version)"
row "Git" "$(git --version)"

# Dependencies: the Quicklisp dist the CI job pins.
curl -fsSL -o "$dist/quicklisp.lisp" https://beta.quicklisp.org/quicklisp.lisp
sbcl --noinform --non-interactive --load "$dist/quicklisp.lisp" \
     --eval '(quicklisp-quickstart:install :dist-url "http://beta.quicklisp.org/dist/quicklisp/2023-06-18/distinfo.txt")' \
     > "$dist/quicklisp.log" 2>&1

# Build.
start=$SECONDS
if lisp --eval '(compass-build:build)' > "$dist/build.log" 2>&1; then
  row "Build" "passed in $((SECONDS - start)) s"
else
  row "Build" "**failed** after $((SECONDS - start)) s; see build.log"
  exit 1
fi
exe=bin/compass
[ -f bin/compass.exe ] && exe=bin/compass.exe
row "Executable" "\`$exe\`, $(size "$exe") bytes"
row "\`compass version\`" "$("./$exe" version 2>&1 | head -1)"

# What the executable needs at run time.
case "$target" in
  linux-*)
    row "Shared libraries" "$(ldd "$exe" | awk '{print $1}' | tr '\n' ' ')"
    row "Newest glibc symbol" "$(objdump -T "$exe" | grep -o 'GLIBC_[0-9.]*' | sort -uV | tail -1)" ;;
  macos-*)
    row "Shared libraries" "$(otool -L "$exe" | tail -n +2 | awk '{print $1}' | tr '\n' ' ')" ;;
  windows-*)
    row "DLLs" "$( (objdump -p "$exe" 2> /dev/null | awk '/DLL Name/ {print $3}' | tr '\n' ' ') || echo 'objdump not available')" ;;
esac

# Start-up time: five runs of compass version.
TIMEFORMAT=%R
times=$( { for i in 1 2 3 4 5; do time "./$exe" version > /dev/null; done; } 2>&1 | tr '\n' ' ')
row "Start-up, 5 runs (s)" "$times"

# The test suite, through the development image.
if lisp --eval '(compass-build:test)' > "$dist/test.log" 2>&1; then status=passed; else status="**failed**"; fi
row "Tests" "$status: $(grep -E 'Did [0-9]+ checks' "$dist/test.log" | tr -s ' ') $(grep -E 'Fail:' "$dist/test.log" | head -1 | tr -s ' ')"

# The executable just built, on this repository.
"./$exe" check > "$dist/check.log" 2>&1; code=$?
row "\`compass check\`" "exit $code: $(grep -E '^Checked' "$dist/check.log")"
"./$exe" index --check > "$dist/index.log" 2>&1; code=$?
row "\`compass index --check\`" "exit $code: $(head -1 "$dist/index.log")"

# Git: the authors and dates outline derives from history.
"./$exe" outline COMPASS-0001 > "$dist/outline.log" 2>&1; code=$?
row "Git from the executable" "exit $code: $(sed -n 3p "$dist/outline.log")"

# The archive a release would publish.
case "$target" in
  windows-*)
    archive="$dist/compass-$target.zip"
    powershell -NoProfile -Command "Compress-Archive -Path '$exe' -DestinationPath '$archive'" ;;
  *)
    archive="$dist/compass-$target.tar.gz"
    tar -czf "$archive" -C "$(dirname "$exe")" "$(basename "$exe")" ;;
esac
row "Archive" "\`$(basename "$archive")\`, $(size "$archive") bytes"
row "SHA-256" "\`$(sha256 "$archive" | awk '{print $1}')\`"
printf '\n' >> "$summary"
