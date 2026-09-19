# SCP-0002 — Carousel, Vessel, and Runtime value ownership

- Status: Accepted
- Author(s): Codex (agent) for on-the-ground
- Created: 2026-09-17
- Updated: 2026-09-17
- Requires owner decision: yes
- External implementation ADRs: Runtime orchestration review recorded by `on-the-ground/subsea_cable_runtime#1`
- Evidence repositories/revisions: `on-the-ground/subsea_cable_runtime` POC; [language issue #2](https://github.com/on-the-ground/subsea_cable_language/issues/2)
- Activation pull request: [#3](https://github.com/on-the-ground/subsea_cable_language/pull/3)
- Effective language revision: `79debc4fe1106ccdee96278811b74609468e7dd6`
- Supersedes: the former use of **Vessel** as the deduction component
- Superseded by: —

## Summary

The **Carousel** is Subsea Cable's demand-driven deduction engine. **Vessel** is
only the metaphor for a complete Consumer Runtime; it is not a second component
or deduction engine. The still-unexposed region is the **Folded Cable**, while
the **undeduced frontier** contains occurrences that already exist but have not
committed a deduction.

The Runtime owns the Outcome & Value Store. The Scheduler delivers evaluation
outcomes to it, and the Carousel reads resolved routed values through a narrow,
read-only port. The Codebase stores artifacts, aliases, revisions, and deduction
records, but never live evaluation outcomes or routed runtime values.

## Motivation and reproduction

The Carousel POC exposed two incompatible models in the canonical documents.
`CAROUSEL_ENGINE_PLAN.md` assigned deduction to Carousel, while `AGENTS.md`,
`METAPHORS.md`, `FOR_AGENTS.md`, and `RUNTIME_CONTRACT.md` still assigned it to
Vessel and sometimes called the deferred region the “Folded Carousel.” The POC
also needed resolved upstream values without defining whether Carousel,
Scheduler, Codebase, or the surrounding Runtime owned them.

Language issue #2 preserved the discrepancy and separated the terminology,
component ownership, and value-store questions.

## Existing invariant under pressure

- There must be exactly one owner of alias resolution and deduction commits.
- Deduction remains an atomic commit and never waits while holding a partial
  record.
- Scheduler outcomes must not become Codebase artifacts or rewrite deductions.
- Carousel must not evaluate leaves or interpret Scheduler policy.
- Runtime results must remain available for explicit downstream routing.

## Classification

This is a portable component-boundary decision. It changes no `.vyg` syntax or
Goal topology, but every conforming consumer must expose the same ownership
seams so implementations do not build competing Vessel and Carousel engines or
store live outcomes in incompatible layers.

## Proposed specification

A conforming Consumer Runtime contains independently testable responsibilities
equivalent to:

```text
Vessel (metaphor for the complete Consumer Runtime)
├─ Frontend
├─ Codebase + Deduction Ledger
├─ Carousel — deduction engine
├─ Outcome & Value Store
├─ Scheduler Port
└─ Host Port
```

The required ownership is:

- **Carousel**: demand-time alias resolution, application of reduction rules,
  atomic deduction commits, occurrence/frontier tracking, routing, lineages,
  and publication of grounded Touchdowns.
- **Outcome & Value Store**: attempt outcomes, scope outputs, and resolution of
  routed value references. It belongs to the Runtime surrounding Carousel.
- **Scheduler**: eligibility, ordering, attempts, outcomes, and `@policy`; it
  delivers outcomes to the Runtime store.
- **Host**: primitive semantics, arrow-function leaf evaluation, and Anchor
  resolution/invocation.
- **Codebase**: immutable artifacts, mutable aliases, revisions, and deduction
  records only. It stores no live attempt outcome or routed Runtime value.

Carousel may read a resolved value through a narrow Runtime-owned port. It may
not write outcomes, inspect Scheduler policy to manufacture a value, or commit
a placeholder for an unresolved value.

Terminology is fixed as follows:

- **Folded Cable**: structure not yet exposed as occurrences;
- **undeduced frontier**: exposed occurrences whose deductions have not
  committed;
- **committed deduction**: immutable selected hash and reduction result;
- **Touchdown**: grounded leaf occurrence published by Carousel;
- **Vessel**: the whole Runtime metaphor, never an interface named as an
  additional deduction owner.

## Alternatives

| Alternative | Benefits | Costs/reason rejected |
|---|---|---|
| Vessel owns deduction; Carousel names only the folded region | Preserves early documents | Leaves no engine for Touchdown prefetch and conflicts with the implemented model |
| Vessel and Carousel both deduce | Superficially preserves both names | Two authorities can resolve different aliases or commit duplicate structure |
| Carousel also owns outcomes | Fewer interfaces | Mixes evaluation policy and effects into structural deduction |
| Codebase stores live values | Central storage | Confuses immutable/auditable structure with run-scoped execution state |
| **Accepted: Carousel deduces; Runtime owns values; Vessel is the whole metaphor** | One owner per transition and a precise mental model | Requires coordinated terminology migration |

## Philosophy and boundary audit

- Structure remains owned by Carousel; execution policy remains Scheduler work.
- Goal and function separation is unchanged.
- Policy erasure cannot change Carousel's structural responsibilities.
- Host, Carousel, and Scheduler remain replaceable behind explicit ports.
- Alias resolution remains demand-scoped per occurrence, and deductions remain
  immutable commits.
- Value routing remains explicit; the store only preserves values produced by
  actual outcomes.
- The boundary is independent of implementation language and storage backend.

## Compatibility and migration

- Previously valid source affected: none.
- Previously invalid source newly accepted: none.
- Stored artifact/hash impact: none.
- Diagnostic impact: none.
- Migration strategy: rename deduction-facing Vessel APIs/components to
  Carousel; reserve Vessel for whole-Runtime prose; introduce a Runtime-owned
  value-read port where necessary.
- Version/profile requirement: consumers claiming the post-SCP-0002 Runtime
  Contract must expose these ownership boundaries.

## Grammar and conformance impact

- `README.md` changes: component and terminology ownership only.
- ANTLR changes: semantic comments only.
- EBNF changes: semantic comments only.
- valid cases: unchanged.
- invalid cases: unchanged.
- runtime cases: component tests must prove Carousel cannot write outcomes and
  Codebase cannot store them.

## Reference experiment

The external Carousel POC uses a Runtime-owned value source, feeds Scheduler
outcomes into it, and lets Carousel read values only when routing can proceed.
Its implementation remains non-normative; this proposal standardizes only the
portable ownership boundary.

## Unresolved questions

None for ownership. Carousel traversal, prefetch scope, completion detection,
and resource budgets remain separate plan decisions.

## Owner decision record

- Decision requested on: 2026-09-17
- Maintainer/agent recommendation: Carousel owns deduction; Runtime owns the
  Outcome & Value Store; Vessel remains the whole-Runtime metaphor.
- Owner response: accepted
- Decision date: 2026-09-17
- Conditions: migrate all canonical documents together; never implement two
  deduction engines.

## Activation record

- Canonical documents synchronized: philosophy, semantics, agent guidance, and
  implementation-neutral contracts and plans
- Grammar projections synchronized: not applicable; no source syntax changed
- Diagnostics and examples synchronized: canonical explanations and examples
- Conformance cases synchronized: deduction documentation and cases
- Compatibility and migration notes synchronized: SCP compatibility section
  and migration playbook
- Verification commands and results: activation PR checks passed

## Final rationale

One state transition must have one owner. Carousel is the mechanism that turns
demand into committed structure and Touchdowns. Runtime values arrive from a
different lifecycle and therefore remain outside it. Vessel is useful as the
ship carrying those parts, not as a second machine hidden inside the ship.
