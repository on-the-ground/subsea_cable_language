# SCP-0004 — Voyage Plans and Fully Touchdown Cable artifacts

- Status: Accepted
- Author(s): Codex (agent) for on-the-ground
- Created: 2026-09-18
- Updated: 2026-09-18
- Requires owner decision: yes
- External implementation ADRs: [runtime ADR 0007 — Voyage results and incremental reuse boundary](https://github.com/on-the-ground/subsea_cable_runtime/blob/docs-vessel-frame/docs/decisions/0007-voyage-results-and-incremental-reuse.md) (proposed)
- Evidence repositories/revisions: `on-the-ground/subsea_cable_runtime` POC and the owner-directed Vessel plan
- Supersedes: the source-level equation “Program = Cable” and the `.subc` source extension
- Superseded by: —

## Summary

A Subsea Cable source file is a **Voyage Plan**, written with the `.vyg`
extension. A **Vessel** accepts that plan and carries the Frontend, Codebase,
Carousel, Outcome & Value Store, Scheduler, and Host ports needed to realize it.
The Carousel remains the only deduction engine.

A terminated voyage produces two distinct results:

1. a **Fully Touchdown Cable**, represented externally as a canonical ordered
   list of content hashes; and
2. the Root outcome, including its output value or `NoOutput` when successful,
   or its failure/cancellation diagnostic otherwise.

The list is deliberately simple. Provenance, lineages, dependency observations,
and reverse lookup live in a sidecar index rather than inside each item hash.
That separation lets a later voyage reuse unchanged cable segments after an
intermediate Goal changes, without rewriting the earlier voyage or repeating
every deduction.

## Motivation

The earlier documents used *Program* and *Cable* as synonyms. That was useful
while specifying lazy deduction, but it leaves no precise name for the authored
input versus the concrete, grounded result. It also makes the complete Runtime
look like a collection of peer components rather than the product an agent or
operator addresses.

The new model is:

```text
Voyage Plan (.vyg)
        |
        v
      Vessel
  [Frontend + Codebase + Carousel + Store + Scheduler + Host ports]
        |
        +----> Fully Touchdown Cable (ordered hash list)
        |
        `----> Root outcome
```

The distinction is required for persistent Codebases and incremental
deduction. A later edit should invalidate only the cable segments whose
structure or required values changed. The immutable record of an earlier
voyage must remain auditable.

## Terminology and ownership

### Voyage Plan

A Voyage Plan is the authored Subsea source unit. It contains one Root, Goal
definitions, value bindings, dependencies, routing, Anchors, and ordered policy
metadata. Its source extension is `.vyg`.

The plan defines structural dependency and routing precedence. It does not
define wall-clock execution order, success aggregation, retry, or other
Scheduler policy.

### Vessel

Vessel names the complete Consumer Runtime and its outward product boundary.
Agent-facing CLI, MCP, service, or library entry points are Vessel adapters.
They may validate, commit, resolve, run, and inspect voyages through the
assembled whole.

Implementations may expose Carousel or other component APIs for embedding,
testing, or replacement. Such APIs must be identified as component surfaces;
they are not alternate Consumer Runtimes and must not transfer deduction
ownership away from Carousel.

### Carousel

Carousel is still the only deduction engine. It resolves demanded Goal aliases,
applies reduction rules, commits deduction records, tracks occurrences and
lineages, and publishes Touchdowns. Vessel does not become a second deduction
engine merely because it owns the outward control surface.

### Fully Touchdown Cable

A Fully Touchdown Cable is the finalized projection of every grounded
evaluation instance reached by one terminated voyage. Under SCP-0001's current
conservative value barrier, each grounded Touchdown occurrence has exactly one
evaluation instance. “Fully” means that every list item is a terminal grounded
leaf, never an intermediate Goal. It
does not force every merely possible or undemanded future occurrence to deduce,
and it does not change lazy alias observation or Scheduler demand semantics.

The artifact records the voyage that actually occurred. Different demand,
prefetch, policy, alias timing, or Host-produced routing values may legitimately
produce different cables from the same authored plan. The provenance record
makes those differences auditable.

## Source extension

`.vyg` replaces `.subc` immediately. This project is pre-1.0 and has no stable
source-extension compatibility promise, so the canonical corpus and
documentation do not carry a dual-extension transition period. A consumer may
offer a local legacy import tool, but `.subc` is not a conforming source
extension after this SCP.

This change affects filenames and manifests, not the token grammar.

## Voyage result contract

A terminated voyage exposes an envelope equivalent to:

```text
VoyageResult
  voyagePlanHash
  touchdownCableHash
  touchdownHashes[]
  rootOutcome
  provenanceRef
```

The concrete serialization and hash algorithm are profile-versioned, but the
following semantics are portable.

### Ordered hash list

- `touchdownHashes` is an ordered **list**, not a set.
- Order is the lexicographic order of stable structural occurrence paths. Each
  committed reduction assigns child ordinals from its authored result order;
  parallel children therefore retain authored branch order. Host completion,
  Scheduler dispatch, and deduction wall-clock order never affect the list.
- Structural sharing does not collapse evaluation instances. Distinct
  occurrences or argument tuples are preserved. If two evaluation instances
  have identical grounded content, the same hash may appear twice.
- `touchdownCableHash` hashes a version tag and a length-framed encoding of the
  ordered list.
- The Root outcome is not folded into the cable hash. Structure and execution
  outcome remain different lifecycles.

### Touchdown content identity

Each `touchdownHash` identifies a canonical grounded leaf descriptor. The
descriptor contains enough structural content to distinguish at least:

- function-leaf versus Anchor-leaf kind;
- the selected authored artifact and artifact-local leaf path;
- the concrete Anchor identifier where applicable;
- canonical resolved arguments;
- ordered occurrence policy metadata; and
- the language/value-encoding profile needed to interpret those fields.

`runId`, runtime occurrence ID, list position, lineage, timestamps, attempt IDs,
Host outcomes, and mutable storage locations are excluded. They are provenance,
not reusable content identity.

A Touchdown hash identifies grounded structural work. It does **not** prove that
two Host invocations have the same effects or result. Host implementation or
capability versions belong to an outcome-reuse policy and journal, not to the
portable structural identity unless a later profile explicitly says otherwise.

## Provenance and reverse lookup

Every cable artifact has a provenance sidecar. It supports both directions:

```text
deduction / intermediate Goal occurrence -> cable list positions or ranges
cable list position                      -> evaluation instance + deduction ancestry + lineages
```

The sidecar records at least:

- the source voyage and language/profile revisions;
- each new voyage occurrence, grounded evaluation instance, and active lineages;
- selected `ArtifactHash`, canonical arguments, primitive profile, and
  committed reduction-result hash for each deduction;
- the ordered cable positions or ranges contributed by that deduction;
- stable dependency slots for alias and value observations; and
- an optional `reusedFrom` reference when a new deduction reuses an immutable
  segment from an earlier voyage.

Lineage is intentionally outside `touchdownHash`. Moving an unchanged subtree
must not destroy content reuse merely because its new route or list position is
different.

## Dependency fingerprints

### Alias observations

`ArtifactHash + arguments` is not enough to reuse a complete subtree. Each
unqualified descendant reference resolves when its own occurrence is demanded.
An alias may even move between two observations of the same `Name/Arity` in one
voyage.

An alias fingerprint is therefore an ordered collection of observations keyed
by a stable reference slot within the reusable segment:

```text
referenceSlot, requested Name/Arity, selected ArtifactHash, observed revision
```

It is not a map from `Name/Arity` to one hash and must not use a run-local
occurrence ID as its portable key.

### Value observations

Segments whose reduction depends on routed values, lookup keys, primitive
results, or other Host-derived values also record stable value slots and
canonical value digests. Such a segment can be reused only after the new voyage
has established identical required values.

An Outcome Journal may establish those values without re-invoking the Host, but
outcome reuse is not implied by structural reuse. Without an authorized journal
or cache policy, the Host is evaluated again and only then may equal values
permit downstream structural reuse.

## Incremental deduction

Incremental deduction creates a new voyage and new immutable deduction records.
It never edits or retargets a committed record from an earlier voyage.

A cable segment is structurally reusable only when all identity inputs match:

- selected artifact and canonical arguments;
- relevant language, encoding, and primitive profiles;
- ordered policy-bearing structural content;
- every alias observation at its stable reference slot; and
- every required value observation at its stable value slot.

On reuse, the Vessel/Carousel boundary commits a new record for the new
occurrence and may point to the prior immutable segment through `reusedFrom`.
New occurrence IDs, lineages, and cable positions are computed for the new
voyage. They are not copied into content identity.

Changing one intermediate Goal invalidates that Goal's affected segment and
every value-dependent downstream segment, but not unrelated segments whose
fingerprints still match. Implementations may use Merkle trees, interval
indexes, or other internal structures; the portable outward cable remains the
simple ordered hash list.

## Boundary audit

- Carousel remains the sole deduction owner.
- Scheduler still owns demand, eligibility, attempts, and policy.
- The Voyage Plan declares structure, not execution timing.
- The Codebase may store immutable Voyage Plans, cable manifests, deduction
  provenance, and reuse indexes; it still stores no live evaluation outcome.
- Root outputs and Host outcomes stay in the Runtime-owned Outcome & Value
  Store or an explicit Outcome Journal.
- Reuse never changes the meaning of an old hash or committed deduction.

## Compatibility and migration

- Source filenames change from `.subc` to `.vyg`.
- Token grammar and structural syntax are unchanged.
- Existing source content can be migrated by renaming the file.
- Corpus manifests and fixture filenames change atomically with the canonical
  documentation.
- Runtime repositories update their pinned language revision before renaming
  examples and user-facing commands.
- Existing deduction ledgers remain historical evidence but lack the portable
  cable/provenance fields required for incremental reuse.

## Conformance impact

- all canonical source fixtures use `.vyg`;
- documentation and grammar comments use `.vyg`;
- conformance runners read the paths in `conformance/cases.tsv` rather than
  assuming an extension;
- voyage-result conformance must cover ordered parallel entries, duplicate
  hashes, policy-bearing descriptors, provenance in both directions, distinct
  alias observations for the same `Name/Arity`, pure-segment reuse,
  value-dependent invalidation, and immutable `reusedFrom` records;
- a Runtime that has not implemented voyage-result artifacts must report that
  capability as unsupported rather than returning an incomplete object under
  the Fully Touchdown Cable name.

## Owner decision record

- Decision requested on: 2026-09-18
- Options presented: retain Program/Cable synonymy and `.subc`; rename only the
  Runtime product; or adopt Voyage Plan input and content-addressed Cable output
- Owner response: adopt `.vyg` Voyage Plans and return a Fully Touchdown Cable
  hashed list plus output, with lineage/provenance sufficient for incremental
  reuse after intermediate Goal edits
- Decision date: 2026-09-18
- Authorized specification changes: source extension, Program/Cable ontology,
  Vessel outward boundary, voyage-result and provenance contracts
- Authorized conformance changes: rename all canonical source fixtures and add
  voyage-result scenarios as the external Vessel implements them

## Final rationale

The authored route, the engine that grounds it, the grounded cable, and the
execution result are four different things. Naming them separately makes the
Vessel usable as an agent-facing product and makes incremental deduction
auditable without confusing structural reuse with effect reuse.
