# Deduction Conformance Scenarios

These scenarios specify observable Runtime behavior that syntax-only `.subc`
fixtures cannot express. They are normative for implementations claiming the
demand-time alias and deduction profile.

For every scenario, an artifact is immutable after storage, alias updates are
atomic, and a successful deduction record contains the occurrence ID, requested
name and arity, selected full artifact hash, observed codebase revision,
arguments, result structure, and active lineages.

## 1. Parent deduction does not resolve a child

1. Store `B/0` as `hash-b1` and bind alias `B/0 -> hash-b1`.
2. Store `Upper/0 = [] -> B` and demand the Root occurrence of `Upper/0`.
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
profile. The Vessel requests `x + 1` from that Host capability. No Goal node,
leaf, or Scheduler work is created for the operator expression. The successful
value and Host profile identity are recorded with the deduction.

## 8. Both leaf forms cross the Host boundary

Ground one arrow-function leaf and one `$Anchor` leaf. The Scheduler offers both
to the Host:

- the Host evaluates the validated arrow-function body;
- the Host resolves and invokes the Anchor identifier.

The Anchor registry is only one Host capability; it is not the whole Host.
