# SCP-0014 — Laid Cable Channel Semantics and Goal Output Multiplicity

- Status: Draft
- Author(s): on-the-ground owner with Codex
- Created: 2026-09-26
- Updated: 2026-09-26
- Requires owner decision: yes
- External implementation ADRs: —
- Evidence repositories/revisions: design discussion; implementation evidence pending
- Activation pull request: —
- Effective language revision: —
- Supersedes: on activation, every conflicting clause in prior SCPs and
  canonical projections; exact clause map pending compatibility audit
- Superseded by: —

## Summary

This draft records the owner decisions reached while testing Subsea Cable's
model against a streaming Eratosthenes example.

A Goal is not a synchronous function and Subsea does not define a function
stack, generator implementation, `yield`, lazy-list value, or first-class
channel value. A Vessel **lays** a Goal target as a live Cable. Values enter the
Cable from the left, every Goal connection is implemented as an implicit
channel-equivalent edge, and Values may be consumed at the right or connected
to another Goal or Host Anchor.

One input travels through the laid Cable as one serial result segment. Values
within that segment may flow immediately and trigger asynchronous downstream
work, but the next input does not begin until the current segment's
`EndOfResult` has propagated through the complete Cable. Consequently
`EndOfResult` requires no portable identifier. `EndOfStream` is distinct: it is
produced only after `decommision(cable)` and complete drainage, and it causes
the connected pipeline to stand down.

When a `/N` Goal emits several Values, the Value payload and its FIFO emission
position are different things. The k-th Value carries Runtime/provenance
metadata `emissionOrdinal = k`; that metadata is not a Subsea value. Any
downstream occurrence caused by it receives a tagged `Emission(k)` position
segment, distinct from the tagged `Authored(k)` segments assigned by authored
reduction-result order.

Goal signatures gain an output multiplicity of exactly `0`, `1`, or `N`.
Subsea declares and connects these signatures; the Host implementation produces
the actual outputs. In particular, a WASM Host may implement `/N` by using WASM
continuations or stack switching without introducing generator mechanics into
the Subsea language.

This file is a design record only. None of these rules is effective language
semantics until an activation pull request synchronizes every canonical,
grammar, compatibility, migration, and conformance projection and is merged.

## Directional precedence and superseding rule

This proposal is an intentional language-direction replacement, not an
additive compatibility profile constrained by the current function-like,
single-result, or input-bearing Root model.

For design review and subsequent integration work, every owner-decided rule in
this proposal has **directional precedence** over conflicting language designs,
accepted SCP text, canonical prose, grammar commentary, implementation plans,
and conformance assumptions that predate it. A discovered conflict is required
superseding work; it is not a reason to omit, weaken, reinterpret, or refuse to
project the new rule. In particular, an implementation or documentation agent
must not answer that a decided rule cannot be reflected merely because the
current contract says otherwise.

This precedence has a deliberately narrow governance meaning:

- it fixes the direction this proposal and its activation work must follow;
- it requires the compatibility audit to identify and replace every conflicting
  prior clause explicitly;
- it forbids silently preserving an old behavior inside an apparently updated
  projection;
- it does **not** make this Draft effective semantics before activation.

Until the activation pull request merges, authoritative `main` continues to
describe the effective language for conformance claims. The activation pull
request must change this proposal to Accepted while atomically synchronizing or
superseding every affected canonical, grammar, compatibility, migration, and
conformance projection. After that merge, the conflicting earlier rules have
no residual authority over the activated scope.

This precedence governs review and activation work. An implementation claiming
conformance to the current unactivated `main` must still obey `AGENTS.md`: if an
Accepted SCP and a canonical projection disagree, it stops the affected path
and reports the repository defect. It must not implement this Draft early or
silently choose between conflicting contracts.

## Decision digest

```text
lay(GoalTarget)                      -> live Cable
value -> cable                       -> send one input
cable -> Goal                        -> connect output Values to a Goal
cable -> $Anchor                     -> Vessel-managed per-Value Anchor trigger
decommision(cable)                   -> stop admission and begin final drainage

Goal signature                       Name / inputArity / outputMultiplicity
outputMultiplicity                   0 | 1 | N

per-input terminal                   EndOfResult(outcome), with no ID
whole-Cable terminal                 EndOfStream
authored position segment            Authored(k)
/N emission position segment         Emission(k), k is zero-based FIFO order
input provenance prefix              Input(k), k is accepted-input order
```

The following explored models are **not** part of this design:

- no `ResultScope` object;
- no `resultScopeId`;
- no channel-of-channels portable model;
- no Subsea `yield` operation;
- no lazy-list or Stream value in the Subsea value domain;
- no partial application or currying;
- no `$Anchor(cable)` in the ordinary Anchor contract;
- no default concurrent processing of separate Cable inputs;
- no activated `@flatten`, `concat`, `interleave`, or cross-input `merge`
  semantics in this core.

## Motivation

The previous Root/application model made an expression such as
`Eratosthenes[50]` carry too many unrelated meanings: Root selection, argument
binding, deferred occurrence construction, demand, and eventual result. It also
presumed a single function-like output even though the Vessel–Host lifecycle is
asynchronous and a Host implementation may naturally produce zero, one, or
many outputs.

The desired operational shape is instead:

```text
cable = lay(Eratosthenes)
50 -> cable

for each Value from cable:
    consume it

decommision(cable)
```

Within Voyage structure, consumption remains declarative:

```text
cable -> $printLn
```

The Vessel, rather than authored loop syntax, turns each Value into an Anchor
evaluation under Scheduler control.

## 1. Layer ownership

### 1.1 Subsea Cable owns declarations and connections

Subsea owns:

- the Goal DAG;
- full Goal input signatures;
- output multiplicity declarations;
- explicit routing and structural dependency;
- Goal-to-Goal and Cable-to-sink connections;
- opaque ordered policy metadata;
- the distinction between `EndOfResult` and `EndOfStream`.

Subsea does not specify the implementation technique by which a Host produces
multiple values. It adds no generator stack, coroutine body, `yield`, or lazy
list to Voyage syntax.

### 1.2 Host owns implementation and output production

The Host owns the concrete implementation of grounded leaves and Anchors. It
may use native async facilities, threads, callbacks, WASM continuations, stack
switching, or another implementation technique.

For `/N`, the Host-facing protocol can publish multiple Values for the current
input and must explicitly signal `EndOfResult`. This protocol obligation does
not expose the Host's implementation mechanism in the Voyage Plan.

### 1.3 Vessel owns the live channel lifecycle

The Vessel owns:

- laying the live Cable;
- input admission and buffering;
- channel-equivalent blocking and backpressure;
- dispatch through the Scheduler and Host port;
- conversion of Host outcomes into Value and terminal frames;
- per-input serialization across the complete laid Cable;
- propagation of `EndOfResult`;
- final drainage and `EndOfStream`;
- provenance and the Fully Touchdown Cable.

## 2. Laying and decommissioning a Cable

### 2.1 `lay`

The conceptual operation:

```text
cable = lay(Eratosthenes)
```

lays a live Cable for the selected Goal target. Laying does not itself supply a
Goal input. The input-bearing Root form `Eratosthenes[50]` is not the execution
entry model of this design; input is sent separately to the laid Cable.

A laid Cable may accept multiple inputs over its lifetime:

```text
50  -> cable
100 -> cable
```

The exact placement of `lay` in portable source syntax versus the outward
Vessel API remains a grammar-surface task. Its lifecycle meaning is fixed here.

`lay` creates the live Cable but does not start an evaluation segment and does
not pin the three run-start declarations. Each attempted input send performs
segment admission in this order:

```text
input send
  -> pin Scheduler registry identity
  -> pin Host capability snapshot/profile identity
  -> pin forwarding allowlist revision
  -> admit and create the input segment
  -> later disclose/deduce work for that segment
```

If any declaration cannot be pinned, the send returns
`ProfileNegotiationFailed`. The input is not admitted, no segment or occurrence
is created, and no `EndOfResult` is emitted for it. A successfully admitted
later segment may wait behind the active segment, but its three pins are already
immutable while it waits; no alias resolution, deduction, Touchdown, or Host
work for it may begin early.

Pins are per input segment, not per laid Cable. Successive segments on the same
long-lived Cable may therefore use different declaration identities. Cable
provenance records the pins associated with each admitted segment, and a later
registry or allowlist change never rewrites an earlier segment's pins.

Neither `lay` nor segment admission pins a codebase revision or resolves the
laid Root Goal to an artifact. An unqualified laid target remains symbolic
`Name/inputArity`. When a segment becomes active, its Root occurrence resolves
that alias only when the occurrence is actually demanded; every descendant
unqualified occurrence follows the same existing demand-time rule.

