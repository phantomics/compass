---
name: compass-review
description: Review a Compass document or pull request for judgment-level conformance the deterministic toolchain cannot check — genre fit, section-shape adherence, decision-record quality, prior-art coverage, cross-reference plausibility, and README-transclusion drift. Use before accepting or merging a Compass document.
---

# compass-review

Judgment-level review skill for the Compass documentation standard (the S9
authoring-assistance layer; see `Compass.md` §22 and §23 S9, tracked as
`doc/Plan.AuthoringAssistance.md`). It produces a review report for a human
editor. It assesses the qualities deterministic checks structurally cannot —
whether the document is the *right shape and substance* for its genre — not the
mechanical checks the §22 toolchain owns (required fields present, vocabulary
values legal, ids resolve).

## When to use

Use before **accepting or merging** a Compass document, or when the user asks to
"review this doc", "check this Plan/Log/Survey", or "look over this PR for the
docs". Also use to sanity-check a document `compass-author` just scaffolded.

Do **not** use to create documents (`compass-author`) or to resolve
cross-references and registers (`compass-lookup`). Do not treat this skill as the
approval gate — see Invariants.

## Reference material

Read from the shared bundle to ground the review in the standard:

- `../reference/section-shapes.md` — the §14 spine + optional ancestral sections
  per genre (the yardstick for section-shape review).
- `../reference/vocabularies.md` — genre definitions and the normativity grid
  (for genre-fit judgment).
- `../reference/references.md` — §8 `D`/`O` record shape, §9 reference/citation
  rules, §12 accessibility MUSTs.
- `../reference/frontmatter.md` — the §7 schema (for spotting obvious front-matter
  problems, though deep schema checking belongs to the §22 toolchain).

## Review dimensions

Assess each and record findings with severity (see report format):

1. **Genre fit (§4).** Does the content match the declared `genre`? Watch for
   mismatches the ancestor corpora make common:
   - a `Plan` with no `Roadmap` and no forward design (may be a `Log` or `Arch`);
   - a `Survey` that decides rather than explores, or is normative (Survey is
     non-normative — should it be a `Plan` or `Arch`?);
   - a `Log` describing unbuilt work (a `Plan`), or a `Ref`/`Spec` describing
     code that does not yet exist (an `Arch`);
   - an `Eval` with no rubric or shared scenario (it is a `Survey`);
   - a `Spec` written without RFC-2119 normative language (§14);
   - a `Memo` record that states a design choice (a `D`-record), a known gap (an
     `O`-record), or a rule about one file (a source-header `Invariant:`), or a
     `Memo` host whose records amount to a comprehensive description (fold them
     into a `Ref` and mark them `Superseded`).
   Use the normativity grid and maturity ladder to name the better-fitting genre
   when you flag a mismatch.

2. **Memo admission (§4).** For each `Draft` or newly `Current` M-record,
   judge the three tests the toolchain cannot check, and say which fail:
   - **Durable** — will it hold for the life of the code, beyond this session
     or branch?
   - **Consequential** — would misunderstanding it lead to wrong code or wasted
     work?
   - **Not evident** — is it absent from the code, the source headers, and
     existing documents?
   Also check that the `**Basis:**` actually supports the claim (the toolchain
   checks only that one is present), that the heading is a claim and the body
   is present-tense and short, and that the record sits in the host for its
   major component.

3. **Section-shape adherence (§14).** Compare against `section-shapes.md`:
   - the required §14 spine sections are present and in order;
   - each section carries the *right content* (e.g. Verification states a
     test-run command and pass count for a `Log`; Prior Art is a real
     comparison, not a stub);
   - optional ancestral sections, where used, are placed correctly.

4. **Decision-record quality (§8).** For each `D`-record: is the **Context** a
   real problem with forces (not a restatement of the decision)? Are the
   **Alternatives** genuinely considered options with reasons for rejection (not
   strawmen or empty)? Does the **Decision** follow from the context? Are the
   `D`-ids mirrored in the `decisions:` front-matter? Same scrutiny for
   `O`-records and `open-questions:`.

5. **Cross-reference plausibility (§9).** For each `relates-to`/`cites`/`D`/`O`
   citation and inline id-link: does the cited target actually concern what the
   citing text claims? (Use `compass-lookup` to resolve the target and confirm
   its subject.) Flag prose-only mentions of other documents that should be
   id-keyed links, and links to old `DevLog.`/`DevPlan.` names.

6. **Code-reference discipline (§9).** In `Log`/`Plan`, are code references
   commit-pinned (`path[:symbol]@revision`) rather than bare `file:line`? Prefer
   symbol anchors. (Existence/validity of the revision is a toolchain check;
   here judge whether the *form* is right and the reference is plausible.)

7. **Prior-art coverage.** For `Survey`/`Eval`: is the prior art adequate for the
   claim, or are obvious comparators missing? For program-scope `Eval`/`Arch`
   leaning on foreign sources, is there a source-map appendix (§9)?

8. **Accessibility (author-time, §12).** Tables have header cells and captions;
   diagrams have text-equivalent descriptions; headings nest without skipping;
   links use meaningful text; `language` is declared. (These are also toolchain
   checks; flag any you can see.)

9. **README-transclusion drift (§10, S7).** For a compiled `README.md` with a
   `README.md.compass` template, check whether committed content still matches
   what the transclusion directives would produce. This is best-effort until the
   fixture compiler (S7) exists; flag suspected drift for the editor.

10. **Provenance and approval (§6, §7, §22).** If the document was
   authored or reviewed with LLM help, is `provenance:` present? If it carries
   `approved-by`, is that a person (never the `provenance:` assistant), and is
   it someone other than the sole author unless the namespace has a declared
   solo steward who is the approver?

## Report format

Produce a report for the human editor (§6), not an edit. Structure:

```
# Review — <id or filename> (<genre>, <scope>)

**Summary:** <one-line overall assessment and recommendation>

## Findings
- [ERROR]   <dimension> — <finding and where> — <suggested fix>
- [WARNING] <dimension> — <finding> — <suggested fix>
- [NOTE]    <dimension> — <observation>

## Strengths
- <what the document does well>

## Recommendation: <Accept | Revise | Reconsider genre | Needs human decision>
```

Severity guidance, mirroring §22: reserve **ERROR** for things that would block
merge (wrong genre, missing required §14 sections, empty/strawman decision
records, broken or implausible cross-references, bare-line code refs in
Log/Plan). Use **WARNING** for SHOULD-level issues (thin prior art, missing
optional-but-expected sections, style drift). Use **NOTE** for suggestions.

## Invariants

- This skill **proposes**; it is **never the approval authority**. Human
  editorial review (§6) sets `approved-by`; the §22 toolchain determines
  conformance. Never edit `status`, `approved-by`, or `reviewed`, and never
  claim a document "conforms".
- Complement, do not duplicate, the deterministic toolchain: focus on judgment.
  Where a mechanical check overlaps (a11y, id resolution), flag what you can see
  but defer authority to the toolchain once it exists.
- Until `COMPASS-DRAFT-toolchain` exists, state that mechanical conformance is
  unverified and this review is advisory only.
- Review the whole change: for a PR, consider every added/modified document, not
  only the most recent.
