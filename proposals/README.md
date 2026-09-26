# Subsea Cable Proposals

Subsea Cable Proposals (SCPs) are the design record for changes to language
syntax, semantics, identity, diagnostics, component boundaries, or portable
policy contracts.

Use `TEMPLATE.md` and allocate a number during review. Draft filenames may begin
with `draft-`, but a proposal MUST receive its numeric filename before its
status may transition to Accepted. Proposal history is retained when a proposal
is rejected, withdrawn, or superseded. The activation validator recognizes both
numbered and `draft-` proposal paths so an accidental status transition cannot
bypass the atomic-activation checks.

Implementation ADRs remain in their external implementation repositories. An SCP
links those ADRs and extracts the implementation-independent language question.

See `GOVERNANCE.md` for statuses and the complete decision procedure. In
particular:

- merging a Draft or Discussion SCP records the proposal but does not change
  the language;
- an approving owner decision is recorded while the SCP remains Discussion;
- the SCP changes to Accepted only in the same pull request that synchronizes
  every affected canonical document, grammar, diagnostic, example, and
  conformance case; and
- the decision becomes effective only when that activation pull request merges.

The activating SCP records that pull request and the resulting effective
language revision. There is no Accepted-but-not-yet-effective state.
Partially approved work must be split so an Accepted SCP contains only its
complete effective contract; pending normative questions remain in a separate
Draft or Discussion SCP.

One activation pull request may activate multiple SCPs. Each records the same
pull request and the single commit created on `main` by squash-merging it.
Existing Discussion SCPs that mention an accepted core are not grandfathered;
their next activation must complete the contract or split pending normative
parts into follow-up proposals.

## Accepted proposals

- [SCP-0001 — Touchdown consumption and window counting](0001-touchdown-consumption-and-window-counting.md)
- [SCP-0002 — Carousel and Runtime ownership boundaries](0002-carousel-runtime-boundaries.md)
- [SCP-0003 — Explicit staging of value-producing calls](0003-explicit-value-producing-call-staging.md)
- [SCP-0004 — Voyage Plans and Fully Touchdown Cable artifacts](0004-voyage-plans-and-touchdown-cable-artifacts.md)
- [SCP-0005 — Guarded conditional recursion](0005-guarded-conditional-recursion.md)
- [SCP-0006 — Live Vessel–Host cooperation](0006-live-vessel-host-cooperation.md)
- [SCP-0007 — Occurrence kind for inline Goal-arrow stages](0007-inline-goal-arrow-stage-occurrence.md)
- [SCP-0008 — Top-level values in artifact identity](0008-artifact-hash-value-closure.md)
- [SCP-0009 — Structure-valued ordinary lookup maps](0009-structure-valued-lookup-maps.md)
- [SCP-0010 — Errors for NoOutput where a value is required at runtime](0010-dynamic-nooutput-errors.md)
- [SCP-0011 — Policy addressee and the Host policy channel](0011-policy-addressee-and-host-channel.md)

## Proposals under discussion

- [SCP-0014 — Laid Cable channel semantics and Goal output multiplicity](0014-laid-cable-channel-semantics.md)
  — Draft; owner-decided direction with remaining activation details