Consequently successive segments on one Cable may execute different artifacts,
and a segment admitted into the input queue may observe an alias revision newer
than the one current at admission. Alias observations are recorded in that
segment's immutable deduction provenance. Rebinding never changes an already
deduced occurrence, but no earlier segment, Cable creation event, or queued
input freezes an undeduced occurrence for a later segment.

There is no one-shot `evaluate(GoalTarget(goalRef, arguments))` operation and no
equivalent input-bearing Goal entry under another name. An operator or debugger
that targets an arbitrary Goal must use the same lifecycle as every other
client:

```text
cable = lay(goalRef)
arguments -> cable
decommision(cable)
```

The resulting Cable handle is the observation and control handle. Debugging
does not create a second evaluation model.

### 2.2 `decommision`

The owner-selected lifecycle term and spelling is:

```text
decommision(cable)
```

After decommission begins:

- the Cable accepts no new input;
- already accepted inputs remain ordered and are drained;
- the active input segment and every downstream operation it caused are allowed
  to reach a terminal outcome, subject to cancellation and policy;
- the Vessel emits `EndOfStream` only after complete drainage.

If the Cable is never decommissioned, it remains live and no absence of Values
is interpreted as termination.

## 3. Implicit channel contract

Every Goal connection is logically a channel-equivalent edge. `chan` is not a
Subsea value or required source keyword.

The portable behavioral contract is:

- FIFO transmission for Values produced on the active connection;
- a `/N` Value's zero-based FIFO position is control/provenance metadata, not
  part of its payload and not visible as a Voyage value;
- receiving from an empty live edge waits;
- sending to a full buffer waits;
- capacity `0` has rendezvous behavior;
- silence is not termination;
- only the explicit terminal protocol establishes completion;
- buffer capacity and concrete physical transport remain Runtime/profile
  concerns rather than Voyage syntax or `@policy`.

The implementation may use Go channels, queues, continuations, callbacks, or
another mechanism, but observable behavior must satisfy the portable contract.

Channel capacity is selected by Vessel configuration, for example
`vessel.conf`. Every Runtime profile defines a default used when the operator
does not configure one; capacity `0` remains a valid rendezvous setting. The
exact configuration key, numeric default, and reload behavior are profile
details, not language syntax.

Channel capacity does not replace SCP-0001's Touchdown prefetch window:

- the prefetch window limits how far structural deduction and Touchdown
  publication may advance;
- channel capacity limits transmission of Values after an invocation is
  already running;
- both limits apply at their own boundaries and neither overrides the other.

When a send waits because the channel is full, the Host invocation has already
started and remains an active attempt. The Scheduler must not reclassify it as
an occurrence that was never eligible or never dispatched. Attempt accounting,
cancellation, timeout, and evidence therefore continue across the blocked send.

## 4. One active input segment per Cable

Inputs are admitted in FIFO order. Exactly one input segment is active through
the laid Cable at a time.

```text
Input(50)
  Value(...)
  Value(...)
  EndOfResult(...)

Input(100)
  Value(...)
  Value(...)
  EndOfResult(...)
```

The second input does not begin merely because the first Goal has accepted or
locally processed the first input. It begins only after the first input's
`EndOfResult` has propagated through the complete connected Cable and all work
caused by that input has drained.

This prohibition includes structural work. While an earlier input segment is
active, the Vessel may queue a later accepted input but must not disclose,
deduce, prefetch across, resolve aliases for, or dispatch Host work for that
later input. SCP-0001 Touchdown prefetch remains available inside the active
segment only.

Within one active segment:

- Values may flow downstream immediately;
- independent DAG branches may execute asynchronously;
- each Value connected to a Goal or Anchor may trigger downstream work;
- the downstream edge emits its `EndOfResult` only after all work caused by the
  current segment has terminated.

`{...}` parallel composition is one composite Goal, represented by one
`parallel` occurrence. Its branches do not expose branch-local `EndOfResult`
frames on the composite's outward edge.
Branch terminals remain internal scope state; after the composite's work has
terminated and drained, the composite emits exactly one `EndOfResult` carrying
its single Scheduler-determined scope outcome. Arrival order never combines or
selects that outcome.

Because separate input segments never overlap, the portable `EndOfResult`
frame needs no ID. The Vessel may retain internal correlation and provenance;
those implementation records do not become a `resultScopeId` or portable frame
field.

Runtime state has three isolation layers:

| Layer | State |
|---|---|
| input segment | declaration pins, occurrence/deduction namespace, attempts, Outcome & Value Store, routed Values, and one `EndOfResult` |
| laid Cable | input queue, channel buffers, channel-capacity selection, lifecycle/decommission state, and aggregation of immutable segment provenance into the final Cable result |
| shared Runtime | Codebase/alias index, append-only ledger backend and indexes, and an activated Goal-step memo or separately authorized Outcome Journal |

The Outcome & Value Store is always segment-private. An attempt outcome,
satisfied output, or routed Value from one segment must never satisfy a value
barrier, binding, or occurrence in another segment. A shared ledger backend does
not merge namespaces: every record remains owned by its segment, and reuse may
only refer to an earlier immutable record through the separately activated memo
contract.

This isolation does not create a portable `ResultScope` object. Every
successfully admitted input receives a zero-based `Input(k)` provenance and
ordering prefix, but that ordinal is not attached to `Value`, `EndOfResult`, or
`EndOfStream` frames. Implementations may use a different internal segment key
in addition to `Input(k)`.

## 5. Terminal protocol

### 5.1 `EndOfResult`

`EndOfResult` marks completion of the currently active input's result segment.
It is a control frame, not a Subsea value, and carries no scope or message ID.

A successful segment may contain no Value. In that case its first result frame
is `EndOfResult(Succeeded)`. This is an ordinary empty result segment, not the
legacy internal `NoOutput` value/state and not a routing failure. A downstream
Goal connected to the edge is invoked zero times for that segment and the
terminal continues through the Cable.

Conceptually it retains the existing outcome distinction:

```text
EndOfResult(Succeeded)
EndOfResult(Failed(diagnostic))
EndOfResult(Cancelled(diagnostic?))
```

The exact wire encoding is a Runtime protocol concern. A normal Value is never
invented to represent failure.

### 5.2 `EndOfStream`

`EndOfStream` is not an alias for `EndOfResult`.

- `EndOfResult` ends one input segment while the Cable remains live.
- `EndOfStream` ends the entire laid Cable.

The Vessel emits `EndOfStream` only after `decommision(cable)`, input admission
has stopped, accepted work has drained, and the final `EndOfResult` has
propagated. Connected consumers stand down when they observe `EndOfStream`.

## 6. Goal signature and identity

The canonical explanatory signature notation becomes:

```text
GoalName / inputArity / outputMultiplicity
```

Output multiplicity is exactly one of:

```text
0   successful evaluation produces exactly zero Values
1   successful evaluation produces exactly one Value
N   successful evaluation produces zero or more Values
```

Examples:

```text
PrintLn/1/0
ReadConfig/1/1
Eratosthenes/1/N
```

Output multiplicity belongs to the Goal signature and structural identity, but
it is not an overload axis.

```text
alias lookup key:       GoalName / inputArity
resolved signature:     GoalName / inputArity / outputMultiplicity
```

One codebase revision cannot publish separate `/0`, `/1`, and `/N` overloads
under the same `GoalName/inputArity` lookup key. The selected artifact declares
the one output multiplicity contract that applies.

A change in output multiplicity changes structural identity and requires the
same compatibility discipline as another structural signature change.

Consequently multiplicity participates in `GoalNodeId` through the resolved
artifact's `StructureHash`:

```text
GoalNodeId = StructureHash(including outputMultiplicity) + inputArity
```

It is not appended as a second lookup key or overload component. Goal-step memo
keys that contain `GoalNodeId` therefore distinguish artifacts whose output
multiplicity differs.

## 7. Host result obligations

### 7.1 `/0`

On success the Host produces no Value. When Host work completes, the Vessel
emits `EndOfResult(Succeeded)`.

If a `/0` Goal has a downstream Value connection, that downstream Goal is
invoked zero times and the successful empty segment propagates normally. The
absence of a Value does not raise `NoOutputNotRoutable`.

A successful `/0` Host operation that attempts to publish a Value violates its
declared signature.

### 7.2 `/1`

On success the Host produces exactly one Value. The Vessel then emits
`EndOfResult(Succeeded)`.

If the implementation cannot produce the Value, it returns a failure or
cancellation outcome; it does not fabricate a sentinel Subsea value. The Vessel
then emits the corresponding non-success `EndOfResult`.

A successful `/1` operation that produces zero Values or more than one Value is
a Host multiplicity protocol violation. Zero Values from `/1` is not reclassified
as `NoOutputNotRoutable`.

### 7.3 `/N`

On success the Host may produce zero or more Values and must explicitly signal
exactly one `EndOfResult` for the current input.

