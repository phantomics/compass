---
id:            <NAMESPACE>-DRAFT-<slug>
title:         <Topic> Guide
genre:         Guide
subtype:       tutorial             # tutorial (learning-oriented) | howto (task-oriented) (§4)
scope:         project              # component | project | program
project:       <project>
component:     <component>
language:      en
status:        Current              # Current | Draft | Deprecated (§6)
api-version:   <version>
provenance:
  assistant:   <assistant>
relates-to:
  - <ID>
---

# <Topic> Guide

<Overview abstract: what the reader will be able to do by the end.>

## Prerequisites

- <what the reader needs installed/known before starting>

<!-- =========================================================
     Choose ONE body shape according to `subtype`:

     subtype: tutorial  — a narrated, learning-oriented walkthrough.
       Attested style: a "Design Goals" framing, then a primitives
       overview, then a REPL walkthrough with `### <step>` headings and
       code blocks carrying inline `;; =>` expected-output comments.

     subtype: howto     — a terse, task-oriented procedure.
       Attested style: a "## Quick Start" with numbered `### 1. …` steps,
       ending in the achieved result.
     ========================================================= -->

## <Body>

### <Step>

<Narration (tutorial) or numbered action (howto).>

```lisp
<code>
;; => <expected output>
```

<Close by stating the achieved result and linking related documents by id (§9).>
