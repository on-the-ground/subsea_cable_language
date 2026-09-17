# SCP-NNNN — Top-level values in artifact identity

- Status: Draft
- Author(s): Claude (agent) for on-the-ground
- Created: 2026-09-17
- Updated: 2026-09-17
- Requires owner decision: yes
- External implementation ADRs: [subsea_cable_runtime `0004-artifact-hash-value-closure.md`](https://github.com/on-the-ground/subsea_cable_runtime/blob/main/docs/decisions/0004-artifact-hash-value-closure.md)
- Evidence repositories/revisions: `on-the-ground/subsea_cable_runtime` (Carousel POC, pinned to this repository at `cbc6f53`)
- Supersedes: —
- Superseded by: —

## Summary

Specify which top-level non-Goal bindings a stored Goal artifact captures, so that `ArtifactHash` and `StructureHash` identify what a Goal can observe.

## Motivation and reproduction

Goal bodies read top-level value bindings (for example `issue` in the `FOR_AGENTS.md` plan). README defines `ArtifactHash` as the identity of the authored Goal term but does not say whether the values it reads are part of it. Without them, two programs whose Goals read different values would share a hash. The POC includes every value binding of the source unit, which is coarse: editing an unrelated value changes every hash in the unit.

## Existing invariant under pressure

- README: `ArtifactHash` identifies the complete authored term, including its policy projection; `StructureHash` is its policy-erased projection; unqualified Goal references stay symbolic.
- Top-level bindings form one order-independent scope.

## Classification

Artifact identity is language-level: it decides structural sharing (`GoalNodeId`) and replay.

## Proposed specification

Recommended option A:

- An artifact captures the transitive closure of top-level value bindings its term references by name, in canonical order.
- Captured values are part of both the authored and the structural projection; policies inside them are erased only in the structural projection.
- Goal references stay symbolic and are not captured.

## Alternatives

| Alternative | Benefits | Costs/reason rejected |
|---|---|---|
| A. Capture the referenced value closure (recommended) | Precise identity; unrelated edits do not change hashes | Needs a closure computation |
| B. Capture all unit values (POC today) | Simple | Unrelated edits change every hash; weak structural sharing |
| C. Inline values into the term before hashing | Self-contained terms | Duplicates large values; loses the binding name |
| D. Forbid Goal bodies from reading top-level values | No capture needed | Breaks existing examples |
| Make no language change | — | Hashes are not comparable across Runtimes |

## Philosophy and boundary audit

Identity only; routing, policy, and demand-time alias resolution are unaffected.

## Compatibility and migration

- Previously valid source affected: none.
- Previously invalid source newly accepted: none.
- Stored artifact/hash impact: defines hashes; existing stores must be re-hashed under the accepted encoding profile.
- Diagnostic impact: none.
- Migration strategy: re-store artifacts.
- Version/profile requirement: canonical encoding profile revision.

## Grammar and conformance impact

- `README.md` changes: define capture.
- ANTLR/EBNF changes: none.
- runtime cases: two units whose Goals read different values get different hashes; an unrelated value edit keeps the hash.

## Reference experiment

The POC uses option B under profile `poc-sha256-canon/1`, marked experimental (ADR 0004).

## Unresolved questions

- Canonical encoding and hash algorithm for cross-runtime interoperability remain open.

## Owner decision record

- Decision requested on: 2026-09-17
- Maintainer/agent recommendation: option A
- Owner response: pending
- Decision date: —
- Conditions: —

## Final rationale

Pending.
