# SCP-0004 — Voyage Plans and Fully Touchdown Cable artifacts

- Status: Accepted
- Author(s): Codex (agent) for on-the-ground
- Created: 2026-09-18
- Updated: 2026-09-18
- Requires owner decision: yes
- External implementation ADRs: [runtime ADR 0007 — Voyage results and incremental reuse boundary](https://github.com/on-the-ground/subsea_cable_runtime/blob/main/docs/decisions/0007-voyage-results-and-incremental-reuse.md) (proposed; link becomes valid after the companion Runtime PR merges)
- Evidence repositories/revisions: `on-the-ground/subsea_cable_runtime` POC and the owner-directed Vessel plan
- Activation pull request: [#5](https://github.com/on-the-ground/subsea_cable_language/pull/5)
- Effective language revision: `003b1e2404e01ad3e33eee8781ec2f408055091c`
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

## Motivation and reproduction

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

The companion Runtime POC can already publish Touchdowns, retain immutable
deduction records, and exercise alias timing and value barriers. It cannot yet
persist a Voyage Plan, produce a Cable manifest, reverse-map the manifest to
intermediate deductions, or reuse a segment across runs. Runtime ADR 0007 and
`docs/VESSEL_PLAN.md` preserve that implementation gap as the reference
experiment rather than silently choosing storage behavior.

## Existing invariant under pressure

- The former equation “Program = Cable” gives the authored input and realized
  result one name, so it cannot express a persisted plan that produces an
  auditable grounded artifact.
- Deduction commits an exact artifact per demanded occurrence, while
  unqualified descendants remain mutable until their own demand. A reuse key
  based only on the parent artifact and arguments loses those later alias
  observations.
- `StructureHash` is policy-erased and shared, while occurrences, lineages,
  evaluation instances, and outcomes have different lifecycles. Putting all of
  them into one hash destroys either structural sharing or auditability.
- Carousel owns structural commits; Scheduler and Host own execution. Reusing
  structure must not silently become permission to reuse an outcome or effect.

## Classification

Voyage Plan naming, source extension, Cable identity, immutable deduction
reuse, and the Vessel/Carousel public boundary are portable language and
Runtime-contract questions. They cannot be repaired by changing one Goal,
adding a Host Anchor, selecting a Scheduler profile, or choosing a storage
backend. Merkle layout, indexes, persistence technology, Outcome Journal
retention, and transport APIs remain implementation-specific Runtime work.

## Proposed specification

### Terminology and ownership

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
prefetch, policy effects, alias timing, or Host-produced routing values may
legitimately cause a voyage to reach different leaves. Policy metadata itself
does not change a leaf's structural content hash. The provenance record makes
both the structural result and the active policies auditable.

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
  schedulerProfile
  deductionControlRef
  touchdownCableHash
  touchdownHashes[]
  rootOutcome
  provenanceRef
```

The concrete serialization and hash algorithm are profile-versioned, but the
following semantics are portable.

`schedulerProfile` identifies the Scheduler semantics active for the voyage.
`deductionControlRef` refers to canonical provenance for the demand mode,
explicit demand sequence, initial prefetch target, and every prefetch
reconfiguration. These envelope fields MUST NOT enter an individual Touchdown
content hash.

### Ordered hash list

- `touchdownHashes` is an ordered **list**, not a set.
- Order is the lexicographic order of each leaf's root-to-leaf vector of
  non-negative child ordinals. Ordinal segments are compared numerically, not
  as decimal strings: `[0, 2]` precedes `[0, 10]`. Each committed reduction
  assigns child ordinals from its authored result order; parallel children
  therefore retain authored branch order. An implementation MUST NOT sort a
  serialized dotted occurrence path. Host completion, Scheduler dispatch, and
  deduction wall-clock order never affect the list.
- Structural sharing does not collapse evaluation instances. Distinct
  occurrences or argument tuples are preserved. If two evaluation instances
  have identical grounded content, the same hash may appear twice.
- `touchdownCableHash` hashes a version tag and a length-framed encoding of the
  ordered list.
- The Root outcome is not folded into the cable hash. Structure and execution
  outcome remain different lifecycles.

### Membership and termination

An evaluation instance becomes a Cable member when Carousel commits its
grounded leaf and publishes `TouchdownPublished`. Membership is monotonic for
that voyage:

- speculative and explicitly demanded Touchdowns use the same rule;
- a published instance remains a member if it is withheld, consumed,
  discarded, never dispatched, failed, or cancelled;
- attempt success and Root success do not determine membership;
- an occurrence that never reaches `TouchdownPublished` is not a member.

`DiscardTouchdown` changes the prefetch-window lifecycle; it does not undo the
deduction commit or remove a Cable member. A failed or cancelled voyage exposes
the ordered Cable accumulated through its terminal boundary together with the
separate failed or cancelled Root outcome.

A voyage that publishes no Touchdowns has a valid empty Cable. Its
`touchdownCableHash` is the hash of the same profile/version tag and canonical
length-framed list encoding used for every Cable, with item count zero. The
empty Cable is not represented by a missing hash, `null`, or the hash of an
unframed empty byte sequence.

Publication-time membership intentionally records **all structure the voyage
actually grounded**, rather than only work later handed to or completed by the
Host. Consequently, the same Voyage Plan, Codebase state, Host behavior, and
inputs may produce different Cable hashes under different demand or prefetch
histories. Meaningful Cable comparison therefore requires the same Scheduler
profile and the same deduction-control provenance, including every prefetch
change.

### Touchdown content identity

Each `touchdownHash` identifies a canonical grounded leaf descriptor. The
descriptor contains enough structural content to distinguish at least:

- function-leaf versus Anchor-leaf kind;
- the selected policy-erased `StructureHash` and artifact-local leaf path;
- the concrete Anchor identifier where applicable;
- canonical resolved arguments;
- the language/value-encoding profile needed to interpret those fields.

`runId`, runtime occurrence ID, list position, lineage, timestamps, attempt IDs,
Host outcomes, ordered policies, and mutable storage locations are excluded.
They are occurrence, execution, or provenance data—not reusable structural
content identity. The exact selected `ArtifactHash` remains in the deduction
record even when policy erasure permits structural reuse.

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
referenceSlot, requested Name/Arity, selected ArtifactHash,
selected StructureHash, observed revision
```

It is not a map from `Name/Arity` to one hash and must not use a run-local
occurrence ID as its portable key. The full tuple is audit evidence. Structural
compatibility compares stable slot, requested `Name/Arity`, and selected
`StructureHash`; if the exact `ArtifactHash` differs while that structural
projection remains equal, the new deduction still records the newly selected
artifact and its policies.

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

- selected policy-erased structural identity and canonical arguments;
- relevant language, encoding, and primitive profiles;
- every alias observation at its stable reference slot; and
- every required value observation at its stable value slot.

A change that affects only policy metadata may therefore reuse the prior
policy-erased structural segment while committing the new `ArtifactHash`, new
occurrence metadata, and new Scheduler policy inputs. The new voyage can still
produce a different overall Cable if those policies cause it to reach a
different set of leaves.

On reuse, the Vessel/Carousel boundary commits a new record for the new
occurrence and may point to the prior immutable segment through `reusedFrom`.
New occurrence IDs, lineages, and cable positions are computed for the new
voyage. They are not copied into content identity.

Changing one intermediate Goal invalidates that Goal's affected segment and
every value-dependent downstream segment, but not unrelated segments whose
fingerprints still match. Implementations may use Merkle trees, interval
indexes, or other internal structures; the portable outward cable remains the
simple ordered hash list.

## Alternatives

| Alternative | Benefits | Costs/reason rejected |
|---|---|---|
| Make no language change; keep Program and Cable synonymous | No migration | Cannot distinguish persisted input from grounded result and provides no portable incremental-reuse artifact |
| Return a set of hashes | Simple membership | Loses authored order and duplicate evaluation instances, so it cannot reproduce the realized Cable |
| Put run ID, occurrence ID, lineage, and position into item hashes | Direct lookup from each item | Makes identical structural work different in every voyage and prevents cross-run reuse |
| Use only `ArtifactHash + arguments` | Small reuse key | Misses descendant lazy alias observations and value-dependent branches |
| Put provenance inside the list | One object | Couples a simple portable result to Runtime-specific indexes and mutable audit detail |
| Treat structural reuse as Host outcome reuse | Maximum apparent speedup | Can suppress effects and reuse results under the wrong Host or value evidence |
| Begin membership at consume/first dispatch | Excludes speculative work and reduces prefetch sensitivity | Makes a structural deduction artifact depend on Scheduler dispatch and erases published, committed Touchdown structure that was withheld or discarded |
| **Accepted core: ordered structural hashes plus provenance sidecar** | Simple outward artifact, duplicate preservation, bidirectional audit, and independent reuse policy | Requires versioned descriptor/fingerprint profiles and a separate Outcome Journal decision |

## Philosophy and boundary audit

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
- F9 still governs which captured top-level values enter `StructureHash`.
  Cable artifacts produced before that rule is accepted are experimental and
  MUST NOT be used as portable cross-version reuse evidence.

## Grammar and conformance impact

- all canonical source fixtures use `.vyg`;
- documentation and grammar comments use `.vyg`;
- conformance runners read the paths in `conformance/cases.tsv` rather than
  assuming an extension;
- voyage-result conformance must cover ordered parallel entries, duplicate
  hashes, policy-erased descriptors with policy-bearing provenance, distinct
  alias observations for the same `Name/Arity`, pure-segment reuse,
  value-dependent invalidation, immutable `reusedFrom` records, published but
  withheld/discarded/failed/cancelled membership, failed and cancelled voyage
  results, and the canonical empty Cable;
- comparisons asserting equal Cable hashes must fix the Scheduler profile,
  demand mode and sequence, initial prefetch target, every prefetch
  reconfiguration, applicable Host/primitive profiles, alias-observation
  timeline, and routed input evidence;
- a Runtime that has not implemented voyage-result artifacts must report that
  capability as unsupported rather than returning an incomplete object under
  the Fully Touchdown Cable name.

## Reference experiment

The external `on-the-ground/subsea_cable_runtime` POC is pinned to this language
PR by submodule while the two proposals are reviewed. It proves demand-time
alias selection, immutable per-occurrence deductions, Touchdown publication,
discard/consume acknowledgement, conservative value barriers, and strict
Carousel/Host/Scheduler ownership. It deliberately reports SCP-0004 voyage
artifacts and incremental reuse as unsupported. Runtime ADR 0007 and the Vessel
plan define the staged experiment and its acceptance tests.

## Unresolved questions

- **F9 artifact value closure:** `StructureHash` does not yet have a decided
  top-level value-closure rule. Cable descriptors and reuse decisions produced
  before F9 is accepted are experimental and MUST NOT be used as portable
  cross-version reuse evidence.
- Concrete canonical encodings and algorithms remain profile-versioned even
  after the semantic field sets are confirmed.

## Owner decision record

- Decision requested on: 2026-09-18
- Options presented: retain Program/Cable synonymy and `.subc`; rename only the
  Runtime product; or adopt Voyage Plan input and content-addressed Cable output
- Owner response: adopt `.vyg` Voyage Plans and return a Fully Touchdown Cable
  hashed list plus output, with lineage/provenance sufficient for incremental
  reuse after intermediate Goal edits
- Decision date: 2026-09-18
- Accepted core: source extension, Program/Cable ontology, Vessel outward
  boundary, ordered hashed-list result, and provenance sufficient for
  incremental reuse
- Additional owner response: confirmed publication-time monotonic membership,
  failed/cancelled voyage behavior, and canonical empty Cable on 2026-09-18
- Detailed contract: numeric structural ordering, descriptor fields,
  stable-slot fingerprints, immutable `reusedFrom`, policy erasure, value
  evidence, envelope comparison metadata, and structural-versus-outcome reuse
  separation were written after the core response, reviewed in language PR #5,
  and **confirmed by the owner on 2026-09-18** in that pull request's review
  thread. They are confirmed by that record, not by this proposal describing
  them.
- Conditions: the F9 dependency in Unresolved questions stands. Cable
  descriptors produced before F9 is accepted are experimental.
- Authorized conformance changes: rename all canonical source fixtures and add
  voyage-result scenarios as the external Vessel implements them

## Activation record

- Canonical documents synchronized: public naming, philosophy, semantics,
  agent guidance, and implementation-neutral contracts and plans
- Grammar projections synchronized: `.vyg` source extension documentation in
  `SubseaCable.g4` and `SubseaCable.ebnf`
- Diagnostics and examples synchronized: Voyage Plan, Fully Touchdown Cable,
  and result-envelope terminology and examples
- Conformance cases synchronized: canonical fixture extensions, deduction
  documentation, and voyage-result cases
- Compatibility and migration notes synchronized: SCP compatibility section,
  public naming guidance, and migration playbook
- Verification commands and results: activation PR checks passed

## Final rationale

The authored route, the engine that grounds it, the grounded cable, and the
execution result are four different things. Naming them separately makes the
Vessel usable as an agent-facing product and makes incremental deduction
auditable without confusing structural reuse with effect reuse.
