# Deduction Conformance Scenarios

These scenarios specify observable Runtime behavior that syntax-only `.vyg`
fixtures cannot express. They are normative for implementations claiming the
demand-time alias and deduction profile.

For every scenario, an artifact is immutable after storage, alias updates are
atomic, and a successful deduction record contains the occurrence ID, requested
name and arity, selected full artifact hash, observed codebase revision,
arguments, result structure, and active lineages.

## 1. Parent deduction does not resolve a child

1. Store `B/0` as `hash-b1` and bind alias `B/0 -> hash-b1`.
2. Store `Upper = [] -> B[]` as `Upper/0` and demand the Root occurrence of
   `Upper/0`. (A Goal-arrow body reference always carries `[...]` or `(...)`;
   a bare `B` is valid only as a composition stage.)
3. The committed Upper deduction exposes a child occurrence containing symbolic
   `B/0`; that child has no selected artifact hash yet.
4. Rebind `B/0 -> hash-b2`.
5. Demand the child B occurrence.

The B deduction MUST select `hash-b2`, not `hash-b1`.

## 2. A committed occurrence never retargets

1. Bind `B/0 -> hash-b1`.
2. Demand occurrence `b-occurrence`; it commits `hash-b1`.
3. Rebind `B/0 -> hash-b2`.
4. Demand `b-occurrence` again.

The Runtime MUST reuse its committed deduction record and MUST NOT resolve the
alias again.

## 3. Separate occurrences can observe separate revisions

1. Create two distinct unqualified `B/0` occurrences.
2. With `B/0 -> hash-b1`, demand the first occurrence.
3. Rebind `B/0 -> hash-b2`.
4. Demand the second occurrence.

The first deduction MUST retain `hash-b1`; the second MUST select `hash-b2`.
The occurrences remain distinct even if their arguments and lineages happen to
match.

## 4. Hash-qualified references stay pinned

1. Store an occurrence authored as `B#<prefix-of-hash-b1>[]`.
2. Prepare its containing artifact, resolving the prefix to full `hash-b1`.
3. Rebind the human-readable `B/0` alias to `hash-b2`.
4. Demand the qualified occurrence.

The deduction MUST select `hash-b1`. It MUST NOT consult the current alias.

## 5. Intermediate deductions are checkpoints

1. Demand a composite Goal that exposes a descendant Goal but does not yet
   demand that descendant.
2. Persist the successful parent deduction record.
3. Interrupt and resume the run.

The Runtime MUST restore the parent as committed and the descendant as
undeduced. Touchdown is not required for the parent deduction to be a durable
structural checkpoint.

## 6. Failed deduction is atomic

Force a failure during alias lookup, dynamic routing, cycle detection, or Host
primitive evaluation before a deduction can finish.

The Runtime MUST NOT retain a partial successful deduction record or expose
partially committed children. Earlier deduction records remain unchanged.

## 7. Primitive semantics belongs to the Host

Deduce `A = [x] -> B[x + 1]` under an identified Host primitive-semantics
profile. Carousel requests `x + 1` from that Host capability. No Goal node,
leaf, or Scheduler work is created for the operator expression. The successful
value and Host profile identity are recorded with the deduction.

## 8. Both leaf forms cross the Host boundary

Ground one arrow-function leaf and one `$Anchor` leaf. The Scheduler offers both
to the Host:

- the Host evaluates the validated arrow-function body;
- the Host resolves and invokes the Anchor identifier.

The Anchor registry is only one Host capability; it is not the whole Host.

## 9. Conditional deduction exposes only the selected branch

Validate and store the following while both `A/0` and `B/0` aliases exist:

```subsea
Choose = [flag] -> [
    flag,
    {
        true: A[],
        false: B[],
    },
]
```

