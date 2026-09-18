# Carousel Deduction Engine — Objective and Plan

> **Status:** owner direction captured; implementation has not started. This is
> a design and execution plan, not yet a normative replacement for the current
> Runtime Contract.

## Objective

Build the **Carousel** as Subsea Cable's demand-driven deduction engine. Its job
is to keep evaluation supplied with grounded leaf Goal occurrences without
eagerly unfolding the whole Program.

The governing rule is:

> Deduce at least far enough to supply the leaf evaluation currently demanded,
> then maintain the user-requested number of additional Touchdown occurrences
> ahead of evaluation whenever the available structure and values permit it.

If the requested prefetch is `2`, the leaf currently selected for evaluation is
not one of those two. Carousel tries to keep two additional grounded leaves
behind that active evaluation frontier. The number `2` is an example, not a
language default chosen by this document.

```text
folded Cable
    |
    v
[ current evaluation demand ] [ prefetched Touchdown 1 ] [ prefetched Touchdown 2 ]
                ^                              |
                |                              v
            Scheduler <---------------- Touchdown window
                |
                v
               Host
```

As the Scheduler consumes a grounded leaf, Carousel advances deduction only as
far as needed to replenish the requested window. This continuous producer and
consumer relationship is what lets evaluation proceed without turning the
entire Goal DAG into an eager expansion.

## Why this engine is necessary

The Host defines concrete computation: primitive semantics, arrow-function leaf
evaluation, and `$Anchor` resolution and invocation. The Scheduler decides when
and under which policy grounded work is attempted. Neither responsibility
produces the grounded leaf occurrences they need.

Carousel supplies that missing mechanism:

```text
Goal artifacts + current aliases + routed values
                         |
                         v
                     Carousel
          demand-driven deduction and commit
                         |
                         v
                Touchdown occurrences
                         |
                         v
                  Scheduler -> Host
```

Without Carousel, a Runtime either has no leaf to evaluate or is forced to
materialize the whole future eagerly. The first cannot run; the second destroys
the mutable undeduced region that gives Subsea Cable its demand-paged character.

## Accepted terminology and ownership

**Carousel is the deduction engine.** It owns demand-time alias resolution, application
of reduction rules, atomic deduction commits, occurrence/frontier tracking,
routing, lineage propagation, and delivery of grounded leaves.

The Vessel remains the surrounding metaphor that carries the Carousel and the
Cable; it must not become a second deduction engine. The target implementation
boundary is therefore:

```text
Consumer Runtime
    Source Frontend
    Codebase
    Carousel          deduction engine
    Outcome & Value Store
    Scheduler Port    evaluation eligibility and policy
    Host Port         concrete computation
    Diagnostics/Trace
```

This boundary is accepted by
[SCP-0002](../proposals/0002-carousel-runtime-boundaries.md) and is reflected
coherently across the canonical documents. An implementation must not create a
second Vessel deduction engine alongside Carousel.

## Required distinctions

Carousel must keep these states separate:

| State | Meaning | Owner |
|---|---|---|
| Undeduced occurrence | Symbolic or pinned occurrence whose reduction has not committed | Carousel |
| Committed intermediate deduction | Hash and resulting structure are immutable, but no descendant leaf is grounded yet | Carousel |
| Touchdown occurrence | A grounded arrow-function or Anchor leaf exists | Carousel publishes it |
| Buffered Touchdown | Grounded leaf published but not yet consumed for evaluation | Carousel/Scheduler boundary |
| Evaluation eligible | Scheduler policy and upstream outcomes allow an attempt | Scheduler |
| In flight / completed | Host evaluation has started or produced an outcome | Scheduler and Host |

Touchdown is not success, readiness policy, or execution. A leaf can be grounded
while the Scheduler still considers it ineligible. Carousel counts grounded,
not-yet-consumed Touchdown occurrences; it does not reinterpret Scheduler
policy to manufacture a count.

## Prefetch contract

### Sliding window

The working contract is a sliding window:

1. An unfinished run creates demand for at least one evaluable leaf path.
2. Carousel deduces until that demand reaches Touchdown or cannot progress.
3. Carousel continues deduction to produce the requested number of additional
   buffered Touchdown occurrences.
