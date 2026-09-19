# Consumer Runtime Contract

This document defines the minimum contract for a Subsea Cable consumer implementation.
It is language-neutral. “MUST”, “MUST NOT”, “SHOULD”, and “MAY” describe
conformance requirements; concrete API spelling is implementation-specific.

This contract is for independently maintained implementations. It does not
designate an official Runtime or authorize Runtime source code in the language
repository.

This contract does not define concrete `@policy` behavior. It defines only the
boundary needed to carry policy metadata without corrupting Goal structure.

## 1. Component boundary

A conforming consumer consists of independently testable components:

```text
Frontend
  decode → preprocess → parse → validate → prepare artifacts

Codebase
  immutable artifact store + mutable Name/Arity index + revision history

Carousel
  demand-driven deduction → committed structure + undeduced frontier

Outcome & Value Store
  evaluation outcomes + scope outputs → resolved routed values

Scheduler Port
  grounded occurrences + policy metadata ↔ execution outcomes

Host Port
  primitive semantics + arrow-function evaluation + $Anchor resolution/invocation
```

The assembled whole is the **Vessel**, the complete Consumer Runtime. Vessel
is a name for that whole and for the product an operator or agent addresses.
No individual component, package, or interface inside it may claim to be the
whole Vessel, and every component other than Carousel MUST NOT deduce.

The deployment MAY package these together. Their responsibilities MUST remain
separable in interfaces and tests.

- The Carousel MUST resolve a Goal alias only when that occurrence is demanded. It
  MUST NOT resolve Anchors, evaluate grounded leaves, or interpret policies.
- The Runtime-owned Outcome & Value Store MUST accept actual Scheduler/Host
  outcomes and expose resolved routed values through a narrow read port.
- The Carousel MAY read that port but MUST NOT write outcomes; the Codebase MUST
  NOT store live outcomes or routed Runtime values.
- The Host's arrow-function evaluator MUST NOT call another Subsea Goal or
  create Goal structure; it evaluates only the terminal body already validated
  for its Goal.
- The Host MUST NOT decide Goal topology or silently perform hidden
  orchestration for the migrated slice.
- The Scheduler MUST NOT rewrite Goal definitions, routing, or committed
  deductions.
- The Frontend and Codebase MUST NOT depend on one Scheduler or Host registry.

### 1.1 Live Vessel–Host cooperation

A general-purpose Vessel is not a compiler that emits Host code or a prospective
Cable and then relinquishes the voyage. From initial Root demand until a
terminal Root outcome, it MUST remain the logical owner of the voyage lifecycle:

```text
Carousel deduction -> Touchdown -> Scheduler eligibility -> Host evaluation
                   -> outcome/value -> resumed deduction
```

The Host returns typed outcomes to the Runtime-owned Outcome & Value Store.
Accepted outputs may resolve explicit routed values, and Carousel may read those
values to unblock or select later deductions. This loop repeats without
rewriting any committed deduction until the voyage terminates.

This is a semantic boundary, not a process-topology requirement. Vessel and
Host MAY run in one process, link statically or dynamically, communicate by
callback or FFI, embed a module, or use local or remote messaging. A suspended
Vessel remains logically live if its state can resume the same unfinished
voyage.

A compiler MAY validate, normalize, cache prepared artifacts, or generate code
linked with this Runtime loop. Those preparation steps MUST keep each
unqualified Goal reference symbolic until its exact occurrence is demanded and
MUST NOT create a deduction record outside a voyage. A deployment that
permanently hands all later control to a detached Host MUST NOT advertise
conformance to the general Vessel profile. It MUST NOT present prospective
output as the terminated voyage's Fully Touchdown Cable or Root outcome. See
[SCP-0006](../proposals/0006-live-vessel-host-cooperation.md).

## 2. Frontend contract

### 2.1 Source decoding and preprocessing

The Frontend MUST:

- decode source strictly as UTF-8;
- reject malformed input as `InvalidSourceEncoding`;
- implement the preprocessing algorithm in `conformance/README.md`;
- preserve source spans through comment removal and newline coalescing;
- treat Identifiers and hash qualifiers as ASCII-only;
- decode String escapes to Unicode scalar sequences without normalization;
- reject an invalid scalar escape as `InvalidUnicodeEscape`.

The parser MUST consume the entire normalized token stream through EOF.

### 2.2 Validation

Validation MUST occur before any artifact from the source unit is committed and
before deduction begins. It MUST cover at least:

- exactly one valid Root;
- binding, parameter, and destructuring uniqueness;
- casing law and structural contexts;
- function-arrow leaf restrictions;
- direct structural positioning of value-producing Goal/Anchor calls;
- Goal name/arity resolution;
- callability;
- map-key identity and duplicates;
- statically decidable lookup/destructuring failures;
- conditional selector purity and branch-map structure;
- guarded-recursion analysis and unguarded cycles;
- structure-valued lookup map binding site, entry form, and use position;
- all cases in `conformance/cases.tsv`.

Outside a function-arrow leaf, validation MUST reject a `Goal(...)` or
`$anchor(...)` nested inside an argument, policy argument, operator operand,
lookup key, or ordinary value container as `InvalidStructuralContext`. Direct
Goal-arrow bodies, composition elements, and resolving-map branches remain
valid call occurrences. Primitive expressions create no occurrence and remain
valid in arguments. Inside a function-arrow leaf, nested Anchors remain Host
call sites while every Subsea Goal reference remains forbidden.

A conditional structural selector MUST be an effect-free value expression. A
Goal or Anchor occurrence/call anywhere in that selector is
`InvalidStructuralContext`. Every conditional branch is validated, but a
guarded recursive definition component is valid when every definition cycle
crosses a recursive branch beneath a conditional map and that map has at least
one branch that exits the component. Validation MUST NOT attempt to prove that a
particular input terminates.

The conditional pipeline contains exactly the selector and branch map, with an
optional trailing comma. A later serial stage must contain that pipeline as one
nested stage. A bare Goal name in selector position is value lookup, not Goal
shorthand, and reports `UnboundName` when no value binding exists.