Remove the current `B/0` alias, then demand `Choose[true]`. Carousel MUST
evaluate the selector through Host primitive semantics, commit the selected key,
and expose one symbolic `A/0` child. It MUST NOT create a `B/0` occurrence,
resolve that alias, or report `GoalNotFound` for the unselected branch.
Structural validation still checks the authored branch form and statically
available arity information. `ConditionalBranchSelected` MUST record the
selector's stable value slot, canonical digest, selected normalized key, and
active primitive profile. Even though the selected `A/0` edge is non-recursive,
speculative replenishment MAY expose the symbolic child but MUST NOT deduce it;
an explicit Scheduler demand is required to cross the committed conditional
branch edge.

## 10. Guarded recursion creates fresh occurrences

Demand `CountDown[2]` from `conformance/valid/conditional-recursion.vyg`.
After each selection, explicitly demand the exposed recursive child. Successive
demands MUST expose distinct occurrences for `CountDown[1]`, `CountDown[0]`, and
`Done[]`. The three `CountDown/1` occurrences MAY share one `GoalNodeId`, but
each MUST retain its own arguments, lineage, alias observation, and immutable
deduction record. No edge points back to an ancestor occurrence. Prefetch MUST
NOT cross any of the committed conditional branch edges without those explicit
demands.

## 11. Recursive steps retain demand-time alias behavior

1. Demand a guarded recursive occurrence far enough to expose, but not demand,
   its next symbolic recursive child.
2. Rebind the recursive Goal's `Name/Arity` alias to a new artifact that
   preserves a compatible guarded form.
3. Demand the child.

The child MUST select the new hash. The parent and every earlier recursive step
retain their committed hashes. Guarded recursion never pins all future steps at
the first occurrence.

## 12. A valid recursive voyage may not terminate

Use a guarded recursive Goal whose selector never chooses its authored exit for
the supplied input. Validation and deduction MUST NOT report `CycleDetected`
merely because the same Goal definition is selected repeatedly. Each selected
step commits normally only after explicit Scheduler demand. Speculative
replenishment MUST stop at each exposed conditional child even while the
Touchdown window is empty and even when local analysis did not classify the
selected edge as recursive. An explicit deduction-work budget may pause the
demand sequence and Scheduler policy may cancel the voyage. Every completed
record remains immutable and no synthetic exit or partial deduction is
permitted.

## 13. An unresolved selector crosses no value barrier

1. Create a conditional occurrence whose selector depends on an unresolved
   routed output from an earlier Host leaf.
2. Explicitly demand the conditional occurrence before that output resolves.
3. Resolve the output and demand the same occurrence again.

Step 2 MUST report `DeductionBlocked(pendingValue)`, commit no deduction, select
no key, create no branch occurrence or alias observation, and emit no
`ConditionalBranchSelected`. A speculative pass reports the corresponding
`PrefetchBlocked` reason. Step 3 evaluates the selector and commits exactly one
selected branch atomically.

## 14. Late alias cycles distinguish guarded re-entry

Create a demanded unqualified occurrence whose alias resolves to a
`GoalNodeId` already on its ancestor chain.

- With no committed conditional branch selection between the ancestor and the
  explicitly demanded occurrence, deduction MUST fail atomically with
  `CycleDetected`.
- Reaching that same unguarded re-entry during speculative replenishment MUST
  instead abandon the path silently: no occurrence, no `CycleDetected`, and no
  other diagnostic. Demanding it afterwards MUST report `CycleDetected`, so the
  diagnostic does not depend on the prefetch target.
- With at least one committed conditional selection on that path, Carousel MUST
  allow a fresh occurrence. It MUST NOT reuse the ancestor occurrence or create
  a back-edge.

## 15. Conditional reuse requires selector-value evidence

Record a conditional deduction that selected `_`, then start a later voyage
whose corresponding selector produces a different value that also selects `_`.
The two `ConditionalBranchSelected` events have the same selected key but
different canonical selector-value digests. The later voyage MUST NOT reuse the
earlier selected-branch segment. Reuse is permitted only when the stable value
slot, digest, primitive profile, and every other SCP-0004 dependency fingerprint
match.
