# SCP-0011 — Policy addressee and the Host policy channel

- Status: Accepted
- Author(s): Claude (agent) for on-the-ground
- Created: 2026-09-18
- Updated: 2026-09-20
- Requires owner decision: yes (decided; Owner decision R9 stays open separately)
- External implementation ADRs: pending (subsea_cable_runtime, Host policy channel)
- Evidence repositories/revisions: `on-the-ground/subsea_cable_runtime` POC; owner design review 2026-09-18
- Supersedes: the implicit assumption that every `@policy` is addressed to the Scheduler
- Superseded by: —

## Summary

A `@policy` is metadata addressed to somebody. Two addressees exist, and the
language never said so:

- **Scheduler-addressed** policies change eligibility, the attempt lifecycle, or
  a scope's outcome: retry, timeout, cancellation, completion criteria. The
  Scheduler interprets them, inside the Vessel. This is the case the documents
  already assume.
- **Host-addressed** policies change what happens inside exactly one grounded
  leaf invocation: run it in a separate process, use a resource class. The Host
  interprets them; the Scheduler must not.

The test is mechanical: **if it changes eligibility, the attempt lifecycle, or a
scope's outcome, it is Scheduler-addressed; if it changes only what happens
inside exactly one grounded leaf invocation, it is Host-addressed.**

"Vessel" is the name of the whole Consumer Runtime — Scheduler Port and Host
Port included — so it cannot name one side of this split. This proposal
therefore says *Scheduler-addressed* throughout, and reserves *Vessel* for the
assembled whole and for the product an operator addresses.

The test rules out cases that look Host-shaped but are not. Batching or
coalescing several leaves is Scheduler work: it touches ordering and eligibility
across more than one occurrence, so it is Scheduler-addressed even though the
batch is ultimately executed by the Host.

Host-addressed policies travel with the evaluation request that already exists.
The grounded leaf envelope already carries `directPolicies[]`; this proposal
gives the Host the authority to interpret a declared subsequence of them, names
that subsequence `hostPolicies[]`, and makes it the *only* policy field the
Host-facing request carries. A Host declares the policy identifiers it
accepts in its capability description, the same way it declares Anchors. A
policy claimed by both the Scheduler registry and the Host is an error, not a
precedence question.

## Motivation and reproduction

`@policy` is defined as opaque, ordered occurrence metadata that the Scheduler
interprets, and an unknown policy fails its scope with `UnknownPolicy`. That
leaves no way to write a policy meant for the Host:

```subsea
Patch = [d] -> @separateProcess("worker") $editFiles(d)
```

Today this fails with `UnknownPolicy` in every conforming Runtime, because the
Scheduler is the only interpreter and it cannot know the identifier.

The envelope is not the gap. RUNTIME_CONTRACT §8 already delivers
`directPolicies[]` — identifier, decoded arguments, target span — with every
grounded arrow-function and Anchor occurrence, and the Scheduler already hands
that envelope to the Host capability. What is missing is narrower and sharper:

- the metadata arrives **undifferentiated**, so a Host cannot tell which entries
  were meant for it and which are the Scheduler's to interpret;
- no rule grants a Host the **authority** to interpret any of them; and
- there is no **filtered projection**, so honouring one entry would mean reading
  all of them, including Scheduler-addressed policies the Host must not see.

So the gap is a rule about who a policy is for, plus a named projection of
metadata that already travels with the request: **no new port, and no new policy
payload**. The Host-facing request schema does change — `directPolicies[]` comes
out of it and `hostPolicies[]` goes in — because a projection that leaves the
full envelope in place would hide nothing. What this proposal does not add is a
second channel or a second kind of metadata.

## Existing invariant under pressure

- `$Anchor` and `@policy` identifiers remain **external symbolic names**; the
  language does not enumerate them (RUNTIME_CONTRACT §2.3).
- The Scheduler owns eligibility, ordering, attempts, outcomes, and `@policy`
  (SCP-0002).
- The Host supplies primitive semantics, function-leaf evaluation, and Anchor
  invocation, and **must not decide Goal topology**.
- Ordered policies are part of the authored artifact identity and are erased in
  the structural projection.
- Unknown policies are rejected rather than ignored, and they fail where they
  are disclosed, not at validation time.
