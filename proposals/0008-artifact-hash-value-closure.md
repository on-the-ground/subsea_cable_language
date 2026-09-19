# SCP-0008 — Top-level values in artifact identity

- Status: Accepted
- Author(s): Claude (agent) for on-the-ground
- Created: 2026-09-17
- Updated: 2026-09-20
- Requires owner decision: yes
- External implementation ADRs: [subsea_cable_runtime `0004-artifact-hash-value-closure.md`](https://github.com/on-the-ground/subsea_cable_runtime/blob/main/docs/decisions/0004-artifact-hash-value-closure.md)
- Evidence repositories/revisions: `on-the-ground/subsea_cable_runtime@d62f1c3` (Carousel POC; evidence gathered while pinned to this repository at `cbc6f53`)
- Activation pull request: [#10](https://github.com/on-the-ground/subsea_cable_language/pull/10)
- Effective language revision: the commit on `main` produced by squash-merging PR #10
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

### Structure-valued lookup maps are captured by structure

A structure-valued ordinary lookup map
([SCP-0009](0009-structure-valued-lookup-maps.md)) is a top-level binding whose
entries are Goal structure, so the plain value rule would capture Goal
references inside it and freeze them into the artifact's identity. That would
destroy demand-time alias resolution for every Goal named in the map.

Such a map is therefore captured **by structure, not by value**:

- its keys and the shape of each entry are part of the capturing artifact's
  `ArtifactHash`, exactly as authored;
- an unqualified Goal reference inside an entry is captured as the symbolic
  `Name/Arity` it is, and still resolves when its own occurrence is demanded;
- a hash-qualified reference inside an entry is captured with its pinned hash,
  as everywhere else;
- policies authored inside entries follow the ordinary rule: part of the
  authored projection, erased in the structural projection.

Editing an entry's structure therefore changes the hash; rebinding a Goal the
entry names does not. This is the same split the language already applies to a
Goal body, applied to a map that holds Goal structure.

### What this does not cover

Captured values are **compile-time identity**: they say what the authored term
can observe. They are unrelated to SCP-0004's value-slot fingerprints, which are
**runtime observations** recorded so a later voyage can decide whether a
committed segment is reusable. A value can appear in both, for different
reasons, and neither substitutes for the other.

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

- Canonical encoding and hash algorithm for cross-runtime interoperability
  remain open. This SCP fixes *what* is captured; a future encoding profile
  fixes *how* it is serialized and hashed.

## Owner decision record

- Decision requested on: 2026-09-17
- Maintainer/agent recommendation: option A
- Owner response: accepted — option A, the referenced value closure, with
  structure-valued lookup maps captured by structure rather than by value
- Decision date: 2026-09-20
- Conditions: unqualified Goal references inside a captured map stay symbolic

## Activation record

- Canonical documents synchronized: `README.md` artifact identity, `implementation/RUNTIME_CONTRACT.md` §2.3 and §6, `AGENTS.md`, `FOR_AGENTS.md`, `implementation/CAROUSEL_POC_FINDINGS.md` F9
- Grammar projections synchronized: not applicable; no source syntax changed
- Diagnostics and examples synchronized: not applicable; no diagnostic kind changed
- Conformance cases synchronized: `conformance/DEDUCTION.md` §22, including a
  case that fails a direct-only capture (`Goal` → value `a` → value `b`, change
  `b`) and a case fixing that reordering binding declarations changes no hash
- Compatibility and migration notes synchronized: SCP compatibility section; existing stores must be re-hashed under the accepted encoding profile
- Verification commands and results: `python .github/scripts/validate_scp_activation.py` passes; `python .github/scripts/test_validate_scp_activation.py` passes; `mkdocs build --strict` passes; every markdown link resolves and every `conformance/cases.tsv` path exists

## Final rationale

An artifact's identity should cover what its term can actually observe, and
nothing else. Capturing the whole unit makes unrelated edits invalidate
unrelated hashes; capturing nothing makes two different programs share one. The
closure is the smallest set that is still honest. The one exception exists for
the same reason: a map full of Goal structure is not data the term reads, it is
structure the term selects from, and freezing the names inside it would trade
identity precision for the language's central property.
