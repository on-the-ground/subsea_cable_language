# Subsea Cable Proposals

Subsea Cable Proposals (SCPs) are the design record for changes to language
syntax, semantics, identity, diagnostics, component boundaries, or portable
policy contracts.

Use `TEMPLATE.md` and allocate a number during review. Draft filenames may begin
with `draft-`; accepted history is never deleted merely because a proposal was
rejected or superseded.

Implementation ADRs remain in their external implementation repositories. An SCP
links those ADRs and extracts the implementation-independent language question.

See `GOVERNANCE.md` for statuses and decision procedure.

## Accepted proposals

- [SCP-0001 — Touchdown consumption and window counting](0001-touchdown-consumption-and-window-counting.md)
- [SCP-0002 — Carousel and Runtime ownership boundaries](0002-carousel-runtime-boundaries.md)
- [SCP-0003 — Explicit staging of value-producing calls](0003-explicit-value-producing-call-staging.md)
- [SCP-0004 — Voyage Plans and Fully Touchdown Cable artifacts](0004-voyage-plans-and-touchdown-cable-artifacts.md)
- [SCP-0006 — Live Vessel–Host cooperation](0006-live-vessel-host-cooperation.md)

## Proposals under discussion

- [SCP-0005 — Guarded conditional recursion](0005-guarded-conditional-recursion.md) — core direction accepted; SCC, demand, selector, provenance, and conformance details awaiting confirmation