- The grounded leaf envelope already carries `directPolicies[]` —
  **only** policies authored on that exact occurrence (RUNTIME_CONTRACT §8).
  Policies do not inherit to descendants.
- The Frontend and Codebase MUST NOT depend on one Scheduler or Host registry
  (RUNTIME_CONTRACT §1).

The first invariant supplies the correction. Anchors are already resolved by
the Host rather than by the language; a Host-addressed policy is the same kind
of name and deserves the same treatment.

## Classification

This is a portable contract and diagnostic question, not a grammar question.
The grammar already admits any policy identifier. What changes is who is
authorized to interpret it, which projection of the existing envelope it appears
in, where it may be attached, and which diagnostic a conflict produces. It
cannot be a Runtime profile choice: two Runtimes that split policies differently
would run the same source with different effects.

## Proposed specification

### Addressee resolution

A Runtime resolves an occurrence's ordered policies against two declarations:

- the **Scheduler policy registry** (Scheduler-addressed identifiers), and
- the **Host capability declaration** (Host-addressed identifiers, with arity
  or argument schema, declared alongside Anchors).

Resolution outcomes:

| Claimed by | Result |
|---|---|
| Scheduler only | Scheduler-addressed; the Scheduler interprets it; it never crosses to the Host |
| Host only | Host-addressed; the Scheduler does not interpret it; it rides in the Host-facing request as `hostPolicies[]` |
| Both | **`PolicyConflict`** — see below |
| Neither | `UnknownPolicy`, unchanged |

### Pinned declarations and resolution time

Three declarations are **pinned at run start**: a Runtime MUST record a
versioned Scheduler registry identity, a Host capability snapshot/profile
identity, and the forwarding-allowlist revision (see *Deployment allowlist*) for
the run, and MUST resolve every occurrence's policies against those pinned
declarations, not against whatever is registered when the occurrence happens to
be disclosed.

This matters because occurrences are disclosed lazily. Without pinning, a
registry or capability change mid-voyage could route the same identifier to a
different addressee for a later occurrence, or turn it into a double claim
partway through, and neither provenance nor replay would be deterministic. With
pinning, addressee resolution is a function of the source plus the recorded
version identities.

Provenance records all three identities. A Runtime MUST NOT re-resolve an
already disclosed occurrence's addressee.

Pinning is a portable safety rule, so it has no permissive branch: when any of
the three cannot be pinned, the run **MUST refuse to start**, before any
occurrence is disclosed and before deduction begins. That refusal is a profile
negotiation / run-start failure, not a new language diagnostic — this proposal
adds no kind for it — but whether the run may proceed is single-valued. Leaving
it optional would reopen exactly the non-deterministic fallbacks pinning exists
to close: live resolution, or an empty declaration treated as "claims nothing".

### Double claim is an error, not a precedence rule

A policy identifier claimed by both the pinned Scheduler registry and the pinned
Host capability is `PolicyConflict` in the **`policy` phase**, reported when the
bearing occurrence is disclosed — the same place `UnknownPolicy` is reported
today. Host argument-schema mismatch is reported the same way.

This is deliberately *not* a `validation`-phase error. The Frontend and Codebase
MUST NOT depend on a Scheduler or Host registry (RUNTIME_CONTRACT §1), external
policy identifiers and arguments are attached by the policy engine at occurrence
disclosure, and structural validation is complete without them. Raising a
registry-dependent conflict into `validation` would make the authored artifact's
acceptance depend on an attached Runtime.

A `check` or lint pass with profiles attached MAY report the same conflict
earlier as a **non-authoritative preflight diagnostic**. A preflight report is a
courtesy: it does not change the authoritative phase, and its absence does not
make the source valid.

No Runtime may resolve the collision by precedence, by configuration order, or
by silently sending the policy to both. A Host that shadows a Scheduler policy
must be rejected loudly, because the alternative lets a Host capture a future
standard policy name.

### Where a Host-addressed policy may be attached

An evaluation request exists only for a grounded leaf. A Host-addressed policy
therefore has `targetKinds = {function-leaf, anchor}`: it MUST be authored
directly on the grounded leaf occurrence it configures.