Zero Values followed by `EndOfResult(Succeeded)` is a valid empty `/N` result.
Every connected downstream Goal is invoked zero times, and the terminal
propagates without `NoOutputNotRoutable`.

For one `/N` invocation, the Vessel assigns each successfully accepted Value a
zero-based monotonically increasing `emissionOrdinal` in FIFO send order. For
example, a payload `17` with `emissionOrdinal = 3` is the fourth Value; the
number `3` is not inserted into the payload stream. Every downstream occurrence
caused by that Value carries an `Emission(3)` position segment before the
downstream occurrence's authored position segments.

- a Value after `EndOfResult` is a Host protocol violation;
- a second `EndOfResult` is a Host protocol violation;
- if the Host continuation returns normally without `EndOfResult`, the Vessel
  reports a Host protocol violation rather than silently treating it as empty;
- Host crash or disconnection is converted by the Vessel to a failed terminal;
- if the Host remains live but silent, the input remains pending.

An authored policy such as `@timeout(30)` may bound silence. Silence alone is
never interpreted as `NoOutput`, success, or `EndOfResult`.

## 8. Full input binding; no partial application

Subsea supports no partial application, currying, or implicit completion of a
written Goal argument list.

A Goal receives its complete input tuple at once. A definition such as the
following curried shape has no Subsea meaning:

```text
B = [dep1] -> [dep2] -> ...
```

Inside serial structure, the only contextual routing shorthand is a bare unary
Goal:

```text
[A, B]
```

It is shorthand only for:

```text
[A, [x] -> B[x]]
```

For every Value emitted by A during the active input segment, B receives that
one complete unary input. The shorthand does not generalize to any other arity.

Written arguments are complete and receive no implicit upstream insertion:

```text
[A, B[y]]
```

selects a complete `B/1` input and discards A's Values. It does not partially
apply `B/2` and wait for A to fill a missing argument.

"Discards A's Values" does not erase A from the structure. A is still demanded
and evaluated according to the serial dependency, its effects still happen,
its Touchdowns remain Fully Touchdown Cable members, and its outcome and
provenance remain observable. Only value binding from A into B is absent.

To combine a lexical value with the routed Value, the author writes the binding
explicitly:

```text
[A, [x] -> B[y, x]]
```

There is no stream-to-scalar coercion. If A is `/N`, each Value frame binds `x`
independently and creates one complete downstream evaluation:

```text
A/N emits 10, 20, 30

[A, [x] -> B[y, x]]
  -> B[y, 10]
  -> B[y, 20]
  -> B[y, 30]
```

The same per-Value rule applies when the complete downstream structure contains
a resolving-map selector or a function-leaf argument: each invocation sees one
ordinary Value, not the `/N` stream as a scalar object. An empty `/N` creates no
such invocation. The Runtime never chooses the first Value, implicitly collects
Values, or raises a multiplicity error merely because more than one Value was
emitted.

A source expression that tries to obtain a scalar by nesting a Goal or Anchor
call inside an argument, selector, lookup key, operator operand, or ordinary
value container remains `InvalidStructuralContext`. Collection, first-value
selection, reduction, and similar behavior require an explicit Goal/Host
primitive; they are not implicit routing behavior.

The concrete call-suffix grammar shown in these compatibility examples is
subject to the grammar migration required by the laid-Cable model. The semantic
rules—full tuple binding and the sole bare-unary shorthand—are decided.

## 9. Connecting a live Cable to a sink

### 9.1 Vessel-managed Anchor triggering

The accepted form is:

```text
cable -> $Anchor
```

It means that the Vessel:

- observes each Value emitted by the Cable for the current input;
- creates the corresponding Anchor evaluation with that Value as its complete
  unary input;
- dispatches it under Scheduler admission, policy, and backpressure;
- records each invocation's outcome and provenance;
- does not pass `EndOfResult` or `EndOfStream` as Anchor arguments;
- delays propagation of the input's terminal until all Anchor work caused by
  that input has terminated.

This is declaratively equivalent to an event-driven Host loop over Values, but
the loop is owned by the Vessel so every Anchor invocation remains visible in
the Goal DAG and runtime evidence.

If the sink needs additional input, routing is explicit rather than partially
applied:

```text
cable -> [value] -> $Anchor(prefix, value)
```

### 9.2 Passing the Cable to an Anchor is not the default contract

The following is not accepted by this design:

```text
$Anchor(cable)
```

