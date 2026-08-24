# Shared reference bundle for the Compass skills

Compact, derived extractions from `../../Compass.md` that the Compass skills
(`compass-author`, `compass-review`, `compass-lookup`, and eventually
`compass-derive`) read on demand, so each skill need not re-derive the rules
from the full 1400-line standard on every invocation.

- `vocabularies.md` — genres, subtypes, scopes, statuses, the normativity grid,
  the maturity ladder (§4, §5, §6).
- `frontmatter.md` — the §7 YAML schema, required vs. optional fields, the
  Git-derived-field rules, identifiers and provisional allocation (§5, §7, §13).
- `section-shapes.md` — the §14 normative section spine per genre, plus the
  optional ancestral sections attested in the classic/origin/lexter corpora.
- `references.md` — the §8 `D`/`O` registers, §9 reference and citation rules,
  §12 author-time accessibility MUSTs, §13 allocation, §10 layout.

**`Compass.md` is the source of truth.** This bundle is a convenience projection
of it. If the two disagree, the standard wins; update this bundle to match. This
directory has no `SKILL.md`, so the skill loader does not treat it as a skill.
