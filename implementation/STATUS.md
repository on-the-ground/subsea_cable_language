# External Implementation Starting Point

## Current state

- Structural language semantics are documented in `README.md`.
- ANTLR and EBNF projections are present and synchronized at the current review
  level.
- ANTLR 4.13.2 generation has been exercised successfully.
- A lexical-preprocessing reference algorithm and initial conformance corpus
  exist under `conformance/`.
- Demand-time alias resolution, deduction commits, and error ownership are
  specified.
- This repository contains no official Runtime and will not host one.
- No concrete anchoring policy semantics have been accepted.
- No open-source migration experiment has started.
- An independent, non-normative Carousel/Runtime proof of concept exists in
  `on-the-ground/subsea_cable_runtime`; its findings are in
  `CAROUSEL_POC_FINDINGS.md`. It provides evidence but has no authority to settle
  an open decision.
- No production Carousel deduction engine implementation has started. Its objective,
  Touchdown-prefetch model, design questions, and phased plan are recorded in
  `CAROUSEL_ENGINE_PLAN.md`. SCP-0002 is accepted and the canonical documents
  use Carousel as the sole deduction engine; Vessel names the whole Runtime
  metaphor only.

## Starting phase for a new external implementation

**Phase 0 — Freeze the implementation profile.**

In a separate implementation repository, the next implementing agent should:

1. read the files listed in `AGENTS.md`;
2. read `CAROUSEL_ENGINE_PLAN.md` and inventory its unresolved boundary
   decisions together with any normative contradictions;
3. copy the ADR template and create the eight Phase 0 decision records listed in
   `implementation/decisions/README.md` inside the external repository;
4. select one reference language/build system using the rubric in
   `implementation/README.md`;
5. define the reproducible one-command conformance workflow;
6. select one small open-source target and a bounded slice, but do not migrate it
   before Gates 1–3 pass;
7. begin frontend implementation only after Gate 0 is satisfied.

The agent may make reversible implementation-profile choices and record them.
It must stop for owner review if a choice changes source-language semantics,
weakens a conformance case, merges Carousel/Host/Scheduler/value-store
responsibilities, or
claims cross-runtime hash interoperability.

Every design issue discovered after Phase 0 follows the same rule: preserve the
reproduction, freeze the affected path, open a proposed ADR, and request the
owner's decision. No iteration may silently promote an implementation choice to
language or architectural behavior.

If it is language-level, also open an SCP in this repository. Do not submit the
Runtime implementation itself here.

## Explicit prohibition

Do not start by implementing `@retry`, `@timeout`, delivery guarantees, or policy
composition. The first code must establish the Runtime boundary and language
conformance. Concrete policies are admitted only through migration evidence.

## Definition of a useful next handoff

The next handoff should contain:

- links to the Phase 0 decision records;
- the chosen implementation profile and rationale;
- the exact build/test command;
- Gate 0 evidence;
- any real language-spec blocker, separated from implementation preference;
- the smallest Phase 1 implementation slice ready to build.
