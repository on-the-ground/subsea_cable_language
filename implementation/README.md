# External Runtime and Policy-Discovery Guide

This directory guides independent projects in building a conforming Subsea Cable
Runtime and discovering anchoring policies from real software. Runtime code and
implementation-specific ADRs live in those external repositories, not in the
Subsea Cable language repository. This guide intentionally does not predesign retry,
timeout, delivery, or failure-aggregation semantics.

The deduction engine objective, Touchdown prefetch model, backpressure boundary,
and phased delivery plan are tracked separately in
[CAROUSEL_ENGINE_PLAN.md](CAROUSEL_ENGINE_PLAN.md). Read it before freezing a
Runtime component model; it records an owner-directed boundary change that has
not yet been propagated into the normative Runtime Contract. The proposed
coordination of Carousel, Host, and `@policy` from a run command to the Root
outcome is in [RUNTIME_ORCHESTRATION_PLAN.md](RUNTIME_ORCHESTRATION_PLAN.md),
and evidence from an external proof of concept is in
[CAROUSEL_POC_FINDINGS.md](CAROUSEL_POC_FINDINGS.md).

The external-implementer starting point is recorded in [STATUS.md](STATUS.md). A
new implementation agent copies the relevant templates into its own repository
and starts there after reading the language repository instructions.

The strategy is empirical:

```text
structural specification
        ↓
one conforming reference runtime
        ↓
one real program slice migrated to Subsea
        ↓
the original program's tests reused as the behavioral oracle
        ↓
fault injection exposes implicit execution assumptions
        ↓
only evidenced policies are specified and implemented
        ↓
repeat with a different workload
```

The objective is not merely to make one port pass. Each iteration must reveal
whether a behavior belongs to structure, value routing, a Host Anchor contract,
Scheduler policy, or an unsupported language feature.

## Design-decision firewall

Iteration findings must never become language design implicitly. When a test,
migration, or fault experiment exposes ambiguity or pressure to change the
design, the implementing agent must:

1. preserve the failing reproduction and normalized trace;
2. stop changes on the affected path;
3. classify the issue as implementation defect, reversible Runtime-profile
   choice, or language/design decision;
4. create a `proposed` ADR containing the evidence, affected invariants, at least
   two viable options when they exist, the agent's recommendation, and migration
   or compatibility impact;
5. explicitly request the owner's decision when the issue crosses the language
   or architectural boundary, and open an SCP here using
   `../proposals/TEMPLATE.md` for a language-level change;
6. record the owner's answer and only then update specification, grammar,
   conformance cases, and implementation in that order.

Unrelated work may continue. The blocked path may not proceed behind a feature
flag, private convention, permissive fallback, or host-specific special case.

Owner decision is mandatory for any change to:

- source syntax or valid/invalid program classification;
- Goal topology, routing, output, reduction, or Root semantics;
- ArtifactHash, StructureHash, GoalNodeId, occurrence, or lineage identity;
- the ownership boundary among Vessel, Host, and Scheduler, including Host
  primitive semantics and both leaf forms;
- a stable diagnostic kind or phase;
- policy target, inheritance, ordering, composition, or topology erasure;
- Host/Codebase interoperability or cross-runtime portability;
- an original behavioral assertion that would be weakened or removed.

A reversible implementation-profile choice may be accepted by the implementing
agent through an ADR only when it changes none of the above and is visibly
versioned as profile behavior.

## Terminology

An implementation produced by following this guide is a **Runtime**, not a
monolithic “Host.” A project may designate one implementation as its reference
profile, but the language repository does not adopt or maintain it as official.
It contains separable parts:

```text
Source Frontend  → UTF-8, preprocessing, parse, validation, artifact preparation
Codebase         → immutable Goal artifacts, mutable aliases, revisions, deduction ledger
Vessel           → lazy deduction, reduction rules, occurrences, lineages, frontier
Scheduler Port   → readiness/outcomes and opaque @policy delivery
Host Port        → primitive semantics, arrow-leaf evaluation, $Anchor resolution/invocation
Diagnostics      → errors, traces, provenance, and conformance evidence
```

The Host supplies concrete computation semantics. The Scheduler interprets
`@policy`. The Vessel owns demand-time Goal alias resolution and structural
deduction, but delegates primitive value semantics to the Host and never
evaluates grounded leaves. A concrete package may ship all parts together, but
its APIs and tests must preserve these boundaries.

## Normative sources

- `README.md` defines structural semantics.
- `METAPHORS.md` defines the precise Cable, deduction, frontier, and Touchdown
  model.
- `SubseaCable.g4` defines parser acceptance.
- `SubseaCable.ebnf` is the implementation-neutral grammar projection.
- `conformance/cases.tsv` defines observable acceptance and stable error kinds.
- `conformance/DEDUCTION.md` defines observable lazy-alias and deduction behavior.
- `implementation/RUNTIME_CONTRACT.md` defines the consumer/runtime boundary.