A live Cable is a Runtime capability, not an ordinary Subsea value. Passing it
through the ordinary Anchor value contract would move receive-loop ownership,
per-Value scheduling, cancellation, retry, and provenance behind one opaque
Host invocation.

A future explicitly designed stream-capability Anchor contract may revisit
that special case. It is not inferred from ordinary Anchor invocation.

## 10. Interaction with Fully Touchdown Cable identity

Separate top-level input segments do not execute concurrently in one laid
Cable. Each successfully admitted input receives `Input(k)`, where `k` is its
zero-based admission ordinal. A rejected send consumes no ordinal. The complete
occurrence position is:

```text
Input(k) / <within-segment tagged position vector>
```

The Fully Touchdown Cable is the concatenation of each segment's ordered items
in increasing `Input(k)` order. `Input(0)` is fully ordered before `Input(1)`,
and so on. This outer order follows admission and `EndOfResult` propagation,
not Host timing.

Within one input segment, the inner occurrence position is a lexicographic
vector of tagged non-negative segments:

```text
Authored(k)   authored reduction-result position
Emission(k)  zero-based FIFO position of a Value from one /N invocation
```

An emitted Value's downstream path contains `Emission(k)` before the authored
segments of the connected downstream structure. Segment kind is part of the
canonical position encoding, so an output payload, an emission position, and an
authored child position cannot be confused. At a common parent, equal segment
kinds compare by numeric `k`; mixed kinds compare `Authored` before `Emission`.
The concrete encoding is profile-versioned but must preserve those tags and
that order. A proper-prefix position precedes its descendants.

This supersedes SCP-0004 and `implementation/RUNTIME_CONTRACT.md` §12 where they
say the ordering vector contains only untagged child ordinals drawn from
authored result order. Content hashes remain unchanged: `Input(k)` and tagged
inner positions live in occurrence/provenance identity and Fully Touchdown Cable
ordering, never in an individual Touchdown content hash. Completion timing,
Host latency, or Scheduler dispatch timing must not reorder the Fully Touchdown
Cable.

This draft does not replace the Fully Touchdown Cable with the user Value
stream. They remain distinct:

- the live Value stream is program data flowing through the right end;
- the Fully Touchdown Cable is the terminated voyage's canonical grounded-leaf
  artifact;
- `EndOfResult` and `EndOfStream` are control frames and are not item hashes.

## 11. Deliberately deferred features

The following are outside this core and acquire no default semantics here:

- `@flatten`;
- `concat`, `interleave`, or merge policies across concurrently active input
  result segments;
- tagged `EndOfResult` frames;
- portable `resultScopeId` or `inputMessageId` fields;
- first-class Stream, Channel, Future, Promise, Handle, or lazy-list values;
- passing a live Cable through Maps, Host value arguments, StructureHash input,
  or memo keys;
- multi-input overlap within one laid Cable;
- event-time watermarks;
- exact buffering policy beyond channel-equivalent blocking;
- retry semantics after a `/N` Host has already published partial Values;
- a special Host contract that consumes a whole live Cable.

These features require separate evidence and owner decisions. Implementations
must not infer them from this draft.

## 12. Compatibility impact

This design changes foundational existing contracts:

- the current input-bearing deferred Root form;
- the assumption that one successful Goal evaluation exports one Value or
  `NoOutput`;
- the Host Port's single-outcome shape;
- serial result routing and satisfaction;
- evaluation instance multiplicity for streamed Host output;
- outward evaluation and result observation surfaces;
- Goal signature identity and alias compatibility;
- conformance fixtures that assume single-result Goal connections.

Activation therefore requires an explicit superseding audit rather than silent
reinterpretation of accepted SCPs or canonical prose.

SCP-0014 supersedes SCP-0010 specifically where SCP-0010 treats absence of a
Goal result on a routed Goal-to-Goal or Cable edge as `NoOutputNotRoutable`.
Under this proposal, declared `/0` and empty `/N` produce successful empty
segments, while missing output from `/1` is a multiplicity protocol violation.
SCP-0010 remains in force for a legacy/internal `NoOutput` used where a scalar
value is explicitly required inside a resolving-map binding or function-leaf
body; those are not empty channel segments.

### 12.1 Conflict with the planned evaluation surface and memo work

