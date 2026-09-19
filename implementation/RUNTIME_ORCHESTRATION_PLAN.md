# Runtime Orchestration — Coordinating Carousel, Host, and Policy

> **Status:** proposed operational design. The live Vessel–Host feedback-loop
> and deployment-neutral core are accepted in
> [SCP-0006](../proposals/0006-live-vessel-host-cooperation.md), whose
> compiler/profile details remain under discussion; concrete APIs,
> baseline outcome rules, and policy mechanics in this document remain
> non-normative. It extends
> [CAROUSEL_ENGINE_PLAN.md](CAROUSEL_ENGINE_PLAN.md) and must not be implemented
> on any path marked **Owner decision** until that decision is recorded.
> Concrete policy semantics are still undiscovered; every policy name below is
> illustrative only. Where this document touches an unresolved Carousel
> decision, it describes the boundary and required evidence rather than choosing
> a default. The executable path in this plan follows the current conservative
> value-barrier contract: a deduction never commits pending arguments.

## 1. Question this document answers

When someone commands “evaluate this Program's prepared Root occurrence”, three
different kinds of work must interlock:

```text
Carousel   deduces structure on demand and publishes Touchdown occurrences
Host       gives concrete meaning: primitives, function leaves, $Anchors
?          decides when grounded work runs, calls the Host, reacts to
           outcomes under @policy, and feeds values back so deduction continues
```

The `?` is the **Subsea Cable Runtime**. This document designs how it
orchestrates Carousel and Host from the run command to the final Root outcome.

SCP-0006 fixes one architectural answer before the remaining details: the
Runtime remains a logical participant across this loop. It does not produce a
complete Cable or Host program, hand off all control, and disappear. This does
not require a separate process; an in-process library, embedded module, linked
generated program, or remote service can implement the same boundary.

The Runtime does not own new language semantics. It owns:

- the run lifecycle;
- demand coordination (carrying Scheduler demand and prefetch requests to
  Carousel without inventing either);
- evaluation eligibility and dispatch (the Scheduler role in existing docs);
- `@policy` interpretation through pluggable interpreters;
- the outcome/value store that turns leaf results back into routed values;
- trace, ledger persistence, and recovery.

## 2. The run command is not source syntax

A `.vyg` Root must be a deferred reduction: `RootGoal[args]`. `RootGoal(args)`
is not a valid Root. Preparing a valid Program creates that Root occurrence;
starting a run makes the prepared occurrence the run's first deduction demand,
as required by the language specification.

The run command is therefore a **Runtime API act**, not an alternative spelling
inside `.vyg` source:

```text
source Root:     RootGoal[args]      the Program's sole prepared Root occurrence
Run command:     run(program)        demand that occurrence and await its outcome
```

```text
Runtime.run(RunRequest) -> RunHandle

RunRequest
  root          a validated source unit's prepared Root occurrence
  prefetch      explicit number (no default accepted yet)
  profiles      scheduler profile, policy registry, Host primitive profile
  codebase      revision or live index

RunHandle
  events()        normalized trace stream
  result()        Succeeded(value | NoOutput) | Failed | Cancelled
  cancel(reason)
  setPrefetch(n)
```

An implementation may eventually expose an API that invokes an arbitrary stored
`Name/Arity` with separately supplied arguments. That is not Program execution
and must not be presented as replacing or overriding the source unit's sole
Root. **Owner decision R1:** whether such an ad-hoc invocation API belongs in a
portable Runtime profile. CLI spelling remains implementation-specific and
never changes the language grammar.

## 3. Component model

```text
                        ┌──────────────── Subsea Cable Runtime ────────────────┐
 run / cancel / ───────▶│ Run Controller                                        │
 setPrefetch            │     │                                                 │
                        │     ▼                                                 │
                        │ Demand Coordinator ─demand/prefetch▶ Carousel ────────┼─▶ Host.Primitives
                        │     ▲                                  │   ▲          │   (profile-declared)
                        │     │ structure/scope events            │   │ values   │
                        │     │◀─────── occurrences, touchdowns ──┘   │          │
                        │ Scope Tracker ◀────────────┐                │          │
                        │     │                      │                │          │
                        │     ▼                      │                │          │
                        │ Scheduler Core ──▶ Policy Engine            │          │
                        │     │   (eligibility,   (interpreters)      │          │
                        │     │    dispatch)                          │          │
                        │     ▼                                       │          │
                        │ Dispatcher ─────────── attempts ────────────┼──────────┼─▶ Host.Functions
                        │     │                                       │          │   Host.Anchors
                        │     ▼                                       │          │
                        │ Outcome & Value Store ──────────────────────┘          │
                        │                                                         │
                        │ Codebase · Deduction Ledger · Attempt Log · Trace       │
                        └─────────────────────────────────────────────────────────┘
```

