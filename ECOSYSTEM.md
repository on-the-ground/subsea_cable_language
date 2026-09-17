# Subsea Cable Ecosystem

Host, Vessel, Scheduler, and complete Runtime implementations are maintained
outside the language repository. This page may link independent projects for
discovery; it does not vendor, endorse, or assume maintenance of them.

## Compatibility claims

Every listed project should publish:

- repository and license;
- maintained language/toolchain;
- exact Subsea Cable language revision or release supported;
- Runtime/profile identifier;
- conformance command and current result;
- supported and unsupported features;
- maintainer and security-reporting channel.

“Subsea Cable-compatible” without a language revision/profile and conformance result is
not a meaningful claim.

## Implementations

### subsea_cable_runtime (Carousel POC)

| Field | Value |
|---|---|
| Repository | [on-the-ground/subsea_cable_runtime](https://github.com/on-the-ground/subsea_cable_runtime) |
| License | Apache-2.0 |
| Toolchain | Go 1.24, no third-party modules |
| Language pin | `cbc6f53`, as a git submodule: grammar, conformance corpus, and `README.md` semantics |
| Design documents followed | `implementation/CAROUSEL_ENGINE_PLAN.md`, `implementation/RUNTIME_ORCHESTRATION_PLAN.md`, and SCP-0001 as proposed in #1; the runtime repository's README records the exact revision |
| Profile | `poc-baseline/0` Scheduler, `poc-rational/0` primitives, `poc-sha256-canon/1` artifacts |
| Conformance command | `go test ./...` (runs `conformance/cases.tsv` of the pin; a daily job also runs against `main`) |
| Current result | full `cases.tsv` corpus of the pin passes; `DEDUCTION.md` scenarios 1–4 and 6–8 pass using the corrected scenario 1 source (`[] -> B[]`), scenario 5 only partially (no resume) |
| Supported | demand-driven Carousel with Touchdown prefetch (SCP-0001), conservative value barrier, run-scoped ledger, opaque `@policy` carrier that rejects every policy, deterministic Runtime |
| Unsupported | concrete policy semantics, structure-valued lookup maps, eager `Goal(...)` and value-position `$anchor(...)` outside function leaves, crash/resume, replay, concurrent deduction |
| Status | proof of concept; not an official Runtime; experimental paths are listed in `implementation/CAROUSEL_POC_FINDINGS.md` |
| Security reports | GitHub private vulnerability reporting, as described in the repository's `SECURITY.md` |
| Maintainer | on-the-ground |