- A Host-addressed identifier attached directly to any non-leaf occurrence —
  Goal, serial, parallel, resolving-map, or `goal-arrow-stage`
  ([SCP-0007](0007-inline-goal-arrow-stage-occurrence.md)) — is
  `UnsupportedPolicyTarget`, the kind already used when a policy targets an
  occurrence kind that cannot carry it. The rule is the occurrence-kind list,
  not a fixed enumeration: any future non-leaf kind is excluded by the same
  sentence, because an evaluation request exists only for a grounded leaf.
- A Scheduler-addressed policy is unaffected and may target a
  `goal-arrow-stage` like any other occurrence.
- A composite's policy MUST NOT be forwarded to its descendant leaves. Policies
  do not inherit (RUNTIME_CONTRACT §8: `directPolicies[]` is *only* policies
  authored on this exact occurrence), and forwarding would silently create the
  inheritance the contract denies.

### The Host policy channel

Two boundaries must be kept apart, because a projection alone hides nothing.

**Inside the Runtime**, the occurrence record and the grounded leaf envelope keep
`directPolicies[]` unchanged: all of the occurrence's authored policies, in
source order. The Scheduler needs them, provenance records them, and nothing in
this proposal removes them.

**At the Host boundary**, the Dispatcher constructs the Host-facing evaluation
request, and that request carries only:

```text
hostPolicies[]   the source-order subsequence of this occurrence's
                 directPolicies[] that resolved as Host-addressed
```

- The Host-facing evaluation request MUST NOT carry `directPolicies[]`. Handing
  the Host the full envelope and asking it to read only a projection is not a
  boundary; the Scheduler-addressed entries have to be absent from what crosses,
  or "the Host never sees it" is unimplementable.
- `hostPolicies[]` carries the same entries as the corresponding
  `directPolicies[]` subsequence: same decoded arguments, same target spans, same
  relative source order.
- The Scheduler MUST NOT interpret, reorder, drop, or synthesize the
  Host-addressed subsequence; it only filters and forwards it.
- An empty `hostPolicies[]` is the ordinary case and MUST NOT be conflated with
  a missing field.
- Cross-layer ordering is fixed: the **Scheduler attempt lifecycle wraps the
  Host invocation**. A Scheduler-addressed `@timeout` or `@retry` governs the
  attempt within which the Host applies its own policies.
- The Host MAY reject a policy it advertised but cannot honor for this call;
  that is a Host-phase failure of the attempt, not `UnknownPolicy`.

### What a Host-addressed policy may see of the attempt

The Host already receives the attempt identity — the Dispatcher passes it with
the leaf envelope, and `Host.Control.cancel(attemptId)` is how cancellation
arrives — so this proposal does not forbid observation. Forbidding it would
contradict the Host contract and the cancellation forwarding this proposal
itself requires.

What a Host-addressed policy MUST NOT have is **authority over the attempt
lifecycle**, and that is enforced by non-exposure rather than by refusing calls:

- the Host-policy context exposes **read-only** access to the current
  invocation's attempt identity and cancellation signal, which a policy MAY use
  for delegation, tracing, and idempotency;
- it exposes **no** operation to create, retry, settle, extend, or abandon an
  attempt, and none to read or interpret a Scheduler-addressed policy. Those
  operations do not exist on this surface, so there is nothing to call and no
  refusal to specify;
- consequently a Host-addressed policy changes Runtime attempt state only the
  way any Host invocation does — by the outcome it returns, which the Scheduler
  then interprets.

Observation is inside one invocation; lifecycle control is the Scheduler's.

### Cancellation stays cooperative

A Host-addressed policy that moves work into another process, worker, or machine
does not weaken cancellation, and does not strengthen it either. The existing
rule is unchanged: **cancellation is cooperative**
(RUNTIME_ORCHESTRATION_PLAN §9).

- On cancellation the Host MUST forward the request to the delegated worker and
  MUST record that it did so in the trace.
- The Host MAY still return a late `Succeeded`. The Runtime records both the
  cancellation request and the late outcome; the Scheduler policy decides what
  the late success means.
- A Host MUST NOT claim a cancellation guarantee it cannot honour through a
  delegating policy. Advertising such a policy is advertising delegation, not
  preemption.

### What a Host-addressed policy may and may not do