| Component | Owns | Never does |
|---|---|---|
| Run Controller | run lifecycle, profiles, cancellation, prefetch changes | deduce, evaluate |
| Demand Coordinator | preserve explicit Scheduler demand, prefetch configuration, and Carousel feedback | infer demand from dependency readiness; resolve aliases |
| Carousel | deduction, alias resolution, ledger commits, lineage, Touchdown window | evaluate leaves, interpret policy |
| Scope Tracker | containment tree, dependency edges, per-scope state and outcome | change topology |
| Scheduler Core | eligibility, ordering, concurrency limits | commit deductions |
| Policy Engine | attach and drive `@policy` interpreters, validate combinations | edit structure or values |
| Dispatcher | turn a Touchdown into Host attempts; cancel attempts | choose policy |
| Outcome & Value Store | attempt outcomes, scope outputs, `ValueRef` resolution | invent values |
| Host | primitive meaning, function-leaf evaluation, Anchor invocation | see structure or aliases |

These boundaries are accepted in
[SCP-0002](../proposals/0002-carousel-runtime-boundaries.md): the Runtime owns
the Outcome & Value Store; Carousel reads resolved values through a narrow port
and never writes outcomes. **Vessel** names the whole Runtime metaphor—the ship
that carries the Carousel, ledger, and Codebase and connects them to the
Seafloor (Host)—not a second deduction engine. This closes R7, R8, and Carousel
plan decision 10.

## 4. Core runtime data model

```text
Occurrence        exposed structural node from Carousel (see RUNTIME_CONTRACT §8)
                  kind: Goal | serial | parallel | resolving-map
                        | function-leaf | anchor
Scope             runtime state attached 1:1 to an occurrence
Touchdown         published grounded leaf envelope (window member)
ValueRef          (occurrenceId, exportPath)  unresolved | resolved(value|NoOutput)
EvaluationInst    (runId, occurrenceId, resolved argument tuple)
Attempt           (evaluationInst, attemptNo, attemptId)
Outcome           Succeeded(value|NoOutput) | Failed(diag) | Cancelled(diag?)
PolicyBinding     (occurrenceId, ordered policies, interpreter states)
```

### 4.1 Scope state machine

Every **exposed** structural occurrence gets one Scope. Still-folded Cable is
Carousel state, not a population of pre-created occurrences or Scopes. An
exposed Goal occurrence may be undeduced, committed, or failed:

```text
Undeduced ──demand──▶ Deducing ──commit──▶ Open ──outcome──▶ Satisfied(output)
    │                    │                   │               Failed(diag)
    │                    └─fail─▶ Failed      └─cancel──────▶ Cancelled
    └─withdraw─▶ Withdrawn  (never deduced; ledger unaffected)
```

Leaf scopes refine `Open`. Under the conservative value barrier a leaf is
grounded only with resolved arguments, so no leaf waits for arguments:

```text
Grounded ─▶ Waiting(deps|withheld|capacity) ─▶ Eligible ─▶ InFlight ─▶ outcome
                                                 ▲            │
                                                 └─reattempt──┘  (Scheduler)
```

### 4.2 Baseline scope outcome rules

The language states dependency and routing, not success rules. The Runtime
therefore needs a **named, versioned baseline profile** (`baseline-local/0`),
explicitly not language semantics:

| Scope kind | Satisfied when (baseline) | Output | Fails when (baseline) |
|---|---|---|---|
| Goal occurrence | its reduction body scope is satisfied | body output | body fails |
| Serial | last element satisfied | last element's output | any element fails |
| Unkeyed parallel | all children satisfied | `NoOutput` always | any child fails |
| Resolving map | every branch produced a value | `{key: value}` | any branch fails or yields `NoOutput` |
| Function / Anchor leaf | an attempt succeeds | attempt value | final attempt fails |

