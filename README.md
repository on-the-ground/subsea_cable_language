# \_\_C Language — Subsea Cable Language


![The Subsea Cable footballfish mascot discovering a cable on the seafloor](assets/branding/subsea-cable-footballfish-scene.png)


> **Programs are not instruction sequences. They are executable intent.**

> **Status:** evolving pre-1.0 language specification. There is no official
> Runtime. Implementations must pin the exact specification revision/profile
> they support.

![The original Subsea Cable concept sketch](assets/subsea-cable-concept.jpg)

The sketch above is the conceptual anchor for the language. The Sea is Goal
Space; a `.vyg` source file is a Voyage Plan; the Vessel is the complete
Consumer Runtime; its Carousel realizes the Cable by demand-driven deductions;
and Touchdown is reached when successive deductions arrive at a Host-provided
concrete leaf. A terminated voyage returns a Fully Touchdown Cable and its Root
outcome. See
[METAPHORS.md](METAPHORS.md) for the precise textual model.

Subsea Cable is not another programming language.

It is a language-agnostic, infrastructure-agnostic representation of programs.

Instead of describing *how* computations should execute, Subsea Cable describes *what* a program is.

A Subsea program is a dependency structure. In this specification,
**Program** names that semantic Goal/dependency program, while **Voyage Plan**
names the authored `.vyg` unit that describes it. Neither term is a synonym for
the realized Cable.

Everything else is an implementation strategy.

The official language name is **Subsea Cable**. **`__C`** is its visual short
mark, `.vyg` is its source-file extension, and `subsea-cable` is the portable
slug and language identifier. `__C` is branding, not a source identifier,
namespace, package, CLI name, or generated symbol. The language is not called
“SubC.”

---

## Why?

Modern languages ask functions to play two completely different roles.

Functions implement computation.

But functions are also forced to describe the dependency structure of an entire program.

As a result, implementation and orchestration become inseparable.

Program structure becomes execution order.

Subsea Cable separates them.

```
Program
    ↓
Goal Structure

Implementation
    ↓
Functions

Execution
    ↓
Schedulers
```

Functions remain implementations.

Schedulers remain execution strategies.

Subsea Cable defines only the structure of the program.

## Repository Scope

This repository is the canonical **language base** for Subsea Cable. It contains
the philosophy, structural semantics, grammar, conformance corpus, proposal
process, and guidance for independent implementers.

It does **not** contain or accept production Host, Carousel, Scheduler, or complete
Runtime implementations. Implementations belong in independently maintained
repositories. Their authors may discover missing concepts while implementing or
migrating real programs; those findings return here as evidence-backed language
proposals and conformance cases, not as implementation code.

```text
This repository                 External repositories
-----------------------------   --------------------------------
philosophy and terminology      Host/Runtime/Scheduler code
language specification          language-specific adapters
ANTLR and EBNF grammar          storage and deployment backends
conformance cases               framework integrations
accepted design proposals       implementation-specific ADRs
```

See [CONTRIBUTING.md](CONTRIBUTING.md), [GOVERNANCE.md](GOVERNANCE.md), and the
[implementer guide](implementation/README.md).

### Agents are the first users

The files in this repository are the language knowledge base, not source
material waiting to be rewritten into a documentation product. They must remain
easy for an agent to discover, read in a deliberate order, cite by path and
heading, and bind directly into its working context.

Any website is therefore a generated projection of these canonical files. It
may add navigation, search, presentation, and interactive explanations, but it
must not become a second editable specification or require agents to scrape or
build the site to understand Subsea Cable.

### Language base map

| Need | Start here |
|---|---|
| Why the language exists | [MANIFESTO.md](MANIFESTO.md), [TheProblem.md](TheProblem.md) |
| Core metaphors and boundaries | [METAPHORS.md](METAPHORS.md) |
| Public naming, mascot, and downloadable assets | [BRAND.md](BRAND.md) |
| Semantics and usage | this `README.md` |
| Executable/neutral grammar | [SubseaCable.g4](SubseaCable.g4), [SubseaCable.ebnf](SubseaCable.ebnf) |
| Validity and diagnostics | [conformance](conformance/README.md) |
| Guarded conditional recursion | [Recursion.md](Recursion.md), [SCP-0005](proposals/0005-guarded-conditional-recursion.md) |
| Guidance for reasoning and contributing agents | [FOR_AGENTS.md](FOR_AGENTS.md) |
| Building an external implementation | [implementation](implementation/README.md) |
| Carousel deduction engine and Touchdown prefetch plan | [implementation/CAROUSEL_ENGINE_PLAN.md](implementation/CAROUSEL_ENGINE_PLAN.md) |
| Runtime orchestration of Carousel, Host, and policy | [implementation/RUNTIME_ORCHESTRATION_PLAN.md](implementation/RUNTIME_ORCHESTRATION_PLAN.md) |
| Findings from the external Carousel POC | [implementation/CAROUSEL_POC_FINDINGS.md](implementation/CAROUSEL_POC_FINDINGS.md) |
| Accepted boundary and language decisions | [SCP-0002](proposals/0002-carousel-runtime-boundaries.md), [SCP-0003](proposals/0003-explicit-value-producing-call-staging.md), [SCP-0004](proposals/0004-voyage-plans-and-touchdown-cable-artifacts.md), [SCP-0005](proposals/0005-guarded-conditional-recursion.md), [SCP-0006](proposals/0006-live-vessel-host-cooperation.md) |
| Occurrence kinds, artifact identity, and diagnostics | [SCP-0007](proposals/0007-inline-goal-arrow-stage-occurrence.md), [SCP-0008](proposals/0008-artifact-hash-value-closure.md), [SCP-0009](proposals/0009-structure-valued-lookup-maps.md), [SCP-0010](proposals/0010-dynamic-nooutput-errors.md) |
| Policy addressee and the Host policy channel | [SCP-0011](proposals/0011-policy-addressee-and-host-channel.md) |
| Proposing a language change | [proposals](proposals/README.md) |
| Governance and contribution scope | [GOVERNANCE.md](GOVERNANCE.md), [CONTRIBUTING.md](CONTRIBUTING.md) |
| Independent implementations | [ECOSYSTEM.md](ECOSYSTEM.md) |

