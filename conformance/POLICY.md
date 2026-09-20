# Policy Conformance Scenarios

These scenarios specify observable Runtime behavior for `@policy` addressee
resolution and the Host policy channel. They are normative for implementations
claiming the policy profile of
[SCP-0011](../proposals/0011-policy-addressee-and-host-channel.md), and they are
stated with test doubles because addressee resolution depends on an attached
Scheduler registry and Host capability, which no `.vyg` fixture can express.

Throughout, `S` is a Scheduler-addressed identifier declared by the Scheduler
policy registry, `H` is a Host-addressed identifier declared by the Host
capability, and both declarations plus the forwarding allowlist are pinned at
run start unless a scenario says otherwise.

## 1. A Host-addressed policy reaches the Host in source order

Author two Host-addressed policies on one grounded leaf. The Host-facing request
MUST carry both in `hostPolicies[]` in source order, with the same decoded
arguments and target spans the occurrence recorded. The Scheduler MUST NOT
interpret either one.

## 2. A Scheduler-addressed policy never crosses the boundary

Author `S` and `H` on the same grounded leaf. `hostPolicies[]` MUST contain only
`H`, and the Host-facing request MUST NOT carry `directPolicies[]` at all.
Inspecting what crossed the boundary MUST show that `S` is absent, not merely
unread. An empty `hostPolicies[]` is the ordinary case for a leaf with no
Host-addressed policy and MUST NOT be reported as a missing field.

## 3. A double claim is `PolicyConflict` at disclosure

Declare one identifier in both the Scheduler registry and the Host capability,
and author it on an occurrence. Disclosing that occurrence MUST report
`PolicyConflict` in the `policy` phase. No Runtime may resolve the collision by
precedence, by configuration order, or by sending the policy to both.

Run a `check` or lint pass with both profiles attached: it MAY report the same
conflict earlier as a preflight diagnostic, and that report MUST NOT change the
authoritative phase or make the source valid or invalid on its own.

## 4. A policy claimed by neither is `UnknownPolicy`

Unchanged from the existing rule: the bearing occurrence fails its own scope
with `UnknownPolicy` when it is disclosed.

## 5. Host-addressed policies target grounded leaves only

Author a Host-addressed identifier directly on a Goal, serial, parallel,
resolving-map and `goal-arrow-stage` occurrence in turn. Each MUST report
`UnsupportedPolicyTarget`.

Author one on a composite and ground a descendant leaf: the descendant's
`hostPolicies[]` MUST stay empty. Policies do not inherit.

A Scheduler-addressed policy on a `goal-arrow-stage` is accepted, because it is
an ordinary occurrence for the Scheduler; `Reattempt` on it is rejected with
`UnsupportedPolicyTarget` under the existing composite rule.

## 6. Declarations are pinned at run start

Start a run, then change the Scheduler registry, the Host capability, or the
forwarding allowlist while occurrences are still undisclosed. Every
later-disclosed occurrence MUST resolve against the pinned declarations, and
every forwarding decision MUST use the pinned allowlist revision. Provenance
MUST record all three pinned identities.

Start a run in which one of the three cannot be pinned: the run MUST refuse to
start, before any occurrence is disclosed and before deduction begins. That
refusal is a profile-negotiation failure and introduces no language diagnostic.

## 7. Attempt identity is readable; the attempt lifecycle is not reachable

The Host-policy context MUST expose the current invocation's attempt identity
and cancellation signal as read-only, and MUST expose no operation to create,
retry, settle, extend or abandon an attempt, and none to read a
Scheduler-addressed policy. The only way the invocation changes Runtime attempt
state is the outcome it returns.

## 8. Cancellation stays cooperative through a delegating policy

Cancel an attempt whose Host-addressed policy moved the work into another
process or worker. The Host MUST forward the cancellation request to that worker
and record having done so in the trace. If the Host then returns a late
`Succeeded`, the Runtime MUST record both the cancellation request and the late
outcome, and the Scheduler policy decides what the late success means.

## 9. Policy erasure is conditional

Run a voyage and a policy-erased copy of it. For corresponding occurrences that
select the same artifact with the same arguments and the same required routed
values, the structural reduction result MUST be equal. A different topology
downstream of a Host-addressed policy that changed an outcome value is permitted
and is not a failure of this case: the invariant is that a Host-addressed policy
never directly edits topology.

## 10. A withheld policy is `PolicyDenied`

Advertise a Host-addressed identifier from the Host capability but withhold it
in the deployment's forwarding allowlist. The bearing occurrence MUST be refused
in the `policy` phase with `PolicyDenied`, and the refusal MUST appear in the
trace. It MUST NOT be silently dropped, MUST NOT be reported as `UnknownPolicy`,
and MUST NOT be reported as `UnsupportedPolicyTarget`.

## 11. Host-addressed policies key the Outcome Journal

Where an Outcome Journal exists, two attempts with identical structure that
differ only in their Host-addressed policies — `@dryRun` and a real run — MUST
produce different journal keys.

## 12. Execution identity and capability version key the journal

Two attempts differing only in the reported `implementationRevision` MUST
produce different journal keys, with the capability manifest, allowlist and
granted capabilities held identical. The same MUST hold for two attempts
differing only in the reported capability snapshot/profile version, and for two
differing only in the pinned allowlist revision.

The variant tag is part of the key. Construct two attempts whose reported
execution identities carry **identical bytes** under different variants — one
`implementationRevision(x)` and one `capabilitySnapshotSubstitute(x, p)`. They
MUST NOT share a journal entry. Two attempts differing only in
`guaranteeProfile` MUST also produce different keys.

## 13. Identity is reported per attempt, not assumed from the pin

Swap the Host implementation mid-run. The affected attempt MUST report the new
`implementationRevision` with its outcome, and its journal entry MUST be keyed
by the reported value rather than by the run-start value.

Exactly one variant is admissible per attempt. Run all four shapes:

1. `implementationRevision(r)` alone — reusable, keyed by that variant and
   value.
2. `capabilitySnapshotSubstitute(s, p)` alone, where the deployment declares the
   guarantee profile `p` and `s` equals the separately reported serving
   capability snapshot identity — **reusable**. A conforming Runtime MUST NOT
   refuse this outcome merely because no implementation revision was reported.
3. Neither variant, or both variants, or a substitute whose `snapshotIdentity`
   does not equal the serving snapshot, or a substitute with no declared
   guarantee profile — MUST NOT be journal-reusable.
4. A reported capability snapshot identity differing from the run-start pinned
   one — recorded as drift, MUST NOT be reused under the pinned identity;
   addressee resolution still uses the pinned identity, and a deployment MAY
   treat drift as a run-level failure.