A policy may replace the satisfaction rule of the scope it targets (for example
any/quorum on a parallel scope), but can never fabricate an output: a resolving
map cannot be satisfied with a missing key, and an unkeyed parallel scope only
ever outputs `NoOutput`.

## 5. Demand coordination

Carousel is demand-driven, but dependency readiness is not demand. The
Scheduler owns the evaluation demand presented to Carousel. The Runtime's
Demand Coordinator preserves that decision and classifies facts without turning
every ready sibling into mandatory work:

- **Demanded**: explicitly selected by the Scheduler as a current evaluation
  path. The prepared Root supplies the initial demand. A demanded path must be
  grounded even when `prefetch = 0`, unless deduction is blocked or fails.
- **Prefetch candidate**: an undeduced occurrence that Carousel may select while
  trying to supply additional Touchdowns. Being structurally reachable or
  dependency-ready makes an occurrence a candidate, not automatically demanded.
- **Blocked**: deduction currently requires an unresolved routed value, missing
  capability, resource budget, or another observable prerequisite.
- **Withdrawn**: the Scheduler has removed demand before the occurrence deduced.
  A committed deduction is never withdrawn or rewritten.

```text
Scheduler             selects evaluation demand
Demand Coordinator    preserves demand and visible prefetch configuration
Carousel              selects and deduces within that request
```

Ineligible grounded leaves occupy the window, and a full window never blocks
explicit demand ([SCP-0001](../proposals/0001-touchdown-consumption-and-window-counting.md)).
The number and scope of simultaneous demanded paths and the deterministic
selection of prefetch candidates remain Carousel decisions 1, 2, and 4. This
plan does not convert readiness into a portable demand rule.

## 6. The value barrier

Under the current contract, an occurrence whose arguments require an unresolved
`ValueRef` cannot deduce. Carousel commits no deduction record and publishes no
Touchdown for it, and reports why:

- `DeductionBlocked(occurrence, pendingValue)` for an occurrence carrying
  explicit demand;
- `PrefetchBlocked(reasons)` when speculative replenishment stays below the
  target, listing each blocked candidate and its reason.

A Touchdown envelope always contains resolved arguments.

```text
Patch = [diagnosis] -> $editFiles(diagnosis)

Until Diagnose produces diagnosis:
  Patch is blocked below the Touchdown window
  no Patch deduction record exists
  no Patch leaf is grounded
```

This preserves three existing invariants: a successful deduction records its
actual arguments, Touchdown means a grounded concrete leaf, and a dynamic
`DestructureMismatch` remains a deduction error that cannot appear after that
deduction has committed.

Allowing a committed deduction to carry a pending argument would redefine the
deduction record, error boundary, Touchdown, replay, and alias-observation time.
It is therefore not a Runtime profile fallback. Such a design requires a
language-level SCP and explicit owner approval before it can appear on an
implementation path.

**Value-producing calls are not implicit expressions.** Under
[SCP-0003](../proposals/0003-explicit-value-producing-call-staging.md),
`D[C(x)]` and `D[$anchor(x)]` are invalid outside a function leaf. A Goal or
Anchor call must be a direct structural occurrence so that its evaluation stage
and dependency are visible, for example `[C(x), [v] -> D[v]]`. Primitive value
expressions such as `D[x + 1]` remain valid. Carousel never hoists a nested call
or commits a placeholder argument. This closes R3.

## 7. The orchestration loop

The Runtime is an event-driven reactor. One logical loop, serialized per run,
processes these events:

```text
RunRequested          ScopeOutcome           TimerFired
DeductionCommitted    AttemptCompleted       CancelRequested
OccurrenceExposed     ValueResolved          PrefetchReconfigured
TouchdownPublished    PolicyActionRequested  AliasChanged
TouchdownConsumed     TouchdownDiscarded     DemandedTouchdownOverTarget
DeductionBlocked      PrefetchBlocked        DeductionFailed
HostCapabilityChanged
```

### 7.1 Start

1. Validate the request; pin profiles; record the Host primitive profile.
2. Create the prepared Root occurrence and its Scope; record the Scheduler's
   initial demand for it.
3. `carousel.open(run, root, prefetch)`.

### 7.2 On `OccurrenceExposed` / `DeductionCommitted`

1. Scope Tracker creates or opens scopes and records containment and
   dependency edges.
2. Policy Engine attaches direct policies of the exposed occurrence
   (§8.2). An unknown or invalid policy fails that scope with a policy-phase
   diagnostic **before** any affected execution.
3. Demand Coordinator refreshes readiness and blocking facts. Only an explicit
   Scheduler demand or the accepted prefetch-selection contract sends new
   demand to Carousel.

### 7.3 On `TouchdownPublished`

1. The leaf scope enters `Grounded`, then `Waiting` with its blocking reasons:
   unsatisfied structural predecessors, Scheduler withholding, or capacity. An
   occurrence with unresolved arguments cannot be Grounded under the current
   contract.
2. When no reason remains, it becomes `Eligible`.

### 7.4 Dispatch

1. Scheduler Core selects among eligible instances under the concurrency limit
   and scheduling profile.
2. Policy Engine runs `BeforeAttempt` only for policies directly attached to
   that leaf. A composite policy receives only events of its own target scope
   (§8.3); it is not inherited by descendant attempts.
3. For a first attempt, the Dispatcher creates the Attempt record and issues
   `ConsumeTouchdown(runId, occurrenceId, evaluationInstanceId, attemptId)`.
   The Carousel applies it atomically and emits `TouchdownConsumed`. Only an
   authorizing result (`Consumed`, or `Consumed(replayed)` for the same attempt)
   lets the attempt proceed; `AlreadyConsumed` (another attempt won) and `Discarded` abort it
   without a Host call. This is **Owner decision R10**, recorded in
   [SCP-0001](../proposals/0001-touchdown-consumption-and-window-counting.md),
   which also defines the other results, idempotency, and races. Selecting a
   leaf, running `BeforeAttempt`, or withholding dispatch does not consume it.
4. The Dispatcher then calls `Host.Functions.evaluate` or `Host.Anchors.invoke`.
   A synchronous Host refusal leaves the Touchdown consumed and fails the
   attempt in the `host` phase.
5. A later attempt of the same evaluation instance skips step 3: it neither
   re-enters the window nor emits `TouchdownConsumed`.
6. When the Scheduler settles a leaf that was never attempted (for example,
   because an enclosing scope was cancelled), it issues `DiscardTouchdown`; the
   Carousel applies it and emits `TouchdownDiscarded`. If a first dispatch and a
   discard race, the one the Carousel applies first wins.

### 7.5 On `AttemptCompleted`

1. Record the outcome in the Attempt Log.
2. Policy Engine decides: accept, reattempt, fail, or hold (§8.4).
3. On final acceptance, the leaf scope becomes Satisfied or Failed.
4. Outcome propagation (`ScopeOutcome`) walks up the containment tree using the
   scope rules (§4.2) or the targeting policy's replacement rule.
5. Each newly satisfied scope resolves its `ValueRef`s. The Value Store emits
   `ValueResolved`, which Carousel uses to unblock barriers.
6. Newly available values and satisfied predecessors update candidate facts.
   The Scheduler may then issue new demand; readiness alone does not do so.

### 7.6 Completion

- The run succeeds when the Root scope is Satisfied; the result is its output.
- It fails or is cancelled according to the Root scope outcome.
- Carousel may also report `Quiescent(noReachableWork)`. If the Root is still
  Open at that point, the Runtime reports a stuck run with the blocking reasons.
  It never fabricates completion.

## 8. `@policy` flow control

### 8.1 What is fixed and what is not

Fixed by the language: a policy targets exactly the following occurrence,
stacks in source order, has validated value arguments, never changes topology,
and is never copied to children. The Scheduler interprets it and must reject
unsupported ones.

Not fixed: every concrete policy's meaning, inheritance, and composition. This
design supplies a **mechanism** only.

### 8.2 Policy registry and interpreters

```text
PolicyInterpreter
  id, version
  targetKinds          subset of {Goal, serial, parallel, resolving-map,
                                   function-leaf, anchor}
  validateArgs(args)   -> ok | InvalidPolicyArguments
  attach(scopeCtx)     -> state
  on(event, state, scopeCtx) -> [Action]
```

Attachment happens when the occurrence is disclosed, not at run start, because
lazy alias resolution means policies become known only as structure unfolds. A
Runtime may pre-check policies in reachable artifacts as a courtesy, but that
check is not authoritative.

### 8.3 Events an interpreter observes

An interpreter sees only events of the scope it targets:

```text
ScopeOpened            ChildScopeOutcome (composite targets only)
BeforeAttempt          AttemptOutcome    (leaf targets only)
TimerFired             CancelRequested
ScopeOutcomeProposed   (baseline outcome about to be finalized)
```

A composite-targeted policy observes its children's outcomes as a scope-level
fact. It does not become the children's policy. This is how
`@timeout("30s") {Goal1, Goal1}` can govern the parallel scope as one unit
without copying a timeout to each child.

### 8.4 Closed action set

Interpreters return only these actions:

| Action | Effect |
|---|---|
| `Admit` | allow the attempt or scope to proceed |
| `Hold(condition)` | keep a leaf target Waiting until the condition or a timer; its meaning on a composite target is undefined (part of R9) |
| `StartTimer(duration, token)` | ask for a later `TimerFired` |
| `Reattempt(after?)` | leaf: create a new Attempt for the same evaluation instance |
| `CancelScope(reason)` | cancel in-flight attempts and withdraw undeduced demand under the target |
| `FailScope(diag)` | finalize the target as Failed |
| `SatisfyScope(rule)` | finalize using an observed outcome (never a fabricated value) |
| `Emit(traceFields)` | add policy trace data |

No action can edit topology, routing, aliases, or committed deductions.
`CancelScope` withdraws demand, so undeduced descendants simply stay undeduced.

### 8.5 Invariants of flow control

- **A retry never re-deduces.** A leaf reattempt reuses the committed deduction
  and the same selected hash. Replanning happens only through alias changes that
  undeduced occurrences observe.
- **Scope reattempt is undefined.** Retrying a composite would need
  attempt-scoped occurrence identities. **Owner decision R4**; until then,
  `Reattempt` on a composite target is rejected with `UnsupportedPolicyTarget`.
- **Stacking needs a declared pairing.** The registry publishes a composition
  table for supported ordered pairs. A pair missing from the table is
  `PolicyConflict` at attach time. This design deliberately chooses no nesting
  order.
- **Policy erasure is testable without claiming identical demand.** Policy
  actions may change which occurrences are demanded and when, so a
  corresponding occurrence may observe a different alias revision after
  erasure. The invariant is therefore conditional: for corresponding
  occurrences that select the same artifact with the same arguments, erasing
  policy metadata does not change the structural reduction result.
- **Unsupported policies fail where they are disclosed.** Policies become known
  only as occurrences are exposed. With an empty registry, a run starts
  normally; each policy-bearing occurrence fails its own scope with
  `UnknownPolicy` when it is exposed, before any affected execution. Policies
  are never silently ignored to manufacture a comparison run.

### 8.6 Illustration only

```subsea
Patch = [d] -> @retry $editFiles(d)
Read  = [issue] -> @timeout("30s") {ReadCode[issue], ReadLogs[issue]}
```

A hypothetical `retry` interpreter directly targets the `$editFiles` Anchor
occurrence and answers its `AttemptOutcome(Failed)` with `Reattempt`. Written
on the `Patch` Goal occurrence instead (`@retry Patch`), it would never receive
the leaf's attempt events (§8.3), and reattempting the Goal scope itself is
undefined (R4). A hypothetical `timeout` interpreter answers `ScopeOpened` with
`StartTimer`, and `TimerFired` with `CancelScope` and then `FailScope`. Neither
behavior is accepted language or policy semantics.

## 9. Host coordination

| Host capability | Caller | Contract in this design |
|---|---|---|
| Primitives | Carousel (during deduction) and Host function evaluation (operators inside arrow-function leaves) | one profile-declared semantics per run for both callers; results used by a committed deduction are recorded, so replaying that commit does not call the Host again (this replay guarantee covers only the Carousel's calls) |
| Functions | Dispatcher | receives the leaf envelope, attempt ID, and an **Anchor gateway** for nested `$` calls |
| Anchors | Dispatcher and gateway | lookup, signature check, invoke, convert result |
| Control | Dispatcher | `cancel(attemptId)`, capability description, profile identity |

- **Nested Anchor calls** inside an arrow body go through the Runtime's Anchor
  gateway, so they get a call-site ID, the containing occurrence's lineage, and
  trace events. They are not occurrences and carry no policies.
- **Idempotency material.** Each attempt carries
  `(runId, occurrenceId, argumentIdentity, attemptNo)`. `argumentIdentity` is a
  profile-declared digest or opaque identity until canonical cross-runtime value
  encoding is accepted. Whether a Host uses it as an idempotency key is an
  Anchor contract, not language semantics.
- **Cancellation is cooperative.** The Host may report `Cancelled` or a late
  `Succeeded`. The policy decides what a late success means; the Runtime records
  both.
- **Host failures** keep the `host` phase. A policy may react, but it never
  relabels the failure.

## 10. Replanning during a run

- `AliasChanged` never touches committed deductions, including prefetched
  Touchdowns that are still unconsumed.
- Undeduced occurrences observe the new binding when they are selected.
- A run that expects replanning should use a low prefetch; `0` preserves the
  most late binding. The Runtime should report how many speculative deductions
  committed before an alias change landed, so users can see the cost.
- **Owner decision R5:** may a Runtime *withdraw* still-undeduced speculative
  demand when an alias changes? Withdrawal is safe because nothing committed is
  touched. The question is only whether this is a portable behavior or a
  profile choice.

## 11. Concurrency, persistence, recovery

- **One serialized reactor per run.** Host attempts run concurrently. Carousel
  may deduce concurrently internally, but its commits reach the reactor in
  ledger order.
- **Deterministic mode:** a fixed event order, a virtual clock for timers, and
  a recording Host. This mode is required for the golden traces in the Carousel
  plan's Phase 1.
- **Checkpoint** = deduction ledger + resolved values + Attempt Log + scope
  outcomes + policy interpreter state (serialized by the interpreter).
- **Recovery:** rebuild committed and exposed-undeduced scopes from the ledger
  and frontier checkpoint, leave undisclosed structure folded inside Carousel,
  and restore resolved values. Attempts that were in flight become
  `OutcomeUnknown`. What happens next (re-invoke, ask the Host, fail) is policy
  territory and a prime target for evidence-driven discovery.

## 12. Trace additions

On top of the Runtime Contract §11 and Carousel plan events:

```text
RunRequested / RunCompleted(outcome)
DemandObserved(occurrence, demanded|withdrawn)
PrefetchCandidateObserved(occurrence, ready|blocked, reason?)
ScopeOpened / ScopeOutcome(occurrence, outcome, rule)
ValueResolved(valueRef)
AttemptCreated / AttemptCompleted(attemptId, outcome)
PolicyAttached / PolicyAction(occurrence, policy, action)
AnchorGatewayCall(callSiteId, occurrence)
RunStuck(blockingReasons)
```

## 13. Walkthrough

```subsea
Fix = [issue] -> [
    [] -> { code: ReadCode[issue], logs: ReadLogs[issue] },
    [{code, logs}] -> Diagnose[code, logs],
    Patch,
    Verify
]
ReadCode = [issue]      -> $readCode(issue)
ReadLogs = [issue]      -> $ciLogs(issue)
Diagnose = [code, logs] -> $diagnose(code, logs)
Patch    = [d]          -> @retry $editFiles(d)
Verify   = [p]          -> $runTests(p)
Fix["T-1"]
```

Run with `prefetch = 1` under the current value-barrier contract. For the
illustration, the Scheduler requests the next serial stage only after its
predecessor scope is satisfied; this is example profile behavior, not a
language rule.

| # | Event | Runtime reaction |
|---|---|---|
| 1 | `run(program)` | prepared `Fix["T-1"]` is the initial Scheduler demand; Carousel deduces it → serial scope with 4 stages |
| 2 | example Scheduler demands stage 1 and both map branches | deduce → resolving map → ReadCode and ReadLogs → 2 Touchdowns |
| 3 | both leaves Eligible | dispatch both concurrently; each Touchdown is consumed as its attempt is dispatched |
| 4 | Carousel considers stage 2 as a prefetch candidate | destructuring `{code, logs}` needs an unresolved value → `PrefetchBlocked(pendingValue)` |
| 5 | both Anchors succeed | resolving map Satisfied `{code, logs}` → `ValueResolved`; Scheduler may now demand stage 2 |
| 6 | stage 2 deduces → Diagnose Touchdown | dispatch |
| 7 | prefetch examines `Patch` | Patch needs Diagnose's unresolved output → `PrefetchBlocked(pendingValue)`; no deduction commits |
| 8 | Diagnose succeeds | its value resolves; Scheduler demands Patch → deduction commits and exposes the `$editFiles` Anchor occurrence; its direct `retry` metadata attaches; the Touchdown becomes eligible |
| 9 | `$editFiles` fails | the Anchor's own `retry` interpreter → `Reattempt`; same deduction, attempt 2 |
| 10 | Patch succeeds | Scheduler demands Verify; only now can Verify deduce with Patch's resolved output |
| 11 | Verify succeeds | serial Satisfied → `Fix` Satisfied → run result = Verify's value |

## 14. Decisions this design raises

| ID | Question | Recommendation |
|---|---|---|
| R1 | Separate ad-hoc stored-Goal invocation API | keep outside Program execution; profile question only |
| R2 | Scheduler demand scope and cardinality | resolve with Carousel decisions 1–3; never infer demand from readiness |
| R3 | Eager `Goal(...)` and `$anchor(...)` in argument positions | **Accepted** in [SCP-0003](../proposals/0003-explicit-value-producing-call-staging.md): reject nested calls outside function leaves; require an explicit direct structural stage; never hoist or commit placeholders |
| R4 | Reattempting a composite scope | reject until attempt-scoped occurrence identity exists |
| R5 | Withdrawing speculative demand on alias change | profile choice, always traced |
| R6 | Baseline scope outcome rules (§4.2) | accept as named profile `baseline-local/0`, never language |
| R7 | Value store ownership | **Accepted** in [SCP-0002](../proposals/0002-carousel-runtime-boundaries.md): Runtime owns; Carousel reads through a port |
| R8 | Vessel as the Runtime metaphor | **Accepted** in [SCP-0002](../proposals/0002-carousel-runtime-boundaries.md): Vessel names the whole Runtime metaphor, not a component |
| R9 | Policy observation model (§8.3) and closed action set (§8.4) | open; until decided, Runtimes keep policies as opaque ordered metadata, ship no concrete interpreters, and reject every policy they cannot interpret |
| R10 | Exact `TouchdownConsumed` acknowledgement point | **Accepted** in [SCP-0001](../proposals/0001-touchdown-consumption-and-window-counting.md): consume acknowledgement at first dispatch; the window counts every published, unconsumed grounded leaf (Carousel decision 3) |

Carousel plan decisions 3 and 6 are decided together with R10. The other
Carousel plan decisions remain open; prefetch scope and demand count (plan
decisions 1–2) interact directly with §5–§7 and should be decided together
with R2.

## 15. Fit with the implementation phases

- **Phase 2 (external):** Carousel with explicit Scheduler-demand inputs, Scope Tracker,
  and Value Store; fake Host primitives.
- **Phase 3:** Scheduler Core, Dispatcher, Anchor gateway, empty policy
  registry with rejection, `baseline-local/0`.
- **Phases 4–5:** real migration and fault injection. Only then register
  Candidate policy interpreters through the discovery process.

## 16. Conformance scenarios to add

1. The run command demands the Root even with `prefetch = 0`.
2. Dependency readiness alone never creates Scheduler demand or bypasses the
   Touchdown window.
3. A leaf reattempt never produces a second deduction record.
4. A composite policy observes child outcomes without appearing on the
   children's occurrences.
5. `CancelScope` leaves undeduced descendants undeduced, and the ledger is
   unchanged.
6. A policy discovered in a late-deduced occurrence is rejected before that
   occurrence executes.
7. An unkeyed parallel scope outputs `NoOutput` even under a satisfaction
   policy.
8. A pending routed value creates no downstream deduction record or Touchdown;
   after the value resolves, any dynamic `DestructureMismatch` occurs within
   the affected atomic deduction.
9. A stuck run reports its blocking reasons instead of completing.
10. Nested Anchor calls are traced with call-site identity and carry no policy.
11. Policy erasure: for corresponding occurrences that select the same artifact
    with the same arguments, the policy-erased run commits the same structural
    reduction result.

Touchdown consumption, discard, and window-count scenarios are Carousel plan
scenarios 15–23 (SCP-0001).