- It MAY change the outcome value, duration, resource usage, or failure mode of
  one attempt.
- It MUST NOT create, remove, or reorder occurrences, change demand, alter
  committed structure, or make the Host produce Goal structure.
- **Policy erasure is conditional, not absolute.** Because a Host-addressed
  policy may change an outcome value, and that value may later feed a
  conditional selector or a routed argument, a policy-erased run may legitimately
  reach a different topology. The invariant this proposal claims is the one
  RUNTIME_ORCHESTRATION_PLAN §8.5 already states: a Host-addressed policy does
  not directly edit topology, and for corresponding occurrences that select the
  same artifact with the same arguments and the same required routed values,
  erasing policy metadata does not change the structural reduction result.

### Argument validation

A Host declares each policy's arity or argument schema with the identifier. The
Runtime validates Host-addressed policy arguments against the pinned declaration
at occurrence disclosure — the same point it validates Scheduler policy
arguments — and reports `InvalidPolicyArguments` in the `policy` phase.

Structural validation is unaffected and still completes before deduction: it
never consults either declaration, so nothing here moves work into or out of the
`validation` phase.

### Deployment allowlist

A deployment MAY restrict which Host-addressed policies a Runtime forwards. A
policy that a Host advertises but the deployment withholds is refused in the
`policy` phase with the stable kind **`PolicyDenied`** and recorded in the
trace; it is never silently dropped. The kind is distinct on purpose:
`UnknownPolicy` is wrong because the Host does know the identifier, and
`UnsupportedPolicyTarget` is wrong because the target is a legal one — what
failed is the deployment's permission to forward it.

This matters where agents commit source through an MCP surface: without it,
source text is an unmediated channel into the Host.

**The allowlist is pinned like the other two declarations.** It decides whether
a real Host effect happens, so its lifetime cannot be left implicit: a Runtime
MUST pin an allowlist snapshot/revision identity at run start, alongside the
Scheduler registry version and the Host capability snapshot, and MUST evaluate
every forwarding decision in the run against that pinned revision. The pinned
revision is recorded in provenance and is part of the granted-capability
material in the Outcome Journal key. A run whose allowlist cannot be pinned
refuses to start, exactly as for the other two declarations.

Without pinning, the same Host-addressed policy on a later-disclosed occurrence
could be forwarded by one Runtime and refused with `PolicyDenied` by another,
and a change landing between disclosure and dispatch would leave the moment the
`policy` phase is decided undefined. Pinning makes the decision a function of
the source plus one recorded revision, and fixes it at disclosure.

**Live revocation is deliberately out of scope here.** An operator who must stop
an in-flight run's Host effects today cancels the run, which is already defined
and already cooperative. Making the allowlist revocable *within* a run is a
separate proposal, and it would have to define at least: atomic observation and
commit of the revision at each occurrence disclosure; what a revocation means
for an occurrence already disclosed but not yet dispatched, and for one already
in flight; how that interacts with cooperative cancellation and a late
`Succeeded`; and how the journal is keyed when two attempts in one run saw
different revisions. This proposal does not answer those, so it does not permit
the behavior.

### Identity, provenance, and reuse

- Ordered policies of **both** kinds remain part of the authored `ArtifactHash`
  and are erased in `StructureHash`, unchanged.
- A Touchdown content descriptor stays policy-erased (SCP-0004).
- Provenance records the split: which policies were Scheduler-addressed, which
  were Host-addressed, the pinned Scheduler registry version, the pinned Host
  capability snapshot and Host identity, the pinned forwarding-allowlist
  revision, the granted capabilities, and — **per attempt** — the reported Host
  capability snapshot identity plus the tagged execution identity that actually
  served it.
- Consequently a future Outcome Journal MUST key an outcome by at least the
  Touchdown descriptor, the Host identity, the serving attempt's **tagged
  reported execution identity**, the **Host capability snapshot/profile identity
  and version that attempt reported**, the Host-addressed policy digest, and the
  granted capabilities including the pinned allowlist revision. Two attempts
  with identical structure but different Host-addressed policies — `@dryRun` and
  a real run — MUST NOT share a journal entry, and neither may two attempts that
  differ only in execution-identity variant/value or capability profile version.

