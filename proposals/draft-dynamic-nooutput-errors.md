# SCP-NNNN — Errors for NoOutput where a value is required at runtime

- Status: Draft
- Author(s): Claude (agent) for on-the-ground
- Created: 2026-09-17
- Updated: 2026-09-17
- Requires owner decision: yes
- External implementation ADRs: [subsea_cable_runtime `0005-dynamic-nooutput-errors.md`](https://github.com/on-the-ground/subsea_cable_runtime/blob/main/docs/decisions/0005-dynamic-nooutput-errors.md)
- Evidence repositories/revisions: `on-the-ground/subsea_cable_runtime@d62f1c3` (Carousel POC; evidence gathered while pinned to this repository at `cbc6f53`)
- Supersedes: —
- Superseded by: —

## Summary

Name the error kind and phase when a Host leaf returns `NoOutput` where a value is required: into a resolving-map branch, into a routed input, or into a value position inside a function-leaf body.

## Motivation and reproduction

README makes a statically `NoOutput` resolving-map branch invalid and says `NoOutput` cannot be routed, bound, or destructured, but a Host leaf may return `NoOutput` at runtime. The POC reports `NoOutputBranch` and `NoOutputAsValue` in the `host` phase and marks this experimental.

## Existing invariant under pressure

- README: `NoOutput` is not a runtime value; a resolving map's branches must export values.
- Error ownership table: stable `kind` and `phase`.

## Classification

Stable diagnostic kinds and phases are part of the language contract.

## Proposed specification

Recommended option A: a single kind `NoOutputNotRoutable`.

- Phase `deduction` when detected while routing into a deduction (a routed input or a resolving-map result being bound).
- Phase `host` when detected inside a function-leaf body evaluation.

## Alternatives

| Alternative | Benefits | Costs/reason rejected |
|---|---|---|
| A. One kind, phase by detection point (recommended) | Matches existing ownership rules | New kind |
| B. Two kinds (`NoOutputBranch`, `NoOutputAsValue`), both `host` (POC today) | Precise | Misattributes routing failures to the Host |
| C. Treat it as a Host contract violation only | No language change | Hides routing structure |
| Make no language change | — | Runtimes invent different kinds |

## Philosophy and boundary audit

No structural or policy change; clarifies error ownership only.

## Compatibility and migration

- Previously valid source affected: none.
- Previously invalid source newly accepted: none.
- Stored artifact/hash impact: none.
- Diagnostic impact: new stable kind.
- Migration strategy: rename POC kinds.
- Version/profile requirement: language revision.

## Grammar and conformance impact

- `README.md` changes: error ownership table.
- ANTLR/EBNF changes: none.
- runtime cases: a Host leaf returning `NoOutput` into each position.

## Reference experiment

The POC reports the option B kinds, marked experimental (ADR 0005).

## Unresolved questions

- Whether a Scheduler policy may convert the failure (for example into a retry) remains policy discovery.

## Owner decision record

- Decision requested on: 2026-09-17
- Maintainer/agent recommendation: option A
- Owner response: pending
- Decision date: —
- Conditions: —

## Final rationale

Pending.
