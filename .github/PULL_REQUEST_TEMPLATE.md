## Classification

Select exactly one primary classification.

- [ ] Editorial clarification with no semantic change
- [ ] Conformance correction for already specified behavior
- [ ] Language change backed by a Draft or accepted SCP
- [ ] Ecosystem listing
- [ ] Website-only presentation change using canonical repository sources

This repository does not accept Runtime, Host, Vessel/Carousel, Scheduler,
adapter, or production integration code.

## Summary

What canonical language-base artifact changes, and why?

## Evidence

- External implementation repository/revision:
- External proposed ADR:
- SCP:
- Minimal reproduction:
- Original tests/fault injection:
- Normalized traces:

Use `not applicable` only for genuinely editorial or presentation-only changes.

## Language-change gate

- Owner decision required: yes/no
- Exact question presented:
- Recommendation and viable alternatives:
- Recorded owner response, date, and conditions:

- [ ] This PR does not introduce language behavior merely because one Runtime
      found it convenient.
- [ ] Any affected implementation path remained blocked until the required
      owner decision was recorded.
- [ ] A language change has a linked SCP using `proposals/TEMPLATE.md`.
- [ ] No proposed behavior is described as accepted before its SCP is accepted.

## Classification boundary

Why does this belong in the language repository rather than corrected Goal
structure, explicit value routing, a Host Anchor contract, Scheduler
configuration, a reversible Runtime profile, or a deferred feature?

## Philosophy and boundary review

- [ ] Structure remains separate from execution policy.
- [ ] Goal composition remains separate from function implementation.
- [ ] Value routing stays explicit.
- [ ] Host, deduction engine, and Scheduler ownership remains distinct.
- [ ] Terminology follows the accepted SCP-0002 boundary: Carousel is the only
      deduction engine, the Runtime owns the Outcome & Value Store, and Vessel
      names the complete Consumer Runtime rather than any component or
      interface.
- [ ] Unqualified Goal aliases remain lazy until occurrence demand, and no
      committed deduction can be retargeted.
- [ ] Policy erasure preserves topology, or the SCP explicitly changes and
      justifies that invariant.
- [ ] The change is portable across languages and infrastructures.
- [ ] No implementation convenience is presented as language law.

Explain every unchecked applicable item.

## Compatibility

- Previously valid source affected:
- Previously invalid source newly accepted:
- Artifact/hash and stored-codebase impact:
- Diagnostic kind/phase impact:
- Runtime profile impact:
- Migration guidance:

Write `none` only with a reason.

## Synchronized projections

Check every projection affected by this change.

- [ ] `README.md` normative semantics
- [ ] `METAPHORS.md` / `FOR_AGENTS.md` conceptual model
- [ ] `SubseaCable.g4`
- [ ] `SubseaCable.ebnf`
- [ ] `conformance/`
- [ ] implementation-neutral contracts and plans
- [ ] examples, diagnostics, compatibility, and migration notes
- [ ] SCP status and final rationale
- [ ] none of the above require changes; explanation provided below

## Verification

List the exact commands and results used to verify this PR.

- [ ] Required `validate` check passes
- [ ] `mkdocs build --strict` passes
- [ ] `git diff --check` passes
- [ ] Grammar and conformance checks pass when affected
