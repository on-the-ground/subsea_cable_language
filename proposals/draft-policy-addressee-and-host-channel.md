# Draft SCP — Policy addressee and the Host policy channel

- Status: Discussion — addressee model and double-claim handling accepted by the owner; the remaining contract is submitted for confirmation
- Author(s): Claude (agent) for on-the-ground
- Created: 2026-09-18
- Updated: 2026-09-18
- Requires owner decision: yes (Owner decision R9 stays open; this proposal decides only the addressee question)
- External implementation ADRs: pending (subsea_cable_runtime, Host policy channel)
- Evidence repositories/revisions: `on-the-ground/subsea_cable_runtime` POC; owner design review 2026-09-18
- Number: assigned on acceptance
- Supersedes: the implicit assumption that every `@policy` is addressed to the Scheduler
- Superseded by: —

## Summary

A `@policy` is metadata addressed to somebody. Two addressees exist, and the
language never said so:

- **Vessel-addressed** policies change whether, when, and how often the Vessel
  visits an occurrence: retry, timeout, cancellation, completion criteria.
  The Scheduler interprets them. This is the case the documents already assume.
- **Host-addressed** policies change what happens inside one leaf invocation:
  run it in a separate process, use a resource class, batch it. The Host
  interprets them; the Scheduler must not.

The test is mechanical: **if it changes the Vessel's visiting, it is
Vessel-addressed; if it only changes what happens inside one invocation, it is
Host-addressed.**

Host-addressed policies travel with the evaluation request itself — the leaf
envelope carries `(what, args, how)` — so no new port is introduced. A Host
declares the policy identifiers it accepts in its capability description, the
same way it declares Anchors. A policy claimed by both the Scheduler registry
and the Host is a **validation error**, not a precedence question.

## Motivation and reproduction

`@policy` is defined as opaque, ordered occurrence metadata that the Scheduler
interprets, and an unknown policy fails its scope with `UnknownPolicy`. That
leaves no way to write a policy meant for the Host:

```subsea
Patch = [d] -> @separateProcess("worker") $editFiles(d)
```

Today this fails with `UnknownPolicy` in every conforming Runtime, because the
Scheduler is the only interpreter and it cannot know the identifier. The Host —
the only component that could act on it — never sees it: the leaf envelope
carries the leaf identity and arguments but no policy metadata.

The gap is not a missing port. It is a missing field on the request that
already exists, plus a missing rule about who a policy is for.

## Existing invariant under pressure

- `$Anchor` and `@policy` identifiers remain **external symbolic names**; the
  language does not enumerate them (RUNTIME_CONTRACT §2.3).
- The Scheduler owns eligibility, ordering, attempts, outcomes, and `@policy`
  (SCP-0002).
- The Host supplies primitive semantics, function-leaf evaluation, and Anchor
  invocation, and **must not decide Goal topology**.
- Ordered policies are part of the authored artifact identity and are erased in
  the structural projection.
- Unknown policies are rejected rather than ignored.

The first invariant supplies the correction. Anchors are already resolved by
the Host rather than by the language; a Host-addressed policy is the same kind
of name and deserves the same treatment.

## Classification

This is a portable contract and diagnostic question, not a grammar question.
The grammar already admits any policy identifier. What changes is who resolves
it, which envelope carries it, and which diagnostic a conflict produces. It
cannot be a Runtime profile choice: two Runtimes that split policies differently
would run the same source with different effects.

## Proposed specification

### Addressee resolution

A Vessel resolves each occurrence's ordered policies at bind time against two
declarations:

- the **Scheduler policy registry** (Vessel-addressed identifiers), and
- the **Host capability declaration** (Host-addressed identifiers, with arity
  or argument schema, declared alongside Anchors).

Resolution outcomes:

| Claimed by | Result |
|---|---|
| Scheduler only | Vessel-addressed; the Scheduler interprets it; the Host never sees it |
| Host only | Host-addressed; the Scheduler does not interpret it; it rides in the leaf envelope |
| Both | **`PolicyConflict`** — see below |
| Neither | `UnknownPolicy`, unchanged |

