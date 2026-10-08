---
id:            <NAMESPACE>-DRAFT-<slug>
title:         <Component> Memos
genre:         Memo
scope:         component            # component | project | program
project:       <project>
component:     <component>          # one host per major component (§14)
language:      en
status:        Current              # Current | Draft | Deprecated | Superseded (§6)
provenance:
  assistant:   <assistant>          # required when LLM-assisted (§7); remove if not
memos:
  - <NAMESPACE>-DRAFT-<slug>-M1     # every record in the body, mirrored (§8)
---

# <Component>: Memos

<One paragraph: the system or component these memos concern, and where its
normative documentation lives (link the Ref/Spec by id, §9).>

## Memos

<!-- One M-record per durable property, in identifier order (§8).
     Admit a memo only if it is durable, consequential, not evident from the
     code or an existing document, and grounded (§4). Anyone, including an
     assistant, may add a Draft record; Draft memos are listed for later
     sessions as unreviewed. A person, never an assistant, moves a record to
     Current (§6). Records are never deleted: retire one by changing its
     status. -->

### <NAMESPACE>-DRAFT-<slug>-M1 — <The property, stated as a claim>

**Status:** Draft
**Read-if:** <the task or situation in which this matters, within 160 characters>
**Basis:** <commit-pinned reference `path:symbol@revision`, Compass id, or cites title>; <how it was established>
**Recorded:** <YYYY-MM-DD>           <!-- optional -->
**Superseded-by:** <id>              <!-- only with status Superseded -->

<The property in the present tense, then what it implies for someone changing
the system. Keep it under about 200 words.>
