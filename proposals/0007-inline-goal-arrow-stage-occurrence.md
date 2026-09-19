# SCP-0007 — Occurrence kind for inline Goal-arrow stages

- Status: Accepted
- Author(s): Claude (agent) for on-the-ground
- Created: 2026-09-17
- Updated: 2026-09-20
- Requires owner decision: yes
- External implementation ADRs: [subsea_cable_runtime `0002-inline-goal-arrow-stages.md`](https://github.com/on-the-ground/subsea_cable_runtime/blob/main/docs/decisions/0002-inline-goal-arrow-stages.md)
- Evidence repositories/revisions: `on-the-ground/subsea_cable_runtime@d62f1c3` (Carousel POC; evidence gathered while pinned to this repository at `cbc6f53`)
- Supersedes: —
- Superseded by: —

## Summary

Name how an inline Goal-arrow stage such as `[{code, logs}] -> Diagnose[code, logs]` appears in the Runtime model: its occurrence kind, whether it has a deduction record, and how it appears in lineage.

## Motivation and reproduction

In the external POC, an inline arrow stage inside a serial composition must wait for its routed input, bind it (possibly destructuring it), and only then reduce its body, which may depend on the bound value (for example through lookup). Every program that routes a resolving-map result, including the `FOR_AGENTS.md` example, needs this. `RUNTIME_CONTRACT.md` §8 lists only `Goal | serial | parallel | resolving-map | function-leaf | anchor`, so the POC had to invent an occurrence kind.

## Existing invariant under pressure

- `RUNTIME_CONTRACT.md` §8: the closed list of occurrence kinds and the deduction record fields (requested name and arity, selected hash).
- README: lineage segments are Goal `Name/Arity`; a Goal-arrow body is reduction structure.
- The conservative value barrier: an occurrence with unresolved arguments cannot commit a deduction.

## Classification

This is a component-boundary and identity question (occurrence kinds, deduction records, lineage), not a Runtime profile: independent Runtimes must agree on it to compare ledgers and traces. Goal structure, routing, and Host contracts cannot express it.

## Proposed specification

Recommended option A:

- Add the occurrence kind `goal-arrow-stage`.
- It is deducible: it stays undeduced until demanded and until its routed input resolves (conservative barrier).
- Its deduction binds the input to its parameters (a mismatch is a deduction-phase `DestructureMismatch`), reduces its body, and commits a deduction record with `referenceKind = inline-arrow`, the parameter arity, no requested name, and no artifact hash; the enclosing artifact supplies identity.
- It adds no lineage segment; its children inherit the enclosing Goal lineage.
- It **does** take a child-ordinal segment. A `goal-arrow-stage` is a committed
  reduction, so it assigns child ordinals to its result in authored order and
  occupies one segment of every descendant leaf's root-to-leaf ordinal vector
  under [SCP-0004](0004-voyage-plans-and-touchdown-cable-artifacts.md). Lineage
  and ordinal position are separate axes: the stage is invisible in lineage and
  visible in ordering. Without this rule two Runtimes would disagree on
  `touchdownCableHash` for the same voyage.
- A Scheduler-addressed `@policy` MAY target it, like any other occurrence: it
  carries its own `directPolicies[]` and inherits none. It is a composite, so
  `Reattempt` on it is rejected with `UnsupportedPolicyTarget` under the
  existing rule in `implementation/RUNTIME_ORCHESTRATION_PLAN.md` §8.5. A
  Host-addressed policy MUST NOT target it, because it is not a grounded leaf
  ([SCP-0011](0011-policy-addressee-and-host-channel.md)).

## Alternatives

| Alternative | Benefits | Costs/reason rejected |
|---|---|---|
| A. Deducible `goal-arrow-stage` occurrence (recommended) | Uniform with Goal occurrences; ledger shows when routed values were bound | New kind and a record without a hash |
| B. Expand the body inside the parent deduction with a pending input | No new kind | Commits structure with a pending value; violates the conservative barrier |
| C. Treat the stage as an anonymous Goal with a synthetic name and hash | Reuses Goal records | Invents identities that are not in the source; lineage noise |
| Make no language change | — | Runtimes diverge on kinds, ledgers, and traces for common programs |

## Philosophy and boundary audit

Structure/execution separation, Goal/function separation, policy erasure, and demand-time alias resolution are unaffected. Value routing stays explicit: the stage binds exactly the routed value.

## Compatibility and migration

- Previously valid source affected: none.
- Previously invalid source newly accepted: none.
- Stored artifact/hash impact: none.
- Diagnostic impact: none.
- Migration strategy: Runtimes add the occurrence kind and record.
- Version/profile requirement: Runtime Contract revision.

## Grammar and conformance impact

- `README.md` changes: none, or a note on inline stages.
- ANTLR/EBNF changes: none.
- valid/invalid cases: none.
- policy/runtime cases: a deduction scenario showing an inline stage blocked until its input resolves, then committing one record.

## Reference experiment

The POC implements option A as an experimental path (ADR 0002). Tests: `TestValueBarrierBlocksPrefetch`, `TestDestructureMismatchAtDeduction`.

## Unresolved questions

- None. Policy targeting is settled above.

## Owner decision record

- Decision requested on: 2026-09-17
- Maintainer/agent recommendation: option A
- Owner response: accepted — option A, with the stage taking an ordinal segment
  like any other occurrence and remaining a legal Scheduler-policy target
- Decision date: 2026-09-20
- Conditions: the stage adds no lineage segment; `Reattempt` on it stays
  `UnsupportedPolicyTarget`; Host-addressed policies may not target it

## Final rationale

An inline arrow stage is a real deduction: it waits for a routed value, binds
it, and only then reduces a body that may depend on that value. Everything a
Runtime must record about a deduction — when it committed, what it bound, what
it produced — is already defined for occurrences, so the stage becomes an
occurrence rather than a special case hidden inside its parent. Keeping it out
of lineage and inside the ordinal vector reflects what it is: not a Goal anyone
named, but a place in the realized structure.