### Double claim is an error, not a precedence rule

A policy identifier claimed by both the Scheduler registry and the Host
capability is `PolicyConflict`. Its phase follows the existing dual-phase
pattern used by `KeyNotFound` and `DestructureMismatch`: when the Vessel can
compare both declarations before deduction — which it can whenever the Host is
attached, including `check` and lint — the phase is `validation`; otherwise it
is the `policy` phase at disclosure.

No Runtime may resolve the collision by precedence, by configuration order, or
by silently sending the policy to both. A Host that shadows a Scheduler policy
must be rejected loudly, because the alternative lets a Host capture a future
standard policy name.

### The Host policy channel

The evaluation request carries the How:

```text
evaluate(leaf identity, arguments, host-addressed policies)
```

- Host-addressed policies are delivered in the leaf envelope as **ordered,
  opaque** metadata, preserving their relative source order.
- The Scheduler MUST NOT interpret, reorder, drop, or synthesize them.
- Vessel-addressed policies MUST NOT be delivered to the Host.
- The Host MAY reject a policy it advertised but cannot honor for this call;
  that is a Host-phase failure of the attempt, not `UnknownPolicy`.
- `Host.Cancel` remains binding regardless of any Host-addressed policy. A
  policy that moves work into another process, worker, or machine does not
  relieve the Host of cancellation.

### What a Host-addressed policy may and may not do

- It MAY change the outcome value, duration, resource usage, or failure mode of
  one attempt.
- It MUST NOT create, remove, or reorder occurrences, change demand, alter
  committed structure, or make the Host produce Goal structure.
- It MUST NOT be required for structural validity: erasing every policy still
  yields the same topology and the same reduction results for occurrences
  deduced in both runs.

### Argument validation

A Host declares each policy's arity or argument schema with the identifier.
The Vessel validates Host-addressed policy arguments against that declaration
at the same point it validates Scheduler policy arguments, and reports
`InvalidPolicyArguments` with the existing phase rules. Structural validation
therefore still completes before deduction.

### Deployment allowlist

A deployment MAY restrict which Host-addressed policies a Vessel forwards. A
policy that a Host advertises but the deployment withholds is refused in the
`policy` phase and recorded in the trace; it is never silently dropped. This
matters where agents commit source through an MCP surface: without it, source
text is an unmediated channel into the Host.

### Identity, provenance, and reuse

- Ordered policies of **both** kinds remain part of the authored `ArtifactHash`
  and are erased in `StructureHash`, unchanged.
- A Touchdown content descriptor stays policy-erased (SCP-0004).
- Provenance records the split: which policies were Vessel-addressed, which
  were Host-addressed, the Host identity, and the granted capabilities.
- Consequently a future Outcome Journal MUST key an outcome by at least the
  Touchdown descriptor, the Host identity, the Host-addressed policy digest,
  and the granted capabilities. Two attempts with identical structure but
  different Host-addressed policies — `@dryRun` and a real run — MUST NOT share
  a journal entry.

### Capability reporting

A Vessel reports, for the attached Host and Scheduler: Anchor identifiers,
Host-addressed policy identifiers with schemas, Scheduler-addressed policy
identifiers, and the forwarding allowlist in effect.

## Alternatives

| Alternative | Benefits | Costs/reason rejected |
|---|---|---|
| **Accepted: Host capability declares its policy identifiers** | Matches how Anchors already work; no grammar change; addressee can change without rewriting source or invalidating artifact hashes; forwarding gate is natural | Reading source alone does not reveal the addressee; needs an explicit collision rule |
| Encode the addressee in the identifier (`@host.x`) | Addressee visible in source; no collisions by construction | Language change while R9 is open; promoting a Host hint to a standard policy renames it and **changes every artifact hash that uses it**; forwarding gate must be added separately |
| Send every policy to both sides | Simplest wiring | `@timeout` would be interpreted twice with no source-visible winner |
| Host silently ignores what it does not know | No new errors | Turns a typo into silent behavior change; contradicts the existing reject-unknown rule |
| Infer the addressee from the target occurrence kind | No declarations | Both kinds target leaves; inference cannot separate them |
| Keep the status quo | No change | Host-directed How is unwritable; authors hide it inside Anchor arguments, which buries execution intent in data |