Subsea Cable is licensed under the [Apache License 2.0](LICENSE).

---

## Voyage Plans are Blueprints

A `.vyg` file is not executable code.

It is not bytecode.

It is not a virtual machine instruction set.

It is not another runtime.

A `.vyg` file is a Voyage Plan: an authored blueprint for a Cable.

It describes

* goals
* dependencies
* expansion boundaries
* execution anchors

Nothing more.

Each `.vyg` Voyage Plan has exactly one Root: its sole top-level expression that
is not a binding. The Root must be a deferred Goal reduction such as
`BuildProduct[input]` or `BuildProduct#7fa31c[input]`: its base identifier's first
ASCII letter is uppercase, it has one `[...]` suffix, and it has no following
call suffix. A bare name, map access, literal, map, Anchor, arrow, or eager
`Goal(...)` call cannot be a Root. A Voyage Plan may contain any number of bindings,
but a binding-only file or a file with multiple Root expressions is invalid.
Root creates the voyage's first demand for deduction; it does not control codebase
storage or visibility.

The plan is input, not the realized Cable. The Vessel validates and stores it,
then Carousel progressively commits the demanded structure. A terminated voyage
returns the Root outcome and a Fully Touchdown Cable: a canonical ordered list
of hashes for the grounded leaves that the voyage actually reached. Provenance
keeps the reverse mapping to intermediate deductions so later voyages can reuse
unchanged segments without mutating old records. See [SCP-0004](proposals/0004-voyage-plans-and-touchdown-cable-artifacts.md).

The Vessel remains a logical participant until that voyage terminates. It
coordinates Carousel deduction, Scheduler eligibility, Host evaluation, and
the return of outcomes and routed values that may unlock later structure. It is
not merely a compiler that hands a completed Cable or generated Host program to
a detached executor. This requirement does not prescribe deployment: Vessel
and Host may share one process, link as a library, embed generated code, or
communicate remotely. See
[SCP-0006](proposals/0006-live-vessel-host-cooperation.md).

---

## Language Generic

Subsea Cable does not replace Java.

It does not replace Go.

It does not replace Rust.

It complements them.

Every language can become a Subsea consumer simply by implementing the specification.

```
.vyg

        ↓

Java
Go
Rust
Kotlin
Python
...
```

---

## Infrastructure Generic

Execution is not prescribed.

The same program may execute using

* a sequential scheduler
* a parallel scheduler
* a distributed runtime
* Kubernetes
* Temporal
* eBPF
* custom schedulers

Subsea Cable intentionally leaves execution strategy outside of the language.

---

## Reduction, Deduction, and Evaluation

Subsea Cable separates three things that ordinary programs often collapse.

**Reduction** is the language rule that describes how a resolved Goal definition
and its arguments produce subordinate structure or a leaf.

**Deduction** is the demand-driven Runtime event that resolves one Goal
occurrence, applies its reduction rule, and commits the selected artifact hash
and resulting structure. Deduction—not Touchdown—is the commit boundary.

**Evaluation** runs a concrete leaf after successive deductions have grounded
it. Evaluation remains distinct from deduction.

An unqualified child exposed by one deduction is a new symbolic `Name/Arity`
occurrence. Its position is committed, but its current alias is not resolved to
an `ArtifactHash` until that child is itself demanded. The concrete Goal DAG is
therefore disclosed incrementally rather than frozen in full before work begins.

---

## Goal Arrows and Function Arrows

A Goal arrow describes a structural reduction rule:

```subsea
Upper = [] -> [A, B, C]
C = [b] -> [D[b], E]
```

Square brackets are serial composition. `B` depends on `A` and receives its
result, while `C` likewise depends on `B`. When `C` is deduced, its reduction
rule produces a serial structure that
becomes conceptually `[A, B, D, E]`, while lineage still records `Upper.C.D` and
`Upper.C.E`.

A serial composition contains at least two elements and exports the output of
its final element. `[A, B]` therefore exports B's value. If B produces no value,
the whole composition exports `NoOutput`. Earlier results are discarded unless
they are routed explicitly.

Bare `[]` and singleton `[A]` are not expressions. This does not affect
`[] -> ...`, which declares a zero-arity Goal, or `Goal[]`, which is a deferred
zero-argument Goal reference.

Curly braces with commas are parallel composition:

```subsea
Upper = [x, y] -> { C[x], D[y] }
```

`C[x]` and `D[y]` have no dependency edge between them, so a Scheduler may run
them concurrently. Braces permit concurrency but do not require simultaneous
execution. A no-argument Goal is written as bare `A` inside a composition rather
than `A[]` when it is an initial serial stage or a parallel sibling.

An unkeyed parallel composition exports no value. When followed by another
serial element, the structure contains a dependency from the composite node to
that element, but the language does not decide when the composite is considered
satisfied. Goal names are never turned into result keys automatically:

```subsea
[{A, B}, C[]] // C has a structural dependency on the parallel composite
```

An unkeyed parallel composition also requires at least two elements. Singleton
`{A}` is invalid, while `{}` is an ordinary empty map value. Its output state is
always `NoOutput`, regardless of branch results.

`NoOutput` is not a runtime value: it is not `null`, unit, or an empty map, and
it has no source literal. It cannot be routed, bound, or destructured. A later
stage may still depend on it structurally when every argument is explicit:

```subsea
[{A, B}, C[]]          // valid: dependency only; C/0
[{A, B}, C[y]]         // valid: y comes from lexical scope
[{A, B}, C]            // invalid: bare C requires an upstream value
[{A, B}, [x] -> C[x]]  // invalid: there is no value to bind to x
```

To pass parallel results downstream, every exported result needs an explicit
key in a resolving map:

```subsea
[
    [] -> {x: A, y: B},
    [{x, y}] -> [C[x], D[y]]
]
```

The keyed map is the direct body of a Goal arrow. Its branches are independent
and expose one immutable map-shaped result
`{x: resultOfA, y: resultOfB}`. The following Goal arrow receives that one value
and destructures it. `{A, B}` alone can never provide values for `[{x, y}]`
because it exports nothing.

