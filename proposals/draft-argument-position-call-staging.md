# SCP-NNNN — Staging of value-producing calls in argument positions

- Status: Draft
- Author(s): Claude (agent) for on-the-ground
- Created: 2026-09-17
- Updated: 2026-09-17
- Requires owner decision: yes (Owner decision R3 in `implementation/RUNTIME_ORCHESTRATION_PLAN.md`)
- External implementation ADRs: [subsea_cable_runtime `docs/decisions/0006-argument-position-call-staging.md`](https://github.com/on-the-ground/subsea_cable_runtime/blob/main/docs/decisions/0006-argument-position-call-staging.md)
- Evidence repositories/revisions: `on-the-ground/subsea_cable_runtime` (Carousel POC, pinned to this repository at `cbc6f53`)
- Supersedes: —
- Superseded by: —

## Summary

Specify how a value-producing call that appears where a routed value is needed
is staged: an eager Goal call `C(x)` or an Anchor call `$f(x)` inside a Goal or
Anchor argument list, a policy argument, a lookup key, or an operator operand
outside a function-leaf body. Both need an evaluation before the enclosing
deduction can bind a real value, and the current documents do not say how the
enclosing atomic deduction exposes and waits for that evaluation.

## Motivation and reproduction

`README.md` allows both call forms as value expressions and says eager Goal or
Anchor calls found only in an unselected short-circuit branch "do not join the
resulting dependency/evaluation structure", which implies that selected calls
do join it. The conformance corpus contains such calls (`valid/core.subc` uses
`C(x)` as a serial stage; `invalid-semantic/DestructureMismatch.subc` uses
`$emit(Leaf(values))`).

The Carousel POC cannot run these programs without inventing a rule:

```subsea
C = (x) -> x + 1
D = [y] -> $d(y)
Root = [x] -> D[C(x)]
Root[1]

E = [x] -> D[$f(x)]
```

Deducing `Root` needs the value of `C(x)`, which requires evaluating a Goal
through the Scheduler and Host. Deducing `E` needs the result of an Anchor call,
which is an effect. The POC rejects both with `UnsupportedByProfile`
(tests `TestEagerCallIsRefusedByProfile` and
`TestStartRefusesProgramsThePOCCannotRun`).

## Existing invariant under pressure

- Deduction is atomic and commits actual arguments; the conservative value
  barrier forbids committing a placeholder.
- The Carousel never evaluates grounded leaves; Host effects happen only in
  Scheduler-dispatched evaluation.
- Primitive operator evaluation during deduction has no effect.

## Classification

This decides dependency structure, value routing, and the Carousel/Scheduler
boundary for valid source. It cannot be expressed as a Host contract or a
Scheduler profile.

## Proposed specification

No recommendation is accepted. Candidate options:

- **A. Hoisting.** Validation or preparation rewrites each selected
  argument-position call into an explicit preceding stage and routes its result
  by name, as if the author had written
  `[[] -> {a: C(x)}, [{a}] -> D[a]]`. The enclosing deduction commits only after
  the hoisted stage's value resolves.
- **B. Two-phase deduction.** The enclosing occurrence commits a structural
  record that exposes the call as a demanded child and stays blocked; a second
  commit binds the arguments. This changes the meaning of "deduction is the
  commit".
- **C. Restrict.** Allow value-producing calls only inside function-leaf bodies
  (where the Host evaluates them) and in explicit composition stages; reject
  them in Goal/Anchor argument lists, policy arguments, and lookup keys
  (`InvalidStructuralContext`).

## Alternatives

| Alternative | Benefits | Costs/reason rejected |
|---|---|---|
| A. Hoisting | Keeps one commit per deduction and explicit routing; reuses existing stages | Adds synthetic stages and occurrence identities; short-circuit selection must be decided before hoisting |
| B. Two-phase deduction | No source rewriting | Weakens the single-commit model; replay and alias timing become more complex |
| C. Restrict | Simplest and most explicit | Previously valid source becomes invalid, including `valid/core.subc` if `C(x)` stages are affected |
| Make no language change | — | Every Runtime chooses its own staging; programs in the corpus remain unrunnable |

## Philosophy and boundary audit

- Structure vs execution policy: A and C keep it; B blurs the commit boundary.
- Goal vs function separation: unchanged; function bodies keep Anchor calls.
- Policy erasure: unaffected, but policy arguments containing calls must follow
  the same rule.
- Carousel/Host/Scheduler: all options keep effects out of the Carousel.
- Alias resolution: a hoisted or exposed Goal call is its own occurrence,
  resolved on its own demand.
- Value routing: A makes it explicit; B keeps it implicit.

## Compatibility and migration

- Previously valid source affected: none under A or B; under C, programs using
  argument-position calls.
- Previously invalid source newly accepted: none.
- Stored artifact/hash impact: A may change the stored term if hoisting happens
  before storage.
- Diagnostic impact: C adds `InvalidStructuralContext` cases.
- Migration strategy: C requires rewriting calls into explicit stages.
- Version/profile requirement: language revision.

## Grammar and conformance impact

- `README.md` changes: staging rule and short-circuit interaction.
- ANTLR/EBNF changes: none for A and B; none required for C.
- valid/invalid cases: depend on the option.
- runtime cases: deduction scenarios for a Goal call and an Anchor call in
  argument position, including an unselected short-circuit branch.

## Reference experiment

The POC blocks both forms outside function-leaf bodies (ADR 0006).

## Unresolved questions

- Whether a selected call inside a short-circuit expression is hoisted before
  or after evaluating the left operand.
- Occurrence identity and lineage for hoisted calls.
- Whether the same rule applies to eager Goal calls used as composition stages
  (`[A[], C(x)]`).

## Owner decision record

- Decision requested on: 2026-09-17
- Maintainer/agent recommendation: none yet; option A is the most compatible
  starting point for discussion.
- Owner response: pending
- Decision date: —
- Conditions: —

## Final rationale

Pending.