If they disagree, record the discrepancy and resolve it before continuing. The
first implementation must not become an accidental source of language law.

## What is deliberately deferred

- concrete retry, timeout, delivery, cancellation, and aggregation policies;
- policy inheritance and policy-conflict rules;
- recursion and data-dependent recursive expansion;
- distributed execution, durable queues, and production storage;
- a standard package manager or import/export system;
- cross-runtime canonical hash compatibility until its encoding ADR is accepted.

The `@policy` carrier itself is not deferred: policy order, arguments, target
occurrence, provenance, and lossless delivery to the Scheduler Port are required.
Unsupported policies must never be ignored silently.

## Phase 0 — Freeze the implementation profile

Before production code, create short decision records for:

1. reference implementation language and build system;
2. canonical artifact encoding and hash algorithm;
3. occurrence-ID, codebase-revision, and deduction-record identity/persistence;
4. public Runtime, Vessel, Host Port, and Scheduler Port APIs;
5. the in-memory Codebase transaction model;
6. the Host primitive-semantics profile;
7. the baseline test Scheduler profile;
8. the first open-source migration target and exact program slice.

The language choice is replaceable. Prefer Go when a small standalone runtime,
official ANTLR target, concurrency, and fault injection dominate. Prefer
TypeScript/JavaScript when the first migration target and its unchanged tests are
already in that ecosystem. Record the tradeoff; do not encode language-specific
behavior into the contract.

The baseline Scheduler is a test profile, not normative Subsea semantics. Its
name and version must appear in traces so its behavior cannot be mistaken for a
language rule.

### Gate 0

- Every item above has an accepted decision record or is explicitly marked as a
  blocking owner decision.
- `RUNTIME_CONTRACT.md` can be mapped to concrete interfaces without merging the
  Vessel, Scheduler, and Host responsibilities.
- No concrete policy semantics have been invented to unblock implementation.

## Phase 1 — Build the frontend first

Implement strict UTF-8 decoding, the required newline/comment preprocessor, the
ANTLR parser, semantic validation, symbolic Goal-reference preparation, and
diagnostics.

Required evidence:

- every syntax-valid case reaches EOF without lexer/parser errors;
- every syntax-invalid case is rejected;
- every semantic-invalid case returns the manifest's stable error kind and
  phase;
- source spans survive preprocessing;
- ASCII Identifier and Unicode String cases behave exactly as specified;
- unqualified Goal references remain symbolic `Name/Arity` values after storage;
- hash-qualified references are expanded to one pinned full hash;
- `@policy` and `$Anchor` arguments are structurally validated without resolving
  their external names.

### Gate 1

All cases in `conformance/cases.tsv` pass automatically. Generated parser output
is treated as build output. A clean checkout can reproduce the result with one
documented command.

## Phase 2 — Implement Codebase and Vessel

Start with an in-memory Codebase. Store unqualified Goal references as symbolic
`Name/Arity`, store hash-qualified references as pinned full hashes, and expose
atomic alias revisions. Implement demand-driven deduction, structural reduction,
the deduction ledger, sharing, occurrences, routed values, lineages, the
undeduced frontier, and Touchdown marking.

Use deterministic fake leaf implementations. Do not introduce real I/O or
policy behavior yet.

Required invariant tests:

- policy erasure yields the same structural projection and `GoalNodeId`;
- `{Goal, Goal}` retains two occurrence/edge identities but one shared Goal node;
- one Goal node can produce multiple evaluation instances for different routed
  argument tuples;
- an occurrence resolves its current alias only when that occurrence is
  demanded;
- a committed deduction retains its selected hash after later alias rebinding;
- two occurrences demanded on opposite sides of an alias update may select
  different hashes;
- every committed intermediate deduction is immutable whether or not its path
  has reached Touchdown;
- unselected lookup-map branches never enter the structure;
- resolving maps are the only maps that export named parallel results;
- `NoOutput` is distinct from every ordinary value;
- a hash-qualified occurrence remains pinned while an unqualified undeduced
  occurrence remains eligible to observe a later alias revision.

### Gate 2

A deterministic golden trace demonstrates parse → prepare → store → demand →
resolve alias → commit deduction → ground leaves for representative serial,
parallel, shared-node,
resolving-map, eager-call, and Anchor cases.
Every scenario in `conformance/DEDUCTION.md` passes automatically.

## Phase 3 — Add Host and Scheduler ports

Implement the abstract ports in `RUNTIME_CONTRACT.md` without adding production
policies.

The Host Port supplies primitive semantics to Vessel deductions and evaluates
grounded arrow-function and Anchor leaves. The Scheduler Port receives every
deduced structural occurrence—including policy-bearing composites—plus grounded
leaves and reports execution outcomes. A composite policy remains on
that composite occurrence; it is not copied onto descendants. The Vessel remains
unaware of Host registries, retries, timeout clocks, success aggregation, or
cancellation strategy.

