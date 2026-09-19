# Subsea Cable Proposals

Subsea Cable Proposals (SCPs) are the design record for changes to language
syntax, semantics, identity, diagnostics, component boundaries, or portable
policy contracts.

Use `TEMPLATE.md` and allocate a number during review. Draft filenames may begin
with `draft-`; proposal history is retained when a proposal is rejected,
withdrawn, or superseded.

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

## Accepted proposals

- [SCP-0001 — Touchdown consumption and window counting](0001-touchdown-consumption-and-window-counting.md)
- [SCP-0002 — Carousel and Runtime ownership boundaries](0002-carousel-runtime-boundaries.md)
- [SCP-0003 — Explicit staging of value-producing calls](0003-explicit-value-producing-call-staging.md)
- [SCP-0004 — Voyage Plans and Fully Touchdown Cable artifacts](0004-voyage-plans-and-touchdown-cable-artifacts.md)

## Proposals under discussion

- [SCP-0005 — Guarded conditional recursion](0005-guarded-conditional-recursion.md) — core direction accepted; SCC, demand, selector, provenance, and conformance details awaiting confirmation
- [SCP-0006 — Live Vessel–Host cooperation](0006-live-vessel-host-cooperation.md) — live feedback loop and deployment-neutral core accepted; compiler/profile details awaiting confirmation
