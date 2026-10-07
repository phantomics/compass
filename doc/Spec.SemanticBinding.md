---
id:            COMPASS-DRAFT-semantic-binding
title:         Compass Semantic Binding — RDF Vocabulary, Identity, and Shapes
genre:         Spec
scope:         program
program:       Compass
component:     semantic-binding
language:      en
status:        Draft
schema-version: "0.1"
authors:
  - Sloane
provenance:
  assistant:   opencode
relates-to:
  - COMPASS-0001
  - COMPASS-DRAFT-toolchain
  - COMPASS-DRAFT-source-headers
  - COMPASS-DRAFT-agent-workflow
  - COMPASS-DRAFT-secure-development
cites:
  - title:     "RFC 4151 — The 'tag' URI Scheme"
    locator:   "§2, Tag syntax and rules"
    external:  true
  - title:     "RDF 1.1 Concepts and Abstract Syntax (W3C Recommendation)"
    locator:   "§3, RDF graphs; §3.5, blank nodes and skolemization"
    external:  true
  - title:     "RDF 1.1 Turtle; RDF 1.1 N-Triples; RDF 1.1 N-Quads (W3C Recommendations)"
    locator:   "Grammar sections"
    external:  true
  - title:     "JSON-LD 1.1 (W3C Recommendation)"
    locator:   "§3.1, the context; §10, security considerations"
    external:  true
  - title:     "DCMI Metadata Terms"
    locator:   "dcterms: title, created, modified, creator, relation, replaces, isReplacedBy, subject, language, identifier"
    external:  true
  - title:     "PROV-O: The PROV Ontology (W3C Recommendation)"
    locator:   "§3.1 Starting Point classes; prov:SoftwareAgent"
    external:  true
  - title:     "SKOS Simple Knowledge Organization System Reference (W3C Recommendation)"
    locator:   "§4 Concept schemes"
    external:  true
  - title:     "Shapes Constraint Language (SHACL) (W3C Recommendation)"
    locator:   "§2 Shapes; §4.8 sh:in"
    external:  true
  - title:     "CiTO, the Citation Typing Ontology (SPAR ontologies)"
    locator:   "cito:cites"
    external:  true
  - title:     "DOAP — Description of a Project"
    locator:   "doap:Project, doap:repository, doap:GitRepository"
    external:  true
  - title:     "SIOC Core Ontology Specification"
    locator:   "sioc:Space, sioc:has_space"
    external:  true
  - title:     "FOAF Vocabulary Specification"
    locator:   "foaf:Document, foaf:Person"
    external:  true
  - title:     "w3id.org — Permanent Identifiers for the Web"
    locator:   "README, registering a redirect (perma-id/w3id.org)"
    external:  true
open-questions:
  - COMPASS-DRAFT-semantic-binding-O1
  - COMPASS-DRAFT-semantic-binding-O2
  - COMPASS-DRAFT-semantic-binding-O3
  - COMPASS-DRAFT-semantic-binding-O4
---

# Semantic Binding Specification

This specification defines the **RDF binding** of the Compass information
model: a vocabulary of classes and properties, a rule that gives every Compass
document, register entry, and related thing a permanent IRI, a mapping from the
§7 front-matter and the §8 registers onto that vocabulary, and SHACL shapes that
express the standard's constraints as data. With it, a Compass corpus can be
exported to any RDF triplestore and queried with SPARQL, and later ingested by
Classic. It replaces the RDF column of [COMPASS-0001](../Compass.md) §7 and the
mapping table of §17 by amendment. The toolchain work that implements it is
COMPASS-DRAFT-toolchain-D17 in [COMPASS-DRAFT-toolchain](Plan.Toolchain.md). The
key words MUST, MUST NOT, SHOULD, SHOULD NOT, and MAY are used as described in
RFC 2119.

## Overview

§3 defines Compass as a binding-independent information model, of which
Markdown with YAML front-matter is the reference binding. This document defines
a second binding, in RDF. Under Tier 1 (§16) it is **derived one-way**: the
Markdown corpus in Git remains the single source of truth, and RDF is an export
that is regenerated, never edited. Under the future Tier 2 the same vocabulary
becomes Classic's storage schema for the corpus.