#### Which identities are pinned, and which are reported

The two uses have different correctness conditions, so they observe at
different times:

- **Addressee resolution** must be deterministic across the whole voyage, so it
  uses the identities pinned at run start and nothing else. Nothing in this
  section changes that.
- **Outcome reuse** must describe what actually produced the outcome, and only
  the attempt knows that. For an outcome to be journal-reusable, a Host MUST
  therefore report with it the capability snapshot identity that served the
  attempt and exactly one tagged execution identity:

```text
reportedExecutionIdentity =
    implementationRevision(revisionOrDigest)
  | capabilitySnapshotSubstitute(snapshotIdentity, guaranteeProfile)
```

The journal MUST key by the variant tag as well as its value, so identical bytes
in the two namespaces never collide.

Run-start pinning alone cannot carry this. A Host may swap its binary or adapter
mid-voyage; a Runtime keying by the run-start value would record the old
implementation against a new implementation's outcome and reopen exactly the
reuse this rule closes. The Runtime generally cannot verify a no-swap promise
either, so requiring one would move the guarantee outside what the contract can
check.

- An outcome whose attempt reports neither execution-identity variant, reports
  both, or omits its serving capability snapshot identity MUST NOT be
  journal-reusable. Refusing reuse is always safe; guessing is not.
- A deployment that cannot expose an implementation revision at all MAY instead
  guarantee that its capability snapshot identity changes whenever any
  implementation revision that can affect outcome meaning changes, and MUST
  identify that guarantee as a profile. The attempt then reports
  `capabilitySnapshotSubstitute(snapshotIdentity, guaranteeProfile)`. The
  substitute's `snapshotIdentity` MUST equal the separately reported serving
  capability snapshot identity; a mismatch makes the outcome non-reusable. The
  fallback changes the execution-identity variant, never when it is observed;
  its tag, snapshot identity, and guarantee profile all enter the journal key.
- When an attempt reports a capability snapshot identity that differs from the
  run-start pinned one, that is **drift**: the Runtime MUST record it, the
  outcome MUST NOT be reused under the pinned identity, and a deployment MAY
  treat drift as a run-level failure. Addressee resolution still uses the pinned
  identity, because changing it mid-voyage is the non-determinism pinning
  exists to prevent.
- A deployment that wants replay determinism MAY additionally pin the
  implementation revision at run start and refuse to start, or fail the run on
  drift. That is a stricter profile layered on the reporting rule, not an
  alternative to it.
- The tagged execution identity and reported capability snapshot belong in the
  key rather than in structural identity because SCP-0004 places Host
  implementation and capability version in **outcome-reuse policy and the
  journal**. The same Host identity with the same allowlist and granted
  capabilities can still be a different implementation after an upgrade, and
  its earlier outcomes are not reusable.

### Capability reporting

A Runtime reports, for the attached Host and Scheduler: Anchor identifiers,
Host-addressed policy identifiers with schemas, Scheduler-addressed policy
identifiers, the pinned identities — Scheduler registry version, Host
capability snapshot/profile version, and forwarding-allowlist revision — with
the allowlist contents in effect, which per-attempt execution-identity variants
the Host supports, and the guarantee-profile identifier for any
capability-snapshot substitution.

## Alternatives

| Alternative | Benefits | Costs/reason rejected |
|---|---|---|
| **Accepted: Host capability declares its policy identifiers** | Matches how Anchors already work; no grammar change; addressee can change without rewriting source or invalidating artifact hashes; forwarding gate is natural | Reading source alone does not reveal the addressee; needs an explicit collision rule |
| Encode the addressee in the identifier (`@host.x`) | Addressee visible in source; no collisions by construction | Language change while R9 is open; promoting a Host hint to a standard policy renames it and **changes every artifact hash that uses it**; forwarding gate must be added separately |
| Send every policy to both sides | Simplest wiring | `@timeout` would be interpreted twice with no source-visible winner |
| Host silently ignores what it does not know | No new errors | Turns a typo into silent behavior change; contradicts the existing reject-unknown rule |
| Infer the addressee from the target occurrence kind | No declarations | A Scheduler-addressed policy may also target a leaf, so the target kind narrows what a Host policy may target but cannot decide the addressee |
| Resolve declarations live instead of pinning them at run start | No snapshot machinery | A mid-voyage registry change would re-route an identifier for later occurrences or create a double claim partway through; provenance and replay stop being deterministic |
| Keep the status quo | No change | Host-directed How is unwritable; authors hide it inside Anchor arguments, which buries execution intent in data |

