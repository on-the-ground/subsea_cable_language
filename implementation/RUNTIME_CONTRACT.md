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

Vessel
  demand-driven deduction → committed structure + undeduced frontier

Scheduler Port
  grounded occurrences + policy metadata ↔ execution outcomes

Host Port
  primitive semantics + arrow-function evaluation + $Anchor resolution/invocation
```

The deployment MAY package these together. Their responsibilities MUST remain
separable in interfaces and tests.

- The Vessel MUST resolve a Goal alias only when that occurrence is demanded. It
  MUST NOT resolve Anchors, evaluate grounded leaves, or interpret policies.
- The Host's arrow-function evaluator MUST NOT call another Subsea Goal or
  create Goal structure; it evaluates only the terminal body already validated
  for its Goal.
- The Host MUST NOT decide Goal topology or silently perform hidden
  orchestration for the migrated slice.
- The Scheduler MUST NOT rewrite Goal definitions, routing, or committed
  deductions.
- The Frontend and Codebase MUST NOT depend on one Scheduler or Host registry.

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
- Goal name/arity resolution;
- callability;
- map-key identity and duplicates;
- statically decidable lookup/destructuring failures;
- unsupported recursion/cycles;
- all cases in `conformance/cases.tsv`.

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
- `$Anchor` and `@policy` identifiers MUST remain external symbolic names.

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
- Host primitive failures while routing are reported in the deduction context;
- arrow-function and Anchor lookup/signature/implementation failures are Host
  errors;
- unknown, conflicting, or inapplicable policies are policy errors.

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
  ordered policy metadata. Incidental formatting and source spans remain
  sidecar metadata unless a later language contract deliberately includes them;
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

## 7. Vessel contract

The Vessel accepts a prepared Root occurrence and deduces only what is demanded.
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

The Vessel produces occurrence/containment events for all deduced structural
occurrences, plus grounded leaf occurrences and dependency/readiness facts for
the Scheduler Port. This is required because a policy may target a serial,
parallel, resolving-map, Goal, or leaf occurrence. The Vessel MUST NOT copy a
composite's policy onto its descendants. It MUST NOT decide retry, timeout,
cancellation, delivery guarantees, result caching, duplicate suppression, or
success aggregation.

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
occurrenceKind       Goal | serial | parallel | resolving-map | function-leaf | anchor
lineages[]
directPolicies[]     only policies authored on this exact occurrence
dependencies[]
source/provenance
```

This record preserves composite policy targets without inventing policy
inheritance. Containment and dependency are distinct relationships and MUST NOT
be collapsed.

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
dependencies[]       occurrence/evaluation prerequisites
provenance           Host primitive profile, codebase revision, runtime profile, source references
```

The exact serialization is profile-specific. The information and distinctions
are mandatory.

## 9. Host Port contract

The Host Port supplies every concrete computation semantic that Subsea does not
own. It has three independently testable capabilities:

```text
Primitive Semantics   value operators requested during deduction or leaf evaluation
Function Evaluation   validated arrow-function leaf bodies
Anchor Resolution     lookup and invocation of opaque $Identifier capabilities
```

The Vessel MAY call Primitive Semantics while applying a reduction rule, but it
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

Trace event names are a Runtime-profile diagnostic contract, not Subsea source
syntax. Changes must be versioned because migration comparisons depend on them.

## 12. Run and recovery boundary

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

## 13. Minimum test doubles

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

## 14. Explicit non-conformance

An implementation is not suitable as conformance or proposal evidence if it:

- resolves an unqualified Goal reference before its own occurrence is demanded;
- allows a later alias update to retarget an already committed deduction;
- fails to record the selected full hash and observed codebase revision for each
  unqualified deduction;
- treats source occurrences as identical merely because arguments match;
- allows Host functions to alter Goal topology invisibly;
- hardcodes policy semantics inside the Vessel;
- ignores unknown policies;
- uses one giant Anchor to retain the original program's orchestration;
- reports original tests as evidence while weakening their assertions;
- exposes implementation-language exceptions as the only diagnostic contract.

## 15. Contract-change protocol

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