The binding is designed to be **forge-ready without describing a forge**. A
later specification will integrate Compass with Classic's Git-forge imprint
(see [Afterword: Limits](#afterword-limits)). This binding fixes the three
things such an integration depends on, and nothing more:
- an identity scheme that maps one-to-one onto Classic's URI scheme;
- predicates that agree with those Classic already uses, wherever those are
  standard;
- review and acceptance modelled as PROV activities, to which a signed workflow
  transition can later be attached.

### Design principles

1. **Reuse before invention.** A Compass concept that an established vocabulary
   already expresses uses that vocabulary's term: Dublin Core terms (DCTERMS),
   PROV-O, SKOS, SHACL, CiTO, DOAP, SIOC, FOAF, schema.org. The `compass:`
   vocabulary holds only what is specific to Compass.
2. **Agree with Classic where Classic is standard.** Classic annotates each slot
   with an RDF predicate. Where it uses a standard term (`rdf:type`,
   `rdfs:label`, `dcterms:created`, `dcterms:modified`, SIOC), this binding uses
   the same term.
3. **Controlled vocabularies are data.** Genres are classes; subtypes,
   scopes, statuses, and source-header values are SKOS concepts. A store can
   list, label, and validate them without the toolchain.
4. **Structure, not prose.** The binding exports metadata, registers, sections,
   links, and code references. Body prose stays in the Markdown and in the Lexis
   tree (§16).
5. **Asserted and derived kept apart.** Facts written in the corpus are
   asserted. Values the toolchain computes, such as authority weight, are
   exported only on request and only in a separate graph.
6. **Deterministic output.** The same corpus at the same revision MUST yield the
   same triples, with no blank nodes, so exports can be diffed and checked.

## Required Namespaces

### The `compass:` vocabulary

The vocabulary namespace is **`https://w3id.org/compass/vocab#`**. Its concept
schemes use sibling namespaces under `https://w3id.org/compass/`.

The namespace IRI is permanent. w3id.org is a redirection service: the IRI
stays fixed while the document it redirects to can move, so a change of hosting
is made by updating the redirect, never by changing the IRI. Changing the
namespace IRI itself would orphan every triple already stored under it and
would be a major amendment (§13). The redirect is registered by a pull request
to the w3id.org repository; until it is, the IRIs serve as names but do not
dereference, which does not affect their use as identifiers.

Hosting matters only for the vocabulary. The `tag:` IRIs of documents and
records (see [Required Identity](#required-identity)) are names that no service
resolves, so no lapse of hosting can affect them; the dated authority keeps them
unique even if its domain later changes hands. The vocabulary namespace uses
w3id.org rather than a self-hosted domain because a lapsed domain can be
registered by someone else, who could then serve arbitrary content at every
vocabulary IRI. w3id.org is a community-maintained service whose redirect rules
are public, so no single domain renewal can break or hijack the namespace. It is
not contractually guaranteed; if it ever failed, stored triples would keep their
meaning and only dereferencing would stop.

The vocabulary is published as `vocab/compass.ttl`, with the SHACL shapes in
`vocab/compass-shapes.ttl` and the JSON-LD context at
`https://w3id.org/compass/context.jsonld`. The vocabulary carries
`owl:versionInfo` equal to this specification's `schema-version`.

### Prefixes

Table: Prefixes used by this binding and the namespace IRIs they abbreviate.

| Prefix | Namespace IRI | Use |
|---|---|---|
| `compass:` | `https://w3id.org/compass/vocab#` | Compass classes and properties |
| `cstatus:` | `https://w3id.org/compass/status#` | Status concepts (§6) |
| `cscope:` | `https://w3id.org/compass/scope#` | Scope concepts (§5) |
| `csubtype:` | `https://w3id.org/compass/subtype#` | Subtype concepts (§4) |
| `cconcern:` | `https://w3id.org/compass/concern#` | Source-header `Concerns` values |
| `cstability:` | `https://w3id.org/compass/stability#` | Source-header `Status` values |
| `cweight:` | `https://w3id.org/compass/weight#` | Authority weights (derived only) |
| `rdf:` | `http://www.w3.org/1999/02/22-rdf-syntax-ns#` | |
| `rdfs:` | `http://www.w3.org/2000/01/rdf-schema#` | |
| `owl:` | `http://www.w3.org/2002/07/owl#` | |
| `xsd:` | `http://www.w3.org/2001/XMLSchema#` | |
| `dcterms:` | `http://purl.org/dc/terms/` | Titles, dates, creators, relations |
| `prov:` | `http://www.w3.org/ns/prov#` | Entities, activities, agents |
| `skos:` | `http://www.w3.org/2004/02/skos/core#` | Concept schemes |
| `sh:` | `http://www.w3.org/ns/shacl#` | Shapes |
| `cito:` | `http://purl.org/spar/cito/` | Citations |
| `doap:` | `http://usefulinc.com/ns/doap#` | Projects and repositories |
| `sioc:` | `http://rdfs.org/sioc/ns#` | Spaces |
| `foaf:` | `http://xmlns.com/foaf/0.1/` | Documents and people |
| `schema:` | `https://schema.org/` | Source code |

## Required Identity

### Authorities

Every namespace MUST declare a **tagging authority** in its repository's
project manifest (`compass.sexp`, COMPASS-DRAFT-toolchain-D4), under the
`:authorities` key added by COMPASS-DRAFT-toolchain-D17. An authority follows
RFC 4151: a DNS name or an email address that the steward controlled on a given
date, followed by a comma and that date (`YYYY`, `YYYY-MM`, or `YYYY-MM-DD`).
For example, `example.net,2026` or `sloane@example.net,2026-10`. The date is part
of the identity: it fixes whose name the authority was when minting began, so
the IRIs stay unique even if the domain later changes hands. An authority, once
used, MUST NOT change; a new authority would mint new IRIs for every document.

The examples in this specification use the illustrative authority
`example.net,2026`.

### IRI forms

Let `<A>` be the namespace's authority and `<ns>` the namespace short name in
lower case. Every IRI is a `tag:` URI:

Table: IRI forms for each kind of resource.

| Resource | IRI form | Example |
|---|---|---|
| Namespace | `tag:<A>:<ns>` | `tag:example.net,2026:compass` |
| Document | `tag:<A>:<ns>/<ID>` | `tag:example.net,2026:compass/COMPASS-0001` |
| Register entry (`D`, `O`, M) | `tag:<A>:<ns>/<ID>` | `tag:example.net,2026:compass/COMPASS-D3` |
| Provisional document or entry | `tag:<A>:<ns>/<provisional ID>` | `tag:example.net,2026:compass/COMPASS-DRAFT-toolchain` |
| Translation (§19) | `tag:<A>:<ns>/<ID>@<locale>` | `tag:example.net,2026:origin/ORIGIN-0012@fr` |
| Section of a document | document IRI `#` anchor | `…/COMPASS-0003#the-uniqueness-guarantee` |
| Component concept | `tag:<A>:<ns>/component/<component>` | `tag:example.net,2026:compass/component/toolchain` |
| Person or software agent | `tag:<A>:agent/<slug>` | `tag:example.net,2026:agent/sloane` |
| Source file or directory | `tag:<A>:<ns>/src/<path>` | `tag:example.net,2026:compass/src/src/ledger.lisp` |
| Commit | `tag:<A>:<ns>/commit/<full SHA>` | |
| Node owned by one document (citation, code reference, acceptance) | document IRI `#` local name | `…/COMPASS-0003#cite-4f1c2a9e` |

Rules:
- `<ID>` is the Compass identifier exactly as written (§5, §13); it is ASCII and
  needs no escaping. Paths in source IRIs are percent-encoded where RFC 3986
  requires it.
- A cross-namespace reference uses the **target** namespace's authority, read
  from the federated repository's manifest. An exporter that cannot find the
  authority of a referenced namespace MUST report it and omit the triple, never
  guess an authority.
- Source files, directories, and commits belong to a repository rather than a
  namespace; they use the first namespace listed in the repository's
  `:namespaces`, called its primary namespace.
- Agent slugs are derived from the identity as canonicalised by `.mailmap`
  (§7): lower case, with runs of characters other than letters and digits
  replaced by one hyphen. Email addresses are never exported.
- Nodes owned by one document use fragment IRIs with deterministic local names:
  `#acceptance`; `#cite-<h>` and `#ref-<h>`, where `<h>` is the first eight
  hexadecimal digits of the SHA-256 of the citation's title or the code
  reference's text. Blank nodes MUST NOT be used.

### Provisional identifiers and assignment

A provisional document or entry is exported under its provisional IRI. Once
`compass assign` gives it a canonical identifier, exports use the canonical
IRI, and for every alias in the ledger the exporter emits

```turtle
<tag:example.net,2026:compass/COMPASS-DRAFT-toolchain>
    owl:sameAs <tag:example.net,2026:compass/COMPASS-0003> .
```

so that triples recorded under the provisional IRI still join. The canonical
resource also carries `compass:provisionalAlias` with the provisional
identifier as a string.

### Relationship to Classic URIs

Classic mints URIs of the form `classic:<authority>,<date>:<path>/<local-id>`,
modelled on tag URIs (`CLASSIC:src/uri.lisp@6e4f02d`). A Compass `tag:` IRI maps
to a Classic URI by replacing the scheme only:

```text
tag:example.net,2026:compass/COMPASS-0001
classic:example.net,2026:compass/COMPASS-0001
```

This corrects §5, which says that a document's identifier "is identical to the
document's Classic URI". The identifier is identical to the *last segment* of
both IRIs, and the two IRIs correspond one-to-one. Two consequences fall to
Classic, not to this binding:
- Classic's parser requires a Crockford base32 local identifier, optionally
  followed by a slug, so `COMPASS-0001` would be misparsed. Classic must accept
  Compass identifiers as local identifiers in the space it uses for Compass
  documents.
- In Turtle and SPARQL, `classic:` is also a prefix label in Classic's slot
  annotations. A `classic:`-scheme IRI MUST therefore always be written in angle
  brackets, never as a prefixed name, and Classic SHOULD give its vocabulary
  prefix a label other than `classic:`.

## Required Classes

Table: Classes defined or reused by the binding.

| Class | Superclasses | Instances |
|---|---|---|
| `compass:Document` | `prov:Entity`, `foaf:Document` | Every Compass document |
| `compass:Survey`, `compass:Eval`, `compass:Architecture`, `compass:Plan`, `compass:Log`, `compass:Ref`, `compass:Guide`, `compass:Spec`, `compass:Glossary`, `compass:Ideation` | `compass:Document` | One class per §4 genre |
| `compass:Memo` | `compass:Document` | Memo host documents; defined once COMPASS-DRAFT-agent-workflow-D1 is accepted |
| `compass:Record` | `prov:Entity` | Every register entry |
| `compass:DecisionRecord`, `compass:OpenQuestion`, `compass:MemoRecord` | `compass:Record` | `D`, `O`, and M entries (§8; COMPASS-DRAFT-agent-workflow-D2) |
| `compass:Section` | | A heading-delimited section of a document |
| `compass:Namespace` | `sioc:Space` | A Compass namespace |
| `doap:Project`, `doap:GitRepository` | | The project and repository that own a namespace |
| `compass:Acceptance` | `prov:Activity` | The act of accepting a document (§6) |
| `compass:Commit` | `prov:Activity` | A Git commit, exported with history |
| `foaf:Person`, `prov:SoftwareAgent` | `prov:Agent` | Authors, reviewers, approvers; assistants |
| `compass:ExternalWork` | | A work cited from outside the corpus (§9) |
| `compass:CodeReference` | | A commit-pinned code reference (§9) |
| `compass:SourceFile`, `compass:Directory` | `schema:SoftwareSourceCode` (files) | Items of the source map (COMPASS-DRAFT-source-headers) |

The genre class follows the `genre:` value, not the file prefix:
`genre: Architecture` gives `compass:Architecture`. Subtypes are not classes;
they are concepts (see below).

### Concept schemes

Each controlled vocabulary is a `skos:ConceptScheme`. Every concept carries
`skos:prefLabel` equal to the value as written in front-matter, and
`skos:inScheme`.

Table: Concept schemes and their members.

| Scheme | Members | Source |
|---|---|---|
| `cscope:` | `component`, `project`, `program` | §5 |
| `csubtype:` | `prior-art`, `comparison`, `tradeoff`, `threat-model` (pending), `tutorial`, `howto` | §4; `threat-model` from COMPASS-DRAFT-secure-development |
| `cstatus:` | `Draft`, `Proposed`, `In-Review`, `Accepted`, `Implemented`, `Design-Record`, `Deprecated`, `Superseded`, `Rejected`, `Withdrawn`, `Current` | §6, as amended by COMPASS-DRAFT-toolchain-D5 |
| `cconcern:` | `security-boundary`, `concurrency`, `wire-format`, `persistent-format`, `public-api`, `ffi`, `hot-path` | COMPASS-DRAFT-source-headers |
| `cstability:` | `experimental`, `stable`, `deprecated` | COMPASS-DRAFT-source-headers |
| `cweight:` | `Authoritative`, `Directive`, `Contextual`, `Provisional`, `Excluded` | COMPASS-DRAFT-toolchain-D12 (derived) |

A component is a concept in a per-namespace scheme, `tag:<A>:<ns>/component`,
since component names are chosen by each namespace rather than controlled by
the standard.

Pending members (marked above) enter the published vocabulary only when the
amendment that defines them is accepted.

## Required Mappings

### Front-matter

Each §7 field maps as follows. The subject is the document's IRI. A field that
is absent produces no triple. Git-derived fields (§7) are exported with their
effective value, whether written or derived.

Table: Front-matter fields and the triples they produce.

| Field | Predicate | Object |
|---|---|---|
| `id` | the subject IRI itself; `dcterms:identifier` | the identifier as a string |
| `title` | `dcterms:title` and `rdfs:label` | string with language tag from `language` |
| `genre` | `rdf:type` | the genre class |
| `subtype` | `compass:subtype` | `csubtype:` concept |
| `scope` | `compass:scope` | `cscope:` concept |
| `program`, `project` | `compass:program`, `compass:project` | string |
| `component` | `dcterms:subject` | component concept |
| (namespace, from the identifier) | `sioc:has_space` | namespace IRI |
| `language` | `dcterms:language` | `xsd:language` literal |
| `status` | `compass:status` | `cstatus:` concept |
| `api-version`, `schema-version` | `compass:apiVersion`, `compass:schemaVersion` | string |
| `created`, `updated` | `dcterms:created`, `dcterms:modified` | `xsd:date` |
| `authors` | `dcterms:creator` | agent IRI (`foaf:Person`) |
| `reviewers` | `compass:reviewer` | agent IRI |
| `approved-by`, `reviewed` | `compass:acceptance` to a `compass:Acceptance` node, and the shortcut `compass:approvedBy` | see [Review and acceptance](#review-and-acceptance) |
| `provenance.assistant` | `compass:assistedBy` | agent IRI (`prov:SoftwareAgent`) |
| `provenance.session` | `compass:assistanceSession` | string |
| `supersedes` | `dcterms:replaces` | document IRI |
| `superseded-by` | `dcterms:isReplacedBy` | document IRI |
| `relates-to` | `dcterms:relation` | document IRI |
| `cites` | `cito:cites` | `compass:ExternalWork` node |
| `decisions`, `open-questions`, `memos` | `compass:introduces` for each record defined in this document; `compass:amends` for each listed record defined elsewhere | record IRI |
| `glossary` | `compass:glossary` | document IRI |
| `read-if` (extension, COMPASS-DRAFT-toolchain-D13) | `compass:readIf` | string |
| Unregistered extension keys | not exported | |

An external work carries `dcterms:title`, `compass:locator` (string), and
`compass:external true`.

### Registers

A `D`, `O`, or M record defined by a heading in a document (COMPASS-DRAFT-toolchain-D16)
produces:

Table: Triples for a register record.

| Source | Predicate | Object |
|---|---|---|
| The heading's identifier | the subject IRI; `dcterms:identifier` | string |
| The heading's title | `rdfs:label` | string |
| The record's kind | `rdf:type` | `compass:DecisionRecord`, `compass:OpenQuestion`, or `compass:MemoRecord` |
| The host document | `compass:hostedBy` (inverse `compass:hosts`) | document IRI |
| The defining section | `compass:definedIn` | section IRI |
| `**Status:**` | `compass:status` | `cstatus:` concept |
| `**Read-if:**` (memos) | `compass:readIf` | string |
| `**Basis:**` (memos) | `compass:basis` (the text), plus `compass:evidence` for each reference or identifier it contains | string; code reference or document IRI |
| `**Recorded:**` (memos) | `compass:recorded` | `xsd:date` |
| `**Superseded-by:**` (memos) | `dcterms:isReplacedBy` | record or document IRI |
| Context, Decision, Alternatives, and body prose | not exported by default; with `--with-text`, `compass:context`, `compass:decision`, `compass:alternatives`, `compass:text` | string |

### Ledger facts

For every ledger entry (COMPASS-DRAFT-toolchain-D3) the identified resource
carries `compass:allocatedOn` (`xsd:date`), `compass:allocatedBy` (agent IRI),
`compass:originalPath` (string), and, where present, `compass:provisionalAlias`
with the matching `owl:sameAs` from the provisional IRI.

### Body structure

- **Sections.** Each heading produces a `compass:Section` with `rdfs:label`
  (the heading text), `compass:anchor`, `compass:level` (an integer), and
  `compass:order` (its position in the document); the document relates to it by
  `dcterms:hasPart`, and a subsection to its parent by `dcterms:isPartOf`.
- **Document links.** A link to another document's identifier (§9) produces
  `compass:linksTo` from the containing section to the target document or
  section. `compass:linksTo` is a subproperty of `dcterms:references`.
- **Code references.** Each commit-pinned code reference produces a
  `compass:CodeReference` with `compass:path`, `compass:symbol` or
  `compass:lineStart` and `compass:lineEnd`, `compass:revision`, and
  `compass:inNamespace` for a cross-repository reference; the containing section
  relates to it by `compass:citesCode`. Where the manifest knows the forge, the
  reference also carries `schema:url` with the forge permalink.

### Review and acceptance

Acceptance is modelled as an activity so that the evidence of review can grow
without changing the vocabulary:

```turtle
<tag:example.net,2026:compass/COMPASS-0003>
    compass:acceptance <tag:example.net,2026:compass/COMPASS-0003#acceptance> ;
    compass:approvedBy <tag:example.net,2026:agent/sloane> .

<tag:example.net,2026:compass/COMPASS-0003#acceptance>
    a compass:Acceptance ;
    prov:wasAssociatedWith <tag:example.net,2026:agent/sloane> ;
    dcterms:date "2026-10-20"^^xsd:date ;
    compass:approvalMode compass:SoloApproval .
```

`compass:approvalMode` is `compass:SoloApproval` or `compass:SecondReviewer`,
from the namespace's declaration (COMPASS-DRAFT-agent-workflow-D6). The
shortcut `compass:approvedBy` MUST be emitted alongside the activity, for
simple queries. A future forge integration attaches its evidence, such as a
signed workflow transition, to the acceptance node.

### Namespaces, projects, and history

- A namespace carries `compass:prefix` (its short name), `compass:steward`
  (agent IRI), `compass:approvalMode`, `compass:ownedBy` (a `doap:Project`), and
  `compass:federatesWith` for each namespace in the manifest's `:federation`.
- The project carries `doap:name` and `doap:repository` to a
  `doap:GitRepository` with `doap:location` where the manifest gives a remote.
- With `--history`, each commit that touched a document produces a
  `compass:Commit` with `compass:touched` (document IRI), `prov:endedAtTime`,
  `prov:wasAssociatedWith` (the committer's agent IRI), and `compass:assistedBy`
  for each `Assisted-by:` trailer (COMPASS-DRAFT-agent-workflow-D7).

### Source map

When source headers exist (COMPASS-DRAFT-source-headers), each in-scope file
produces a `compass:SourceFile`, and each directory with a description a
`compass:Directory`, related by `dcterms:isPartOf`.

Table: Source-header fields and the triples they produce.

| Header field | Predicate | Object |
|---|---|---|
| Summary line | `schema:description` | string |
| `Read-if` | `compass:readIf` | string |
| `See` | `compass:rationale` | document, section, or record IRI |
| `Invariant` | `compass:invariant` | string, one triple per field |
| `Tests` | `compass:testedBy` | source file or directory IRI, or the test system's name |
| `Status` | `compass:stability` | `cstability:` concept |
| `Generated-by` | `compass:generatedBy` | source file IRI |
| `Concerns` | `compass:concern` | `cconcern:` concept |
| `Co-change` | `compass:coChange` | source file IRI |

The source map describes one revision: the export carries
`compass:asOfRevision` on the namespace.

### Derived values

Authority weight (COMPASS-DRAFT-toolchain-D12) is computed, never written in the
corpus. It is exported only with `--derived`, as `compass:weight` with a
`cweight:` concept, and only into the named graph
`tag:<A>:<ns>/graph/derived`. Formats without named graphs (Turtle,
N-Triples) receive derived triples only in a separate output file. A consumer
can always tell an asserted fact from a computed one.

## Required Shapes

The SHACL shapes in `vocab/compass-shapes.ttl` express the standard's
constraints over the exported graph. They cover:
- the required fields of §7, per document;
- the status vocabulary of each genre family (§6, amended by
  COMPASS-DRAFT-toolchain-D5 and D12, and COMPASS-DRAFT-agent-workflow-D4);
- agreement of `dcterms:isReplacedBy` with `cstatus:Superseded`;
- record kinds: a record listed under `decisions` is a `compass:DecisionRecord`,
  and so on;
- memo hosting: a `compass:MemoRecord` is hosted only by a `compass:Memo`.

The shapes MUST be **generated** from the same vocabulary data the Lisp
validator uses, never written separately, so that the two cannot drift. The
Lisp validator (`compass check`) remains the authority for conformance (§22);
the shapes let tools outside Lisp check exported data.

An excerpt:

```turtle
compass:PlanShape a sh:NodeShape ;
    sh:targetClass compass:Plan ;
    sh:property [
        sh:path compass:status ; sh:minCount 1 ; sh:maxCount 1 ;
        sh:in ( cstatus:Draft cstatus:Proposed cstatus:In-Review cstatus:Accepted
                cstatus:Implemented cstatus:Design-Record cstatus:Deprecated
                cstatus:Superseded cstatus:Rejected cstatus:Withdrawn ) ] ;
    sh:property [ sh:path dcterms:title ; sh:minCount 1 ] ;
    sh:property [ sh:path dcterms:creator ; sh:minCount 1 ] .
```

Shapes are the one place where the binding uses blank nodes. They are
vocabulary, not exported corpus data.

## Required Export Behaviour

The toolchain exports with `compass export --rdf FORMAT`
(COMPASS-DRAFT-toolchain-D17). An exporter conforming to this specification:

- MUST support N-Triples and Turtle, and SHOULD support N-Quads, TriG, and
  JSON-LD;
- MUST produce byte-identical output for the same corpus at the same revision
  with the same options (N-Triples and N-Quads sorted; Turtle grouped by
  subject in IRI order);
- MUST NOT emit blank nodes;
- MUST NOT emit a triple whose object is a reference it could not resolve; it
  reports the reference instead, as `ref/doc-resolves` does;
- MUST export only asserted triples by default, with `--derived`, `--history`,
  and `--with-text` as explicit opt-ins;
- MUST refuse to export a namespace without a declared authority;
- SHOULD declare every prefix of the [prefix table](#prefixes) in formats that
  have prefixes.

## Alignment with Classic

Table: Where this binding and Classic's current slot predicates meet.

| Concept | Classic today | This binding | Note |
|---|---|---|---|
| Identity | `uri` slot annotated `rdf:about` | The subject IRI | Same model: in RDF the identity is the subject, not a property |
| Type | `rdf:type` | `rdf:type` | Adopted |
| Name | `rdfs:label` on named resources | `rdfs:label` and `dcterms:title` | Adopted, with `dcterms:title` added |
| Created, modified | `dcterms:created`, `dcterms:modified` | Same | Adopted, replacing §7's `schema:dateCreated`/`dateModified` |
| Containment | SIOC | `sioc:has_space`, `compass:Namespace ⊑ sioc:Space` | Adopted |
| Workflow state | `workflow:currentState` | `compass:status` | Classic's `workflow:` prefix has no published IRI; a forge integration maps one to the other |
| Classic-specific terms | `classic:`, `workflow:`, `wiki:`, `theme:` prefixes | Not used | Classic needs a table expanding these prefixes to IRIs before its data can be joined with Compass exports |

### Corrections to the standard

This binding corrects four points of [COMPASS-0001](../Compass.md), to be
carried by amendment when it is accepted:
1. **§5:** the identifier corresponds one-to-one to a Classic URI; it is not
   identical to one (see [Relationship to Classic URIs](#relationship-to-classic-uris)).
2. **§7:** `supersedes` maps to `dcterms:replaces`, not `prov:wasRevisionOf`,
   which PROV-O reserves for a revised version of the same entity; a superseding
   document is usually a different one.
3. **§7:** `title` maps to `dcterms:title` (and `rdfs:label`), not the legacy
   `dc:title`; `created` and `updated` map to `dcterms:created` and
   `dcterms:modified`; `id` maps to the subject IRI, not `classic:uri`.
4. **§7 and §17:** the RDF column and the mapping table are replaced by
   references to this specification.

## Security Considerations

- **Personal data.** Exports name authors, reviewers, and approvers, and with
  `--history` they reveal who committed what and which assistants were used.
  Email addresses are never exported. A private corpus's export inherits the
  corpus's confidentiality; loading it into a shared store discloses it.
- **Federated stores.** Loading several namespaces' exports into one store
  merges data of differing trust. Queries whose results feed agents should
  respect the federation trust levels proposed in
  [COMPASS-DRAFT-secure-development](Survey.SecureDevelopment.md) (candidate 2).
- **JSON-LD remote contexts.** A JSON-LD processor that fetches
  `https://w3id.org/compass/context.jsonld` at load time depends on that host
  and can be fed a substituted context. Consumers SHOULD pin a local copy of the
  context, as JSON-LD 1.1 §10 advises.
- **Disclosure.** Security-related `O`-records and memos are exported like any
  other record. A public export is subject to the same disclosure care as the
  public corpus (COMPASS-DRAFT-secure-development-O4).
- **Exported text is still text.** With `--with-text`, record prose enters the
  store. Anything that later delivers query results to an agent faces the
  prompt-injection risks described in the secure-development survey.

## Conformance Walkthrough

This walkthrough exports a fragment of the toolchain Plan as it would stand
after acceptance. Its identifier, numbers, dates, and authority are
illustrative.

1. **Declare the authority** in `compass.sexp`:
   ```lisp
   :authorities ((:namespace "COMPASS" :authority "example.net,2026"))
   ```
2. **Run the export:**
   ```text
   compass export --rdf turtle > compass.ttl
   ```
3. **Read the result.** The document, one of its decisions, one citation, and
   the alias left by assignment:

```turtle
@prefix compass: <https://w3id.org/compass/vocab#> .
@prefix cstatus: <https://w3id.org/compass/status#> .
@prefix cscope:  <https://w3id.org/compass/scope#> .
@prefix dcterms: <http://purl.org/dc/terms/> .
@prefix rdfs:    <http://www.w3.org/2000/01/rdf-schema#> .
@prefix owl:     <http://www.w3.org/2002/07/owl#> .
@prefix xsd:     <http://www.w3.org/2001/XMLSchema#> .
@prefix sioc:    <http://rdfs.org/sioc/ns#> .
@prefix cito:    <http://purl.org/spar/cito/> .
@prefix c:       <tag:example.net,2026:compass/> .
@prefix ag:      <tag:example.net,2026:agent/> .

c:COMPASS-0003
    a compass:Plan ;
    dcterms:identifier "COMPASS-0003" ;
    dcterms:title "Compass Validation Toolchain"@en ;
    rdfs:label "Compass Validation Toolchain"@en ;
    compass:scope cscope:program ;
    compass:status cstatus:Accepted ;
    dcterms:language "en"^^xsd:language ;
    dcterms:created "2026-10-05"^^xsd:date ;
    dcterms:creator ag:sloane ;
    compass:assistedBy ag:opencode ;
    compass:approvedBy ag:sloane ;
    sioc:has_space <tag:example.net,2026:compass> ;
    dcterms:subject <tag:example.net,2026:compass/component/toolchain> ;
    dcterms:relation c:COMPASS-0001 ;
    compass:introduces c:COMPASS-D3 ;
    compass:readIf "changing validation rules, ID allocation, or the ledger format" ;
    compass:provisionalAlias "COMPASS-DRAFT-toolchain" ;
    cito:cites <tag:example.net,2026:compass/COMPASS-0003#cite-4f1c2a9e> .

c:COMPASS-D3
    a compass:DecisionRecord ;
    dcterms:identifier "COMPASS-D3" ;
    rdfs:label "The allocation ledger holds immutable facts only" ;
    compass:status cstatus:Accepted ;
    compass:hostedBy c:COMPASS-0003 .

<tag:example.net,2026:compass/COMPASS-0003#cite-4f1c2a9e>
    a compass:ExternalWork ;
    dcterms:title "PEP 1 — PEP Purpose and Guidelines" ;
    compass:locator "PEP Editor Responsibilities & Workflow" ;
    compass:external true .

c:COMPASS-DRAFT-toolchain owl:sameAs c:COMPASS-0003 .
```

Description: the Plan is typed as `compass:Plan`, with its title, scope,
status, language, creation date, creator, assistant, approver, namespace,
component, a related document, a decision it introduces, its routing line, its
provisional alias, and a citation. The decision is typed, labelled, given a
status, and linked to its host. The citation is a fragment of the Plan's IRI.
The provisional IRI is declared the same as the canonical one.

4. **Load and query.** Any SPARQL store accepts the file. Three example
   queries:

```sparql
PREFIX compass: <https://w3id.org/compass/vocab#>
PREFIX cstatus: <https://w3id.org/compass/status#>
PREFIX dcterms: <http://purl.org/dc/terms/>

# Accepted decisions whose host relates to a document that has been replaced
SELECT ?decision ?host ?old ?new WHERE {
  ?decision a compass:DecisionRecord ;
            compass:status cstatus:Accepted ;
            compass:hostedBy ?host .
  ?host dcterms:relation ?old .
  ?old dcterms:isReplacedBy ?new .
}
```

```sparql
PREFIX compass:  <https://w3id.org/compass/vocab#>
PREFIX cconcern: <https://w3id.org/compass/concern#>

# Security-boundary files with no tests named in their headers
SELECT ?file WHERE {
  ?file a compass:SourceFile ; compass:concern cconcern:security-boundary .
  FILTER NOT EXISTS { ?file compass:testedBy ?t }
}
```

```sparql
PREFIX compass: <https://w3id.org/compass/vocab#>
PREFIX dcterms: <http://purl.org/dc/terms/>
PREFIX rdfs:    <http://www.w3.org/2000/01/rdf-schema#>

# Open questions across every loaded namespace, with their host's last update
SELECT ?q ?label ?host ?modified WHERE {
  ?q a compass:OpenQuestion ; rdfs:label ?label ; compass:hostedBy ?host .
  OPTIONAL { ?host dcterms:modified ?modified }
}
ORDER BY ?modified
```

5. **Validate.** Run any SHACL processor with `vocab/compass-shapes.ttl` over
   the export; it reports the same structural violations `compass check` would,
   for the subset of rules the shapes express.

## Open Questions

### COMPASS-DRAFT-semantic-binding-O1 — Dereferenceable identifiers

`tag:` URIs are names, not locations: no protocol resolves them. That suits
permanent identity, but a browser or linked-data client cannot follow one. An
HTTP form could be added alongside, such as a w3id.org path per namespace
(`https://w3id.org/compass/id/<ns>/<ID>`) redirecting to the rendered document,
linked by `owl:sameAs`. Is that worth registering, and who would host the
targets?

### COMPASS-DRAFT-semantic-binding-O2 — People across authorities

An author who works in two namespaces with different authorities receives two
agent IRIs. Should the exporter link them (`owl:sameAs`, by matching `.mailmap`
identities across the federation), should people use a single authority of
their own, or should people be identified by an external IRI such as an ORCID
or a WebID where they have one?

### COMPASS-DRAFT-semantic-binding-O3 — Record text by default

Record prose (Context, Decision, Alternatives) is the most useful text to
search, and the decisions are short. Exporting it by default would make the
store far more useful for questions such as "which decisions mention
federation?". It also enlarges the injection and disclosure surface. Should
`--with-text` become the default for records only?

### COMPASS-DRAFT-semantic-binding-O4 — Ontology profile

The vocabulary is written in RDFS with a few OWL terms (`owl:sameAs`,
`owl:versionInfo`). Should it declare an OWL 2 profile (for example OWL 2 RL)
so that reasoners can infer superclass membership and inverse properties, or
stay at RDFS and leave inference to queries?

## Afterword: Limits

- **An export, not a store.** Under Tier 1 the RDF is derived; editing triples
  changes nothing in the corpus. Tier 2 reverses this only when Classic becomes
  the authoritative store (§16).
- **No prose.** Bodies stay in Markdown and Lexis; the store answers questions
  about structure, relationships, and status, not about what a section says,
  except for record text under `--with-text`.
- **Names that do not resolve.** Neither the `tag:` IRIs nor the w3id.org
  vocabulary IRIs dereference until a redirect is registered (see
  COMPASS-DRAFT-semantic-binding-O1).
- **Classic's half.** Joining Compass data with Classic data needs Classic's
  prefix table and its acceptance of Compass identifiers as local identifiers.
  Both are Classic's work.
- **Shapes cover structure only.** Judgment-level review (§6, `compass-review`)
  and the Git-dependent checks have no SHACL form.
- **Forge integration is separate.** A later specification, built on this one,
  will cover the relation of Compass documents and records to Classic's project
  management imprint (`CLASSIC-DRAFT-project-management`): tasks, branch
  references, review requests, signed workflow transitions as acceptance, the
  seeding of draft Logs from the Git event stream, and the Tier-2 storage of a
  corpus. It will add its terms under its own namespace, through §18, without
  changing this vocabulary.
