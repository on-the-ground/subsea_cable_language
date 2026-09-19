# Agent Instructions

Agents are the first users of this repository. Treat the repository Markdown,
grammar, and conformance files as the canonical, directly consumable knowledge
base. A documentation website may index, arrange, or render these sources, but
must not move the authoritative content into a website-only format, introduce a
second editable copy, or make understanding the language depend on a site build.

Before implementing a Subsea Cable consumer/runtime, read these files in order:

1. `README.md` — normative structural semantics.
2. `METAPHORS.md` — the precise Cable, Sea, Carousel, deduction, and Touchdown
   model.
3. `SubseaCable.g4` and `SubseaCable.ebnf` — executable and neutral grammar.
4. `conformance/README.md` — preprocessing and conformance requirements.
5. `implementation/README.md` — phased execution strategy and completion gates.
6. `implementation/RUNTIME_CONTRACT.md` — component boundaries and mandatory
   runtime behavior.
7. `implementation/CAROUSEL_ENGINE_PLAN.md` — the owner-directed deduction
   engine objective, Touchdown prefetch plan, and unresolved contract decisions.
8. `implementation/MIGRATION_PLAYBOOK.md` — how to migrate a real project and
   discover policies from evidence.
9. `proposals/0004-voyage-plans-and-touchdown-cable-artifacts.md` — the
   Voyage Plan input, Fully Touchdown Cable output, provenance, and incremental
   reuse contract.
10. `proposals/0005-guarded-conditional-recursion.md` — selective branching and
    guarded recursion.
11. `proposals/0006-live-vessel-host-cooperation.md` — the live, bidirectional
    Vessel–Host voyage lifecycle and the deployment-neutral compiler boundary.
12. `proposals/0011-policy-addressee-and-host-channel.md` — who each `@policy`
    is addressed to and how a Host-addressed one reaches the Host.

Every proposal in `proposals/` numbered `0001`–`0011` is Accepted. A merged
proposal is a decision; the decision is in force because the canonical documents
and `conformance/` carry it. When they disagree, the canonical documents and the
conformance corpus are what an implementation follows, and the disagreement is a
defect to report.

Use **Subsea Cable** as the language name, **`__C`** only as its visual short
mark, `.vyg` for source files, and `subsea-cable` for portable slugs/language
IDs. Never call the language “SubC” or use `__C` as a code identifier.

Build the Host/Runtime in a separate repository. This language repository does
not accept production Host, Carousel, Scheduler, adapter, or complete Runtime
implementation code. Changes here are limited to language specification,
grammar, conformance, philosophy, governance, and design proposals.

Do not begin with policy design. Preserve `@policy` annotations as opaque,
ordered occurrence metadata and reject unsupported policies explicitly. Add
concrete policy semantics only through the discovery process in the migration
playbook.

Keep these terms separate:

- **Voyage Plan**: the authored `.vyg` source input. It describes dependency
  and routing precedence; it is not the realized Cable or an execution trace.
- **Vessel / Consumer Runtime**: the whole runtime metaphor—frontend, validator,
  codebase, Carousel, Outcome & Value Store, Scheduler port, and Host port taken
  together. Vessel is not a second deduction component. It is the whole an
  operator or agent addresses; a component or interface is never named Vessel.
- **Reduction**: the structural rule encoded by a resolved Goal artifact.
- **Deduction**: demand-time alias resolution plus application and commit of one
  occurrence's reduction rule.
- **Carousel**: lazy deduction, structural reduction, occurrences, routing,
  lineages, the frontier, and Touchdown publication.
- **Fully Touchdown Cable**: the canonical ordered list of grounded leaf
  content hashes produced by a terminated voyage. Occurrence identity,
  lineages, positions, and reverse lookup live in provenance, not item hashes.
- **Outcome & Value Store**: Runtime-owned attempt outcomes, scope outputs, and
  routed values; Carousel may only read resolved values through a narrow port.
- **Host**: primitive semantics, arrow-function leaf evaluation, and `$Anchor`
  resolution/invocation.
- **Scheduler**: execution eligibility, outcomes, and `@policy` only.
- **Occurrence kinds**: `Goal`, `serial`, `parallel`, `resolving-map`,
  `goal-arrow-stage`, `function-leaf`, `anchor`. An inline Goal-arrow stage is a
  real deducible occurrence: it waits for its routed input, binds it, commits a
  record without a requested name or hash, adds no lineage segment, and still
  takes one child-ordinal segment.
