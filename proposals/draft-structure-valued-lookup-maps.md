# SCP-NNNN — Structure-valued ordinary lookup maps

- Status: Draft
- Author(s): Claude (agent) for on-the-ground
- Created: 2026-09-17
- Updated: 2026-09-17
- Requires owner decision: yes
- External implementation ADRs: [subsea_cable_runtime `0003-structure-valued-lookup-maps.md`](https://github.com/on-the-ground/subsea_cable_runtime/blob/main/docs/decisions/0003-structure-valued-lookup-maps.md)
- Evidence repositories/revisions: `on-the-ground/subsea_cable_runtime@d62f1c3` (Carousel POC; evidence gathered while pinned to this repository at `cbc6f53`)
- Supersedes: —
- Superseded by: —

## Summary

Specify where an ordinary map whose entries are Goal structure may be bound, how its entries are validated, and how a selected entry receives routed input.

## Motivation and reproduction

README allows "an ordinary-map lookup whose selectable entries are all valid Goal structure" as a Goal-arrow body, but the grammar parses map entries as value expressions, and nothing says where such a map may be defined or how a selected entry is routed. The POC originally accepted a top-level map literal and checked entries at the lookup site; that choice is now blocked in the POC pending this proposal.

## Existing invariant under pressure

- README: lookup selection (`map[key]`, exact key then `_`), "only the selected entry participates".
- README: inside serial or parallel composition only, a bare uppercase identifier is a Goal stage; elsewhere it is a value name.
- Map literal entries are value expressions in `SubseaCable.g4`.

## Classification

Validity of source and the meaning of structure are language questions.

## Proposed specification

Recommended option A:

- A structure-valued lookup map is a top-level non-Goal binding whose right-hand side is a map literal.
- Every entry value must be Goal structure written with explicit suffixes (`A[]`, `$a`, a composition, or a Goal arrow). A bare identifier in an entry is a value name, so it is not Goal structure (`InvalidStructuralContext`).
- Such a map may be used only in a Goal-structure position; using it as a value is `InvalidStructuralContext`.
- The selected entry receives no implicit upstream value; routing must be explicit in the entry.

## Alternatives

| Alternative | Benefits | Costs/reason rejected |
|---|---|---|
| A. Top-level literal, explicit entries, no implicit routing (recommended) | Statically checkable; consistent with the bare-identifier rule | Less flexible |
| B. Allow bare Goal names in entries | Shorter | Contradicts the rule that bare uppercase names are Goal stages only inside compositions |
| C. Remove structure-valued lookup maps | Simplest | Loses value-selected structure, which README intends |
| Make no language change | — | Every Runtime chooses its own validation and routing |

## Philosophy and boundary audit

Selection stays a deduction-time value decision using Host primitive semantics; no execution policy is introduced; policy erasure is unaffected.

## Compatibility and migration

- Previously valid source affected: programs relying on bare entries or on implicit routing into entries become invalid under A.
- Previously invalid source newly accepted: none.
- Stored artifact/hash impact: none.
- Diagnostic impact: `InvalidStructuralContext` for the cases above.
- Migration strategy: add explicit suffixes and routing.
- Version/profile requirement: language revision.

## Grammar and conformance impact

- `README.md` changes: define the binding site, entry form, and routing.
- ANTLR/EBNF changes: none.
- invalid semantic cases: bare entry; map used as a value; lookup of a parameter as structure.
- policy/runtime cases: dynamic `KeyNotFound` and wildcard selection.

## Reference experiment

The POC blocks structure-valued lookup with `UnsupportedByProfile` until a decision (ADR 0003).

## Unresolved questions

- Whether a lookup map may be shared across artifacts, and how it enters `ArtifactHash` (see the artifact-closure proposal).

## Owner decision record

- Decision requested on: 2026-09-17
- Maintainer/agent recommendation: option A
- Owner response: pending
- Decision date: —
- Conditions: —

## Final rationale

Pending.
