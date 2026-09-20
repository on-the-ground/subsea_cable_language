# Carousel POC Findings

> **Status:** index of evidence, not normative. Findings come from an
> independent proof of concept of the Carousel and its orchestrating Runtime,
> maintained at
> [on-the-ground/subsea_cable_runtime](https://github.com/on-the-ground/subsea_cable_runtime).
> This page does not decide anything and does not replace the ADR/SCP process:
> every language-level gap links an external ADR and a Subsea Cable Proposal,
> and the POC marks the affected path as experimental or blocked until the
> owner decides.

Related plans: [CAROUSEL_ENGINE_PLAN.md](CAROUSEL_ENGINE_PLAN.md) and
[RUNTIME_ORCHESTRATION_PLAN.md](RUNTIME_ORCHESTRATION_PLAN.md).

## Open language-level gaps

None. Every gap this POC surfaced has an accepted SCP; the table below records
where each one landed so the POC can be brought onto the decided contract.

| ID | Gap | Decision | External ADR | POC path |
|---|---|---|---|---|
| F3 | Occurrence kind, deduction record, and lineage of an inline Goal-arrow stage | [SCP-0007](../proposals/0007-inline-goal-arrow-stage-occurrence.md) — accepted; the stage also takes one child-ordinal segment | `docs/decisions/0002-inline-goal-arrow-stages.md` | experimental; align with `RUNTIME_CONTRACT.md` §8.1 |
| F8 | Binding site, entry form, and routing of structure-valued lookup maps | [SCP-0009](../proposals/0009-structure-valued-lookup-maps.md) — accepted | `docs/decisions/0003-structure-valued-lookup-maps.md` | blocked (`UnsupportedByProfile`); unblock and implement |
| F9 | Which top-level values an artifact captures in its hash | [SCP-0008](../proposals/0008-artifact-hash-value-closure.md) — accepted option A (referenced closure) | `docs/decisions/0004-artifact-hash-value-closure.md` | experimental; POC still captures all unit values (option B) |
| F10 | Error kind and phase for runtime `NoOutput` where a value is required | [SCP-0010](../proposals/0010-dynamic-nooutput-errors.md) — accepted `NoOutputNotRoutable` | `docs/decisions/0005-dynamic-nooutput-errors.md` | experimental; POC still reports the two option-B kinds |

ADR paths are relative to the runtime repository.

## Resolved

| ID | Finding | Resolution |
|---|---|---|
| F1 | `conformance/DEDUCTION.md` scenario 1 used `Upper/0 = [] -> B`, which the grammar rejects | Scenario corrected to `Upper = [] -> B[]`; invalid-syntax case `bare-goal-body.vyg` added |
| F2 | Empty source unit | The grammar requires at least one statement (confirmed with ANTLR). Invalid-syntax case `empty-program.vyg` added |
| F4 | Policy-erasure invariant lacked a condition | Orchestration plan §8.5 and §16 scenario 11 now condition it on the same selected artifact and arguments |
| F5 | `Hold` on a composite target | Orchestration plan §8.4 leaves it undefined as part of R9 |
| F6 | Timing of failures found by speculative prefetch | A Scheduler decision tied to explicit demand; the POC surfaces them only on demand |
| F6a | Consumption point and window counting | [SCP-0001](../proposals/0001-touchdown-consumption-and-window-counting.md) (Accepted) |
| F7 | Routing into a nested serial stage | Already specified: explicit brackets never receive an implicit argument, so in `[A, [B, C]]` the inner `B` is `/0`. The POC tests this |
| F11 | Bare uppercase names outside compositions | Already specified: a bare uppercase identifier is a Goal stage only inside serial or parallel composition. The POC's fallback was a defect and was removed |
| F12 | Staging of value-producing calls in argument positions | [SCP-0003](../proposals/0003-explicit-value-producing-call-staging.md) (Accepted): nested Goal/Anchor calls outside function leaves are `InvalidStructuralContext`; use an explicit direct structural stage. The external POC implements this on its published `main` (runtime ADR 0006). Applying the rule exposed that the `DestructureMismatch` fixture used a nested call; the fixture now uses the deferred form and an eager variant is a separate case |
| F13 | Deduction-engine and live-value ownership | [SCP-0002](../proposals/0002-carousel-runtime-boundaries.md) (Accepted): Carousel alone owns deduction; the Runtime owns the Outcome & Value Store; Vessel names the whole Runtime metaphor |

The orchestration plan's internal inconsistencies noted in earlier revisions of
this page (`Waiting(args)`, per-occurrence vs. aggregate blocking reports, the
empty-registry rejection point, and the primitive-semantics callers) are fixed
in the plan text.

## Policy discovery

The POC ships no concrete policy interpreters. Its pinned Scheduler registry and
Host policy capability set are both empty, so it keeps `@policy` as opaque,
ordered occurrence metadata and rejects every identifier as unclaimed with
`UnknownPolicy` when its occurrence is disclosed. It does not claim the
SCP-0011 Host-policy channel. Concrete policy semantics wait for migration
evidence, an ADR, and an owner decision, as `POLICY_DISCOVERY.md` requires.

## POC-only diagnostic kinds

These kinds exist only in the POC profile and are not proposed for the language
error table: `UnsupportedByProfile` (phase `profile`); `InjectedFailure`,
`AnchorFailed`, `NoOutputBranch`, `NoOutputAsValue` (phase `host`); and
`RunStuck`, `RunCancelled`, `StepBudgetExceeded`, `ChildFailed`,
`CancelledByPolicy`, `FailedByPolicy` (phase `policy`).