The final designs recorded in language issues
[#11](https://github.com/on-the-ground/subsea_cable_language/issues/11) and
[#12](https://github.com/on-the-ground/subsea_cable_language/issues/12), the
tracking order in
[#13](https://github.com/on-the-ground/subsea_cable_language/issues/13), and
Vessel ADRs 0008 and 0009 predate this direction and cannot proceed unchanged.
In particular:

- `evaluate(GoalTarget(goalRef, canonicalArguments))` treats arguments as part
  of an input-bearing entry operation. SCP-0014 removes that operation and its
  input-bearing `GoalTarget` variant rather than preserving either as sugar:
  arbitrary-Goal operation and debugging must use `lay(goalRef)`, separate
  sends, and `decommision`;
- the planned `EvaluationResult` and result-retention surface assumes one Root
  result and must represent Value sequences, per-input `EndOfResult`, final
  `EndOfStream`, and decommissioning;
- ADR 0008's run-start pinning must move from one input-bearing evaluation
  start to per-send segment admission; `lay` itself performs no such pinning;
- ADR 0008 must not turn those per-segment declaration pins into a codebase or
  Root-artifact pin: aliases remain occurrence-local demand-time observations;
- a Goal-step memo key that includes `GoalNodeId` must observe the
  multiplicity-bearing `StructureHash` defined here;
- memo and isolation work must not treat a laid Cable's successive input
  segments as one canonical argument tuple or share live Values between them;
- ADR 0008's former two-layer evaluation/Runtime table must become the
  segment/Cable/Runtime table defined here, with Outcome & Value Store and
  deduction namespaces private to one segment.

The implementation work tracked by #13 must freeze every path that depends on
those assumptions until this proposal decides their replacement or explicit
compatibility projection. A conflict with the already written issues or ADRs is
not authority to preserve their older entry/result model.

One-shot `evaluate(GoalTarget, arguments)` is explicitly **not** a compatibility
projection. Adapters must not recreate it as `lay + send + implicit
decommision`, because that would restore the input-bearing entry model under a
different API spelling.

## 13. Required canonical and conformance projections

An eventual activation must synchronize at least:

- `AGENTS.md` and `FOR_AGENTS.md`: agent-facing precedence, entry, routing,
  signature, terminal, and Host/Vessel boundaries;
- `README.md`: laid Cable model, signature notation, routing, terminals, and
  removal/migration of the input-bearing Root form;
- `METAPHORS.md`: live Cable ends, per-input result segments, decommissioning,
  and whole-Cable termination;
- grammar projections: `lay`, send/connect syntax, `decommision`, signature
  declaration, and any call-suffix migration;
- Runtime/Vessel contracts: Host streaming protocol, channel blocking,
  per-input serialization, terminal propagation, and Anchor sinks;
- Scheduler contract: admission and completion of per-Value downstream work;
- SCP-0004 projection: streaming-triggered evaluation identity without timing-
  based Cable reordering;
- SCP-0010 projection: remove `NoOutputNotRoutable` from routed channel absence,
  retain it only for explicitly scalar resolving-map/function-leaf contexts,
  and classify missing `/1` output as a multiplicity protocol violation;
- compatibility and migration guidance for existing `.vyg` programs;
- `conformance/DEDUCTION.md`, `conformance/cases.tsv`, and concrete fixtures;
- `implementation/CAROUSEL_ENGINE_PLAN.md` and
  `implementation/RUNTIME_ORCHESTRATION_PLAN.md`;
- `ECOSYSTEM.md` supported/unsupported capability tables;
- Vessel ADRs 0007, 0008, and 0009 and the work schedule tracked by language
  issue #13, including ADR 0008's three-layer isolation table;
- agent guidance and examples;
- `proposals/README.md` and the documentation index.

Minimum conformance coverage includes:

1. `/0` successful empty output followed by Vessel `EndOfResult`;
2. `/1` exactly one Value followed by Vessel `EndOfResult`;
3. `/1` zero/multiple successful Values rejected as protocol violations;
4. `/N` empty, singleton, and multiple output;
5. `/N` missing, duplicate, and late `EndOfResult` violations;
6. silence remaining pending until policy intervention;
7. two Cable inputs proving no cross-input overlap;
8. immediate intra-segment downstream Value flow;
9. `cable -> $Anchor` creating one invocation per Value and delaying the
   segment terminal until all such work terminates;
10. `decommision(cable)` rejecting new input, draining accepted work, and
    producing one `EndOfStream`;
11. no partial application and only the bare-unary routing shorthand;
12. output multiplicity participating in structural identity but not alias
    overload selection;
13. `/N` output payload and `Emission(k)` metadata remaining distinct;
14. tagged `Authored(k)` and `Emission(k)` positions producing stable Fully
    Touchdown Cable ordering independent of Host completion timing;
15. queued later input receiving no disclosure, deduction, alias observation,
    prefetch, or Host dispatch before the active segment drains;
16. `[A, B[y]]` preserving A's evaluation, effects, Touchdowns, outcome, and
    provenance while discarding only its routed Values;
17. `/0` and empty `/N` invoking a downstream Goal zero times and propagating
    `EndOfResult(Succeeded)` without `NoOutputNotRoutable`;
18. missing `/1` output reported as a multiplicity protocol violation rather
    than `NoOutputNotRoutable`;
19. TUI, MCP, library, and service adapters exposing arbitrary-Goal debugging
    through `lay(goalRef)` plus separate send/decommission operations and
    exposing no input-bearing `evaluate(GoalTarget, arguments)` equivalent;
20. a parallel composite exposing exactly one outward `EndOfResult`, with all
    branch-local terminals remaining internal to its one composite scope;
21. configured and default channel capacities producing identical result
    semantics while changing only permitted blocking behavior;
22. a full-channel send remaining one active attempt rather than reverting to
    undispatched Scheduler ineligibility;
23. Touchdown prefetch and channel capacity independently enforcing their own
    structural and Value-flow bounds;
24. `lay` creating no evaluation segment and pinning no run-start declaration;
25. every accepted input segment pinning all three declaration identities
    before occurrence disclosure or deduction;
26. pin failure rejecting only that send with `ProfileNegotiationFailed` and
    producing no segment, occurrence, Cable member, or `EndOfResult`;
27. successive segments on one Cable retaining distinct immutable pin sets;
28. rebinding the laid Root alias between two sends causing the later segment
    to select the artifact visible at its own Root-demand time;
29. a queued later segment observing no alias until it becomes active and its
    Root occurrence is demanded;
30. rebinding leaving every already deduced occurrence unchanged;
31. one segment's routed Values and attempt outcomes never satisfying another
    segment's binding, value barrier, or occurrence;
32. a shared ledger backend preserving distinct immutable deduction namespaces
    for successive segments on the same Cable;
33. Cable-level buffers and lifecycle state remaining distinct from both
    segment-private live state and Runtime-shared services;
34. successfully admitted inputs receiving consecutive `Input(k)` provenance
    prefixes while rejected sends consume no ordinal;
35. duplicate inner occurrence paths in different segments remaining distinct
    through their `Input(k)` prefix;
36. the Fully Touchdown Cable concatenating segment-local ordered lists by
    increasing `Input(k)` without adding that ordinal to any control frame or
    Touchdown content hash;
37. a three-Value `/N` source creating three independent complete downstream
    bindings/evaluations in FIFO order;
38. an empty `/N` creating no downstream scalar binding or invocation;
39. no implicit first-value selection, collection, or multiplicity failure when
    routing `/N` Values one frame at a time;
40. nested Goal/Anchor use in a scalar position remaining
    `InvalidStructuralContext` rather than becoming a stream conversion.

## 14. Remaining drafting questions

These questions affect projection details but do not reopen the decisions above:

1. exact source spelling for output multiplicity declarations;
2. exact grammar migration from current `Goal[...]` and `Goal(...)` forms;
3. whether `lay`, send/connect, and `decommision` are portable Voyage syntax,
   outward Vessel operations, or a shared surface with identical semantics;
4. exact Host diagnostic names for multiplicity and terminal violations;
5. retry and cancellation after partial `/N` publication;
6. the concrete `vessel.conf` key, each profile's numeric default, observability,
   and whether configuration reload affects already laid Cables;
7. the precise accepted-input boundary during a race with
   `decommision(cable)`.

## Owner decision record

- Decision requested on: 2026-09-26
- Maintainer/agent recommendation: adopt the laid-Cable, implicit-channel,
  `/0|/1|/N`, ID-less `EndOfResult`, serialized-input, Vessel-managed sink core
  recorded above; defer flattening and stream-capability extensions.
- Owner response: core direction decided through the design discussion captured
  in this draft
- Decision date: 2026-09-26
- Conditions: this Draft records decisions but is not effective semantics;
  activation requires a complete compatibility and superseding audit.

## Activation record

Not yet activated.

- Canonical documents synchronized: —
- Grammar projections synchronized: —
- Diagnostics and examples synchronized: —
- Conformance cases synchronized: —
- Compatibility and migration notes synchronized: —
- Verification commands and results: —