## Philosophy and boundary audit

- Structure stays separate from execution policy: a Host-addressed policy never
  directly edits topology.
- The Carousel is unaffected; it neither reads nor forwards policy.
- The Scheduler keeps demand, eligibility, attempts, and cancellation, and its
  attempt lifecycle still wraps every Host invocation.
- The Host gains no power over Goal structure, only over its own invocation.
- Policy non-inheritance, alias laziness, and deduction immutability are
  unchanged; policy erasure keeps exactly the conditional form §8.5 already
  gives it.
- The Frontend and Codebase still depend on no Scheduler or Host registry.
- Portability holds: addressee resolution depends on pinned declarations, not on
  an implementation's internal naming.

## Compatibility and migration

- Previously valid source affected: none.
- Previously invalid source newly accepted: source carrying Host-addressed
  policies, once a Host advertises them.
- Stored artifact/hash impact: none. Policies were already part of the authored
  hash and their spelling does not change.
- Diagnostic impact: `PolicyConflict` gains the double-claim case in the
  `policy` phase; `UnsupportedPolicyTarget` gains Host-addressed policies
  attached to non-leaf occurrences; `PolicyDenied` is new; `UnknownPolicy`
  narrows to identifiers claimed by neither declaration. No diagnostic moves
  into the `validation` phase.
- Migration strategy: Hosts that already accept out-of-band execution hints
  declare them as policies and stop smuggling them through Anchor arguments.
- Version/profile requirement: consumers advertise support for the Host policy
  channel.

## Grammar and conformance impact

- `README.md`: define the two addressees and the resolution table.
- ANTLR/EBNF: no production changes; synchronized comments only.
- valid cases / invalid syntax cases: none.
- invalid semantic cases: none that are source-only. Addressee resolution
  depends on the attached Scheduler registry and Host capability, so the
  corpus cannot express it as a `.vyg` fixture.
- runtime cases, stated with test doubles:
  1. a Host-addressed policy appears in `hostPolicies[]` in source order and the
     Scheduler never interprets it;
  2. a Scheduler-addressed policy on the same leaf stays out of
     `hostPolicies[]`, and the Host-facing evaluation request carries no
     `directPolicies[]` at all — inspecting what crossed the boundary shows the
     Scheduler-addressed entry is absent, not merely unread;
  3. a policy claimed by both pinned declarations is `PolicyConflict` in the
     `policy` phase at disclosure; a `check` pass with profiles attached reports
     it earlier as a non-authoritative preflight diagnostic and the
     authoritative phase does not change;
  4. a policy claimed by neither is `UnknownPolicy`, unchanged;
  5. a Host-addressed identifier attached to a Goal, serial, parallel,
     resolving-map or `goal-arrow-stage` occurrence is
     `UnsupportedPolicyTarget`, and a composite's policy never reaches a
     descendant leaf's `hostPolicies[]`;
  6. a registry or capability change mid-run does not alter the addressee of a
     later-disclosed occurrence, and provenance records the pinned versions; a
     run whose declarations cannot be pinned refuses to start before any
     occurrence is disclosed;
  7. an allowlist change mid-run alters no forwarding decision in that run: the
     pinned revision governs throughout, and provenance records it;
  8. the Host-policy context exposes read-only attempt identity and the
     cancellation signal and exposes no retry/settle/extend operation at all;
     a Host outcome is the only way that invocation changes Runtime attempt
     state;
  9. cancellation of an attempt carrying a delegating Host-addressed policy is
     forwarded to the worker and traced; a late `Succeeded` is recorded
     alongside the cancellation request and the Scheduler decides its meaning;
  10. conditional policy erasure: for corresponding occurrences that select the
      same artifact with the same arguments and required routed values, erasing
      policy metadata leaves the structural reduction result unchanged;
  11. a withheld policy under a deployment allowlist is refused in the `policy`
      phase with `PolicyDenied` and traced;
  12. two attempts differing only in Host-addressed policies produce different
      Outcome Journal keys, and so do two attempts differing only in the
      reported execution-identity variant/value, only in the reported capability
      snapshot/profile version, or only in the pinned allowlist revision — an
      `implementationRevision(x)` key never collides with a
      `capabilitySnapshotSubstitute(x, profile)` key even when `x` has identical
      bytes;
  13. a Host that swaps its implementation mid-run reports the new revision with
      the affected attempt's outcome, that outcome is keyed by the reported
      revision rather than the run-start value; an outcome reporting neither or
      both execution-identity variants is not journal-reusable; a declared
      substitute variant is reusable under its own tagged key and guarantee
      profile only when its snapshot identity matches the separately reported
      serving snapshot; and a reported capability snapshot identity differing
      from the pinned one is recorded as drift without changing addressee
      resolution.

