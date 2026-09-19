# SCP-0006 — Live Vessel–Host cooperation

- Status: Accepted
- Author(s): Codex (agent) for on-the-ground
- Created: 2026-09-18
- Updated: 2026-09-20
- Requires owner decision: yes
- External implementation ADRs: —
- Evidence repositories/revisions: owner design review 2026-09-18,
  [language PR #7 review](https://github.com/on-the-ground/subsea_cable_language/pull/7#pullrequestreview-5256145171),
  `FOR_AGENTS.md`, `implementation/RUNTIME_ORCHESTRATION_PLAN.md`, and SCP-0004
- Activation pull request: [#10](https://github.com/on-the-ground/subsea_cable_language/pull/10)
- Effective language revision: the commit on `main` produced by squash-merging PR #10
- Supersedes: any interpretation of Vessel as a compiler that hands a completed
  Cable to a detached Host
- Superseded by: —

## Summary

A conforming general-purpose Vessel is a live Consumer Runtime that remains a
logical participant throughout a voyage. Carousel deduction reaches grounded
leaves, Scheduler offers eligible evaluation instances to the Host, Host
outcomes and values return to the Vessel, and those values may unblock or select
later deduction. This feedback loop continues until the voyage terminates.

This is a semantic lifecycle requirement, not a deployment requirement. Vessel
and Host may communicate across processes or run in one process through a
library, static link, callback, FFI, embedded module, or equivalent mechanism.

A tool may validate, normalize, cache prepared artifacts, or generate Host
bindings, but those preparation steps are not deduction and MUST leave every
unqualified Goal occurrence symbolic until that exact occurrence is demanded in
a voyage. A producer that emits Host code or a prospective leaf manifest and
then relinquishes the voyage is not by itself a Vessel. Generated code may still
be conforming when it embeds or links the same live feedback-loop
responsibilities.

## Motivation and reproduction

The agent-facing design begins with an iterative loop:

```text
plan -> act -> observe -> plan again
```

Subsea externalizes the durable state of that loop: committed deductions,
undeduced occurrences, routed values, lineages, evaluation outcomes, and the
Root outcome. The existing Runtime orchestration design already describes the
necessary operational loop:

```text
deduce -> Touchdown -> schedule -> Host evaluation
       -> record outcome/value -> resume deduction
```

SCP-0004 also makes a Fully Touchdown Cable the realized structural artifact of
a terminated voyage, not the authored input. Without an explicit boundary
decision, an implementation could nevertheless describe Vessel as a compiler
whose output is handed to a Host that independently decides all later work.
That interpretation removes the return path by which Host-derived values
unblock routing, conditional selection, later alias observation, and agent
replanning.

The distinction matters even when all components share one process. The issue
is not RPC versus a library. It is whether Vessel remains responsible for the
voyage state machine while Host evaluation occurs.

## Existing invariant under pressure

- Deduction stops at an unresolved routed-value barrier. Only an accepted Host
  outcome can resolve that value and allow affected deduction to continue.
- Unqualified occurrences observe their alias when demanded, so later structure
  may deliberately remain open while earlier leaves execute.
- Host owns concrete computation but MUST NOT decide Goal topology or hide
  orchestration.
- Scheduler owns evaluation eligibility and policy; Host does not absorb that
  role merely because it executes a leaf.
- Fully Touchdown Cable membership records structure actually grounded during
  the voyage. It is not equivalent to a source-level compilation target.

A detached compiler/Host model cannot preserve all of these invariants unless
the generated output contains the Runtime feedback loop. In that case it is a
deployment of the live Vessel model, not an alternative to it.

## Classification

This is a portable Vessel/Host/Scheduler ownership and lifecycle decision. It
changes no source syntax and assigns no concrete policy behavior. It cannot be
left to a Host Anchor contract or an implementation-specific Scheduler profile,
because every conforming general-purpose Runtime must agree on whether Host
results return to the deduction lifecycle.

## Proposed specification

### Live voyage loop

From initial Root demand until termination, the Vessel MUST retain the logical
voyage lifecycle and coordinate this closed loop whenever the voyage requires
Host-provided results:

1. Carousel commits demanded structure and publishes grounded Touchdowns.
2. Scheduler decides evaluation eligibility and offers an evaluation instance
   to the appropriate Host capability.
3. Host returns a typed outcome to the Runtime-owned Outcome & Value Store.
4. Accepted outputs resolve explicit routed values.
5. Carousel may read those resolved values and continue or select later
   deduction without rewriting any earlier deduction.
6. The loop repeats until the Root succeeds, fails, is cancelled, or the voyage
   otherwise reaches a defined terminal state.

The Host MUST NOT independently unfold Goal structure, select later Goal
aliases, or manufacture the Fully Touchdown Cable. The Scheduler, not the Host,
continues to own eligibility, attempts, and `@policy` interpretation.

### Deployment neutrality

The contract does not require a daemon, network service, or separate process.
A conforming implementation MAY use:

- one process with ordinary function calls;
- a dynamic or static library;
- callbacks, FFI, or an embedded module such as WebAssembly;
- sidecar, local IPC, or remote service communication; or
- generated code linked with a compatible Runtime loop.

Suspension and recovery are also allowed. “Live” means logically participating
in the unfinished voyage, not continuously occupying a thread or process.

### Compiler and static-preparation tools

A compiler MAY validate, normalize, cache prepared artifacts, or generate Host
bindings. These steps MUST preserve every unqualified Goal reference as symbolic
`Name/Arity` until that exact occurrence is demanded in a voyage. They MUST NOT
create a deduction record outside that voyage; only Carousel may commit one
after observing the run's occurrence, arguments, codebase revision, and active
lineages.

Those tools MUST NOT present an unexecuted prospective artifact as the
terminated voyage's Fully Touchdown Cable or Root outcome. If generated code
must react to Host results, it MUST embed, link, or communicate with a component
that preserves the live Vessel responsibilities above. A compiler-only producer
that permanently hands off all later control may be a useful external tool, but
the deployment it ships MUST NOT advertise conformance to the general Vessel
profile unless that deployment implements the live loop above.

## Alternatives

| Alternative | Benefits | Costs/reason rejected |
|---|---|---|
| Make no specification change | Existing documents already imply the loop | Leaves room to market a compiler-only handoff as a complete Vessel |
| Vessel emits Host code or a complete Cable and exits | Simple deployment and conventional build artifact | Cannot generally cross value barriers or retain planning, alias, routing, and provenance state without recreating Vessel inside the output |
| Require a separate Vessel daemon | Operational boundary is visually obvious | Confuses semantic ownership with deployment and excludes embedded/library uses |
| **Accepted core: live logical cooperation, deployment-neutral** | Preserves value-dependent unfolding and agent replanning while allowing in-process, linked, embedded, or remote packaging | Requires a bidirectional Runtime/Host contract for unfinished voyages |

## Philosophy and boundary audit

- Structure remains Carousel-owned; Host execution never invents topology.
- Execution policy remains Scheduler-owned; the feedback loop does not move it
  into Host.
- Goal and function remain distinct: Goal structure unfolds in Carousel and
  concrete leaves run in Host.
- Policy erasure still preserves topology for corresponding occurrences.
- Alias resolution remains demand-time and committed deductions remain
  immutable.
- Host-derived values re-enter only through explicit outputs and routing.
- The decision is portable across process, library, embedded, and distributed
  implementations.

## Compatibility and migration

- Previously valid source affected: none.
- Previously invalid source newly accepted: none.
- Stored artifact/hash impact: none.
- Diagnostic impact: none.
- Runtime impact: a detached compiler-only producer is not sufficient evidence
  for general Vessel conformance. Its generated deployment may claim that
  profile only when it links or communicates with the required feedback-loop
  components.
- Version/profile requirement: consumers claiming the general Vessel contract
  after this SCP MUST implement the live lifecycle boundary.

## Grammar and conformance impact

- `README.md` changes: clarify that a Voyage Plan is sailed through a live
  Vessel/Host loop and that compiler output is not the general Runtime model.
- ANTLR changes: none.
- EBNF changes: none.
- valid or invalid source cases: none.
- Runtime cases: verify at least one routed Host value unblocks later deduction;
  verify no Host call can rewrite prior deductions or independently select later
  Goal topology; verify equivalent in-process and out-of-process adapters obey
  the same event boundary. These cases are recorded in
  `conformance/DEDUCTION.md` §§16–18.

## Reference experiment

The existing external Runtime POC and
`implementation/RUNTIME_ORCHESTRATION_PLAN.md` already model Carousel
Touchdown publication, Scheduler dispatch, Host completion, value resolution,
and resumed deduction as one voyage lifecycle. This SCP fixes that loop as the
portable architectural direction while leaving transport and concrete API
spelling implementation-specific.

## Unresolved questions

- Concrete streaming, callback, IPC, and recovery APIs remain Runtime choices.
- Code-generation formats remain future profile or implementation work.
- Concrete Scheduler policy semantics remain deliberately unspecified.

## Owner decision record

- Decision requested on: whether Vessel is a live collaborator with Host or a
  compiler that hands off a completed output and exits.
- Maintainer/agent recommendation: choose live cooperation and keep deployment
  topology neutral; retain compilation as an optimization/tooling surface.
- Owner response: accepted. Vessel and Host coexist and cooperate through the
  voyage; they may be separate processes or participate in one process through
  a library or other embedding form.
- Decision date: 2026-09-18
- Conditions: do not assign Scheduler policy to Host and do not require a
  separate process.
- Accepted core: live Vessel–Host cooperation and deployment-topology
  neutrality.
- Accepted in full on 2026-09-20: the compiler/static-preparation limits, the general
  Vessel profile-claim rule, and the synchronized runtime cases were confirmed
  after the PR #7 review rounds and are normative in
  `implementation/RUNTIME_CONTRACT.md` §1.1 and `conformance/DEDUCTION.md`
  §§16–18.
- Review round 1 (2026-09-20, language PR #7): two P1 and three P2 findings are
  addressed in this revision. Static preparation no longer performs deduction;
  general Vessel conformance is an observable profile claim rather than a rule
  about a tool's name; the three runtime cases are recorded in
  `conformance/DEDUCTION.md`; status and evidence distinguish the accepted core
  from pending details; and the no-remainder proof with no normative consequence
  is removed.
- Review round 2 (2026-09-20, language PR #7): three P2 findings are addressed.
  The general value-barrier contract now assigns `DeductionBlocked(pendingValue)`
  and its speculative counterpart rather than leaving §16 ahead of the contract;
  §18 compares an event multiset plus per-occurrence causal order instead of
  requiring a global frontier order; and trace normalization defines transport
  removal, volatile-field erasure, and stable occurrence/attempt identities.
  The optional wording fixes for ledger comparison and the AGENTS reading-order
  status are included as well.

## Activation record

- Canonical documents synchronized: `implementation/RUNTIME_CONTRACT.md` §1.1, `METAPHORS.md`, `README.md`, `FOR_AGENTS.md`, `AGENTS.md`, `implementation/README.md`, `implementation/RUNTIME_ORCHESTRATION_PLAN.md`
- Grammar projections synchronized: not applicable; no source syntax changed
- Diagnostics and examples synchronized: not applicable; no diagnostic kind changed
- Conformance cases synchronized: `conformance/DEDUCTION.md` §§16–18
- Compatibility and migration notes synchronized: SCP compatibility section; a detached compiler-only producer may not advertise the general Vessel profile
- Verification commands and results: `python .github/scripts/validate_scp_activation.py` passes; `python .github/scripts/test_validate_scp_activation.py` passes; `mkdocs build --strict` passes; every markdown link resolves and every `conformance/cases.tsv` path exists

## Final rationale

Subsea Cable is intended to carry plans whose later structure can depend on
observed results. Its agent use case makes that feedback loop central rather
than exceptional. A compiler may prepare or package the loop, but a detached
compiler cannot replace the general Vessel lifecycle without losing the
property the language is designed to provide.
