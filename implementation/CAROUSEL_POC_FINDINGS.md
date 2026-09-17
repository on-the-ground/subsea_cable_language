# Carousel POC Findings

> **Status:** evidence for owner review, not normative. It comes from an
> independent proof of concept of the Carousel and its orchestrating Runtime,
> maintained outside this repository at
> [on-the-ground/subsea_cable_runtime](https://github.com/on-the-ground/subsea_cable_runtime)
> (pinned to this repository at `cbc6f53`). Each item names what the POC did so
> it could keep running. None of these choices is a proposed default. Items
> that change language semantics need an SCP; items marked **Owner decision**
> need an explicit decision before they are specified.

Related plans: [CAROUSEL_ENGINE_PLAN.md](CAROUSEL_ENGINE_PLAN.md) and
[RUNTIME_ORCHESTRATION_PLAN.md](RUNTIME_ORCHESTRATION_PLAN.md).

## Specification contradictions

### F1. DEDUCTION scenario 1 uses a body the grammar rejects

`conformance/DEDUCTION.md` scenario 1 stores `Upper/0 = [] -> B`. In
`SubseaCable.g4`, `goalBody → goalReference` requires `[...]` or `(...)`, so a
bare `B` is only valid as a composition stage. The POC follows the grammar and
writes the scenario as `Upper = [] -> B[]`.

**Needed:** either correct the scenario text, or allow a bare zero-arity Goal as
a direct Goal-arrow body (grammar and README change).

### F2. Empty source unit

Review of the first POC PR asked for an empty source to parse and fail as
`InvalidRoot`. The current grammar does not allow that: `SubseaCable.g4` has
`program : TERMINATOR? statementList EOF` and `statementList` requires at least
one `statement`; the EBNF has the same shape. Generating the parser from
`SubseaCable.g4` with ANTLR 4.11.1 and parsing an empty file reports
`line 1:0 mismatched input '<EOF>'`, and a file of blank lines reports the same
at EOF. The POC therefore keeps `SyntaxError` for empty sources.

**Needed:** if empty programs should reach semantic validation, change both
grammars and add an empty-file conformance case (an SCP); otherwise add an
empty-file `SyntaxError` case to record the current rule.

## Missing contract pieces

### F3. Inline Goal-arrow stages have no occurrence kind — **Owner decision**

`RUNTIME_CONTRACT.md` §8 lists `Goal | serial | parallel | resolving-map |
function-leaf | anchor`. An inline stage such as `[{code, logs}] -> Diagnose[code,
logs]` must bind a routed value before its body can be reduced, and its body can
depend on that value (for example through lookup). The POC models it as a
deducible occurrence `goal-arrow-stage`: it waits behind the value barrier,
then commits a deduction record with `referenceKind = inline-arrow`, no
artifact hash, and no lineage segment of its own.

**Needed:** decide whether an inline arrow is its own occurrence kind, whether
it gets a deduction record, and how it appears in lineage.

### F4. The policy-erasure invariant needs a condition

Policy actions can change when occurrences are demanded. An occurrence can then
observe a different alias revision in the policy-erased run and select another
artifact. The accurate invariant is: *for an occurrence that selects the same
artifact with the same arguments, erasing policies does not change its
structural reduction result.* The POC test compares only occurrences deduced in
both runs, with no alias changes.

### F5. `Hold` on a composite target has no meaning

`Waiting` exists only for leaves. Interpreting a composite `Hold` as holding
descendants would be the implicit inheritance review point 4 forbids. The POC
allows `Hold` only on leaf targets. **Owner decision:** restrict it to leaves,
or define it as a Scheduler-side hold on demand under the composite.

### F6. Failures found by speculative prefetch

Carousel plan scenario 10 requires that a failure found ahead of evaluation must
not disturb the evaluating leaf. The POC records every prefetch-found failure
at deduction time and surfaces it only when the Scheduler explicitly demands
that occurrence (`DeductionFailureDeferred` → `DeductionFailureSurfaced`); a run
that never demands it ends for lack of demand. The Carousel reports the
occurrence's state to each demand (`accepted`, `already-committed`, `failed`,
`withdrawn`, ...) so the Scheduler can do this.