## Reference experiment

The POC ships no concrete interpreters and rejects every policy, so it can
implement this contract without inventing policy semantics: the Host interface
gains a capability declaration, the Dispatcher builds a Host-facing request
carrying `hostPolicies[]` and no `directPolicies[]`, and policy binding splits
the ordered list into two source-order subsequences against pinned declarations.
Scenarios 1–13 above become Runtime tests with the existing Scheduler and Host
doubles.

## Unresolved questions

- Owner decision R9 — the policy observation model and the closed action set —
  stays open. This proposal constrains it: the Scheduler-side action set is the
  set of control verbs the Scheduler already owns (demand, withhold, reattempt,
  cancel, withdraw, reconfigure prefetch, settle scope), and anything outside
  it is either Host-addressed or not a policy.
- Whether any Scheduler-addressed policy becomes standardized across Runtimes
  is a separate question; this proposal only routes identifiers.
- Whether a Host may observe Scheduler-addressed policies for logging is left
  closed for now: it may not.
- `PolicyDenied` is confirmed as a new stable kind for the deployment
  allowlist (owner decision 2026-09-20).
- How a deployment pins a Host capability snapshot when the Host is a live
  external process — a declared profile identity, a signed manifest, or a
  handshake digest — is a Runtime-profile question. The requirement here is only
  that some recorded identity exists and does not change mid-run.

## Owner decision record

- Status: Accepted on 2026-09-20. The core, every item previously submitted for
  confirmation, and `PolicyDenied` as a new stable diagnostic kind are all
  decided.
- Decision requested on: 2026-09-18
- Options presented: Host capability declaration versus encoding the addressee
  in the identifier
- Owner response: adopt the Host capability declaration; a policy claimed by
  both sides is a compile/lint error rather than a precedence rule
- Decision date: 2026-09-18
- Accepted core: two addressees, capability-declared Host policies, the How
  travelling with the evaluation request, and double claim as an error
- Submitted for confirmation: the diagnostic kind and phase for double claim,
  argument-schema validation, the deployment allowlist, provenance and Outcome
  Journal key requirements, and the runtime case list
- Review round 1 (2026-09-18, language PR #8): the owner raised six P1 and two
  P2 findings against this draft. All eight are addressed in this revision —
  `Scheduler-addressed` replaces `Vessel-addressed` and the addressee test is
  restated in eligibility/attempt-lifecycle/scope-outcome terms; the motivation
  is corrected to acknowledge the existing `directPolicies[]` envelope and to
  state the gap as authority plus filtered projection; declarations are pinned
  at run start and resolved at disclosure; the authoritative phase for double
  claim and schema mismatch is `policy`, with `check`/lint demoted to a
  non-authoritative preflight; Host-addressed policies are restricted to
  `{function-leaf, anchor}` with `UnsupportedPolicyTarget` otherwise and no
  inheritance to descendants; cancellation is restated as cooperative; policy
  erasure takes the conditional form of RUNTIME_ORCHESTRATION_PLAN §8.5; and
  the allowlist refusal gets the distinct kind `PolicyDenied`.
- Review round 2 (2026-09-19, language PR #8): two further P1 and two P2
  findings, all addressed. The projection is no longer only a derived field:
  the Runtime-internal envelope keeps `directPolicies[]`, and the Host-facing
  evaluation request the Dispatcher builds carries `hostPolicies[]` and no
  `directPolicies[]`, so invisibility is implementable rather than asserted.
  Pinning loses its permissive branch — a run whose declarations cannot be
  pinned MUST refuse to start, as a profile-negotiation failure. The Host may
  read its own invocation's attempt identity and cancellation context, since the
  Dispatcher already passes them and `Host.Control.cancel(attemptId)` depends on
  them; what is forbidden is authority over the attempt lifecycle. The Outcome
  Journal key gains the pinned Host capability snapshot/profile identity and
  version, per SCP-0004's placement of Host implementation version in
  outcome-reuse policy rather than structural identity.
- Review round 3 (2026-09-19, language PR #8): one P1 and one P2, both
  addressed. The forwarding allowlist is now pinned at run start like the other
  two declarations, recorded in provenance and in the journal's
  granted-capability material, and a runtime case fixes that a mid-run change
  alters nothing in that run; live revocation is named as out of scope with the
  questions a future proposal would have to answer, since cancelling the run is
  the defined way to stop in-flight Host effects today. Attempt-lifecycle
  authority is withheld by non-exposure rather than by an undefined refusal: the
  Host-policy context has read-only attempt identity and cancellation signal and
  simply has no retry/settle/extend operation, so there is no surface, phase or
  outcome left to specify.
- Review round 4 (2026-09-19, language PR #8): one P1 and one P2, both
  addressed. The Outcome Journal key gains the pinned Host implementation
  revision/digest as a separate element, because a binary or adapter can be
  upgraded while the capability manifest, allowlist and granted capabilities
  stay identical; a deployment that cannot expose one must instead guarantee
  that its capability snapshot identity changes with any outcome-affecting
  implementation revision, and say so. The motivation no longer claims "not a
  new field on the request": the Host-facing request schema does change — this
  proposal adds no new port and no new policy payload, but `directPolicies[]`
  leaves that schema and `hostPolicies[]` enters it.
- Review round 5 (2026-09-19, language PR #8): one P1, addressed. Calling the
  implementation revision "pinned" left its observation point undefined, so a
  mid-voyage binary swap would have been keyed under the run-start value. The
  two uses are now separated: addressee resolution keeps the run-start pinned
  identities, while outcome reuse is keyed by the implementation revision and
  capability snapshot identity **the serving attempt reports**, since only the
  attempt knows what ran and a Runtime cannot verify a no-swap promise. An
  outcome with no reported revision is not reusable, a reported capability
  identity differing from the pinned one is recorded as drift, and a deployment
  wanting replay determinism may additionally pin at run start as a stricter
  profile.
- Review round 6 (2026-09-20, language PR #8): one P1, addressed. The
  implementation-revision fallback no longer contradicts the no-revision reuse
  rule or the minimum journal key. Per-attempt execution identity is a tagged
  union of `implementationRevision` and `capabilitySnapshotSubstitute`; the tag
  and value enter the key, the substitute carries its declared guarantee
  profile and must name the separately reported serving snapshot, and only an
  outcome with exactly one variant plus its serving capability snapshot is
  journal-reusable. Runtime cases cover missing, double, mismatched substitute,
  and cross-variant collision behavior.

## Final rationale

A policy says how something should happen. Some of those sentences are about
whether and when work becomes eligible and how its attempts end, and some are
about what happens inside one grounded leaf invocation. The first set belongs to
the Scheduler; the second belongs to the Host, and the language has never said
so. The language already treats Anchor names as the Host's to resolve;
policies meant for the Host are the same kind of name and belong in the same
request. Naming the addressee explicitly keeps the Scheduler from interpreting
sentences that were never addressed to it, and keeps the Host from acquiring
any say over structure.

## Ratification note (2026-09-20)

Accepted together with SCP-0007–SCP-0010. Two cross-proposal seams were closed
in that pass:

- the non-leaf enumeration for `UnsupportedPolicyTarget` now names
  `goal-arrow-stage` and states the rule as "any non-leaf occurrence kind", so
  a later kind cannot silently become a legal Host-policy target;
- `PolicyDenied` is a decided kind, recorded in the error-ownership table in
  `README.md` and in `implementation/RUNTIME_CONTRACT.md` §3.

The runtime cases are recorded in `conformance/POLICY.md`.