## Philosophy and boundary audit

- Structure stays separate from execution policy: a Host-addressed policy
  cannot touch topology.
- The Carousel is unaffected; it neither reads nor forwards policy.
- The Scheduler keeps demand, eligibility, attempts, and cancellation.
- The Host gains no power over Goal structure, only over its own invocation.
- Policy erasure, alias laziness, and deduction immutability are unchanged.
- Portability holds: addressee resolution depends on declarations, not on an
  implementation's internal naming.

## Compatibility and migration

- Previously valid source affected: none.
- Previously invalid source newly accepted: source carrying Host-addressed
  policies, once a Host advertises them.
- Stored artifact/hash impact: none. Policies were already part of the authored
  hash and their spelling does not change.
- Diagnostic impact: `PolicyConflict` gains the double-claim case and a
  validation phase; `UnknownPolicy` narrows to identifiers claimed by neither.
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
  1. a Host-addressed policy reaches the Host in source order and the Scheduler
     never interprets it;
  2. a Vessel-addressed policy never reaches the Host;
  3. a policy claimed by both is `PolicyConflict`, in the `validation` phase
     when the Host is attached before deduction;
  4. a policy claimed by neither is `UnknownPolicy`, unchanged;
  5. a Host-addressed policy cannot change topology: erasing it yields the same
     structure and the same reduction results;
  6. cancellation reaches an attempt carrying a Host-addressed policy that
     moved the work out of process;
  7. a withheld policy under a deployment allowlist is refused in the `policy`
     phase and traced;
  8. two attempts differing only in Host-addressed policies produce different
     Outcome Journal keys.

## Reference experiment

The POC ships no concrete interpreters and rejects every policy, so it can
implement this contract without inventing policy semantics: the Host interface
gains a capability declaration, `LeafContext` carries the Host-addressed slice,
and policy binding splits the ordered list in two. Scenarios 1–8 above become
Runtime tests with the existing Scheduler and Host doubles.

## Unresolved questions

- Owner decision R9 — the policy observation model and the closed action set —
  stays open. This proposal constrains it: the Vessel-side action set is the
  set of control verbs the Vessel already owns (demand, withhold, reattempt,
  cancel, withdraw, reconfigure prefetch, settle scope), and anything outside
  it is either Host-addressed or not a policy.
- Whether any Scheduler-addressed policy becomes standardized across Runtimes
  is a separate question; this proposal only routes identifiers.
- Whether a Host may observe Vessel-addressed policies for logging is left
  closed for now: it may not.

## Owner decision record

- Decision requested on: 2026-09-18
- Options presented: Host capability declaration versus encoding the addressee
  in the identifier
- Owner response: adopt the Host capability declaration; a policy claimed by
  both sides is a compile/lint error rather than a precedence rule
- Decision date: 2026-09-18
- Accepted core: two addressees, capability-declared Host policies, the How
  travelling with the evaluation request, and double claim as an error
- Submitted for confirmation: the diagnostic kind and dual phase for double
  claim, argument-schema validation, the deployment allowlist, provenance and
  Outcome Journal key requirements, and the runtime case list

## Final rationale

A policy says how something should happen. Some of those sentences are about
how the Vessel walks the graph, and some are about what happens inside one
invocation. The language already treats Anchor names as the Host's to resolve;
policies meant for the Host are the same kind of name and belong in the same
request. Naming the addressee explicitly keeps the Scheduler from interpreting
sentences that were never addressed to it, and keeps the Host from acquiring
any say over structure.