A resolving map is still a value producer, not a Goal stage. It may never stand
beside Goals in a composition:

```subsea
[A, {x: B, y: C}, D]          // invalid
[A, [] -> {x: B, y: C}, D]    // valid; ignores A's output
[A, [i] -> {x: B[i], y: C[i]}, D] // valid; routes A's output
```

Only a map literal used as the direct body of a Goal arrow is a resolving map.
Every other map is an ordinary value or selective lookup map. Resolving-map
keys must be concrete, and every branch must export a value; a `NoOutput` branch
cannot materialize its key. Singleton `[] -> {x: A}` is valid, while `{}` is
always an ordinary empty map.

Bare downstream Goals are the one contextual shorthand: `[A, B]` means A/0
followed by B/1, with A's result as B's sole argument. Explicit brackets never
receive an implicit argument:

```subsea
[A[x], B]                         // B/1 receives A's result
[A[x], B[y]]                      // B structurally follows A and receives only y
[A[x], [Aresult] -> B[Aresult, y]] // B/2 receives both explicit values
```

The serial container still orders `B[y]` after `A[x]`, but A's result is
discarded unless it is forwarded explicitly through a Goal-arrow stage. No
upstream value is automatically inserted or appended to a written argument
list.

A downstream parallel composition has one narrowly defined implicit fan-out.
It works only when every branch is a bare Goal with a `/1` implementation:

```subsea
[A, {B, C}]

// exactly equivalent routing
[A, [i] -> {B[i], C[i]}]
```

The same one upstream value is sent to both branches. If either branch is not
unary or needs any other value, all routing must be explicit:

```subsea
[A, [i] -> {B[i], C[i, y]}]
[A, [i] -> {B[y], C[i]}]
```

A fully explicit parallel group ignores the upstream value while retaining the
outer structural dependency:

```subsea
[A, {B[a], C[b]}]
```

Implicit and explicit branches may not be mixed in one unkeyed parallel group.
This fan-out shorthand never applies to resolving maps because maps cannot be
composition stages. Keyed routing must be wrapped in a Goal arrow:

```subsea
[A, [i] -> {x: B[i], y: C[i]}]
```

A Goal arrow may destructure and route one resolving-map result:

```subsea
Distribute = [{x, y}] -> [T1[y], T2[x]]
```

A Goal-arrow body must be reduction structure. It cannot be a primitive,
ordinary map value, or computed operator result. Valid direct forms are a Goal
reference/call, an Anchor leaf/call, another Goal arrow, serial composition,
unkeyed parallel composition, a resolving map, or an ordinary-map lookup whose
selectable entries are all valid Goal structure. Ordinary value expressions
remain valid inside Goal and Anchor argument lists, but those argument
expressions may not themselves contain a value-producing `Goal(...)` or
`$anchor(...)` call.

```subsea
Value = [x] -> 42          // invalid: primitive body
Zero  = [x] -> $host       // valid: Anchor/0; x is unused
Call  = [x] -> $host(x)    // valid: Anchor/1
Bad   = [x] -> (y) -> y    // invalid: function arrow is never inline
```

A bare Anchor receives no implicit Goal parameters. `$host` and `$host()` are
the same zero-argument occurrence. Signature compatibility and resolution belong
to the Host, not structural validation. Serial and parallel elements follow the
same structural restriction, so a value cannot stand beside Goals merely because
it parses as an expression.

### Conditional structural pipelines

A pure selector expression may be followed by a keyed branch map as one
structural pipeline:

```subsea
CountDown = [n] -> [
    n == 0,
    {
        true: Done[],
        false: CountDown[n - 1],
    },
]
```

Carousel evaluates `n == 0` through the active Host primitive-semantics profile
and exposes exactly one Goal-structure branch. The selector creates no Goal
occurrence, leaf, or Scheduler work. The branch map is contextual structure: it
is neither an ordinary value map nor a resolving map. It uses the ordinary
normalized-key rules, including exact-match precedence and optional `_`
fallback. A missing match reports `KeyNotFound` in the existing phase.

All branches undergo structural validation, but an unselected branch creates no
occurrence, resolves no alias, observes no routed value, and contributes no
Touchdown. The selected branch's output state is the conditional pipeline's
output state.

The selector may contain parameters, immutable values, ordinary value
maps/lookups, literals, and primitive operators. It may not contain a Goal or
Anchor occurrence or call. The conditional pipeline receives no implicit
upstream value; bind an upstream value with an enclosing Goal arrow before
using it in the selector or branch arguments.

This conditional form has exactly two elements: the selector and the branch
map, plus an optional trailing comma. `[selector, {true: Left[], false:
Right[]}, Next]` is a syntax error. To continue after the selected branch, make
the conditional pipeline one nested serial stage:

```subsea
[
    [selector, {true: Left[], false: Right[]}],
    Next,
]
```

A bare uppercase Goal name is not a value selector. For example, if `Flag` is a
Goal, `[Flag, {true: Left[], false: Right[]}]` reports `UnboundName` because
Goal definitions never satisfy value lookup.

If the selector requires an unresolved routed value, the containing deduction
stops at the conservative value barrier. It selects no key, creates no branch
occurrence or observation, and commits no placeholder. Explicit demand reports
`DeductionBlocked(pendingValue)`; speculative consideration reports
`PrefetchBlocked` until the value resolves.

The resolved selector is a value observation for SCP-0004 reuse. Provenance
records a stable selector-value slot, its canonical digest, the normalized key
selected, and the Host primitive profile. A prior selected-branch segment may
be reused only when that digest and the other SCP-0004 identity inputs match;
matching only the selected key is insufficient.

This contextual form is distinct from a reusable structure-valued ordinary map
binding, whose general closure and routing rules remain a separate design
question.

Outside a function-arrow leaf, an eager Goal call or Anchor call must itself be
the direct structural occurrence: the complete Goal-arrow body, a serial or
parallel element, or a resolving-map branch.
It may not be hidden inside another call's arguments, a policy argument, an
operator operand, a lookup key, or an ordinary value container.

