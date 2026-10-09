---
name: compass-review
description: Review a Compass document or pull request — first with the compass toolchain's mechanical checks, then for the judgment-level conformance it cannot check — genre fit, section shape, decision-record quality, memo admission, prior-art coverage, cross-reference plausibility, accessibility, and README-transclusion drift. Use before accepting or merging a Compass document.
---

# compass-review

Review skill for the Compass documentation standard (the S9
authoring-assistance layer; see `Compass.md` §22 and §23 S9, tracked as
`doc/Plan.AuthoringAssistance.md`). It produces a review report for a human
editor. It runs `compass check` for the mechanical rules, then assesses what no
deterministic check can: whether the document is the *right shape and
substance* for its genre.

## When to use

Use before **accepting or merging** a Compass document, or when the user asks to
"review this doc", "check this Plan/Log/Survey", or "look over this PR for the
docs". Also use to sanity-check a document `compass-author` just scaffolded.

Do **not** use to create documents (`compass-author`) or to resolve
cross-references and registers (`compass-lookup`). Do not treat this skill as the
approval gate — see Invariants.

## Using the toolchain

This skill runs the `compass` command; `../reference/toolchain.md` has the
details. In short:

1. **Find it:** `compass` on the `PATH`, else `../../bin/compass` from this
   skill's directory. If neither exists, say the toolchain is unavailable, name
   the fix (`make install` in the Compass repository), and continue without it
   as described under [Without the toolchain](#without-the-toolchain).
2. **Once per session**, run `compass help` and use only the commands it lists.
3. **Exit codes:** 0 is clean; 1 means findings, or an identifier that is not
   defined; 2 is a usage or internal error to report, not to retry unchanged;
   141 means the output was cut off by a pipe.
4. **Fix nothing.** This skill reports; it runs only commands that read.

## Reference material

Read from the shared bundle to ground the review in the standard:

- `../reference/toolchain.md` — reading `compass check`, and what the toolchain
  does not check yet.
- `../reference/section-shapes.md` — the §14 spine + optional ancestral sections
  per genre (the yardstick for section-shape review).
- `../reference/vocabularies.md` — genre definitions and the normativity grid
  (for genre-fit judgment).
- `../reference/references.md` — §8 `D`/`O`/M record shapes, §9 reference and
  citation rules, §12 accessibility MUSTs.
- `../reference/frontmatter.md` — the §7 schema.

## Step 1: toolchain findings

1. **Decide what is under review.** For one document, its path. For a pull
   request or branch, the Markdown files it changes:
   `git diff --name-only --diff-filter=d <base>...HEAD -- '*.md'`. Review every
   changed document, not only the most recent.
2. **Run the check over the whole corpus:**
   `compass check --format json` (add `--skip-unmarked` in a repository that
   is still migrating older documents). Checking the whole corpus lets the
   cross-document rules judge the change correctly.
3. **Split the findings.** Findings in the files under review belong to the
   review. Findings elsewhere existed before the change; count them and leave
   them out of the recommendation.
4. **Note what the check left out:** skipped files and unverified references
   (references into namespaces this repository does not load).
5. **Note what was checked:** `compass rules` lists the rules applied; record
   `compass version` for the report header.

A changed Markdown file that is not a document of the corpus (outside the
document directory, or missing front-matter at the repository root) is not
checked at all. If it was meant to be a document, report that as an ERROR.

## Step 2: judgment

Skip what the toolchain already decided: a missing field, an unknown status, an
unresolved link, an unlisted record. Assess the rest, and record findings with
severity (see the report format). `../reference/toolchain.md` lists what the
toolchain does not check yet; the dimensions below cover it.

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
   `memo/basis` checks only that the `**Basis:**` names something checkable;
   judge whether it supports the claim (`compass show` a cited identifier).
   Check also that the heading is a claim and the body is present-tense and
   short, and that the record sits in the host for its major component.

3. **Section-shape adherence (§14).** Compare `compass outline <ID>` against
   `section-shapes.md`:
   - the required §14 spine sections are present and in order;
   - each section carries the *right content* (e.g. Verification states a
     test-run command and pass count for a `Log`; Prior Art is a real
     comparison, not a stub);
   - optional ancestral sections, where used, are placed correctly.

4. **Decision-record quality (§8).** For each `D`-record: is the **Context** a
   real problem with forces (not a restatement of the decision)? Are the
   **Alternatives** genuinely considered options with reasons for rejection (not
   strawmen or empty)? Does the **Decision** follow from the context? Same
   scrutiny for `O`-records: is each a real open question?

5. **Cross-reference plausibility (§9).** The toolchain checks that references
   resolve; judge whether they are apt. For each `relates-to`, `cites`, and
   identifier link, read the target with `compass show <ID>` (or
   `compass show <ID>#<anchor>` for a section) and confirm it concerns what the
   citing text claims. Use `compass refs <ID>` to see how else a target is
   cited, for instance whether other documents treat it as superseded. Flag
   prose-only mentions of documents that should be id-keyed links, and links to
   old `DevLog.`/`DevPlan.` names.

6. **Code-reference discipline (§9).** In `Log`/`Plan`, are code references
   commit-pinned (`path[:symbol]@revision`) rather than bare `file:line`? Prefer
   symbol anchors. The toolchain does not check these yet outside memo bases;
   where it is cheap, confirm a reference with `git show <revision>:<path>`.

7. **Prior-art coverage.** For `Survey`/`Eval`: is the prior art adequate for the
   claim, or are obvious comparators missing? For program-scope `Eval`/`Arch`
   leaning on foreign sources, is there a source-map appendix (§9)?

8. **Accessibility (author-time, §12).** The toolchain does not check these
   yet: tables have header cells and a `Table:` caption; diagrams have a
   `Description:` paragraph; headings nest without skipping; links use
   meaningful text.

9. **README-transclusion drift (§10, S7).** For a compiled `README.md` with a
   `README.md.compass` template, check whether committed content still matches
   what the transclusion directives would produce. This is best-effort until the
   fixture compiler (S7) exists; flag suspected drift for the editor.

10. **Provenance and approval (§6, §7, §22).** If the document was authored or
    reviewed with LLM help, is `provenance:` present? If it carries
    `approved-by`, is that a person (never the `provenance:` assistant), and is
    it someone other than the sole author unless the namespace's `compass.sexp`
    declares that person its steward with `:approval :solo`? The toolchain does
    not check this yet.

## Report format

Produce a report for the human editor (§6), not an edit. Structure:

```
# Review — <id or filename> (<genre>, <scope>)

**Summary:** <one-line overall assessment and recommendation>
**Checked with:** <compass version>, or "not checked by the toolchain"

## Toolchain findings
- <severity> <rule> — <path>:<line> — <message>
- <n> errors and <n> warnings elsewhere in the corpus, not part of this change
- <n> files skipped; <n> references unverified

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
records, implausible cross-references, bare-line code refs in Log/Plan). Use
**WARNING** for SHOULD-level issues (thin prior art, missing
optional-but-expected sections, style drift). Use **NOTE** for suggestions.

Never recommend **Accept** while the files under review have a toolchain error.

## Without the toolchain

If no executable is found, check the mechanical rules you can see by hand
(front-matter fields and vocabularies, record mirroring, link targets) against
`frontmatter.md` and `references.md`, say in the report header that mechanical
conformance was **not** checked by the toolchain, and recommend running
`compass check` before acceptance.

## Invariants

- This skill **proposes**; it is **never the approval authority**. Human
  editorial review (§6) sets `approved-by`; the §22 toolchain determines
  mechanical conformance. Never edit `status`, `approved-by`, or `reviewed`.
- Read only: change nothing in the repository. Never edit the documents under
  review, and never run a command that writes there, such as `compass index`
  without `--stdout`. A scratch file outside the repository, such as saved
  `--format json` output, is fine.
- Complement, do not duplicate, the toolchain: report its findings as it gives
  them, and spend the review's judgment on what it does not check.
