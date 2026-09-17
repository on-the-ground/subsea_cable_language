# Migration Experiment: <name>

## Identity

- Experiment ID:
- Date:
- Agent/owner:
- Upstream repository:
- Pinned revision:
- License:
- Selected program slice:
- Runtime repository/revision/profile:
- Host primitive-semantics profile:
- Scheduler profile:

## Why this target

Describe the new structural or failure model this target contributes. Explain
why the slice is bounded and why its tests are usable.

## Original baseline

- Setup command:
- Test command:
- Toolchain versions:
- Pass/fail/skip count:
- Duration:
- Known flaky/environmental cases:
- Evidence location:

## Public contract under test

- Entrypoint:
- Inputs:
- Outputs:
- Observable effects:
- Public failure shape:
- Timing/order guarantees, if documented:

## Original behavior map

| Source location | Construct | Dependency | Values/effects | Failure behavior | Classification |
|---|---|---|---|---|---|
| | | | | | |

## Subsea Cable model

- Root:
- Subsea Cable source location:
- Goal decomposition summary:
- Serial dependencies:
- Independent products:
- Resolving maps and downstream consumers:
- Shared Goals/repeated occurrences:
- Known unsupported behavior:

## Anchor inventory

| Anchor | Arity | Input | Output | Effect | Original implementation |
|---|---:|---|---|---|---|
| | | | | | |

## Test reuse

| Original test/group | Classification | Unchanged? | Adapter/change | Result |
|---|---|---:|---|---|
| | | | | |

List every weakened, excluded, or rewritten assertion and justify it.

## Happy-path differential result

- Original result/effects:
- Subsea result/effects:
- Relevant original trace:
- Relevant Subsea trace:
- Differences and classification:

## Fault-injection matrix

| Injection | Original behavior | Subsea behavior | Difference | Classification | Evidence |
|---|---|---|---|---|---|
| before leaf start | | | | | |
| after effect/before return | | | | | |
| after success/before acknowledgement | | | | | |
| delayed parallel branch | | | | | |
| failed parallel branch | | | | | |
| duplicate invocation/completion | | | | | |
| cancellation | | | | | |
| crash/resume frontier | | | | | |

## Gap ledger

| Gap | Reproduction | structure/value/Anchor/Scheduler/policy/language | ADR | Status/owner decision | Follow-up |
|---|---|---|---|---|---|
| | | | | | |

## Design decisions raised

For every nontrivial ambiguity:

- ADR link:
- Affected path, currently frozen at:
- Reproduction and trace:
- Existing invariant under pressure:
- Options considered:
- Agent recommendation and reasons:
- Compatibility/migration impact:
- Owner decision required? yes/no
- Owner decision and date:
- Specification/conformance updates authorized:

## Policy candidates

For each candidate:

- Observed behavior:
- Target occurrence:
- Why structure/routing/Anchor contract is insufficient:
- Minimal proposed semantics:
- Rejected alternatives:
- Required tests:
- Promotion stage: Observed / Candidate / Provisional / Stable

## Conformance changes

- Added cases:
- Updated cases:
- Runtime-contract decisions:
- Language-spec discrepancies found:

## Completion checklist

- [ ] Upstream revision and baseline are reproducible.
- [ ] The selected structure is genuinely represented in Subsea.
- [ ] No whole-orchestrator Anchor remains.
- [ ] Behavioral assertions were not weakened silently.
- [ ] Happy path passes or every difference is classified.
- [ ] Fault matrix was executed or each omission is justified.
- [ ] Every gap has one owner layer.
- [ ] No design issue was absorbed implicitly into code or tests.
- [ ] Every owner-required decision has a proposed ADR and recorded answer.
- [ ] Policy candidates have evidence and remain provisional when appropriate.
- [ ] Conformance/decision records were updated.
- [ ] Another agent can reproduce the experiment from this record.

## Final conclusion

State what this experiment taught about the language boundary, not merely
whether the port passed.