**Needed:** the plan should state that surfacing a speculative failure is a
Scheduler decision tied to demand, and what `Demand` returns for a failed
occurrence.

### F6a. The consumption point changes what "N ahead" means (R10)

With consumption at dispatch, the POC keeps N Touchdowns buffered behind an
in-flight leaf. With consumption at completion, the in-flight leaf still
occupies the window, so only N−1 are buffered behind it. A regression test in
the POC shows both. Whichever point R10 selects, the Carousel plan's sentence
"the leaf currently selected for evaluation is not one of those two" fixes the
expected count, so R10 and the window counting rule (Carousel decision 3) must
be decided together.

### F7. Nested serial stages and routing

`[A, [B, C]]` parses. README says explicit brackets never receive an implicit
argument, but it does not say whether a nested serial's first stage receives the
upstream value. The POC routes nothing into a nested serial, so its first bare
stage is `/0`.

### F8. Structure-valued lookup maps

README allows "an ordinary-map lookup whose selectable entries are all valid
Goal structure" as a Goal-arrow body. It does not say where such a map may be
bound or how a bare Goal entry's arity is chosen. The POC requires a top-level
map literal binding, requires every entry to be structure, and checks a bare
entry's arity where the lookup is used.

### F9. Artifact hashes and top-level values

Goal bodies can read top-level value bindings, but README does not say whether
those values are part of `ArtifactHash`. Without them, two different programs
could share a hash. The POC includes all of the unit's value bindings, which is
coarse: editing an unrelated value changes every hash.

### F10. Dynamic `NoOutput` where a value is required

README makes a statically `NoOutput` resolving-map branch invalid, but it does
not name the error when a Host leaf returns `NoOutput` at runtime into a
resolving-map branch or a value position. The POC uses `NoOutputBranch` and
`NoOutputAsValue` with phase `host`.

### F11. Uppercase non-Goal value bindings

`X = 1` is not forbidden, but inside a composition a bare `X` reads as a Goal
stage. The POC treats `X` as a value when no Goal named `X` exists, and as a
Goal otherwise.

### F12. Value-position Anchor calls in Goal arguments

`B[$f(x)]` is syntactically valid, and the short-circuit rule in README implies
such calls join the dependency structure. This is the same staging problem as
eager `Goal(...)` arguments (R3). The POC rejects both with
`UnsupportedByProfile`.

## Residual issues in the orchestration plan

These remain open in [RUNTIME_ORCHESTRATION_PLAN.md](RUNTIME_ORCHESTRATION_PLAN.md):

1. §4.1 still lists `Waiting(args)`, which cannot occur under the conservative
   barrier.
2. §5–§6 report a demanded occurrence's value barrier as `PrefetchBlocked`. The
   POC emits `DeductionBlocked` for a single occurrence and `PrefetchBlocked`
   for the aggregated prefetch shortfall.
3. §9 names the Carousel as the only caller of primitives, but function leaves
   also evaluate operators. The POC uses the same Host primitive profile for
   both within a run.
4. §8.5 says an artifact with policies is "rejected as `UnknownPolicy`" under an
   empty registry. Policies are disclosed lazily, so the POC fails the affected
   scope when its occurrence is exposed, not the whole run up front.
5. §16 lacks a policy-erasure scenario (see F4).

The §13 walkthrough now attaches `@retry` directly to the `$editFiles` Anchor
occurrence, as the direct-target rule requires.

## Implementation defects fixed after review

Review of the first POC PR found runtime defects that were implementation bugs,
not language questions. They are fixed in the runtime repository with
regression tests: the prefetch window was not refilled before time advanced;
deduction records were not keyed by run; canonical encodings concatenated raw
map keys and could collide; and speculative failures could end a manual-demand
run. None of these changes the language.

## POC-only diagnostic kinds

These kinds exist only in this profile and are not proposed for the language
error table: `UnsupportedByProfile` (phase `profile`), `InjectedFailure`,
`AnchorFailed`, `NoOutputBranch`, `NoOutputAsValue` (phase
`host`), and `PolicyTimeout`, `RunStuck`, `RunCancelled`, `StepBudgetExceeded`,
`ChildFailed`, `CancelledByPolicy`, `FailedByPolicy` (phase `policy`).
