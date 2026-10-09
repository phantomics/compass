# Shared reference bundle for the Compass skills

Compact, derived extractions from `../../Compass.md` that the Compass skills
(`compass-author`, `compass-review`, `compass-lookup`, and eventually
`compass-derive`) read on demand, so each skill need not re-derive the rules
from the full standard on every invocation.

- `toolchain.md` — how the skills run the `compass` command: finding the
  executable, its commands and exit codes, reading its findings, what it does
  not check yet, and what to do without it.
- `vocabularies.md` — genres, subtypes, scopes, statuses, the normativity grid,
  the maturity ladder (§4, §5, §6).
- `frontmatter.md` — the §7 YAML schema, required vs. optional fields, the
  Git-derived-field rules, identifiers and provisional allocation (§5, §7, §13).
- `section-shapes.md` — the §14 normative section spine per genre, plus the
  optional ancestral sections attested in the classic/origin/lexter corpora.
- `references.md` — the §8 `D`/`O`/M registers, §9 reference and citation rules,
  §12 author-time accessibility MUSTs, §13 allocation, §10 layout.

**`Compass.md` is the source of truth.** This bundle is a convenience projection
of it. If the two disagree, the standard wins; update this bundle to match.

**`compass rules` is the source of truth for what is checked automatically.**
The rules a skill can leave to the toolchain are the ones it lists; everything
else in this bundle is for drafting and for judgment. The toolchain's tests
check that the rule names and commands these files mention exist.

This directory has no `SKILL.md`, so the skill loader does not treat it as a
skill.
