## Contribution type

- [ ] Editorial clarification with no semantic change
- [ ] Conformance correction for existing semantics
- [ ] Subsea Cable Proposal / language change
- [ ] Ecosystem listing

This repository does not accept Host, Vessel, Scheduler, adapter, or complete
Runtime implementation code.

## Summary

What language-base artifact changes, and why?

## Evidence

- External implementation repository/revision:
- External ADR:
- SCP:
- Minimal reproduction:
- Original tests/fault injection:
- Normalized traces:

Use `not applicable` only for genuinely editorial changes.

## Classification

Why does this belong in the language repository rather than corrected Goal
structure, value routing, a Host contract, Scheduler profile, external Runtime,
or deferred feature?

## Philosophy and boundary review

- [ ] Structure remains separate from execution policy.
- [ ] Goal composition remains separate from function implementation.
- [ ] Value routing stays explicit.
- [ ] Host, Vessel, and Scheduler ownership remains distinct.
- [ ] Unqualified Goal aliases remain lazy until occurrence demand, and no
      committed deduction can be retargeted.
- [ ] Policy erasure preserves topology, or the proposal explicitly changes and
      justifies that invariant.
- [ ] The change is portable across languages and infrastructures.
- [ ] No implementation convenience is presented as language law.

## Compatibility

- Previously valid source affected:
- Previously invalid source newly accepted:
- Artifact/hash impact:
- Diagnostic impact:
- Migration guidance:

## Synchronized artifacts

- [ ] `README.md` semantics/usage
- [ ] `SubseaCable.g4`
- [ ] `SubseaCable.ebnf`
- [ ] `conformance/`
- [ ] conceptual documents where relevant
- [ ] SCP status/final rationale
- [ ] `git diff --check`

Explain every unchecked applicable item.

## Owner decision

- Owner decision required: yes/no
- Question presented:
- Recommendation and alternatives:
- Recorded response/conditions:
