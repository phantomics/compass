---
name: compass-adopt
description: Set up a repository or an empty folder to use the Compass documentation standard — writes compass.sexp with compass init, a .mailmap, the document directory and its ledger, and the Compass block of AGENTS.md, then checks the result. Use when the user wants to "add Compass", "adopt Compass", "set up Compass docs", or start documenting a new project with Compass. In a repository that already has documents, it sets Compass up without migrating them.
---

# compass-adopt

Adoption skill for the Compass documentation standard (the S9
authoring-assistance layer; see `Compass.md` §22 and §23 S9, tracked as
`doc/Plan.AuthoringAssistance.md`). It turns a folder — empty, or an existing
repository — into a Compass repository in one pass: a manifest declaring the
namespace it owns, a `.mailmap` so that Git names its authors consistently, a
document directory with an empty allocation ledger, and the instructions in
`AGENTS.md` that route later sessions to the `compass-*` skills. It writes no
documents of its own, and migrates none.

## When to use

Use when the user wants to start using Compass in a folder that has no
`compass.sexp`: "add Compass to this repo", "set up Compass here", "start the
docs for this new project". Triggers also include a new, empty project folder.

Do **not** use in a folder that already has a `compass.sexp` (it is adopted:
run `compass check` and report instead), to write documents (`compass-author`),
or to convert existing documents to Compass. Migrating a mature corpus is a
separate workflow; this skill sets Compass up beside such documents and leaves
them as they are (see [Existing documents](#existing-documents)).

## Using the toolchain

This skill runs the `compass` command; `../reference/toolchain.md` has the
details. In short:

1. **Find it:** `compass` on the `PATH`, else `../../bin/compass` from this
   skill's directory. If neither exists, say the toolchain is unavailable, name
   the fix (`make install` in the Compass repository), and continue without it
   as described under [Without the toolchain](#without-the-toolchain).
2. **Once per session**, run `compass help` and use only the commands it lists.
3. **Exit codes:** 0 is success; 1 means a refusal or findings, with the reason
   on standard error; 2 is a usage or internal error to report, not to retry
   unchanged.
4. **Pass `--root <folder>`** to every command when the folder being adopted is
   not the current directory.

## Reference material

- `../reference/toolchain.md` — the commands, and the rules for numbers and the
  ledger.
- `../reference/frontmatter.md` — namespaces and identifiers (§5, §13).
- `../../templates/AGENTS.snippet.md` — the Compass block for `AGENTS.md`.

## Workflow

Confirm each fact with the user before writing anything, then write in this
order. Every step is safe to repeat: stop at the first that fails and report
why.

1. **Inspect the folder.**
   - If `compass.sexp` exists, stop: the folder is already adopted.
   - Note whether it is a Git repository (`git rev-parse --is-inside-work-tree`),
     whether it has commits, whether `doc/` or `docs/` exists, and whether it
     holds Markdown files. Markdown files without front-matter are existing
     documents (see [Existing documents](#existing-documents)).
2. **Git.** Compass derives authors and dates from Git, and allocates numbers
   through a ledger that Git keeps; `compass init --ledger` needs a repository.
   If the folder is not one, ask before running `git init -b main`. Never
   commit: the user does.
3. **Gather the facts.**
   - **Namespace:** short uppercase letters and digits (`ORIGIN`, `LEXTER`),
     naming the project that mints the documents. Suggest the folder's name in
     upper case; the user decides. It is permanent once numbers are allocated.
   - **Steward:** the person who owns the namespace and accepts its documents;
     by default the Git user, as `.mailmap` names them (step 4).
   - **Approval mode:** solo if the steward is the only maintainer, so that they
     may accept their own documents (§6); otherwise a second reviewer is
     required.
   - **Document directory:** `doc/` unless the folder already uses `docs/` or
     the user wants another.
   - **Federation:** other Compass repositories this one cites, each as a
     namespace and a path relative to this folder. Ask; none is fine.
4. **Write `.mailmap` first.** Every ledger entry records its allocator, and an
   entry is never edited, so canonical names must exist before the first
   allocation.
   - List the identities in the history with `git shortlog -sne --all` (none in
     a new repository) and the current one with `git config user.name` and
     `git config user.email`.
   - Propose one line per person, `Canonical Name <email>`, mapping each of
     their identities, such as a handle used as `user.name`; confirm with the
     user.
   - If a `.mailmap` exists, add only missing lines. Verify with
     `git check-mailmap "<name> <email>"`.
5. **Write the manifest.** Run `compass init` with the gathered facts and
   `--dry-run` first, for example
   `compass init --namespace DEMO --steward "Ada Lovelace" --solo --dry-run`,
   adding `--doc-directory DIR` and one `--federation NS=PATH` per federated
   repository. Show the user the manifest, then run it without `--dry-run`.
   `compass init` refuses to overwrite an existing manifest.
6. **Create the ledger.** Create the document directory if it is missing, then
   run `compass init --ledger --dry-run` and `compass init --ledger`. In a new
   corpus the ledger has no entries; where documents already carry canonical
   numbers, it records them. If it refuses because a number is defined twice,
   report the duplicates and stop this step: giving them provisional
   identifiers is a migration decision for the user.
7. **Add the Compass block to `AGENTS.md`.** Copy the block of
   `../../templates/AGENTS.snippet.md` from `## Documentation — Compass` to its
   end, without the leading HTML comment, and fill in the facts: the namespace,
   the document directory, where `compass` is installed, the federated
   repositories, and, where there are existing documents, the migration line.
   If `AGENTS.md` exists, append the block; if it already has a Compass
   section, leave it and report the differences. If the project also uses the
   Square testing standard, its block concatenates with this one.
8. **Check the result.**
   - `compass manifest --json` shows the namespace, document directory, ledger,
     stewards, and federation as intended.
   - `compass check`, with `--skip-unmarked` if there are existing documents,
     reports no errors. In a new corpus it warns that no documents were found;
     that is expected until the first document is written.
   - If federated repositories are checked out, `compass check --federation`
     reports any listed path that is missing or does not own its namespace.
9. **Offer the first document.** A new project usually starts with a `Survey`
   ("should we build this?") or a `Plan`. Offer to scaffold it with
   `compass-author`; do not write it here.
10. **Report.** List the files written (`.mailmap`, `compass.sexp`, the ledger,
    `AGENTS.md`, and the directory if new), the `compass check` result, the
    toolchain version, and what the user does next: review and commit the
    files, and restart the agent harness so that `AGENTS.md` is loaded.

## Existing documents

In a repository that already has documentation, adoption sets Compass up
beside it:

- Leave every existing file unchanged. Do not add front-matter, rename files,
  or move them into the document directory.
- Check with `compass check --skip-unmarked`, which skips files without
  front-matter and reports how many it skipped. Report the count.
- In `AGENTS.md`, fill the migration line: documents without front-matter
  remain, and checks run with `--skip-unmarked`.
- Tell the user that converting the existing documents is a separate,
  document-by-document workflow — choosing each one's genre, extracting its
  decisions as records, and pinning its code references to the revisions they
  meant — for which tools are being built. New documents can be written with
  `compass-author` at once.

## Without the toolchain

If no executable is found, do steps 1–4 and 7, then write `compass.sexp` by
hand from the facts, as `(:namespaces ("NS") :doc-directory "doc/" :stewards
((:namespace "NS" :steward "Name" :approval :solo)))`, with `:federation
((:namespace "NS" :path "../repo"))` if needed. Do not create the ledger by
hand. Tell the user that the setup has not been checked, that the ledger is
created with `compass init --ledger` once the toolchain is installed, and how
to install it.

## Invariants

- Write only `.mailmap`, `compass.sexp`, the ledger, the document directory,
  and `AGENTS.md`, each after the user has confirmed its facts. Never modify,
  move, or delete existing files other than appending to `.mailmap` and
  `AGENTS.md`.
- Never commit, push, or change Git configuration.
- Never write the ledger by hand; only `compass init --ledger` creates it.
- Never assign numbers, set an authoritative status, or set `approved-by`.
- The namespace and the steward are the user's decisions; suggest, never
  choose.