```subsea
[C[x], D]                 // valid: explicit dependency and routing
[C(x), [v] -> D[v]]       // valid: eager C is a visible stage
D[C(x)]                   // invalid: hidden eager Goal dependency
D[$fetch(x)]              // invalid: hidden Anchor effect
B[x + 1]                  // valid: effect-free primitive expression
```

The invalid nested forms report `InvalidStructuralContext`. Validation never
invents a hoisted occurrence, and deduction never commits a placeholder while
waiting for a hidden evaluation.

The square-bracket arrow remains structural and may appear inline in Goal
composition. By contrast, a function arrow exists only as the complete leaf
implementation of a named Goal:

```subsea
Add = (x, y) -> x + y
Notify = ({x, y}) -> { $C(x); $D(y) }
```

`(x, y)` receives two arguments. `({x, y})` receives one map value and
destructures it. The function composite uses semicolons to declare strict
left-to-right dependencies. It does not forward non-final values and exposes
the final value. It is not a map or a parallel Goal composition; `;` is valid
only inside this leaf implementation. Error handling remains Scheduler policy.

Function arrows have fixed arity with no default or variadic parameters.
Destructuring requires one map containing every requested key. A non-map or a
missing key produces `DestructureMismatch`; unrelated extra keys are allowed.
Statically evident mismatches are validation errors, while dynamically known
mismatches are deduction errors.

A function arrow is never a value. It cannot be anonymous inline content,
aliased, passed, returned, stored in a map, used as an argument, or inserted as
a stage such as `[Goal1, (x) -> ..., Goal2]`.

Its body is the terminal content of its Goal and may use parameters, literals,
operators, ordinary maps/lookups, and host calls written with Anchors. It may
not reference or call another Subsea Goal at any depth. Therefore `C(x)` and
`C[x]` are both invalid in a function body; Host Anchor calls must be written as
`$C(x)` and `$D(y)`. This keeps all Subsea-level composition in Goal arrows and
pushes executable functions to the Goal graph's leaf boundary. Those Anchor calls do
not create additional Subsea Goal nodes.

Subsea defines structure, not execution policy. Serial and parallel composition
specify dependency edges, independence, value routing, and result keys. They do
not specify success criteria, failure propagation, all/any/quorum completion,
retry, cancellation, timeout, fire-and-forget behavior, or error aggregation.
Those decisions belong to the Scheduler. A dependent evaluation instance can
become eligible only when the Scheduler considers its upstream structure
satisfied and supplies every value that the instance structurally requires.

---

## A Voyage Plan Materializes as a Goal DAG

The Voyage Plan exists from the start; its realized Cable does not.
Demand-driven deductions materialize reachable structure as a directed acyclic graph (DAG), not
necessarily a tree. The complete future graph need not exist or remain fixed in
advance because every undeduced unqualified occurrence still observes a mutable
`Name/Arity` alias when it is demanded.

Source expressions use tree-shaped notation, but occurrences that resolve to the
same policy-erased Goal definition and arity point to one shared structural Goal
node. They add incoming dependency edges; they do not clone the node. Occurrences
that resolve at different times may select different hashes and therefore point
to different nodes even when their human-readable names are equal.

Serial and parallel placement, argument routing, conditional selection, and
resolving keys belong to edges and composite structure. A guarded recursive
definition creates a fresh child occurrence each time its recursive branch is
selected. The child may share a `GoalNodeId` with an ancestor, but the committed
edge points to the new occurrence rather than back to the ancestor. The realized
Cable therefore remains a DAG.

Sharing a Goal node does not combine incoming values or create an implicit
all-parent barrier. Each edge keeps its own routing and may create a separate
evaluation instance. Multiple upstream results feed one evaluation instance
only when an explicit structure such as a resolving map combines them.

## Deduction Preserves Lineages

Deduction is not textual substitution, and lineage is not node identity.

When a Goal occurrence is deduced, the reduction result extends its active
lineages onto every exposed child occurrence.

```
PrepareOrder = [userId, orderInfo] ->
    { GetUserInfo[userId], ValidateOrder[orderInfo] }

PrepareOrder[10, {...}]
```

deduces the explanatory lineage projection

```
{ PrepareOrder/2.GetUserInfo/1[10],
  PrepareOrder/2.ValidateOrder/1[{...}] }
```

not to bare `GetUserInfo` / `ValidateOrder` Goals.

Each path segment contains the Goal's name and arity. The dotted `Name/Arity`
form is explanatory pretty-printing of one Root-to-occurrence lineage held by the
Carousel. It is not `.vyg` source syntax, a unique node address, or reparsable
deduction output. Path `.` and `/arity` are not source-language syntax.

Each incoming lineage is extended across the outgoing edges committed by a
deduction. Deferred `Goal[...]` leaves the child occurrence undeduced; eager
`Goal(...)` demands it immediately. The suffix changes timing, not the reduction
rule. Function parameters, map values, and literals remain lexically scoped and
inherit the active lineage set as context.

---

## Node Identity, Lineage, and Evaluation Are Different

Before deduction, an unqualified Goal occurrence is a symbolic `Name/Arity`
reference with stable occurrence identity but no selected Goal node. When it is
demanded, the Carousel atomically resolves the current alias to an `ArtifactHash`,
commits that choice, and associates the occurrence with the artifact's
policy-erased `StructureHash` and arity. That pair is its `GoalNodeId`.

A structural Goal node is therefore identified by resolved policy-erased
structure and arity, not by its parent, occurrence, lineage, argument values, or
human-readable alias. The definition node is structurally shared; deductions
and evaluations remain occurrence- and argument-sensitive. Deferred `Goal[...]`
and eager `Goal(...)` can resolve to the same node when they observe the same
alias binding; the suffix changes demand timing, not identity after resolution.

A lineage path is one route from the Root to that shared node. A node with
multiple incoming edges therefore has multiple lineages:

```subsea
Root = [] -> { B[1], C[2] }
B = [x] -> D[x]
C = [x] -> D[x]
D = (x) -> x
```

`D/1` is one structural node with two lineages:

```text
Root/0.B/1.D/1
Root/0.C/1.D/1
```

It has evaluation instances for the routed argument tuples `(1)` and `(2)`.
Evaluation remains separate from the shared structure. Structural sharing does
not require result caching or execution coalescing; those remain Scheduler
policy. Each evaluation instance carries the active lineage or lineages that
actually contributed its inputs; the structural node's lineage set is their
union.