4. The Scheduler consumes one or more grounded occurrences and may evaluate them
   through the Host.
5. Each consumption lowers the buffer count and triggers replenishment.
6. Evaluation results may provide values that unblock additional deductions;
   Carousel resumes when those values are committed back to the Runtime.
7. The loop ends only at structural completion, cancellation, or an outcome
   chosen by the Scheduler. Carousel itself does not invent run-level success or
   failure policy.

Conceptually:

```text
while run is structurally active:
    observe evaluation demand and requested prefetch
    while touchdown window is below target:
        choose a demanded frontier occurrence
        if required values are unavailable:
            report why the window is blocked
            stop this replenishment pass
        atomically deduce the occurrence
        publish every newly grounded leaf
    wait for consumption, evaluation result, new demand, cancellation,
    alias/codebase change, or prefetch reconfiguration
```

This pseudocode deliberately does not specify traversal order or Scheduler
policy. Those are explicit design decisions below.

### A target, not a promise of exact cardinality

Prefetch is a lower target subject to structural possibility and a backpressure
bound; it is not permission to split a reduction commit.

One atomic Goal deduction can disclose a parallel product containing multiple
concrete leaves. If the window needs one more leaf and that one deduction
grounds three, all three are committed and published. Carousel may therefore
overshoot the requested count by the indivisible result of one deduction. It
must not discard a branch, partially commit a reduction, or rewrite the Goal
structure merely to hit an exact number.

The target bounds speculative deduction only. Explicitly demanded occurrences
are deduced even when the window is already full, and the resulting over-target
state is reported separately from atomic overshoot (SCP-0001).

Conversely, Carousel may remain below target when progress requires an
evaluation result, a missing input, a failed deduction, or an unresolved
external condition. It reports the blocking reason instead of busy-spinning or
performing evaluation itself.

### A set, not a global queue

A Goal DAG has no single universal “next leaf.” Independent branches can reach
Touchdown together, a shared Goal node can have multiple occurrences and
lineages, and different routed arguments can produce different evaluation
instances.

The prefetched region is therefore a **Touchdown window/set**. A deterministic
ordering may be supplied by a Runtime profile for reproducibility, but that
ordering is not inferred from the word “prefetch” and does not rewrite DAG
dependencies.

## Semantic consequence: prefetch changes commitment time

Prefetch is observable even though it does not change authored topology.
Deduction selects the current `Name/Arity -> ArtifactHash` binding and commits
it. Increasing prefetch can cause an occurrence to deduce before an alias update
that it would otherwise have observed.

Therefore every run must record at least:

- requested prefetch and its scope;
- every change to that request;
- frontier-selection order or the deterministic rule that produced it;
- the demand that caused each deduction;
- selected artifact hash and observed codebase revision;
- Touchdown publication and consumption;
- the reason replenishment stopped below target;
- any atomic overshoot beyond the requested window.

Exact replay cannot rely on the Root artifact and prefetch number alone. It
still requires the deduction ledger. Prefetch configuration and events become
part of the provenance explaining why those deductions committed when they did.

## Component boundaries

### Carousel owns

- accepting evaluation demand and a prefetch request;
- selecting demanded frontier occurrences according to a declared profile;
- resolving an unqualified alias only when its occurrence is selected;
- applying one reduction atomically and committing its record;
- requesting Host primitive semantics when reduction needs them;
- selecting exactly one conditional structural branch from a pure Host-provided
  selector value;
- creating a fresh child occurrence for every selected guarded-recursive step;
- treating every selected conditional child as an explicit-demand boundary
  that speculative replenishment never crosses, irrespective of local recursion
  classification;
- detecting late ancestor `GoalNodeId` re-entry without an intervening
  conditional selection as `CycleDetected` under explicit demand, and abandoning
  that path silently when it is reached speculatively;
- tracking occurrences, dependencies, routing, lineages, and the frontier;
- detecting newly grounded arrow-function and Anchor leaves;
- maintaining and publishing the Touchdown window;
- respecting backpressure and stopping cleanly when blocked;
- never rolling back an earlier committed deduction.

### Carousel does not own

