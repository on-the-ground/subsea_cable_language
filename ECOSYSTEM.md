# Subsea Cable Ecosystem

Carousel, Host, Scheduler, and complete Runtime implementations are maintained
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
| Language pin | a git submodule carrying the grammar, conformance corpus, `README.md` semantics, and the design documents below; the runtime README records the exact revision |
| Design documents followed | `implementation/CAROUSEL_ENGINE_PLAN.md`, `implementation/RUNTIME_ORCHESTRATION_PLAN.md`, `implementation/RUNTIME_CONTRACT.md`, and SCP-0001, SCP-0002, and SCP-0003 at the pin |
| Profile | `poc-baseline/0` Scheduler, `poc-rational/0` primitives, `poc-sha256-canon/1` artifacts |
| Conformance command | `go test ./...` (runs `conformance/cases.tsv` of the pin; a daily job also runs against `main`) |
| Current result | full `cases.tsv` corpus of the pin passes; `DEDUCTION.md` scenarios 1–4 and 6–8 pass using the corrected scenario 1 source (`[] -> B[]`), scenario 5 only partially (no resume) |
| Supported | demand-driven Carousel with Touchdown prefetch (SCP-0001), Runtime-owned Outcome & Value Store read by Carousel through a read-only port (SCP-0002), conservative value barrier, run-scoped ledger, opaque `@policy` carrier that rejects every policy, deterministic Runtime |
| Unsupported | concrete policy semantics, structure-valued lookup maps, crash/resume, replay, concurrent deduction |
| Pending | SCP-0003 call-position validation and direct eager stages are implemented in `subsea_cable_runtime#2`, which is not merged. The published `main` still rejects those calls with `UnsupportedByProfile`. This row is removed, and the Supported row extended, by a metadata follow-up once that pull request merges |
| Status | proof of concept; not an official Runtime; experimental paths are listed in `implementation/CAROUSEL_POC_FINDINGS.md` |
| Security reports | GitHub private vulnerability reporting, as described in the repository's `SECURITY.md` |
| Maintainer | on-the-ground |
