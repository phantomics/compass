# Compass

## Common Ontological Model for Prose Artifacts by Structural Standard

Compass is a formalized methodology for documenting software projects. It includes specifications for writing tutorials and API documents as well as chronicling the development of systems and disclosing the engineering process that led to their creation. [Read the full specification](./Compass.md) for more details.

## The toolchain

`compass` checks a repository's documents against the standard, shows documents and records by identifier, and generates the namespace index. Version 0.1 checks a corpus without the allocation ledger; see [COMPASS-DRAFT-toolchain](doc/Plan.Toolchain.md) for the plan and its later releases.

Build and test it with SBCL and Quicklisp:

```sh
make build        # writes bin/compass
make test         # runs the test suite
make check        # builds, then checks this repository
```

Use it from anywhere inside a repository:

```sh
compass check [PATH...] [--format text|json] [--strict] [--skip-unmarked]
compass show COMPASS-DRAFT-toolchain-D18
compass show COMPASS-0001#7-yaml-front-matter-schema
compass outline COMPASS-DRAFT-toolchain   # headings, anchors, line ranges
compass refs COMPASS-DRAFT-toolchain-D18  # what refers to an identifier
compass index      # writes doc/INDEX.md
compass rules      # lists every rule, its severity, and the section it enforces
```

`compass check` exits 0 when there are no errors, 1 when there are, and 2 on a usage or internal error. `make install` copies the executable to `~/.local/bin`, which the `compass-*` skills in `skills/` expect when they are used outside this repository.

### Dependencies, CI, and hooks

The build uses Quicklisp by default. To use the versions pinned in `ocicl.csv` instead, run `make deps DEPS=ocicl`, then `make build DEPS=ocicl` and `make test DEPS=ocicl`.

`.github/workflows/compass-check.yml` builds the toolchain under both, checks this repository with `compass check --base` against the branch a pull request merges into, checks that `doc/INDEX.md` is current, and runs the tests. Numbers stay unique only if those checks cannot be bypassed (see [the uniqueness guarantee](doc/Plan.Toolchain.md#the-uniqueness-guarantee)), so set the default branch to:

- accept changes only through pull requests;
- require both `compass-check` jobs to pass, with branches up to date before merging (or a merge queue);
- require review from code owners, so that `.github/CODEOWNERS` makes the steward approve every change to the ledger, `doc/REGISTRY.sexp`.

`make hooks` installs `scripts/pre-commit`, which regenerates a stale `doc/INDEX.md`, stages it, and then refuses the commit if `compass check` finds errors.