A structure-valued ordinary lookup map is a top-level binding whose right-hand
side is a map literal and whose entries are Goal structure. Validation MUST
require every entry to be a deferred Goal reference, an Anchor reference, or a
serial or parallel composition of those. It MUST reject a bare identifier entry
as `InvalidStructuralContext`, because a bare identifier in that position is a
value name, and it MUST reject an inline Goal arrow entry with the same kind:
the grammar admits one there, but an entry is selected by lookup rather than
routed into, so its parameters would have no caller. Such a map MUST be used
only in a Goal-structure position; using it as a value is
`InvalidStructuralContext`. A selected entry receives no implicit
upstream value. A named map is never a conditional branch map: the conditional
pipeline's second element MUST be an authored branch-map literal, so `[sel,
Routes]` is a two-stage serial composition and selection from a named map is
written `Routes[key]`
([SCP-0009](../proposals/0009-structure-valued-lookup-maps.md)).

Anchor and policy argument expressions undergo ordinary validation. The external
Anchor identifier, signature, policy identifier, applicability, and behavior do
not belong to structural validation.

### 2.3 Artifact preparation and lazy Goal names

The Frontend MUST apply the categories in `README.md` without destroying lazy
name resolution:

- an unqualified Goal reference MUST be stored as symbolic `Name/Arity`;
- a matching local definition or current codebase entry MAY establish its
  validity at source-validation time, but MUST NOT pin future occurrences;
- a hash-qualified reference MUST resolve to exactly one full `ArtifactHash`
  before storage and MUST retain that pinned hash;
- referenced arity MUST be checked whenever its target is statically known;
- `$Anchor` and `@policy` identifiers MUST remain external symbolic names;
- a prepared artifact MUST capture the transitive closure of the top-level value
  bindings its term references by name, in canonical order, and MUST NOT capture
  a Goal reference, which stays symbolic;
- a captured structure-valued lookup map MUST be captured by structure: its keys
  and entry shapes are part of the artifact, while an unqualified Goal reference
  inside an entry stays symbolic `Name/Arity`
  ([SCP-0008](../proposals/0008-artifact-hash-value-closure.md)).

The prepared artifact MUST retain enough source information for diagnostics and
human-readable traces. Unqualified references are intentionally not fully
elaborated: demand-time alias resolution is language semantics.

## 3. Diagnostic contract

Every diagnostic MUST expose:

```text
kind          stable machine-readable identifier
phase         source | validation | deduction | host | policy
message       human-readable, non-normative text
span?         original source span when available
artifact?     full ArtifactHash after storage or demand-time resolution
occurrence?   occurrence identity after deduction begins
lineages?     active lineage set when available
details       structured expected/actual/available information
cause?        wrapped external failure when applicable
```

Messages MAY vary. `kind` and `phase` MUST be stable. A consumer SHOULD collect
independent validation errors in one pass when recovery is unambiguous, but MUST
NOT continue into artifact commit or deduction after validation failure.

The error ownership table in `README.md` is normative. In particular:

- statically provable missing or wrong-arity Goals are validation errors;
- missing or wrong-arity aliases discovered when an occurrence is demanded are
  deduction errors of the same stable kinds;
- dynamically discovered `KeyNotFound`, `DestructureMismatch`, and cycles are
  deduction errors;
- `CycleDetected` MUST NOT be reported solely because a selected guarded branch
  creates a fresh child occurrence resolving to an ancestor's `GoalNodeId`;
- when late resolution re-enters an ancestor `GoalNodeId`, the absence of an
  intervening committed conditional selection MUST report occurrence-scoped
  `CycleDetected`, while at least one intervening selection MUST NOT report that
  diagnostic and uses a fresh occurrence if deduction otherwise succeeds;
- Host primitive failures while routing are reported in the deduction context;
- arrow-function and Anchor lookup/signature/implementation failures are Host
  errors;
- unknown, conflicting, or inapplicable policies are policy errors, including
  `PolicyConflict` for an identifier claimed by both pinned declarations and
  `PolicyDenied` for a Host-addressed policy the deployment's forwarding
  allowlist withholds;
- a Host leaf returning `NoOutput` where a value is required reports the single
  kind `NoOutputNotRoutable`: phase `deduction` when detected while routing into
  a deduction, and phase `host` when detected inside a function-leaf body
  ([SCP-0010](../proposals/0010-dynamic-nooutput-errors.md)).

## 4. Value contract

The runtime MUST represent at least:

- Boolean;
- Number as a validated source spelling plus the active Host primitive profile's
  produced numeric values;
- String as an exact Unicode scalar sequence;
- Map with deterministic structural key identity;
- internal `NoOutput`, distinct from all user values.

String identity MUST use decoded scalar values without Unicode normalization or
case folding. Map-key identity MUST follow the fixed structural rules in the
language specification and MUST NOT be delegated to host-language equality.

Every deduction MUST record the active Host primitive-semantics profile and
version in provenance. An implementation profile MAY require one fixed Host
primitive profile per run. In all cases a later profile change MUST NOT rewrite
an already committed deduction.

## 5. Codebase contract

The minimum Codebase abstraction exposes operations equivalent to:

```text
getArtifact(fullHash) → artifact | not-found
resolveCurrent(name, arity) → fullHash + codebaseRevision | not-found
resolvePrefix(name, hashPrefix) → zero | one | many artifacts
commitSourceUnit(artifacts, aliasUpdates) → codebaseRevision | conflict
appendDeduction(record) → committed | conflict
getDeduction(occurrenceId) → record | not-found
```

Requirements:

- all named Goals in a valid source unit are eligible for storage, including
  Goals unreachable from Root;
- artifacts are addressed by full content hash;
- the current name index maps exact `(ASCII name, arity)` to one current hash;
- alias updates create observable codebase revisions;
- unqualified references remain symbolic in stored artifacts and resolve through
  that index only when their occurrences are demanded;
- each successful deduction atomically records the selected hash, observed
  revision, arguments, lineages, and result structure before its children can be
  demanded;
- a failed deduction MUST NOT leave a partial deduction record;
- old hashes remain directly addressable unless an explicit storage/GC policy
  removes them;
- a failed source unit MUST NOT partially update its current-name view;
- the reference in-memory Codebase SHOULD commit the unit atomically;
- storage backend collation, locale, and filesystem casing MUST NOT alter name
  equality.

The canonical encoding, hash algorithm, collision response, and short-prefix
minimum are implementation-profile decisions that MUST be recorded before Phase
2. Until a cross-runtime profile is accepted, hashes from different profiles
MUST NOT be claimed interoperable.

## 6. Artifact projections

An implementation MUST distinguish:

- **Authored artifact projection**: canonical prepared Goal term including
  ordered policy metadata and the captured closure of referenced top-level value
  bindings. Incidental formatting and source spans remain sidecar metadata
  unless a later language contract deliberately includes them;
- **Structural projection**: the same term with policy metadata erased;
- **GoalNodeId**: structural identity plus arity;
- **Occurrence identity**: one concrete structural occurrence/edge;
- **Deduction record**: one occurrence's committed reference kind, requested
  `Name/Arity`, selected full hash, observed codebase revision, arguments,
  reduction result, and active lineages;
- **Evaluation instance**: one occurrence/node evaluated with a routed argument
  tuple and active lineage set.

Two artifacts that differ only in policies MAY share a `GoalNodeId` but MUST
remain distinct authored artifacts. An unqualified occurrence has no selected
`GoalNodeId` until deduction resolves its alias. `{Goal, Goal}` MUST preserve two
occurrence identities even when both deductions later select one shared Goal
node.

## 7. Carousel and Runtime-value contract

Two kinds of deduction request appear throughout this document:

- **explicit demand**: the Scheduler asks for one specific occurrence;
- **speculative deduction**: the Carousel deduces an occurrence on its own while
  replenishing the Touchdown window toward its prefetch target.

Unless a rule says *explicit*, "demanded" and "deduced" cover both. The two
resolve aliases, commit deduction records, and obey every other law in this
document identically; they differ only in who initiated the request, and rules
that name *explicit* demand apply to the Scheduler-initiated case alone.

The Carousel accepts a prepared Root occurrence and deduces only what is demanded.
It MUST:

- keep every unqualified occurrence symbolic until that exact occurrence is
  demanded;
- atomically resolve the then-current `(name, arity)` alias, apply the selected
  artifact's reduction rule, and commit a deduction record;
- reuse the committed record if the same occurrence is demanded again;
- keep hash-qualified occurrences pinned while still allowing their reduction
  to remain lazy;
- reduce composite Goals without executing grounded Host leaves;
- obtain primitive value semantics needed by reduction from the Host Port;
- evaluate conditional selectors through Host primitive semantics and expose
  exactly the selected structural branch;
- create a fresh child occurrence for every selected recursive step rather than
  committing a back-edge to an ancestor occurrence;
- preserve serial dependencies and independent parallel structure;
- route only explicitly provided values;
- distinguish unkeyed parallel NoOutput from keyed resolving-map results;
- maintain structural sharing without implicitly merging evaluation instances;
- attach active lineage sets to produced occurrences and values;
- expose every committed deduction and the set of undeduced frontier
  occurrences;
- mark Touchdown when a committed deduction chain reaches a concrete leaf;
- never rewrite any committed deduction, whether or not its path has reached
  Touchdown;
- report occurrence-scoped deduction failures without inventing a run-level
  failure policy.

An unselected conditional branch MUST create no occurrence, resolve no alias,
observe no routed value, and publish no structural or Touchdown event. A valid
guarded recursion that continues indefinitely is non-termination or resource
exhaustion, not `CycleDetected`.

A child selected across any committed conditional branch edge MUST remain
undeduced until the Scheduler explicitly demands that child. Carousel MAY
commit the selection and expose the symbolic child, but MUST NOT cross the edge
during speculative Touchdown replenishment, regardless of available window
capacity or whether local analysis classifies the edge as recursive. Each
explicit demand may deduce that selected child; a recursive step may then expose
the next symbolic child. Deduction-work budgets MAY additionally pause explicit
unfolding, but every completed deduction remains an immutable checkpoint.

When a Goal resolves to a `GoalNodeId` already on its ancestor chain and local
validation did not reject the cycle, Carousel MUST inspect the intervening path
before commit. With at least one committed conditional branch selection on that
path the re-entry is guarded: Carousel MUST NOT report `CycleDetected` for it
and MUST create a fresh occurrence if deduction otherwise succeeds.

With no committed conditional branch selection on that path, the response
depends on who asked. Under explicit demand, deduction MUST fail atomically
with `CycleDetected`. Under speculative deduction, Carousel MUST abandon that
path without committing an occurrence and without reporting a diagnostic, and
the re-entry is classified only once the occurrence is explicitly demanded.
Speculation therefore cannot spin inside an unguarded late alias cycle, and
`CycleDetected` remains reproducible across Runtimes with different prefetch
targets instead of depending on how far speculation happened to reach.

The Carousel produces occurrence/containment events for all deduced structural
occurrences, plus grounded leaf occurrences and dependency/readiness facts for
the Scheduler Port. This is required because a policy may target a serial,
parallel, resolving-map, Goal, or leaf occurrence. The Carousel MUST NOT copy a
composite's policy onto its descendants. It MUST NOT decide retry, timeout,
cancellation, delivery guarantees, result caching, duplicate suppression, or
success aggregation.

### 7.1 Outcome & Value Store boundary

The Outcome & Value Store belongs to the surrounding Runtime, metaphorically
the Vessel. It MUST:

- record actual attempt outcomes delivered through the Scheduler/Host boundary;
- retain satisfied scope outputs, including `NoOutput` as distinct from a
  missing result;
- resolve the value references required by explicit downstream routing;
- expose resolved values to Carousel through a read-only port;
- keep run-scoped execution state out of the Codebase and Deduction Ledger.

Carousel MUST stop at a value barrier when the required value is unresolved. It
MUST report `DeductionBlocked(pendingValue)` for explicit demand and the
corresponding `PrefetchBlocked` reason for speculative consideration. It MUST
NOT commit a placeholder, invoke a leaf to obtain the value, or hold a deduction
half-committed across evaluation. The Scheduler and Host MUST NOT rewrite a
deduction when they deliver an outcome.

This rule includes conditional selectors. Until every value required by the
selector is resolved, Carousel MUST select no key, create no branch occurrence
or observation, and emit no `ConditionalBranchSelected`.

## 8. Occurrence envelopes

Every structural occurrence exposed to the Scheduler MUST carry a
record equivalent to:

```text
runId
occurrenceId
parentOccurrenceId?
referenceKind?       unqualified | hash-qualified
requestedName?
requestedArity?
pinnedArtifactHash?  present before deduction only for hash-qualified references
artifactHash?        selected full hash after deduction
codebaseRevision?    revision observed by unqualified alias resolution
goalNodeId?          present after a Goal occurrence resolves
deductionState       undeduced | committed | failed
occurrenceKind       Goal | serial | parallel | resolving-map | goal-arrow-stage
                     | function-leaf | anchor