Distinct source occurrences remain distinct even when they point to the same
Goal node with the same arguments:

```subsea
{Goal1, Goal1}
```

This contains two sibling occurrences and two edges to one shared `Goal1/0`
node. The structure is therefore technically a directed acyclic multigraph.
Every occurrence/edge has stable identity so lineage and policy attachment can
distinguish duplicates. Whether a Scheduler physically coalesces identical
evaluation work is execution policy, not structural identity.

```
Definition  → shared by GoalNodeId                  (Carousel)
Deduction   → committed per demanded occurrence     (Carousel)
Lineage     → one or more Root-to-occurrence paths   (Carousel)
Evaluation  → distinguished by routed arguments     (Scheduler)
```

This is the same expansion/evaluation split, seen from the naming side.

---

## Leaves

Successive deductions bottom out in exactly two kinds of leaf.

* an arrow-function leaf belonging to a named Goal
* a Host Anchor leaf

Both are Host-provided concrete computation. The difference is representation:
an arrow-function body is present in Subsea source and evaluated by the Host,
while an Anchor is an opaque name whose implementation the Host must resolve.

An Anchor, written `$identifier`, marks a leaf whose implementation the Host must
resolve. Only an identifier may follow `$`; inline location strings are invalid.
Any registry that maps this identifier to a function, service, LLM, person, or
other implementation exists outside Subsea source.

Subsea Cable has no native effects of its own. Anything that touches reality is
behind a Host Anchor.

```subsea
$send
$send(message)
```

An Anchor is opaque and never structurally reduced. Subsea supplies its
identifier, explicit arguments and arity, occurrence identity, and active Goal
lineages. The Host owns resolution, signature compatibility, invocation, and
result semantics.

Anchoring policy uses `@`, independently of Host resolution:

```subsea
@retry Goal1
@retry @atLeastOnce $send(message)
@timeout("30s") {Goal1, Goal1}
```

Each `@policy` prefix attaches How metadata to exactly the following structural
occurrence. It never changes dependency topology, `GoalNodeId`, argument routing,
or result routing. Stacked policies attach to the same target in source order.

Policy-specific meaning, argument schema, same-addressee composition, and
execution belong to the policy's **resolved addressee**. The Runtime policy
phase owns addressee resolution, cross-addressee collision detection,
target-kind enforcement, and the forwarding allowlist; none of those decisions
falls through to an addressee by default. A Scheduler-addressed policy is the
Scheduler's to interpret. A Host-addressed policy — one that changes only what
happens inside exactly one grounded leaf invocation — is the Host's to
interpret, and the Scheduler must not interpret it. An identifier neither
declaration claims is `UnknownPolicy`.

Eligibility, the attempt lifecycle, and scope outcomes stay with the Scheduler
whatever policies exist. Policy inheritance is not delegated to either
addressee: a policy never copies to a descendant occurrence. Neither addressee
may change topology.

A policy on a Goal reference belongs to that occurrence/edge and its lineage,
never to the shared Goal definition or node. Erasing every policy annotation
therefore produces the same structural projection. `StructureHash` excludes
policies; `ArtifactHash` identifies the complete authored term and includes its
ordered policy projection.

For example, the timeout below targets the parallel product as one occurrence;
it does not serialize its children or copy a separate timeout onto each child:

```subsea
@timeout("30s") {Goal1, Goal1}
```

### Who a policy is addressed to

A `@policy` is metadata addressed to somebody, and there are two addressees.

- **Scheduler-addressed** policies change eligibility, the attempt lifecycle, or
  a scope's outcome: retry, timeout, cancellation, completion criteria. The
  Scheduler interprets them.
- **Host-addressed** policies change what happens inside exactly one grounded
  leaf invocation: run it in a separate process, use a resource class. The Host
  interprets them; the Scheduler must not.

The test is mechanical: if it changes eligibility, the attempt lifecycle, or a
scope's outcome, it is Scheduler-addressed; if it changes only what happens
inside exactly one grounded leaf invocation, it is Host-addressed. Batching or
coalescing several leaves crosses more than one occurrence, so it is Scheduler
work even though the Host ultimately executes the batch.

A Runtime resolves each occurrence's ordered policies against the Scheduler
policy registry and the Host capability declaration, both pinned at run start:

| Claimed by | Result |
|---|---|
| Scheduler only | Scheduler-addressed; it never crosses to the Host |
| Host only | Host-addressed; it rides in the Host-facing request as `hostPolicies[]` |
| Both | `PolicyConflict` in the `policy` phase at disclosure |
| Neither | `UnknownPolicy`, unchanged |

A Host-addressed policy may only be authored on a grounded leaf — a
function-leaf or an Anchor occurrence. On any non-leaf occurrence it is
`UnsupportedPolicyTarget`, and a composite's policy is never forwarded to a
descendant leaf, because policies do not inherit. See
[SCP-0011](proposals/0011-policy-addressee-and-host-channel.md).

---

## Names, Codebase References, and Anchors

There is only one naming law, and it is positional.

The base identifier before `[...]` is read by case. A Goal may additionally be
qualified by a codebase hash prefix.

```
Something[...]          uppercase → a Goal
Something#7fa31c[...]   uppercase → a hash-qualified Goal
something[...]          lowercase → a map
```

A lowercase map access takes exactly one key. `something[]` and
`something[first, second]` are invalid, and maps cannot carry hash qualifiers;
Goals may take zero or more arguments.

Leading underscores are ignored for this test. The first ASCII letter decides
the case, so `_Build[...]` is a Goal and `_cache[...]` is a map access. An
identifier containing no letter may not be followed by `[...]`.

Inside serial or parallel Goal composition only, a bare uppercase identifier is
also a Goal stage. This is the only bracket-omission shorthand; a bare lowercase
identifier remains an ordinary value.

The wildcard `_` is reserved for map keys. It is not a general expression and
cannot be used as a standalone value, argument, or pipeline stage.

`_` is available only as the fallback key of an ordinary lookup map. A resolving
map that exports parallel branch results must use concrete keys; wildcard `_`
is invalid in that context because it cannot become a materialized result key.

