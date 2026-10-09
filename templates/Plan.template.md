---
id:            <NAMESPACE>-DRAFT-<slug>
title:         <Topic> Plan
genre:         Plan
scope:         project              # component | project | program
project:       <project>
component:     <component>          # omit for project/program scope if not applicable
language:      en
status:        Draft                # Draft | Proposed | In-Review | Accepted | Implemented (§6)
provenance:
  assistant:   <assistant>
relates-to:
  - <ID>
decisions:
  - <NAMESPACE>-DRAFT-<slug>-D1
open-questions:
  - <NAMESPACE>-DRAFT-<slug>-O1
---

# <Topic>: Development Plan

<One-paragraph abstract: the defining idea, and which documents it assumes
(link them by id, §9).>

## Problem

<The problem and the forces at play.>

## Goals

- <goal>

<!-- optional after Problem: ## Thesis (the central claim of the approach) -->

## Settled Decisions

### <NAMESPACE>-DRAFT-<slug>-D1 — <decision title>

**Status:** Proposed         <!-- a person sets Accepted (§6) -->
**Context:** <the problem and forces>
**Decision:** <what was chosen>
**Alternatives:** <what was rejected, and why>

## <Design section>

<Design detail. Add as many sections as the design needs.>

<!-- optional before Open Questions, a risk/tradeoff section under one of:
## Tradeoffs and Non-Goals
## Scope and Non-Goals
## Tensions and Risks
## Barriers
-->

## Open Questions

### <NAMESPACE>-DRAFT-<slug>-O1 — <question title>

<The unresolved issue and the current thinking.>

## Prior Art

| System | What to draw from |
|---|---|
| <system> | <what to borrow> |

## Roadmap

1. <ordered, indicative milestone>
