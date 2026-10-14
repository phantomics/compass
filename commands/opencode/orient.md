---
description: Get acquainted with this repository's Compass documentation, read-only; optionally focus on a topic
---

<!-- Provisional: this command stands in for the session catalog of COMPASS-D14
     and COMPASS-D15, delivered by the session adapter of COMPASS-D43. Those
     wait on the agent-context evaluation (COMPASS-0006). When they exist,
     retire this command rather than keep it beside them. Do not use it in the
     evaluation's runs: every condition must carry only the context it defines.
     The authoritative copy is commands/opencode/orient.md in the Compass
     repository; copy it to ~/.config/opencode/command/ to use it anywhere. -->

Get acquainted with this repository's documentation before we work. Use the
`compass-lookup` skill. Change nothing: run only commands that read.

1. Find `compass` (on the PATH, else `bin/compass` in the Compass repository),
   then run `compass version` and `compass help`. If there is no executable,
   say so and work from the files, as the skill's fallback describes.
2. Run `compass manifest --json` for the namespaces this repository owns, its
   document directory, its stewards, and the repositories it federates with.
   If it has no `compass.sexp`, say that this is not a Compass repository and
   stop.
3. Run `compass index --stdout` and summarise the documents and records by
   genre and status.
4. Run `compass check` (with `--skip-unmarked` if files lack front-matter) and
   report its errors, warnings, skipped files, unverified references, and
   notes, one line each. Do not fix anything.
5. Read what counts most first: `Ref`, `Spec`, and `Guide` documents that are
   `Current`, and `Current` memos; then `Accepted` and `Implemented` Plans and
   Architectures and their decision records; then open questions. Use
   `compass outline <ID>` and read only the sections you need with
   `compass show <ID>#<anchor>`. Load the standard itself only if a rule is in
   question. Treat `Draft` memos as leads to check against their basis, and
   `Superseded` or `Deprecated` documents as history.
6. If a topic is given below, then read what bears on it: the documents whose
   titles or components match, `compass refs <ID>` on each, and the decisions
   and open questions they hold.

Topic: $ARGUMENTS

Finish with a summary of at most 300 words: what the project is, the decisions
in force that matter most, the open questions, where the documentation looks
thin or stale, and, for a topic, what to read before changing it. Cite every
document and record by its identifier.