A map may contain at most one wildcard and may not repeat an explicit key. An
exact explicit-key match always takes precedence, regardless of declaration
order; `_` is used only when no explicit key matches.

A bare identifier key is static shorthand for a string key with the same
spelling. `success` and `"success"` are duplicates. Keys never perform scope
lookup or expression evaluation. Numeric and string keys remain distinct, so
`1` and `"1"` are different keys.

Key equality uses normalized structural key forms rather than raw source
spelling. Thus `1` and `1.0` are the same numeric key, as are `0` and `-0`;
string escapes are decoded before comparison. String keys are case-sensitive.

Source files are UTF-8, while Identifiers intentionally remain ASCII:
`[A-Za-z_][A-Za-z0-9_]*`. This keeps the casing law and name lookup independent
of Unicode versions, locale, normalization, and visually confusable characters.
The same rule covers Goal and value names, parameters, bare Identifier map keys,
`$` Anchor names, and `@` policy names. Hash qualifiers remain ASCII
alphanumeric.

Strings are sequences of Unicode scalar values. They are not Unicode-normalized:
precomposed `é` and `e` followed by a combining accent are different values.
Invalid UTF-8 is a source-decoding error. Literal non-ASCII scalar values may be
written directly in the source. The supported escapes are `\"`, `\\`, `\n`,
`\r`, `\t`, and `\u{...}`. A Unicode escape has one to six hexadecimal digits
and must denote `0..10FFFF`, excluding the surrogate range `D800..DFFF`.

Escape spelling is not part of String identity. Escapes are decoded first, and
the resulting exact scalar sequence is used for String equality, String map-key
comparison, and canonical hashing. Consequently `"é"` and `"\u{E9}"` are the
same String, while `"é"` and `"e\u{301}"` are not. No locale-aware comparison,
case folding, or normalization participates.

Subsea has one `Number` syntax. A numeric literal is a grammar-validated decimal
string, not a language-defined integer, float, decimal, or fixed-width value.
Subsea assigns it no precision or range and does not prescribe conversion,
overflow, rounding, division, modulo, or division-by-zero behavior. The Host
primitive semantics owns those choices, their results, and their errors. Two
Hosts may therefore use different numeric models while realizing the same Goal
structure.

Numeric map-key identity is deliberately narrower and structural. It is derived
from the literal text without performing numeric evaluation: trailing fractional
zeroes are removed, an empty decimal point is removed, and a minus sign on zero
is discarded. Consequently `1`, `1.0`, and `1.00` are one map key, as are `0`,
`0.0`, and `-0`. This rule exists only so duplicate detection and lookup are
deterministic; it does not define runtime arithmetic or numeric equality.

Primitive operators are intentional deduction-time conveniences. They may be
used wherever a value expression is accepted, including routed Goal arguments:

```subsea
A = [x] -> B[x + 1]
```

When B's argument is needed during deduction, the Carousel requests `x + 1` from
the Host's primitive semantics. This creates no Goal node, leaf, or Scheduler
work. Subsea defines operator syntax, precedence, associativity, and structural
evaluation control such as left-to-right Boolean short-circuiting. The Host
defines operand support and conversion, numeric representation, exact results,
and errors. String `+`, mixed-type equality or ordering, overflow, rounding,
division, modulo, and division by zero are therefore Host contracts. Primitive
operator evaluation itself has no effect, and every successful result must
return to deduction as a Subsea-representable value.

A computed value can select an ordinary-map branch, so the unfolded structure is
relative to three inputs:

```text
Subsea source + input values + Host primitive-semantics profile
```

Every deduction records its active Host primitive-semantics profile in
provenance. A different profile may produce different future deductions, but it
never rewrites deductions that already committed. Runtime `==` is provided by
that Host and is deliberately distinct from the fixed structural equality used
for map-key identity.

`true` and `false` are reserved Boolean literals. There is no truthiness:
`!`, `&&`, and `||` accept only Boolean operands, while equality and comparison
produce Boolean values. Boolean map keys are supported and remain distinct from
strings, so `true` and `"true"` are different keys.

`&&` and `||` short-circuit from left to right. Outside a function-arrow leaf,
their operands cannot contain Goal or Anchor calls because that would hide an
evaluation dependency inside a value expression. Inside a function-arrow leaf,
an Anchor call in an unselected right operand is not invoked. This is Boolean
value selection, not failure handling; execution policy remains with the
Scheduler.

Ordinary lookup maps are selective routing structures. `map[key]` checks an
exact normalized key first and then `_`; only the selected entry participates
in the resulting dependency/value structure. Unselected entries do not. If no
entry matches, lookup reports `KeyNotFound`—as a validation error when the miss
is statically known, otherwise as a deduction error. Resolving maps are
different: their concrete keyed entries declare independent branches and
explicit key-to-result relationships.

A lookup map whose entries are Goal structure is a **structure-valued lookup
map**. It is a top-level binding whose right-hand side is a map literal, and it
may be used only in a Goal-structure position; using it as a value is
`InvalidStructuralContext`. Every entry must be Goal structure written with an
explicit suffix: a deferred Goal reference `A[]`, an Anchor reference `$a`, or a
serial or parallel composition of those. A bare identifier in an entry is a
value name, not a Goal stage, so it is `InvalidStructuralContext`. An inline
Goal arrow parses in that position but is rejected in validation with the same
kind: an entry is selected by lookup, not routed into, so its parameters would
have no caller. The selected entry receives no implicit upstream
value; routing into it must be written explicitly.

A named structure-valued map is not a conditional branch map. `[sel, Routes]` is
a two-stage serial composition whose second stage is the Goal stage `Routes`;
the conditional pipeline of
[SCP-0005](proposals/0005-guarded-conditional-recursion.md) requires an authored
branch-map literal as its second element. Selecting from a named map is written
as the lookup `Routes[key]`. See
[SCP-0009](proposals/0009-structure-valued-lookup-maps.md).

Nothing else in the language depends on case.

