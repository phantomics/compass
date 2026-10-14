# AGENTS.md — the Compass repository

This repository holds the Compass documentation standard (`Compass.md`,
COMPASS-0001), the `compass` toolchain that checks corpora against it (Common
Lisp, in `src/`), the `compass-*` skills (`skills/`), and the genre templates
(`templates/`). Its own documentation is a Compass corpus in `doc/`.

## Documentation — Compass

This repository's documents follow Compass. Use the `compass-*` skills rather
than improvising documents:

- `compass-author` — scaffold a new document (Survey/Eval/Plan/Log/Ref/Guide/
  Spec/Arch/Glossary/Memo) with correct front-matter and section shape.
- `compass-review` — the toolchain's checks plus a judgment-level review before
  a document is accepted.
- `compass-lookup` — resolve identifiers, sections, records, and references.

The skills carry the standard and its reference bundle. Load `Compass.md` only
when a rule is in question; read it by section (`compass outline COMPASS-0001`,
then `compass show COMPASS-0001#<anchor>`) rather than whole.

Run `compass check` before finishing any change to the documentation, and fix
the errors it reports in the files you changed. Numbers are assigned with
`compass assign` only when a person asks for it; never edit the ledger,
`doc/REGISTRY.sexp`, by hand.

Facts for this repository:

- Compass namespace: COMPASS (declared in `compass.sexp`, steward Andrew
  Sengul, solo approval)
- Docs directory: `doc/`, flat; grouping is by the `component:` field. The
  standard itself, `Compass.md`, is at the root.
- The `compass` command: `bin/compass` after `make build`, or `compass` on the
  PATH after `make install`. A stale `bin/compass` checks with old rules; rebuild
  after changing `src/`.
- Federated repositories: CLASSIC (`../classic`), ORIGIN (`../origin`), LEXTER
  (`../../chat/lexter`), as listed in `compass.sexp`. `compass check
  --federation` checks references into them where they are checked out.
- Refer to a record by its full identifier, never a short form such as `D6`
  (`ref/short-record`). The corpus has none; keep it that way.
- Most documents have canonical numbers (`COMPASS-0004` is the toolchain plan).
  Their old provisional identifiers still resolve as aliases in the ledger, but
  write the canonical ones; `ref/stale-alias` warns on the old.

Essentials (full rules in `Compass.md`): every document opens with a §7 YAML
front-matter block; genre and status use the controlled vocabularies; decision
records are ADR-shaped `D`-records with full-identifier headings; new documents
and their records keep provisional `COMPASS-DRAFT-<slug>` identifiers until a
steward assigns numbers, and a record added to a numbered document takes the
identifier `compass next --in <file> --kind <kind>` prints; code references in Log/Plan are commit-pinned
(`path:symbol@revision`), never bare line numbers; documents authored with LLM
help carry `provenance:`; an assistant never sets `approved-by` or an
authoritative status.

## The toolchain

```sh
make build              # bin/compass; fails if a compass function replaces another
make test               # the FiveAM suite; must pass before any change is done
make check              # build, then check this repository
make deps DEPS=ocicl    # then make build/test DEPS=ocicl, with the pinned ocicl.csv
make hooks              # install scripts/pre-commit (only when asked)
```

- The plan is [COMPASS-0004](doc/Plan.Toolchain.md); its decisions are the
  authority for the toolchain's behaviour. How each version was built is in
  [COMPASS-0011](doc/Log.Toolchain.md) (v0.1) and
  [COMPASS-0013](doc/Log.Ledger.md) (v0.2).
- Layers, each using only those before it (`src/packages.lisp`): util, git,
  vocab, model, parse, corpus, rules, report, cli. The `compass` package
  re-exports them for the tests.
- Every source file opens with a source header: a `;;;;` summary line, then
  `Read-if:`, `See:` (decision identifiers), `Invariant:`, `Concerns:`, and
  `Tests:` lines where they apply. Keep it true when you change the file.
- Every rule, command, and decision needs tests; add them in `tests/` and list
  new files in `compass.asd`. Tests of anything using Git build temporary
  repositories (`tests/helpers.lisp`); tests of the command line use `run-cli`.
- Two guards catch mistakes made here before: the build fails when a compass
  function or structure accessor replaces another of the same name, and
  `no-stray-format-strings` fails on a string that continues a line with `~`
  and a newline outside a format control. Messages that continue lines must go
  through `format`, `emit`, `refuse`, `note`, or another formatting operator.
- `commands/opencode/orient.md` is the authoritative `/orient` command, which
  orients an agent in any Compass repository; `.opencode/command/orient.md`
  links to it. It is provisional, standing in for the session catalog
  (COMPASS-D14, COMPASS-D15, COMPASS-D43), and is retired when that exists.
- The skills, their reference bundle, and the commands are tested against the
  toolchain (`tests/test-skills.lisp`): they may name only commands, options, and rules
  that exist or the plan lists, and every filled template must pass
  `compass check`. Changing a command or rule may require changing the skills.
- Changing the vocabulary (`src/vocab.lisp`) requires matching
  `skills/reference/vocabularies.md`; a value from a decision not yet amended
  into the standard is `:pending` and names that decision.

## Working practice

- **The steward commits.** Do not commit, push, or tag unless asked, and do not
  install to `~/.local`.
- **Large work goes in stages** recorded in a Plan, each ending with the tests
  passing. When asked, write a Log of the work; a Log's code references are
  pinned to the commit that holds the work, so it is written after that commit,
  and later work is appended as `## Update <date> — <title>` sections.
- **Verify before reporting:** `make test`; `bin/compass check` (0 errors) and
  `bin/compass index --check`; for a release, the same from a clean worktree of
  the commit, under both `DEPS=ql` and `DEPS=ocicl`.
- **After changing documents**, regenerate `doc/INDEX.md` with `compass index`;
  `index/current` reports a stale one.
- **Amendments to `Compass.md`** land only for accepted decisions, as their
  decisions describe, and bump `schema-version` (§13).
- **Other repositories** (Classic, Origin, Lexter) are the steward's; change
  them only when asked.
