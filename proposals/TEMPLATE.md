# SCP-NNNN — <title>

- Status: Draft
- Author(s):
- Created:
- Updated:
- Requires owner decision: yes/no
- External implementation ADRs:
- Evidence repositories/revisions:
- Supersedes:
- Superseded by:

## Summary

State the proposed language-level change in a few precise sentences.

## Motivation and reproduction

Describe the real implementation or migration that exposed the issue. Link the
smallest reproduction, original behavior, tests, fault injection, and normalized
traces. Hypothetical convenience is insufficient evidence.

## Existing invariant under pressure

Identify the current syntax, semantic rule, identity rule, diagnostic, or layer
boundary that cannot express the observed requirement.

## Classification

Explain why this belongs to the language rather than:

- corrected Goal structure;
- explicit value routing;
- a Host Anchor contract;
- an implementation-specific Runtime profile;
- Scheduler configuration;
- a deferred unsupported feature.

## Proposed specification

Provide implementation-neutral normative behavior, including valid and invalid
forms, ownership, errors, and interaction with existing constructs.

## Alternatives

| Alternative | Benefits | Costs/reason rejected |
|---|---|---|
| | | |

Include “make no language change” as an alternative.

## Philosophy and boundary audit

- Does this preserve structure vs execution policy?
- Does this preserve Goal vs function separation?
- Does policy erasure preserve topology?
- Are Host, Vessel, and Scheduler responsibilities still distinct?
- Do unqualified aliases remain demand-resolved per occurrence, and do completed
  deductions remain immutable commits?
- Is value routing explicit?
- Is the feature portable across languages and infrastructures?

## Compatibility and migration

- Previously valid source affected:
- Previously invalid source newly accepted:
- Stored artifact/hash impact:
- Diagnostic impact:
- Migration strategy:
- Version/profile requirement:

## Grammar and conformance impact

- `README.md` changes:
- ANTLR changes:
- EBNF changes:
- valid cases:
- invalid syntax cases:
- invalid semantic/error cases:
- policy/runtime cases:

## Reference experiment

Describe external prototypes and results. Do not include Runtime implementation
code in this repository.

## Unresolved questions

List unknowns explicitly. An unresolved interaction is not silently assigned a
default.

## Owner decision record

- Decision requested on:
- Maintainer/agent recommendation:
- Owner response:
- Decision date:
- Conditions:

## Final rationale

Completed when Accepted, Rejected, Deferred, Withdrawn, or Superseded. Preserve
the reasons so future implementers do not reopen the same question without new
evidence.