Top-level bindings form one order-independent scope. A binding may refer to a
name declared later in the file. Non-Goal names may be bound once; local Goal
definitions of either implementation kind may share a base name only when their
arities differ. A Goal and a non-Goal binding cannot share a base name. There is
no reassignment, same-name/same-arity redefinition, or last-declaration-wins
behavior.

Direct and mutual Goal recursion is valid when it is structurally guarded by a
conditional branch map. Every definition-level cycle must cross a recursive
reference beneath a conditional selection, and that guarding map must contain
at least one branch that exits the recursive component. Unconditional cycles
and conditional cycles with no exit remain `CycleDetected`.

Validation establishes only that an exit is structurally possible. It does not
prove that a particular input selects it. Each selected recursive step creates
a fresh occurrence with its own arguments, lineage, policies, and deduction
record. Non-termination is therefore a voyage execution/resource condition,
not a validation-time cycle error. See [Recursion.md](Recursion.md) and
[SCP-0005](proposals/0005-guarded-conditional-recursion.md).

Every selected conditional-branch child is an explicit-demand boundary.
Carousel may commit the selection and expose the symbolic child, but MUST NOT
cross that branch edge during speculative Touchdown replenishment; Scheduler
demand is required whether or not local analysis classifies the edge as
recursive. This prevents both statically visible and late alias-assembled
leafless recursion from bypassing the Touchdown window.

For cycles that local validation cannot see, especially cycles introduced by a
late unqualified alias, Carousel compares a resolved `GoalNodeId` with its
ancestor chain. Re-entry with a committed conditional branch selection on the
intervening path is guarded and creates another fresh occurrence. Re-entry with
no such selection is `CycleDetected` when the occurrence was explicitly
demanded; reached speculatively, the path is abandoned with no occurrence and
no diagnostic, so the diagnostic does not depend on the prefetch target.

Names must be unique within one Goal parameter list or destructuring pattern.
Each arrow creates a lexical scope. A nested structural arrow may shadow a
parameter or top-level binding from an enclosing scope.

Goal references use a human-readable name, arity, and optional hash prefix.
Goals may share a name when their arities differ, and `Goal[...]` or `Goal(...)`
supplies arity solely by argument count. Values, types, patterns, and guards do
not participate in overload selection. Default and variadic parameters are not
supported.

An unqualified reference is a lazy symbolic `Name/Arity` occurrence. A
hash-qualified reference pins one stored term:

```subsea
Build[x]            // resolve the current Build/1 alias when this occurrence deduces
Build#7fa31c[x]     // pinned historical ArtifactHash; reduction can remain lazy
```

The hash prefix is authoring syntax and is expanded to one full hash when the
containing artifact is stored. Unqualified references deliberately remain
symbolic in stored terms. Their alias can move until each occurrence is demanded
for deduction.

Storing a source unit creates immutable artifacts and updates the current
`(name, arity)` index. A local unqualified reference may be checked against the
same source unit during validation, but it is still stored as `Name/Arity`; the
local definition initializes the alias rather than permanently pinning every
future occurrence to its hash.

Name resolution is deterministic and follows the syntactic category selected
before lookup:

1. A value Identifier searches the innermost arrow scope outward, then the
   top-level non-Goal bindings. Goal definitions never satisfy value lookup.
2. During validation, an unqualified `Goal/arity` can be checked against an exact
   local definition and the current codebase index. The stored reference remains
   symbolic even when that check succeeds.
3. When an occurrence is demanded, its unqualified `Name/Arity` is atomically
   resolved through the then-current codebase index. The selected full
   `ArtifactHash`, observed codebase revision, arguments, result structure, and
   lineages are committed in a deduction record. That occurrence never resolves
   again.
4. `Name#prefix/arity` bypasses current-name lookup. At artifact storage it must
   match exactly one stored artifact and the required arity, and the full hash is
   retained thereafter.
5. Bare Identifier map keys are String shorthand and perform no lookup.
6. `$name` and `@policy` are deliberately not resolved by structural
   validation. Their registries belong to the Host and Scheduler respectively.

The ordinary value expressions supplied as Anchor or policy arguments still
undergo normal structural validation; only the external name, signature,
applicability, and behavior are deferred to their owning layer.

When a statically checkable unqualified Goal lookup finds no exact arity but
finds the same name at other arities, validation reports `ArityMismatch` with
the available arities. If the name does not exist at all, validation reports
`GoalNotFound`. The same kinds can arise during deduction if the mutable alias
index no longer supplies the demanded `Name/Arity`. A qualified lookup reports
`HashNotFound` or `AmbiguousHashPrefix` before checking arity. Argument types and
values never affect overload selection.

### Error ownership

Errors have a stable machine-readable `kind` and `phase`. Messages are not part
of the language contract. Every error carries a source span when one exists;
after elaboration it also carries the relevant artifact and occurrence identity,
and deduction-time errors carry active lineage information.

| Phase | Owner | Representative kinds |
|---|---|---|
| source | decoder/parser | `InvalidSourceEncoding`, `SyntaxError` |
| validation | structural language | `DuplicateBinding`, `DuplicateParameter`, `InvalidRoot`, `InvalidStructuralContext`, `InvalidUnicodeEscape`, `UnboundName`, statically provable `GoalNotFound`, `ArityMismatch`, `HashNotFound`, `AmbiguousHashPrefix`, `NotCallable`, `DuplicateMapKey`, `CycleDetected` |
| deduction | Carousel using Codebase and Host primitive semantics | dynamic `GoalNotFound`, `ArityMismatch`, `CycleDetected`, `KeyNotFound`, `DestructureMismatch`, `PrimitiveError`, `NoOutputNotRoutable` |
| host | Host | `AnchorNotFound`, `AnchorSignatureMismatch`, `NoOutputNotRoutable` inside a function-leaf body, arrow-function or Anchor leaf implementation failures |
| policy | Scheduler/anchoring layer | `UnknownPolicy`, `InvalidPolicyArguments`, `UnsupportedPolicyTarget`, `PolicyConflict`, `PolicyDenied`, scheduling and upstream-failure outcomes |

