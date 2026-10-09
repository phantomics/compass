---
id:            <NAMESPACE>-DRAFT-<slug>
title:         <Topic> Reference
genre:         Ref
scope:         project              # component | project | program
project:       <project>
component:     <component>
language:      en
status:        Current              # Current | Draft | Deprecated (§6)
api-version:   <version>            # software version described (§6)
provenance:
  assistant:   <assistant>
relates-to:
  - <ID>
glossary:      <ID>                 # optional: the Glossary document's identifier
---

# <Topic> Reference

<Overview abstract: what running software this describes, and its scope.
A living Ref pins code references to a release tag and advances the tag as it
follows new versions (§6, §9).>

## <API / protocol section>

<Reference material: classes, slots, generic-function signatures, protocol
messages. Group by subsystem/layer; one subsection per class or unit.>

### `<class-or-symbol>`

<Description. For each slot/parameter, note type, default, persistence strategy
and/or predicate where relevant.>

- **`<slot>`** — <meaning> (`<annotations>`)

## Project Structure

```
<an ASCII file tree mapping the described code onto the repository>
```

<Close with id-keyed cross-references to related documents (§9).>