- arrow-function or `$Anchor` leaf evaluation;
- concrete primitive meanings supplied by the Host;
- retry, timeout, cancellation, success aggregation, or policy interpretation;
- choosing whether a grounded leaf is Scheduler-eligible;
- run-level outcome;
- silently resolving a language ambiguity for implementation convenience.

### Scheduler owns

- the evaluation demand presented to Carousel;
- structural and policy eligibility after Touchdown;
- selection among eligible grounded evaluation instances;
- concurrency, retries, cancellation, and outcomes;
- consumption acknowledgement and result delivery back to the Runtime.

The Scheduler may influence which work it demands, but it cannot ask Carousel
to violate dependencies, route unavailable values, partially commit a
reduction, or retarget a committed occurrence.

### Host owns

- primitive value semantics requested during deduction;
- evaluation of grounded arrow-function leaves;
- `$Anchor` lookup, signature checking, invocation, and result conversion;
- Host-phase failures.

The Host cannot unfold Goal structure or choose aliases.

## Backpressure and boundedness

The Touchdown window bounds grounded work waiting for evaluation. It does not
automatically bound every resource involved in reaching a leaf. One leaf may
require a long chain of intermediate deductions, and one atomic deduction may
expose a wide product.

The implementation plan must therefore distinguish:

- **prefetch target** — additional grounded leaves requested ahead of
  evaluation;
- **Touchdown buffer limit** — pressure applied at the Scheduler boundary;
- **deduction work budget** — optional per-pass protection against excessive
  depth, width, time, or memory;
- **atomic overshoot** — unavoidable additional leaves from one committed
  reduction.

Resource budgets are Runtime-profile safeguards, not permission to change Goal
semantics. Reaching a budget yields an observable paused/blocked state, not a
fabricated leaf or partial deduction.

They are not the primary guard against leafless speculative recursion. Under
SCP-0005, any selected conditional child may be exposed but MUST NOT be selected
by replenishment; only a new explicit Scheduler demand crosses that edge,
irrespective of local recursion classification. The optional per-pass budget
therefore remains useful for width, non-conditional depth, time, memory, and
explicitly demanded recursion without being required to make prefetch safe.

## Planned engine events

The normalized trace contract should be extended with events equivalent to:

```text
EvaluationDemandChanged
PrefetchRequested
PrefetchReconfigured
ReplenishmentStarted
FrontierOccurrenceSelected
DeductionCommitted
TouchdownPublished
TouchdownConsumed
PrefetchTargetReached
PrefetchBlocked
AtomicPrefetchOvershoot
DemandedTouchdownOverTarget
TouchdownDiscarded
ReplenishmentStopped
```

`TouchdownPublished`, `TouchdownConsumed`, `TouchdownDiscarded`, and
`DemandedTouchdownOverTarget` are fixed by SCP-0001, including their required
fields. Other names are provisional. Event payloads must preserve run, occurrence, lineage,
deduction cause, window counts, requested scope, and monotonic ordering. Existing
`AliasResolved`, `LeafGrounded`, and evaluation events remain distinct rather
than being collapsed into one “progress” event.

## Implementation phases

### Phase 0 — Decide the contract before code

Produce an accepted decision record for each open item listed below. Define the
state machine, the counting rule, the Scheduler/Carousel handshake, and the
terminology migration. Update this plan when decisions are made; do not bury a
default in the first implementation.

**Gate:** two independent implementers can describe the same state transitions
and counts for the conformance scenarios without writing code.

### Phase 1 — Specify the deterministic model

Write an implementation-neutral reference algorithm over an in-memory Codebase,
deduction ledger, frontier, Touchdown set, and fake Scheduler demand. Add golden
state-transition traces for `prefetch = 0`, `1`, and `2` without real Host leaf
execution.

**Gate:** every deduction cause, commit, published leaf, block, replenishment,
and overshoot is visible in a deterministic trace.

### Phase 2 — Implement the minimal Carousel externally

In a separate Runtime repository, implement a single-threaded deterministic
Carousel with a fake Host primitive profile and recording Scheduler. Support one
run, explicit prefetch, atomic ledger commits, and backpressure. Do not add
production queues, retries, or distributed execution.

**Gate:** all model traces from Phase 1 are reproduced byte-for-byte after
normalization.

### Phase 3 — Close the evaluation feedback loop

Connect grounded leaves to the Scheduler and Host test doubles. Feed successful
values and failures back into structural routing, and replenish the Touchdown
window as evaluations are consumed. Demonstrate that evaluation and deduction
can overlap without Carousel evaluating a leaf or Scheduler committing a
deduction.

**Gate:** a running evaluation can coexist with the requested number of
additional Touchdown occurrences whenever the graph permits, and every blocked
shortfall has a precise reason.

### Phase 4 — Prove lazy-alias and replay behavior

Inject alias updates before selection, during replenishment, after deduction
commit, and after Touchdown publication. Compare different prefetch settings and
prove that their different selections are fully explained by their ledgers and
provenance.

**Gate:** no committed occurrence changes hash; every undeduced occurrence sees
the alias current at its own selection; exact replay uses the recorded ledger
rather than recomputing historical alias choices.

### Phase 5 — Add concurrency without changing semantics

Allow concurrent deduction passes and Scheduler consumption while preserving
atomic occurrence selection and ledger commits. Add cancellation, window
reconfiguration, fairness, and resource-budget tests. Concurrency is successful
only if normalized traces still satisfy the deterministic state model.

**Gate:** race injection cannot duplicate a deduction commit, lose a Touchdown,
exceed bounds except by recorded atomic overshoot, or let Host/Scheduler behavior
rewrite structure.

### Phase 6 — Pressure it with real migrations

Use the existing migration playbook with several different graph shapes and
evaluation speeds. Measure evaluation starvation, unnecessary early commits,
memory retained by prefetched occurrences, and alias-observation differences.
Bring language-level gaps back as SCPs; keep tuning and implementation ADRs in
the external Runtime repository.

**Gate:** at least three qualitatively different program slices run without
evaluation starvation when the graph can supply work, and every inability to
fill the window is classified and traceable.

## Mandatory conformance scenarios

1. **Minimum supply:** `prefetch = 0` still grounds the leaf currently demanded
   for evaluation.
2. **Sliding replenishment:** consuming one buffered Touchdown causes exactly the
   necessary further deductions to refill the target when possible.
3. **Value barrier:** a downstream leaf requiring an upstream result remains
   below the window until that result exists; Carousel reports the barrier.
4. **Parallel fill:** independent branches can fill the window without acquiring
   a dependency edge or execution order.
5. **Atomic overshoot:** one deduction that grounds several parallel leaves
   publishes all of them and records the overshoot.
6. **Shared node, distinct occurrences:** structural sharing does not collapse
   separate Touchdown occurrences or their lineages.
7. **Alias before prefetch:** an occurrence selected after an alias move observes
   the new hash.
8. **Alias after prefetch:** an already prefetched and committed occurrence keeps
   its selected hash.
9. **Reconfiguration:** raising and lowering prefetch changes future work but
   never rolls back committed deductions or discards grounded leaves.
10. **Deduction failure ahead:** a failure found during prefetch is
    occurrence-scoped and cannot retroactively alter the currently evaluating
    leaf; Scheduler policy decides broader consequences.
11. **Cancellation:** cancellation stops new demand and replenishment while
    preserving the ledger.
12. **Host boundary:** primitive requests may occur during deduction, but no
    arrow-function or Anchor leaf is evaluated by Carousel.
13. **Policy opacity:** policy metadata survives publication unchanged and never
    affects Carousel topology or count unless an accepted contract explicitly
    changes the demand supplied by the Scheduler.
14. **Replay:** the recorded ledger, window configuration, and events reproduce
    selected artifacts and Touchdown publication order without consulting
    historical mutable aliases.

## Open design decisions requiring explicit resolution

The owner direction fixes the existence and purpose of Carousel and the
prefetch-ahead model. It does not yet answer all interface questions:

1. **Prefetch scope:** per run, Root, Scheduler lane, lineage, or another unit?
2. **Evaluation demand count:** with Scheduler concurrency greater than one, is
   the target `active demand + prefetch`, or is prefetch independently scoped?