Add a deterministic test Host and a named baseline test Scheduler. Unknown
policies must produce an explicit policy-phase error before affected execution;
they must not be dropped.

### Gate 3

- Host primitive behavior is available through a replaceable, identified
  profile and is recorded on deductions that use it.
- Arrow-function and Anchor resolution/signature failures are Host-phase errors.
- Unsupported policies are policy-phase errors.
- Removing every policy changes no topology or routing trace.
- A policy on a composite reaches the Scheduler with its original target and
  without appearing as a direct child policy.
- Replacing the baseline Scheduler requires no parser, Codebase, or Vessel
  changes.
- Replacing the Host profile requires no parser, Codebase, or Scheduler changes;
  the Vessel depends only on the Host primitive-semantics port.

## Phase 4 — Migrate one real program slice

Follow `MIGRATION_PLAYBOOK.md`. Select one bounded orchestration slice rather
than an entire repository. Establish the untouched original test baseline first,
then preserve the same public entrypoint through an adapter backed by Subsea.

Move orchestration into Subsea. Do not make a single `$runOriginalProgram`
Anchor that leaves the dependency structure inside the source language. Genuine
computation and effects remain behind focused Anchors.

Run the original black-box tests unchanged whenever possible. White-box tests
that assert private implementation shape may be adapted or excluded only with a
written reason; behavioral assertions must not be weakened.

### Gate 4

- The original baseline and migrated suite results are recorded.
- The migrated path uses Subsea for the selected slice's dependency structure.
- Every residual orchestration decision outside Subsea is listed in the
  experiment record.
- No new policy has been added merely to imitate an implementation detail.

## Phase 5 — Discover policies with controlled failures

Passing ordinary tests proves behavior on the happy path, not policy semantics.
Use the same public tests plus controlled Host/Scheduler fault injection:

- fail before an effect;
- fail after an effect but before acknowledgement;
- delay one parallel branch;
- duplicate invocation or completion delivery;
- cancel before start and during execution;
- lose or reorder a completion signal;
- crash and resume from the deduction ledger and undeduced frontier;
- return partial success from independent branches.

For each difference from the original program, classify the missing concept in
this order:

1. incorrect Goal dependency or value routing;
2. missing or incorrectly scoped Anchor contract;
3. Scheduler behavior local to the reference profile;
4. reusable anchoring policy;
5. genuinely unsupported structural feature.

Only item 4 creates a policy candidate. Record it with
`EXPERIMENT_TEMPLATE.md`; then follow the promotion rules in
`POLICY_DISCOVERY.md`.

### Gate 5

Every proposed policy has reproducible evidence, a precise target occurrence,
observable semantics, failure cases, and conformance tests. A policy discovered
once remains provisional.

## Phase 6 — Repeat across different workloads

Repeat Phases 4–5 with qualitatively different slices. Recommended progression:

1. deterministic serial pipeline;
2. parallel fan-out/fan-in with explicit result routing;
3. idempotent external effect with transient failure;
4. long-running or cancellable work;
5. crash/resume or distributed delivery, only after the local runtime is sound.

Do not repeatedly choose repositories with the same framework and failure model.
The point is to pressure the abstraction boundary.

## Policy stabilization threshold

- **Observed**: one concrete behavior in one source program.
- **Candidate**: a minimal policy model reproduces that behavior under fault
  injection.
- **Provisional**: documented and implemented in an external Runtime with
  conformance tests.
- **Stable**: required by at least two independent workloads or justified by a
  pre-existing external contract, and portable without referring to the first
  implementation language or framework.

Names may change before Stable. Backward compatibility is not promised for
Observed or Candidate policies.

## Overall completion criteria

This strategy has succeeded when:

- an independent implementer can build another consumer from the Runtime
  Contract and conformance corpus;
- at least one external Runtime passes all language conformance tests;
- at least three qualitatively different real slices pass their behavioral test
  suites through Subsea;
- discovered policies have evidence and portable semantics rather than names
  copied from a framework;
- every known gap is classified as structure, value, Anchor, Scheduler profile,
  policy candidate, or deferred language feature;
- no layer depends on a private behavior of the first implementation.

## Mandatory iteration artifacts

Every real-code iteration leaves the following in its external implementation
repository:

- a completed experiment record based on `EXPERIMENT_TEMPLATE.md`;
- original and migrated test commands and results;
- the Subsea source used for the migrated slice;
- Anchor inventory and contracts;
- normalized execution traces for baseline and injected failures;
- gap classification and policy candidates;
- new or updated conformance cases;
- decision records for any changed runtime contract.
- proposed ADRs and explicit owner decisions for every design issue encountered.

Language-level findings additionally open an SCP in this repository. Runtime
source, implementation ADRs, raw integration fixtures, and deployment code do
not move into the language repository.

An iteration that only changes implementation code is incomplete.