lineages[]
directPolicies[]     only policies authored on this exact occurrence
dependencies[]
source/provenance
```

This record preserves composite policy targets without inventing policy
inheritance. Containment and dependency are distinct relationships and MUST NOT
be collapsed.

### 8.1 Inline Goal-arrow stages

An inline Goal-arrow stage such as `[{code, logs}] -> Diagnose[code, logs]` is an
occurrence of kind `goal-arrow-stage`
([SCP-0007](../proposals/0007-inline-goal-arrow-stage-occurrence.md)). It MUST:

- stay undeduced until it is demanded **and** its routed input resolves, under
  the ordinary conservative value barrier;
- bind that input to its parameters on deduction, reporting a deduction-phase
  `DestructureMismatch` on a mismatch, and then reduce its body;
- commit a deduction record with `referenceKind = inline-arrow`, the parameter
  arity, no requested name and no artifact hash — the enclosing artifact
  supplies identity;
- add no lineage segment: its children inherit the enclosing Goal lineage;
- take one child-ordinal segment like any other committed reduction, so it
  occupies a position in every descendant leaf's root-to-leaf ordinal vector
  under SCP-0004. Lineage and ordinal position are separate axes; a Runtime that
  skipped the segment would produce a different `touchdownCableHash` for the
  same voyage.

A Scheduler-addressed `@policy` MAY target it like any other occurrence. It is a
composite, so `Reattempt` on it is rejected with `UnsupportedPolicyTarget`. A
Host-addressed policy MUST NOT target it.

Every grounded arrow-function or Anchor occurrence delivered across the runtime
execution boundary additionally carries an envelope equivalent to:

```text
runId
artifactHash
goalNodeId
occurrenceId
lineages[]
leafKind             function-leaf | anchor
leafIdentifier       function implementation ID or $Anchor identifier
arguments[]
directPolicies[]     each with identifier, decoded arguments, target span
hostPolicies[]       the source-order Host-addressed subsequence of directPolicies[]
dependencies[]       occurrence/evaluation prerequisites
provenance           Host primitive profile, codebase revision, runtime profile, source references
```

The exact serialization is profile-specific. The information and distinctions
are mandatory.

### 8.2 The Host-facing request carries only `hostPolicies[]`

The envelope above is Runtime-internal. The request the Dispatcher builds for
the Host MUST carry `hostPolicies[]` and MUST NOT carry `directPolicies[]`:
handing the Host the full envelope and asking it to read only a projection is
not a boundary, so a Scheduler-addressed entry has to be absent from what
crosses. `hostPolicies[]` preserves the same decoded arguments, target spans and
relative source order; an empty list is the ordinary case and MUST NOT be
conflated with a missing field. The Scheduler MUST NOT interpret, reorder, drop,
or synthesize the Host-addressed subsequence
([SCP-0011](../proposals/0011-policy-addressee-and-host-channel.md)).

## 9. Host Port contract

The Host Port supplies every concrete computation semantic that Subsea does not
own. It has three independently testable capabilities:

```text
Primitive Semantics   value operators requested during deduction or leaf evaluation
Function Evaluation   validated arrow-function leaf bodies
Anchor Resolution     lookup and invocation of opaque $Identifier capabilities
```

The Carousel MAY call Primitive Semantics while applying a reduction rule, but it
MUST NOT evaluate a grounded leaf. The Scheduler offers grounded arrow-function
and Anchor envelopes to the corresponding Host capability.

A direct Anchor occurrence supplies its grounded envelope. An Anchor call inside
an arrow-function body additionally supplies a stable call-site identity and
inherits the containing occurrence and lineages; it does not create another
Goal node. Host operations return a typed outcome equivalent to:

```text
Succeeded(value | NoOutput)
Failed(hostDiagnostic)
Cancelled(hostDiagnostic?)
```

For primitive semantics, the Host owns operand support, conversion, numeric
representation, exact results, and failures. Subsea still owns syntax,
precedence, short-circuit selection, structural map-key identity, and the rule
that successful results re-enter deduction as Subsea-representable values.

For an arrow-function leaf, the Host owns evaluation of its validated body. It
MUST reject or be unable to receive Subsea Goal calls in that body; only
primitive expressions, ordinary values/maps, and nested `$Anchor` calls are
permitted.

For `$Anchor`, the Host owns:

- identifier lookup;
- supported arity/signature verification;
- conversion between Subsea values and host values;
- invocation and effect execution;
- conversion of its result back to a Subsea value;
- Host-phase diagnostics.

The Host MUST NOT silently normalize String data, use host-native map equality
for structural keys, decide Goal alias resolution, or interpret unknown policy
metadata. A Host adapter MAY
expose capabilities to the Scheduler, but capability negotiation is not Goal
structure.

An Anchor implementation MUST be narrow enough that the selected migrated
program's dependency structure remains visible in Subsea. Wrapping the original
orchestrator as one Anchor is non-conforming for migration evidence.

## 10. Scheduler Port contract

The Scheduler receives structural occurrence records, grounded leaf envelopes,
containment, and dependency facts. It decides if, when, and how an evaluation
instance is offered to the Host Port's Function Evaluation or Anchor Resolution
capability. Function Evaluation uses the same Host boundary for any nested
`$Anchor` calls.

It owns:

- readiness and upstream-outcome interpretation;
- concurrency and resource ordering;
- concrete policy lookup and execution;
- cancellation and retry decisions;
- duplicate/coalescing behavior;
- run-level outcome and failure aggregation.

The Scheduler MUST preserve each ordered policy list and target occurrence. It
MUST reject unsupported policy identifiers explicitly. It MUST NOT silently
drop, rename, inherit, or copy a policy to child occurrences unless a documented
concrete policy specification requires that behavior.

### 10.1 Policy addressee resolution

Every `@policy` is addressed either to the Scheduler or to the Host. A policy is
Scheduler-addressed when it changes eligibility, the attempt lifecycle, or a
scope's outcome, and Host-addressed when it changes only what happens inside
exactly one grounded leaf invocation. Coalescing or batching several leaves
crosses more than one occurrence and is therefore Scheduler work.

A Runtime MUST pin three declarations at run start and resolve every
occurrence's policies against them, never against whatever is registered when
the occurrence happens to be disclosed:

- a versioned Scheduler policy registry identity;
- a Host capability snapshot/profile identity, declaring Host-addressed policy
  identifiers with their arity or argument schema alongside Anchors;
- the forwarding-allowlist revision.

When any of the three cannot be pinned the run MUST refuse to start, before any
occurrence is disclosed and before deduction begins; that refusal is a
profile-negotiation failure and adds no language diagnostic. Provenance records
all three identities, and a Runtime MUST NOT re-resolve an already disclosed
occurrence's addressee.

Resolution outcomes: claimed by the Scheduler only, it is Scheduler-addressed
and never crosses to the Host; claimed by the Host only, it is Host-addressed
and rides in the Host-facing request as `hostPolicies[]`; claimed by both, it is
`PolicyConflict`; claimed by neither, it is `UnknownPolicy`. `PolicyConflict`,
Host argument-schema mismatch (`InvalidPolicyArguments`), and an allowlist
refusal (`PolicyDenied`) are all authoritative in the `policy` phase at
occurrence disclosure. A `check` or lint pass with profiles attached MAY report
the same conflict earlier as a non-authoritative preflight diagnostic; the
authoritative phase does not change and the Frontend and Codebase still depend
on no registry.

A Host-addressed policy has `targetKinds = {function-leaf, anchor}`. On any
non-leaf occurrence kind it is `UnsupportedPolicyTarget`, and a composite's
policy is never forwarded to a descendant leaf. The Scheduler attempt lifecycle
wraps the Host invocation: a Host-addressed policy MAY read its own invocation's
attempt identity and cancellation signal, and the Host-policy surface exposes no
operation to create, retry, settle, extend or abandon an attempt, so the only
way that invocation changes Runtime attempt state is the outcome it returns.
Cancellation stays cooperative: the Host MUST forward a cancellation request to
a delegated worker and trace it, MAY still return a late `Succeeded`, and the
Scheduler decides what that means.

See [SCP-0011](../proposals/0011-policy-addressee-and-host-channel.md).

An implementation MAY ship a deterministic baseline Scheduler profile.
That profile MUST have a distinct name/version and MUST NOT be described as
language semantics.

## 11. Trace and observation contract

Policy discovery requires observable execution. A Runtime used as discovery
evidence MUST emit a normalized, machine-readable trace with events equivalent
to:

```text
SourceValidated
ArtifactCommitted
DeductionDemanded
AliasResolved
ConditionalBranchSelected
DeductionCommitted
OccurrenceExposed
LeafGrounded
EvaluationEligible
EvaluationStarted
EvaluationSucceeded
EvaluationFailed
EvaluationCancelled
DeductionFailed
PolicyRejected
RunCompleted
```

Each event MUST include the relevant run, artifact, occurrence, lineage, and
monotonic sequence information. Wall-clock timestamps MAY be included but MUST
NOT be the only ordering evidence. Values containing secrets MUST support
redaction without erasing structural identity.

`ConditionalBranchSelected` MUST additionally include the selector's stable
value slot, canonical value digest, selected normalized key, and active Host
primitive profile. The raw selector value MAY be redacted. These fields are the
audit and SCP-0004 reuse evidence for value-dependent structural selection.

Trace event names are a Runtime-profile diagnostic contract, not Subsea source
syntax. Changes must be versioned because migration comparisons depend on them.

## 12. Voyage result and incremental reuse

The authored input to a Vessel is a `.vyg` **Voyage Plan**. A Runtime claiming
the `voyage-result` capability MUST expose both the Root outcome and a **Fully
Touchdown Cable** when a voyage terminates. A Runtime that does not implement
the complete contract MUST report the capability as unsupported and MUST NOT
return a partial object under that name.

The Cable is a canonical ordered list of grounded evaluation-instance content
hashes. Order compares each leaf's root-to-leaf vector of non-negative child
ordinals lexicographically, with each ordinal compared numerically rather than
as a decimal string. Child ordinals come from authored reduction-result order,
so parallel branches retain authored branch order. An implementation MUST NOT
sort serialized dotted occurrence paths. Structural sharing MUST NOT collapse
distinct evaluation instances, and duplicate hashes MUST remain duplicate list
entries. Deduction, completion, and dispatch timing MUST NOT reorder the list.

Cable membership begins exactly when Carousel publishes
`TouchdownPublished` for the grounded evaluation instance. Once published, the
member MUST remain in that voyage's Cable whether it is speculative, withheld,
consumed, discarded, never dispatched, failed, or cancelled. Attempt and Root
success MUST NOT determine structural membership. `DiscardTouchdown` changes
window accounting only and MUST NOT undo a deduction or remove a Cable member.

A failed or cancelled voyage MUST expose the Cable accumulated through its
terminal boundary together with its separate Root outcome. A voyage with no
published Touchdown MUST expose a valid empty ordered list. Its Cable hash MUST
use the ordinary profile-tagged, length-framed list encoding with an item count
of zero; it MUST NOT use absence, `null`, or an unframed empty-byte hash.

The voyage-result envelope MUST identify the Scheduler profile and MUST carry a
reference to canonical deduction-control provenance containing the demand mode,
explicit demand sequence, initial prefetch target, and every later prefetch
reconfiguration. These fields MUST NOT enter an individual Touchdown content
hash. Equal-Cable conformance comparisons are meaningful only when that control
context and the other structure-affecting profiles, alias observations, and
routed input evidence are fixed.

The Runtime MUST keep content identity separate from provenance. Run IDs,
occurrence IDs, list positions, lineages, attempts, timestamps, and outcomes
MUST NOT enter a Touchdown content hash. A provenance index MUST support both
intermediate-deduction-to-cable-range and cable-position-to-deduction-ancestry
lookup.

An implementation that reuses a segment in a later voyage MUST:

- verify the selected policy-erased structural identity, canonical arguments,
  applicable profiles, stable-slot alias observations, and required value digests;
- commit new immutable deduction records for the new voyage;
- preserve new occurrence IDs, lineages, and positions rather than copying
  them into content identity; and
- record the prior segment through an auditable `reusedFrom` reference.

For a conditional segment, the selector result is a required value observation.
Its stable value-slot digest and primitive profile MUST match before the prior
selected branch segment can be reused. Matching only the selected key, including
the same `_` fallback, is insufficient.

A `Name/Arity` map is not a sufficient alias fingerprint: separate stable
reference slots may observe different hashes for the same name during one
voyage. The provenance MUST still record each exact selected `ArtifactHash` and
ordered policy list. A policy-only artifact change MAY reuse policy-erased
structure, but MUST commit the new artifact and policy metadata. Structural
reuse also MUST NOT imply Host evaluation, outcome, or effect reuse. Skipping
Host work requires a separately authorized Outcome Journal or cache policy. The
complete portable contract is
[SCP-0004](../proposals/0004-voyage-plans-and-touchdown-cable-artifacts.md).

Where such a journal exists, it MUST key an outcome by at least the Touchdown
descriptor, the Host identity, the **execution identity the serving attempt
reported**, the Host-addressed policy digest, and the granted capabilities
including the pinned allowlist revision. Only the attempt knows what actually
ran it, and a Runtime cannot verify a no-swap promise, so the execution identity
comes from the attempt's report rather than from the run-start pin. Addressee
resolution still uses the pinned identities.

The reported execution identity is a tagged union with **exactly one** variant:

```text
reportedExecutionIdentity =
    implementationRevision(revisionOrDigest)
  | capabilitySnapshotSubstitute(snapshotIdentity, guaranteeProfile)