3. **Counting:** do grounded but Scheduler-ineligible leaves occupy the window?
   **Decided** — see [Recorded decisions](#recorded-decisions).
4. **Traversal choice:** when several frontier occurrences can deduce, what
   deterministic rule or Scheduler hint chooses among them?
5. **Dynamic reconfiguration:** who may change prefetch, when does it take
   effect, and can zero pause speculative deduction while preserving current
   demand?
6. **Backpressure ownership:** which side acknowledges `TouchdownConsumed`, and
   what happens when the Scheduler holds grounded work indefinitely?
   **Decided** — see [Recorded decisions](#recorded-decisions).
7. **Resource budgets:** which limits are mandatory, and which are named Runtime
   profile settings?
8. **Default value:** is prefetch always explicit, or may a Runtime profile
   declare a visible default? No numeric default is accepted yet.
9. **Completion:** how does Carousel distinguish “temporarily cannot fill” from
   “no future reachable work remains” without taking over Scheduler outcome?
10. **Terminology migration:** after Carousel assumes deduction ownership, is
    Vessel retained only as the overall runtime metaphor or removed from the
    component vocabulary? **Decided** — Vessel is the whole Consumer Runtime
    metaphor, not a component; see [Recorded decisions](#recorded-decisions).

Each decision must be recorded before the affected implementation path starts.
Choices that change portable behavior, identity, replay, or component ownership
require an SCP and the owner's explicit decision.

## Recorded decisions

Decision 10 and the Runtime value boundary are closed by
[SCP-0002 — Carousel and Runtime ownership boundaries](../proposals/0002-carousel-runtime-boundaries.md)
(Accepted, owner decision 2026-09-17). Carousel is the sole deduction engine;
the Runtime owns the Outcome & Value Store; the Scheduler reports outcomes to
that store; Carousel observes committed values through a read-only port when
deduction requires them. Codebase stores artifacts and aliases, never live run
values.

Decisions 3 and 6 are closed by
[SCP-0001 — Touchdown consumption and window counting](../proposals/0001-touchdown-consumption-and-window-counting.md)
(Accepted, owner decision 2026-09-17), together with Owner decision R10 in
[RUNTIME_ORCHESTRATION_PLAN.md](RUNTIME_ORCHESTRATION_PLAN.md). SCP-0001 is the
normative record; in summary:

- **Consumption (decision 6).** A published Touchdown leaves the window
  through exactly one applied acknowledgement. At the first dispatch of its
  evaluation instance, the Scheduler issues a consume acknowledgement carrying
  `(runId, occurrenceId, evaluationInstanceId, attemptId)`; the Carousel
  applies it and emits `TouchdownConsumed`; only an authorizing result
  (`Consumed`, or `Consumed(replayed)` for the same attempt) lets that attempt
  invoke the Host. An attempt
  that receives `AlreadyConsumed` lost the race and must not invoke the Host.
  Selection, pre-attempt policy, and withholding do not consume. Later attempts
  issue no consume acknowledgement and never re-enter the window. A Touchdown
  that will never be attempted leaves through a discard acknowledgement that
  the Carousel applies and reports as `TouchdownDiscarded`. Consume and discard
  for one occurrence are serialized; the first applied wins.
- **Counting (decision 3).** The window counts every published grounded leaf
  with no applied consume or discard, including Scheduler-ineligible and
  withheld leaves.
- **Target.** The prefetch target is compared with that count directly.
- **Backpressure.** A full window stops only speculative deduction. Explicitly
  demanded occurrences are always deduced; if such a deduction publishes leaves
  and the window count afterwards exceeds the target, the Carousel emits
  `DemandedTouchdownOverTarget`, not `AtomicPrefetchOvershoot`.

These decisions add the following mandatory conformance scenarios. They use
Scheduler test doubles and assume no concrete policy semantics.

15. **Dispatch consumption:** with `prefetch = N` and one dispatched leaf, the
    window holds `N` unconsumed grounded leaves when the graph permits.
16. **Withheld first dispatch:** a Scheduler test double withholds the first
    dispatch of a grounded leaf; the leaf keeps occupying the window, and no
    speculative deduction exceeds the target because of it.
17. **Ineligible leaf:** a grounded leaf waiting on an upstream outcome counts
    toward the window.
18. **Subsequent attempt:** a Scheduler test double creates another attempt of
    an already consumed evaluation instance; the leaf does not re-enter the
    window, no second `TouchdownConsumed` is emitted, and no deduction repeats.
19. **Demand over the target:** with the window full of ineligible leaves, an
    explicitly demanded occurrence is deduced to Touchdown and
    `DemandedTouchdownOverTarget` is emitted. The same event is emitted when a
    partially filled window (for example one of two) receives a demanded
    deduction that grounds several leaves and ends above the target.
20. **Consume replay:** repeating a consume acknowledgement with the same
    attempt returns `Consumed(replayed)`, authorizes that attempt again, and
    emits nothing; an empty attempt identity is rejected.
21. **Discard before dispatch:** a discarded Touchdown is never handed to the
    Host; a later consume acknowledgement returns `Discarded`.
22. **Dispatch/cancellation race:** in both orders, exactly one of
    `TouchdownConsumed` and `TouchdownDiscarded` is emitted, and the Host is
    invoked only if the consume acknowledgement was applied first.
23. **Competing first dispatch:** when a different attempt already consumed the
    Touchdown, a consume acknowledgement returns `AlreadyConsumed` naming the
    first attempt, and the losing attempt never reaches the Host.

SCP-0005 adds these mandatory structural scenarios:

24. **Selected branch only:** a conditional selector exposes exactly one branch;
    unselected branches create no occurrence, alias observation, or Touchdown.
25. **Recursive occurrence DAG:** a guarded countdown creates one fresh
    occurrence per step while all steps may share one recursive `GoalNodeId`.
26. **Recursive alias timing:** an alias update between recursive demands affects
    only the still-undeduced child occurrence.
27. **Exit branch:** selecting the non-recursive branch stops structural
    unfolding without fabricating or cancelling a recursive occurrence.
28. **Conditional demand boundary:** prefetch with available window capacity may
    commit selection and expose a conditional child but never deduces it. Test
    both a locally non-recursive branch and a recursive branch assembled through
    a late alias; each requires a new explicit Scheduler demand. An input that
    never selects its authored exit remains observable and cancellable rather
    than spinning inside one replenishment pass.
29. **Unresolved selector barrier:** a selector waiting on a routed Host value
    commits no deduction, selects no key, creates no branch, and reports the
    ordinary demand/prefetch blocked state until the value resolves.
30. **Late cycle distinction:** ancestor `GoalNodeId` re-entry without an
    intervening committed conditional selection is `CycleDetected` under
    explicit demand; the same re-entry after such a selection creates a fresh
    occurrence. Reached speculatively instead, the unguarded re-entry abandons
    the path with no occurrence and no diagnostic, and only the later explicit
    demand reports `CycleDetected`, so the diagnostic is independent of the
    prefetch target.
31. **Conditional reuse evidence:** `ConditionalBranchSelected` records the
    stable selector slot, canonical value digest, selected key, and primitive
    profile; changing the digest invalidates selected-branch reuse even when the
    same wildcard branch would be selected.

## Completion criteria

The Carousel design is complete when:

- a user can request a prefetch window without selecting an execution policy;
- evaluation always has at least one grounded leaf when the graph and available
  values permit it;
- requested additional Touchdowns are maintained by sliding replenishment;
- every shortfall and atomic overshoot is observable and explained;
- prefetch never causes eager full-program expansion by default;
- deduction remains atomic, immutable, demand-time, and separately traceable
  from evaluation;
- Scheduler and Host can be replaced without changing Carousel semantics;
- prefetch-induced alias timing is reproducible from the deduction ledger;
- the normative terminology and Runtime Contract describe one engine, not a
  duplicated Vessel/Carousel responsibility;
- external Runtime implementations can pass the same conformance scenarios.

## Immediate next deliverables

1. Resolve the remaining open decisions above (decisions 3, 6, and 10 are
   recorded), beginning with prefetch scope and demand count.
2. Write the state-machine reference algorithm and golden traces.
3. Keep the normative documents and conformance plan synchronized with
   SCP-0002 as the reference algorithm develops.
4. Continue the external minimal implementation at Phase 2; do not add it to this
   language repository.