`KeyNotFound` and `DestructureMismatch` retain the same `kind` when statically
provable, but their phase is `validation`; otherwise they arise during
`deduction`. `NoOutputNotRoutable` follows the same dual-phase pattern: a Host
leaf may return `NoOutput` at runtime, and the failure is `deduction` when it is
detected while routing into a deduction — a routed input, or a resolving-map
result being bound — and `host` when it is detected inside a function-leaf body
evaluation ([SCP-0010](proposals/0010-dynamic-nooutput-errors.md)). The outcome
arrived; it simply cannot be routed, so this is distinct from a leaf failure.
`PolicyDenied` reports a Host-addressed policy that a Host advertises but the
deployment's forwarding allowlist withholds; `UnknownPolicy` is wrong there
because the Host knows the identifier, and `UnsupportedPolicyTarget` is wrong
because the target is legal
([SCP-0011](proposals/0011-policy-addressee-and-host-channel.md)). Late alias resolution can likewise move `GoalNotFound`,
`ArityMismatch`, and `CycleDetected` to deduction without changing their kinds.
`CycleDetected` applies to an unguarded definition cycle or an invalid attempt
to introduce an occurrence back-edge; it does not apply merely because a
guarded recursive branch selects the same Goal definition for a fresh child
occurrence.
`NotCallable` applies to a parsed call-shaped expression whose
syntactic category cannot be called, such as `value(...)`. A Goal found under
the wrong arity reports `ArityMismatch`, not `NotCallable`.

Source or validation errors make the source unit invalid, so no artifacts from
that unit are committed to the codebase and deduction does not begin. A
deduction error is scoped to the failing occurrence: that occurrence does not
commit a partial deduction. Every earlier committed deduction—including
intermediate structure that has not yet reached Touchdown—remains unchanged.
Recovery or termination is Scheduler policy. Host and policy failures never
retroactively change committed Goal structure.

A binding whose right-hand side is `[params] -> goal-body` defines a composite
Goal. A binding whose right-hand side is `(params) -> body` defines a Goal with
an arrow-function leaf implementation.
Both names begin with uppercase after leading underscores are ignored, and both
participate in the same local `Name/Arity` lookup space. Any other permitted
right-hand side defines an immutable non-Goal value. A function arrow is never a
value and cannot be transported or rebound. A string binding is always an
ordinary value and has no package, import, or Anchor-resolution meaning. Host
Anchors never resolve through string bindings. An Anchor itself cannot be bound
directly: `name = $host` is invalid.

There are exactly two value-producing call forms. `Goal(...)` eagerly evaluates
a Subsea Goal; `$anchor(...)` invokes a Host-resolved Anchor. Lowercase values,
maps, pipelines, groups, call results, and every other value are not callable.
Calls cannot be chained. Outside a function-arrow leaf these calls are valid
only as direct structural occurrences and cannot be nested in value
expressions. Inside an arrow-function leaf implementation, Subsea Goal calls
are forbidden and only the Host Anchor form may be used; nested Anchor calls
there belong to the Host evaluation of that one grounded leaf.

Because `$` marks a Host Anchor leaf, a name may never be bound directly to one.

```
Add = [a, b] -> $plus(a, b)   a real goal that reduces to a leaf
Add = (a, b) -> a + b         a named Goal with an arrow-function leaf
Add = $plus                   forbidden — a leaf disguised as a goal
```

An Anchor leaf must be reached through structural Goal reduction. The dedicated
function-arrow binding is the sole form that gives a Goal a direct leaf
implementation.

Subsea has no import, export, package, module, or public/private construct. Every
named Goal definition in a valid source unit is stored in an abstract
content-addressed codebase, including Goals not reachable from Root. Root is only
the entrypoint selected for this Voyage Plan.

```text
Content store:       full ArtifactHash → authored Goal term
Current name index:  (human name, arity) → ArtifactHash
History:             older hashes remain addressable
Deduction ledger:    occurrence → selected hash + committed reduction result
```

Names are mutable indexes, never identity. The codebase backend may be a
filesystem, SQLite database, Git-like store, distributed service, or any other
implementation of the same resolution contract. Deletion, garbage collection,
access control, branches, and namespaces belong to that implementation.

An unqualified reference stored inside an artifact retains `Name/Arity`. It is
the demand-paged address of Goal space. The Carousel resolves it against the
current name index only when that particular occurrence deduces. Alias rebinding
can therefore change still-undeduced structure but can never rewrite a committed
deduction. A hash-qualified reference stores a full pinned hash and bypasses the
mutable name index.

An `ArtifactHash` identifies the stored authored Goal term, including its policy
projection. It also captures the **transitive closure of the top-level value
bindings the term references by name**, in canonical order, so two units whose
Goals read different values never share a hash and an unrelated value edit never
changes one. Unqualified Goal references are not captured: they stay symbolic and
resolve when their own occurrence is demanded. A structure-valued lookup map is
captured by structure rather than by value — its keys and entry shapes are part
of the hash while Goal references inside its entries stay symbolic. See
[SCP-0008](proposals/0008-artifact-hash-value-closure.md).

Its policy-erased `StructureHash` supplies `GoalNodeId` and structural
sharing. This lets two artifacts with identical structure but different
`@policy` metadata share structural nodes without becoming the same authored
artifact. For an unqualified reference, that node identity becomes known only
after the occurrence selects an artifact during deduction.

A Root artifact or source revision alone is not a replay record because future
unqualified occurrences may observe later alias bindings. Exact replay requires
the deduction ledger: occurrence identity, requested name and arity, selected
full hash, arguments, committed result structure, active lineages, and observed
codebase revision for every deduction.

The executable grammar, preprocessing reference algorithm, and acceptance/error
corpus are maintained in [conformance](conformance/README.md).

The external-implementer guide for a conforming Runtime and evidence-driven
policy discovery is maintained in [implementation](implementation/README.md).

---

## Bring Your Own Scheduler

Subsea Cable intentionally ships without an official scheduler.

Host, Carousel, Scheduler, and complete Vessel (Consumer Runtime)
implementations are independent external projects. This repository neither vendors nor designates an official one.

Every project is free to provide execution strategies that fit its own runtime.

---

## Philosophy

Programs describe intent.

Schedulers execute intent.

Functions implement intent.

Subsea Cable connects them.

Not by replacing existing languages—

but by giving them a common representation of programs.
