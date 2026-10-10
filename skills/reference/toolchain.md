# Using the Compass toolchain

How the Compass skills run `compass`, the command that checks a corpus against
the standard. The plan behind it is `doc/Plan.Toolchain.md`
(COMPASS-DRAFT-toolchain). `compass help` and `compass rules` describe the
executable you actually have; where they disagree with this file, they win.

The toolchain **disposes** and the skills **propose** (§22): a skill drafts,
reviews, and looks things up; `compass check` decides what conforms; a person
decides what is accepted (§6). A clean check is never an acceptance.

## Finding the executable

1. `compass` on the `PATH` (`command -v compass`).
2. Otherwise `bin/compass` in the Compass repository that holds these skills,
   which is `../../bin/compass` from a skill's directory.
3. Otherwise there is no toolchain. Say so, name the fix, and continue in
   advisory mode (see [Without the toolchain](#without-the-toolchain)). The
   fix is to run `make install` in the Compass repository, which builds the
   executable (SBCL and Quicklisp are needed) and copies it to `~/.local/bin`.
   Plain `make build` writes `bin/compass` without installing it.

Install the executable on the `PATH` whenever the skills are used outside the
Compass repository, since step 2 works only inside it.

`compass` works on the repository that contains the current directory: the
nearest directory upward with a `compass.sexp`, or failing that a `.git`. Pass
`--root DIR` to work on another repository. If it warns "no documents found",
it is looking in the wrong place.

## What the executable can do

Run `compass help` once per session and use only the commands it lists. Run
`compass version` when a report should say which toolchain checked it.

Table: Commands of toolchain version 0.2.

| Command | Use | Changes files |
|---|---|---|
| `compass check [PATH...]` | Check the corpus; report findings for all files, or only for the PATHs given | No |
| `compass check --federation` | Also check references into the repositories `compass.sexp` lists under `:federation` | No |
| `compass show ID[#ANCHOR]` | Print a document, one section, or one record | No |
| `compass outline ID[#ANCHOR]` | List a document's headings, anchors, and line ranges | No |
| `compass refs ID[#ANCHOR]` | List everything that refers to an identifier or section | No |
| `compass index --stdout` | Print the generated namespace index | No |
| `compass index` | Write `INDEX.md` in the document directory | Yes |
| `compass index --check` | Say whether `INDEX.md` is current; exit 1 if not | No |
| `compass next NS --kind KIND` | Preview the next free number of a kind; a preview only | No |
| `compass next --in FILE --kind KIND` | The next provisional record identifier for a document, such as `NS-DRAFT-slug-D4` | No |
| `compass assign FILE [--dry-run]` | Give an accepted document and its provisional records their numbers, and rewrite references to them | Yes |
| `compass renumber [--dry-run]` | After a merge conflict in the ledger, move this branch's numbers off ones another branch took | Yes |
| `compass init [--namespace NS] [--dry-run]` | Write a starting `compass.sexp` for a repository that has none | Yes |
| `compass init --ledger [--dry-run]` | Create the ledger, recording the numbered identifiers already in use | Yes |
| `compass manifest --json` | Print `compass.sexp` as JSON | No |
| `compass rules` | List the rules the toolchain checks | No |
| `compass version`, `compass help [COMMAND]` | Version and usage | No |

`check`, `outline`, `refs`, and `rules` take `--format json`. Every command
that reads a corpus takes `--root DIR`. `check`, `next`, `assign`, and
`renumber` take `--base REV`, the branch a change will be merged into. Later
versions add `compass diff` and others; use them only when `compass help`
lists them.

## Numbers and the ledger

- **The ledger**, `REGISTRY.sexp` in the document directory, lists every
  number the repository has allocated. It is append-only and is written only by
  `compass assign`, `compass renumber`, and `compass init --ledger`; never edit
  it by hand.
- **New documents and records keep provisional identifiers**
  (`NS-DRAFT-slug`, `NS-DRAFT-slug-D1`). A record added to a document that
  already has a number takes the identifier `compass next --in FILE --kind
  KIND` prints.
- **Run `compass assign` only when the user asks.** It numbers a document only
  once a person has set an accepted status (`Accepted`, `Implemented`,
  `Design-Record`, or `Current`); never set that status to make it run, and
  never use `--force` unless the user asks for it. Run it with `--dry-run`
  first and show the user the report.
- **Short references** such as `D6` change meaning when records are numbered,
  so `assign` refuses while any point at the records it would number. Rewrite
  each as the full identifier the `ref/short-record` warning suggests, after
  checking that the suggestion is what the text means.
- **After a merge conflict in the ledger**, keep both sides (or leave the
  conflict markers) and run `compass renumber`; show the user its report.
- **Old provisional identifiers still resolve** through the ledger: `show`,
  `outline`, and `refs` follow them and say so, and `ref/stale-alias` warns
  where a document still uses one.

## Exit codes

Table: What each exit code means.

| Code | Meaning | What to do |
|---|---|---|
| 0 | Success; for `check`, no errors (warnings may remain) | Continue |
| 1 | `check` found errors; `index --check` found `INDEX.md` stale; `show` or `outline` found nothing for the identifier; `refs` found it neither defined nor referenced; `assign`, `renumber`, or `init` refused, saying why | Read the output and act on it |
| 2 | Usage or internal error, such as a path that is not a document of the corpus | Report the message; fix the command, do not retry it unchanged |
| 141 | The output was closed early, as by `head` | Normal; run again without the pipe if the whole output is needed |

## Reading `compass check`

Text output is one line per finding, then a summary:

```text
doc/Plan.Example.md:7:9: error vocab/status: "Current" is not a status of proposal and record genres; ...
Checked 1 document of 12: 1 error, 0 warnings.
```

With `--format json` the output is one object:

```text
{ "tool", "version", "root",
  "summary":    { "documents", "loaded", "errors", "warnings", "skipped", "unverified" },
  "findings":   [ { "path", "line", "column", "severity", "rule", "message" } ],
  "skipped":    [ path ],
  "unverified": [ { "path", "line", "reference" } ] }
```

- An **error** is a violation of a MUST rule; a **warning**, of a SHOULD rule.
- `vocab/pending` warns that a value comes from a decision the standard has not
  yet adopted. Report it; do not swap the value for another to silence it. The
  skills write the `Superseded` form of COMPASS-DRAFT-toolchain-D5 on purpose.
- **Unverified** references point into namespaces this repository does not
  load. They are not findings; report how many there were.
- `--skip-unmarked` skips files without front-matter. Use it in repositories
  that are still migrating older documents, and say how many were skipped.
- `compass check PATH...` still loads and checks the whole corpus, so that
  duplicate identifiers and cross-document references are judged correctly; it
  only limits which findings are reported.
- A PATH that is not a document of the corpus is a usage error (exit 2):
  documents are the `.md` files under the document directory (the manifest's
  `:doc-directory`, `doc/` by default) and `.md` files at the repository root
  that open with front-matter.

## Fixing findings

- Fix the findings in files you created or changed in this task, and run the
  check again until those files have no errors.
- Report findings in other files; do not fix them unless the user asks.
  Repositories that predate Compass may have many.
- Never edit `doc/INDEX.md` by hand; regenerate it with `compass index`.
- Never write a canonical number from `compass next NS` into a document (the
  provisional identifiers `compass next --in` prints are meant to be written).
  Documents and their
  records keep provisional identifiers (`<NS>-DRAFT-<slug>`, and
  `<NS>-DRAFT-<slug>-D1`, `-O1`, `-M1` for records) until `compass assign`
  gives them numbers at acceptance (§13).
- The skills that only read (`compass-lookup`, `compass-review`) never run a
  command that writes; `compass index --stdout` previews the index without
  writing it.

## What the toolchain does not check yet

`compass rules` lists what is checked. Everything else in the standard is
judgment, for `compass-review` and for the person who accepts a document. As of
version 0.2 that includes:

- that a code reference's symbol is the one meant: `ref/code-exists` finds a
  definition by pattern, and only warns when it finds none;
- the author-time accessibility rules of §12: alt text, table captions, diagram
  descriptions, heading levels, link text;
- the §14 section shape of each genre;
- who may set `approved-by` (never an assistant; the sole author only as the
  declared steward of a solo namespace);
- the judgments of genre fit, decision quality, memo admission, and prior art.

## Other repositories

A repository's `compass.sexp` lists the repositories it federates with:

```lisp
:federation ((:namespace "ORIGIN" :path "../origin"))
```

To look up an identifier in another namespace, run the command in the
repository that owns it: `compass show ORIGIN-0012 --root ../origin`, with the
path taken relative to the directory holding `compass.sexp`. If no entry names
the namespace, ask the user where its repository is.

`compass check --federation` loads those repositories, one hop deep, and checks
references into them; without it, such references are counted as unverified.
It also reports a federated repository that is missing, has no manifest, or
does not own the namespace it is listed for (`federation/path`), and a
namespace two repositories both own (`federation/namespace`).

## Without the toolchain

When no executable is found, a skill works from the files themselves, as each
skill's fallback describes, and says that its output was not checked by the
toolchain. It never reports a document as passing `compass check`.
