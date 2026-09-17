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
| License | not chosen yet |
| Toolchain | Go 1.24, no third-party modules |
| Supported language revision | `cbc6f53` (pinned as a git submodule) |
| Profile | `poc-baseline/0` Scheduler, `poc-rational/0` primitives, `poc-sha256-canon/1` artifacts |
| Conformance command | `go test ./...` (runs `conformance/cases.tsv`; a daily job also tests against `main`) |
| Current result | full `cases.tsv` corpus passes; `DEDUCTION.md` scenarios 1–4 and 6–8, 5 partially |
| Supported | demand-driven Carousel with Touchdown prefetch, conservative value barrier, run-scoped ledger, policy carrier with illustrative interpreters, deterministic Runtime |
| Unsupported | eager `Goal(...)` and value-position `$anchor(...)` outside function leaves, crash/resume, replay, concurrent deduction, composite reattempt |
| Status | proof of concept; not an official Runtime |
| Maintainer | on-the-ground (issues in the repository) |

To add one, open an ecosystem-listing PR following `CONTRIBUTING.md`. Runtime
source code itself remains in the external project.
