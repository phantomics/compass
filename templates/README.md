# Genre templates

Section-skeleton templates for each Compass genre, per `../Compass.md` §14. The
`compass-author` skill (`../skills/compass-author/`) scaffolds new documents from
these, and the fixture compiler (§10, S7) and site build (§16, S8) may draw
on them for consistent structure.

One template per genre:

- `Survey.template.md`, `Eval.template.md`, `Plan.template.md`,
  `Log.template.md`, `Ref.template.md`, `Guide.template.md`,
  `Spec.template.md`, `Arch.template.md`, `Glossary.template.md`,
  `Memo.template.md`

Each template carries the §7 front-matter block (with placeholder values) and
the genre's canonical section headings from §14 as its normative spine. Beyond
that spine, templates include **optional** sections — drawn from the ancestor
corpora Compass was derived from (classic, origin, lexter) — marked with
`<!-- optional: … -->` guidance comments. Authors keep the §14 section names and
order and add optional sections where useful; delete the guidance comments and
any unused placeholders in the finished document.

The `Ideation` genre has no template: it is a rare, curated seed discussion with
no fixed skeleton (§4), authored by hand.

Placeholder conventions used throughout: `<NAMESPACE>-DRAFT-<slug>` for the
provisional identifier (§13), and `<NAMESPACE>-DRAFT-<slug>-D1`, `-O1`, and
`-M1` for the provisional identifiers of the records it holds, numbered from 1
within the document (COMPASS-DRAFT-toolchain-D2); `<angle-bracket>` tokens for
values to fill in; and `~` only as a null illustration in the schema — remove
it in real documents.

A filled-in template should pass `compass check` once it is placed in the
document directory. The toolchain's tests fill in each template and check it.