```

- The journal MUST key by the **variant tag** as well as its value, so identical
  bytes in the two namespaces never collide.
- `implementationRevision` is the ordinary variant: the implementation revision
  or digest that served the attempt.
- `capabilitySnapshotSubstitute` serves a deployment that cannot expose an
  implementation revision at all. That deployment MUST guarantee that its
  capability snapshot identity changes whenever any implementation revision
  that can affect outcome meaning changes, and MUST identify that guarantee as
  a profile, which the attempt reports as `guaranteeProfile`. The substitute's
  `snapshotIdentity` MUST equal the separately reported serving capability
  snapshot identity; a mismatch makes the outcome non-reusable. Its tag,
  snapshot identity and guarantee profile all enter the journal key.
- An outcome whose attempt reports neither variant, reports both, or omits its
  serving capability snapshot identity MUST NOT be journal-reusable. Refusing
  reuse is always safe; guessing is not.
- When an attempt reports a capability snapshot identity that differs from the
  run-start pinned one, that is **drift**: the Runtime MUST record it, the
  outcome MUST NOT be reused under the pinned identity, and a deployment MAY
  treat drift as a run-level failure.
- A deployment that wants replay determinism MAY additionally pin the
  implementation revision at run start and refuse to start, or fail the run on
  drift. That is a stricter profile layered on the reporting rule, not an
  alternative to it.

See
[SCP-0011](../proposals/0011-policy-addressee-and-host-channel.md).

## 13. Run and recovery boundary

For the first local runtime:

- a run begins from one validated, prepared Root occurrence;
- committed deduction records and trace events form the observable structural
  checkpoint boundary; Touchdown is a leaf-grounding state, not the only
  checkpoint;
- a deduction failure commits no partial result and blocks only the affected
  occurrence structurally;
- the Scheduler decides whether that produces retry, cancellation, partial
  continuation, or run failure;
- crash persistence MAY initially be in-memory only but MUST be replaceable.

Durability, distributed leases, and exactly/at-least-once delivery are not
implied by this contract. They may become concrete policies or runtime profiles
only after evidence-driven design.

## 14. Minimum test doubles

A Runtime used for conformance and discovery MUST provide:

- in-memory Codebase with immutable artifact inspection;
- recording Host with deterministic primitive semantics and programmable
  function/Anchor success, failure, delay, and effect points;
- deterministic Scheduler profile;
- fault injector capable of acting before invocation, after effect, before
  acknowledgement, and during completion delivery;
- normalized trace recorder and comparison helpers.

These doubles are mandatory because ordinary happy-path tests cannot discover
policy requirements.

## 15. Explicit non-conformance

An implementation is not suitable as conformance or proposal evidence if it:

- resolves an unqualified Goal reference before its own occurrence is demanded;
- allows a later alias update to retarget an already committed deduction;
- fails to record the selected full hash and observed codebase revision for each
  unqualified deduction;
- treats source occurrences as identical merely because arguments match;
- allows Host functions to alter Goal topology invisibly;
- hardcodes policy semantics inside the Carousel;
- ignores unknown policies;
- commits a deduction record outside a voyage, for example in a compiler or
  static preparation pass;
- delivers `directPolicies[]` to the Host instead of the `hostPolicies[]`
  projection, or lets the Host interpret a Scheduler-addressed policy;
- resolves a policy addressee against a declaration that was not pinned at run
  start;
- uses one giant Anchor to retain the original program's orchestration;
- reports original tests as evidence while weakening their assertions;
- exposes implementation-language exceptions as the only diagnostic contract.

## 16. Contract-change protocol

An implementation experiment may reveal that this contract is incomplete or
internally inconsistent. That finding is evidence, not permission to choose a
new semantic rule.

The agent MUST preserve the reproduction, freeze the affected path, and open a
proposed ADR. The ADR must identify the pressured invariant, options, a reasoned
recommendation, compatibility impact, and required specification/conformance
changes. Any change to language semantics, identity, diagnostic ownership,
policy behavior, or component boundaries requires the owner's explicit decision
before implementation continues on that path.

An implementation MAY proceed with unrelated work. It MUST NOT hide the issue
behind a default, feature flag, adapter special case, or undocumented Runtime
profile behavior.