- **Policy addressee**: a `@policy` is Scheduler-addressed when it changes
  eligibility, the attempt lifecycle, or a scope's outcome, and Host-addressed
  when it changes only what happens inside one grounded leaf invocation. Only
  `hostPolicies[]` crosses to the Host; `directPolicies[]` never does.

A general-purpose Vessel is not a compiler that emits Host code or a prospective
Cable and then disappears. It remains the logical owner of the voyage while
Carousel publishes Touchdowns, Scheduler dispatches eligible instances, Host
returns outcomes, and routed values enable later deductions. This may all occur
inside one process or library; the rule fixes lifecycle ownership, not process
topology. A generated deployment may advertise general Vessel conformance only
when it embeds, links, or communicates with the same live feedback loop.

Never deduce outside a voyage. A compiler or static-preparation pass may
validate, normalize, cache prepared artifacts, or generate bindings, but it
keeps every unqualified Goal reference symbolic and commits no deduction record.
An artifact captures the value closure it references by name; a structure-valued
lookup map is captured by structure, so the Goal names inside it stay symbolic.

Never resolve an unqualified Goal reference to a hash merely because its parent
was parsed, stored, or deduced. It remains a symbolic `Name/Arity` occurrence
until that occurrence is demanded. Deduction atomically records the selected
full hash and resulting structure; later alias changes affect only undeduced
occurrences.

Never edit an earlier deduction ledger to represent reuse. An incremental
voyage commits new occurrence records and may refer to prior immutable segments
with `reusedFrom`. Structural reuse never implies Host outcome or effect reuse.

Never reject a guarded recursive definition merely because its definition graph
is cyclic. A conditional branch selects one structure, and every selected
recursive step creates a fresh child occurrence so the realized Cable remains a
DAG. Speculative replenishment may expose a selected child but never crosses any
committed conditional branch edge; crossing requires explicit Scheduler demand
whether or not local analysis classifies the edge as recursive. Unguarded or
exitless definition cycles, and explicitly demanded late ancestor re-entry with
no intervening conditional selection, remain `CycleDetected`. Speculation never
raises that diagnostic itself; it abandons the path and leaves the call to the
later explicit demand.

Never hide an evaluation dependency inside an argument or other value
expression. Outside a function-arrow leaf, `Goal(...)` and `$anchor(...)` must
be direct structural occurrences; nested forms are `InvalidStructuralContext`.
Primitive expressions such as `B[x + 1]` remain valid because they create no
occurrence or effect.

Never hide existing orchestration behind one large Anchor merely to pass an
original test suite. Move dependency structure into Subsea, keep only genuine
leaf implementation behind `$`, and record every discovered semantic gap.

When the specification, grammar, and conformance corpus disagree, stop that
implementation path, record the discrepancy, and repair or escalate the
language contract. Never choose one behavior silently in the reference runtime.

When an iteration exposes a design issue, do not absorb a convenient answer into
code, tests, or documentation. Freeze the affected path, create a proposed ADR
with reproduction evidence, affected invariants, viable alternatives, a
recommendation, and compatibility impact, then explicitly request the owner's
design decision. Keep that ADR in the external implementation repository and
open a Subsea Cable Proposal here when the issue is language-level. Continue
only unrelated work. The owner must decide any change
to source syntax, structural semantics, identity, layer ownership, error phase,
policy targeting/composition, or the Host/Carousel/Scheduler boundary.

Merging a Draft or Discussion SCP records design history only. An approving
owner decision authorizes integration but does not make the proposal effective.
Treat new behavior as Subsea Cable semantics only after one activation pull
request changes the SCP to Accepted together with every affected canonical and
conformance projection and is squash-merged to `main`. One activation pull
request may activate multiple SCPs. An existing Discussion SCP that mentions an
accepted core remains non-effective until its contract is completed or its
pending normative parts are split into a follow-up proposal and the accepted
scope is activated.

Every completed phase must satisfy its gate in `implementation/README.md` and
leave reproducible tests or evidence. Implementation convenience is not language
semantics.
