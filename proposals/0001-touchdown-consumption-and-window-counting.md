# SCP-0001 — Touchdown consumption and window counting

- Status: Accepted
- Author(s): Claude (agent) for on-the-ground
- Created: 2026-09-17
- Updated: 2026-09-17
- Requires owner decision: yes
- External implementation ADRs: [subsea_cable_runtime `docs/decisions/0001-touchdown-consumption.md`](https://github.com/on-the-ground/subsea_cable_runtime/blob/main/docs/decisions/0001-touchdown-consumption.md)
- Evidence repositories/revisions: `on-the-ground/subsea_cable_runtime` (Carousel POC, pinned to this repository at `cbc6f53`)
- Supersedes: —
- Superseded by: —

## Summary

A published Touchdown leaves the Carousel's Touchdown window through exactly one
applied acknowledgement: a consume acknowledgement at the first dispatch of its
evaluation instance, applied before the Host is invoked, or a discard
acknowledgement if it will never be attempted. The window counts every
published grounded leaf without an applied acknowledgement. Window
backpressure limits only speculative prefetch; explicit Scheduler demand is
always deduced. This closes Carousel plan decisions 3 and 6 and Runtime
orchestration decision R10.

## Motivation and reproduction

The Carousel plan requires the Carousel to keep a requested number `N` of
grounded leaves buffered ahead of evaluation, but left open when a Touchdown
stops counting (decision 6) and which Touchdowns count (decision 3).

The external POC implemented both dispatch-time and completion-time consumption
and ran the same five-step serial program with `prefetch = 2`, one concurrent
attempt, and slow leaves. With consumption at dispatch, two Touchdowns were
buffered behind every in-flight leaf. With consumption at completion, the
in-flight leaf still occupied the window and only one Touchdown was buffered
behind it (regression test `TestPrefetchWindowIsRefilledBehindInFlightWork`).
Two conforming implementations could therefore report the same prefetch target
while committing deductions, and observing aliases, at different times.

## Existing invariant under pressure

- The Carousel plan's objective: "If the requested prefetch is `2`, the leaf
  currently selected for evaluation is not one of those two."
- The minimum-supply rule: the Carousel deduces at least far enough to supply
  the leaf evaluation currently demanded.
- Prefetch changes commitment time, so its counting rule is observable through
  the deduction ledger and alias observation.
- The Carousel must not interpret Scheduler policy or eligibility.

## Classification

This is a portable Carousel/Scheduler boundary contract, not a Runtime profile
choice: it fixes window counts, the normalized trace, backpressure, and
mandatory conformance scenarios. It changes no source syntax, reduction rule,
identity, or diagnostic.

## Proposed specification

### Identities

- An **evaluation instance** is identified by `evaluationInstanceId`, derived
  from `(runId, occurrenceId)` and the occurrence's resolved argument tuple.
  Under the conservative value barrier a grounded leaf occurrence has exactly
  one argument tuple, so one grounded leaf has exactly one evaluation instance.
- An **attempt** is one Scheduler-created try of an evaluation instance,
  identified by `attemptId`.

### What the window counts

The window count is the number of grounded leaves the Carousel has published
for the run and for which neither a consume nor a discard acknowledgement has
been applied. It includes leaves the Scheduler considers ineligible for any
reason: waiting on upstream outcomes, withheld before a first attempt, or
waiting for capacity. The Carousel does not interpret eligibility or policy to
compute it.

### Backpressure applies to speculation only

The prefetch target `N` is compared with the window count directly. When the
count is at or above `N`, the Carousel performs no **speculative** deduction.
Deduction of occurrences carrying explicit Scheduler demand proceeds regardless
of the count. When a deduction of an explicitly demanded occurrence publishes
at least one leaf and the window count **after** that deduction exceeds `N`,
the Carousel emits `DemandedTouchdownOverTarget`, whatever the count was before
(for example, `N = 2`, one leaf buffered, and a demanded deduction grounding two
leaves). This is distinct from `AtomicPrefetchOvershoot`, which is reserved for
a single speculative deduction that grounds more leaves than the remaining
target.

### Consume acknowledgement (first dispatch)

`ConsumeTouchdown(runId, occurrenceId, evaluationInstanceId, attemptId)` is the
single boundary operation that removes a Touchdown from the window. The
Scheduler issues it; the Carousel applies it atomically per occurrence and
emits the normalized `TouchdownConsumed` event. First dispatch is ordered:

1. The Scheduler creates the attempt record, with a non-empty `attemptId`.
2. The Scheduler issues `ConsumeTouchdown`. It must return an **authorizing
   result**: `Consumed`, or `Consumed(replayed)` when the same attempt's
   request is retried after a lost response.
3. Only then does the Scheduler invoke the Host, at most once per attempt; the
   Scheduler's attempt record enforces that bound across replays.

The Carousel records which attempt consumed each Touchdown. Only the two
authorizing results permit a Host invocation. Results:

| Result | Meaning | Authorizes the Host call for this attempt? | Event |
|---|---|---|---|
| `Consumed` | Applied now | yes | `TouchdownConsumed` |
| `Consumed(replayed)` | The same `attemptId` already consumed this Touchdown (for example, the first response was lost and the request was retried) | yes, it reconfirms the same authorization; the Scheduler's attempt record still guarantees at most one Host invocation per attempt | none |
| `AlreadyConsumed(attemptId')` | A **different** attempt consumed this Touchdown first | **no**; this attempt lost the first-dispatch race and ends as aborted | none |
| `Discarded` | A discard was applied first | no; the attempt ends as aborted | none |
| `InvalidAttempt` | `attemptId` is empty | no; boundary error | none |
| `Mismatch` | `evaluationInstanceId` does not match the occurrence | no; boundary error | none |
| `Unknown` | Not a published grounded leaf of this run | no; boundary error | none |

If the Host synchronously refuses an attempt after an authorizing result, the
Touchdown stays consumed and the attempt ends with a Host-phase failure.

Selecting a leaf, evaluating pre-attempt policy, or withholding the first
dispatch never consumes it.

### Subsequent attempts

A later attempt of an already consumed evaluation instance is a separate
Scheduler decision, not a first dispatch. It issues no `ConsumeTouchdown`, does
not re-enter the window, emits no `TouchdownConsumed`, and repeats no
deduction. If a Scheduler issues `ConsumeTouchdown` for it anyway, the result is
`AlreadyConsumed(firstAttemptId)`, and that result does not authorize anything.

### Discard acknowledgement

`DiscardTouchdown(runId, occurrenceId, reason)` removes a buffered Touchdown
that the Scheduler has decided will never be attempted (for example, because an
enclosing scope was cancelled, failed, or withdrawn). The Scheduler issues it;
the Carousel applies it and emits `TouchdownDiscarded`.

| Result | Meaning |
|---|---|
| `Discarded` | Applied now; `TouchdownDiscarded` emitted |
| `AlreadyDiscarded` | No-op, no event |
| `AlreadyConsumed(attemptId)` | No-op, no event; cancellation of that attempt is Scheduler/Host work |
| `Unknown` | Boundary error |

### Races

Consume and discard acknowledgements for one occurrence are serialized by the
Carousel; the first one applied wins, and the other returns the table result
above. A dispatch that loses to a discard never reaches the Host. A discard that
loses to a dispatch leaves the window unchanged, and the in-flight attempt is
cancelled through the Scheduler and Host.

### Held work

While the Scheduler withholds grounded work, that work keeps counting against
the window. Releasing or discarding it is Scheduler behavior.

### Normalized trace events

| Event | Required fields |
|---|---|
| `TouchdownPublished` | `runId`, `occurrenceId`, `evaluationInstanceId`, `windowCount` |
| `TouchdownConsumed` | `runId`, `occurrenceId`, `evaluationInstanceId`, `attemptId`, `windowCount` |
| `TouchdownDiscarded` | `runId`, `occurrenceId`, `evaluationInstanceId`, `reason`, `windowCount` |
| `DemandedTouchdownOverTarget` | `runId`, deduced `occurrenceId`, `windowCount`, `target` |

`windowCount` is the count after the event is applied. Every event also carries
the monotonic sequence number required by the Runtime Contract.

## Alternatives

| Alternative | Benefits | Costs/reason rejected |
|---|---|---|
| Consume at selection | Highest throughput | A leaf withheld or rejected before its attempt stops counting, so the Carousel commits deductions (and alias choices) earlier than evaluation can use them |
| **Consume at first dispatch** | Matches the plan's objective: `N` buffered behind dispatched work; needs no new Host capability | A leaf queued inside a remote Host counts as consumed — **accepted** |
| Consume at Host start | Window matches actual execution | Requires a new Host start acknowledgement; identical to dispatch for local Hosts |
| Consume at completion | Most late binding; retries stay visible in the window | Only `N−1` buffered behind in-flight work, contradicting the objective unless counting is corrected |
| Count only eligible leaves | More aggressive speculation | The Carousel would have to track Scheduler eligibility, crossing the boundary |
| Correct the target by in-flight count | Target means "N behind in-flight" under any consumption point | Unnecessary once consumption happens at dispatch; adds Carousel knowledge of attempts |
| Re-enter the window during a reattempt backoff | Automatic backpressure while retries fail | Repeated consume events per attempt; mixes Scheduler retry state into the window |
| Make no decision (profile choice) | No contract change | Implementations report the same target with different commit timing, breaking replay comparisons |

## Philosophy and boundary audit

- Structure vs execution policy: unchanged; consumption is a boundary
  acknowledgement, not topology.
- Goal vs function separation: unchanged.
- Policy erasure: unaffected; no policy semantics are defined here.
- Carousel, Host, and Scheduler responsibilities: the Scheduler decides when to
  dispatch and issues acknowledgements; the Carousel alone applies them and owns
  the window count; the Host is invoked only after an authorizing result
  (`Consumed` or `Consumed(replayed)`).
- Aliases stay demand-resolved per occurrence; completed deductions stay
  immutable.
- Value routing: unchanged.
- Portability: independent of implementation language and infrastructure.

## Compatibility and migration

- Previously valid source affected: none.
- Previously invalid source newly accepted: none.
- Stored artifact/hash impact: none.
- Diagnostic impact: new boundary results only; no language error kinds.
- Migration strategy: Runtimes consuming at other points must move to first
  dispatch and emit the events above.
- Version/profile requirement: Runtimes claiming Carousel conformance implement
  this SCP.

## Grammar and conformance impact

- `README.md` changes: none.
- ANTLR changes: none.
- EBNF changes: none.
- valid cases / invalid syntax cases / invalid semantic cases: none.
- policy/runtime cases: Carousel plan mandatory scenarios 15–23, stated with
  Scheduler test doubles and without concrete policy semantics.

## Reference experiment

The external POC implements consumption at first dispatch through a single
consume acknowledgement, window counting of all unconsumed published leaves,
demand priority over a full window, and discard handling, with tests for each
scenario above.

## Unresolved questions

- Prefetch scope and the demand count under Scheduler concurrency greater than
  one (Carousel plan decisions 1 and 2) remain open.
- Encoding of `evaluationInstanceId` across Runtimes remains a canonical
  encoding question.

## Owner decision record

- Decision requested on: 2026-09-17
- Maintainer/agent recommendation: consume at first dispatch; count all
  unconsumed published leaves; compare the target directly; reattempts never
  re-enter the window.
- Owner response: accepted all four core recommendations (2026-09-17).
- Detailed contract: the acknowledgement results (including the same-attempt
  replay that re-confirms authorization and the competing-attempt
  `AlreadyConsumed` that authorizes nothing), the discard rule, races (the
  first applied acknowledgement wins), demand priority, the after-count
  over-target condition, the trace fields, and Carousel plan scenarios 15–23
  as mandatory conformance were written afterwards at the owner's review
  request in on-the-ground/subsea_cable_language#1 and **confirmed by the
  owner** (2026-09-17).
- Decision date: 2026-09-17
- Conditions: prefetch scope and demand count (Carousel plan decisions 1 and 2)
  stay open.

## Final rationale

Consumption at first dispatch is the only point that keeps the plan's
objective — `N` grounded leaves buffered behind the work already handed to the
Host — without adding a Host capability or teaching the Carousel about
eligibility or attempts. Counting every unconsumed published leaf keeps the
Carousel ignorant of Scheduler policy. Limiting backpressure to speculation
preserves the minimum-supply rule.
