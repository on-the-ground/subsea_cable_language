# SCP-0009 — Structure-valued ordinary lookup maps

- Status: Accepted
- Author(s): Claude (agent) for on-the-ground
- Created: 2026-09-17
- Updated: 2026-09-20
- Requires owner decision: yes
- External implementation ADRs: [subsea_cable_runtime `0003-structure-valued-lookup-maps.md`](https://github.com/on-the-ground/subsea_cable_runtime/blob/main/docs/decisions/0003-structure-valued-lookup-maps.md)
- Evidence repositories/revisions: `on-the-ground/subsea_cable_runtime@d62f1c3` (Carousel POC; evidence gathered while pinned to this repository at `cbc6f53`)
- Activation pull request: [#10](https://github.com/on-the-ground/subsea_cable_language/pull/10)
- Effective language revision: the commit on `main` produced by squash-merging PR #10
- Supersedes: —
- Superseded by: —

## Summary

Specify where an ordinary map whose entries are Goal structure may be bound, how its entries are validated, and how a selected entry receives routed input.

[SCP-0005](0005-guarded-conditional-recursion.md) separately accepts the
contextual `[selector, {key: GoalBranch}]` form. This draft now concerns only
reusable structure-valued ordinary map bindings outside that conditional
pipeline.

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
- Every entry value must be Goal structure written with an explicit suffix: a
  deferred Goal reference `A[]`, an Anchor reference `$a`, or a serial or
  parallel composition of those. A bare identifier in an entry is a value name,
  so it is not Goal structure (`InvalidStructuralContext`).
- An **inline Goal arrow entry is rejected in validation**, also as
  `InvalidStructuralContext`. The grammar does admit it —
  `mapEntry : mapKey ':' expression` and `expression : goalArrow | logicalOr`,
  so `{k: [x] -> A[x]}` parses — but an entry is reached by lookup, not by
  routing, so a parameterized entry would have no caller to supply its
  arguments. This is a semantic restriction on a syntactically valid form, in
  the same way a nested `Goal(...)` parses and is rejected. No production
  changes.
- A brace literal inside an entry is an ordinary map, not a resolving map,
  because a map is resolving only as the direct body of a Goal arrow.
- Such a map may be used only in a Goal-structure position; using it as a value is `InvalidStructuralContext`.
- The selected entry receives no implicit upstream value; routing must be explicit in the entry.

### Which diagnostic, and where

Two accepted rules reject a bare uppercase name in structure position, with
different kinds, because the positions differ:

| Position | Rule | Kind |
|---|---|---|
| Conditional selector, `[Name, {…}]` | SCP-0005: the selector is a value expression, so `Name` is a value lookup | `UnboundName` when no value binding exists |
| Structure-valued map entry, `{k: Name}` | This SCP: an entry must be Goal structure written with an explicit suffix | `InvalidStructuralContext` |
| Serial or parallel composition stage | README: a bare uppercase identifier is a Goal stage | — (valid) |

A named structure-valued map is **not** a conditional branch map. Writing
`[sel, Routes]` is a two-stage serial composition whose second stage is the Goal
stage `Routes`, not the conditional pipeline of SCP-0005, whose second element
must be an authored branch-map literal. Selecting from a named map is written as
a lookup, `Routes[key]`.

### Identity

A structure-valued lookup map is captured by structure, not by value: its keys
and entry shapes enter the referencing artifact's `ArtifactHash`, while
unqualified Goal references inside entries stay symbolic and resolve at demand
time. See [SCP-0008](0008-artifact-hash-value-closure.md).

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

- None. Capture is settled by SCP-0008; sharing follows from it, because a map
  referenced by two artifacts contributes the same structural capture to both.

## Owner decision record

- Decision requested on: 2026-09-17
- Maintainer/agent recommendation: option A
- Owner response: accepted — option A, with structural capture per SCP-0008 and
  the diagnostic split above
- Decision date: 2026-09-20
- Conditions: entries stay explicit; no implicit routing into a selected entry

## Activation record

- Canonical documents synchronized: `README.md` lookup-map semantics, `implementation/RUNTIME_CONTRACT.md` §2.2, `FOR_AGENTS.md`, `implementation/CAROUSEL_POC_FINDINGS.md` F8
- Grammar projections synchronized: no production change. `mapEntry : mapKey ':' expression` and `expression : goalArrow | logicalOr` admit more than the accepted entry forms, so the restriction is semantic: a bare identifier entry and an inline Goal arrow entry both parse and are rejected in validation
- Diagnostics and examples synchronized: `InvalidStructuralContext` for a bare entry, an inline Goal arrow entry, and a structure-valued map used as a value, with the position split against SCP-0005's `UnboundName`
- Conformance cases synchronized: `conformance/valid/structure-valued-lookup-map.vyg`, `conformance/invalid-semantic/StructureMapBareEntry.vyg`, `conformance/invalid-semantic/StructureMapArrowEntry.vyg`, `conformance/invalid-semantic/StructureMapAsValue.vyg`, `conformance/cases.tsv`, `conformance/DEDUCTION.md` §21
- Compatibility and migration notes synchronized: SCP compatibility section; programs relying on bare entries or implicit routing become invalid
- Verification commands and results: `python .github/scripts/validate_scp_activation.py` passes; `python .github/scripts/test_validate_scp_activation.py` passes; `mkdocs build --strict` passes; every markdown link resolves and every `conformance/cases.tsv` path exists

## Final rationale

The language already lets a value choose structure; what was missing was where
such a map may be written and what an entry must look like. Requiring explicit
suffixes keeps one rule for bare uppercase names instead of a position-dependent
guess, and refusing implicit routing keeps every value that reaches a Goal
visible at the place it is passed.
