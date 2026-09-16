# README.md

# Subsea Cable

> **Programs are not instruction sequences. They are executable intent.**

Subsea Cable is not another programming language.

It is a language-agnostic, infrastructure-agnostic representation of programs.

Instead of describing *how* computations should execute, Subsea Cable describes *what* a program is.

A Subsea program is a dependency structure.

Everything else is an implementation strategy.

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

---

## Programs are Blueprints

A `.subsea` file is not executable code.

It is not bytecode.

It is not a virtual machine instruction set.

It is not another runtime.

A `.subsea` file is a blueprint.

It describes

* goals
* dependencies
* expansion boundaries
* execution anchors

Nothing more.

Each `.subsea` Program has exactly one Root: its sole top-level expression that
is not a binding. The Root must be a deferred Goal reduction such as
`BuildProduct[input]`: its identifier's first ASCII letter is uppercase, it has
one `[...]` suffix, and it has no following call suffix. A bare name, map access,
literal, map, Anchor, arrow, or eager `Goal(...)` call cannot be a Root. A
Program may contain any number of bindings, but a binding-only file or a file
with multiple Root expressions is invalid. Library/module-only files are not
currently a separate language form.

---

## Language Generic

Subsea Cable does not replace Java.

It does not replace Go.

It does not replace Rust.

It complements them.

Every language can become a Subsea consumer simply by implementing the specification.

```
.subsea

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

## Expansion before Evaluation

Traditional languages expose evaluation.

Subsea Cable exposes reduction.

Programs are expanded into executable leaf nodes.

Only then are those leaves evaluated.

Expansion and evaluation are independent concerns.

---

## Goal Arrows and Function Arrows

A Goal arrow describes structural reduction:

```subsea
Upper = [] -> [A, B, C]
C = [b] -> [D[b], E]
```

Square brackets are serial composition. `B` depends on `A` and receives its
result, while `C` likewise depends on `B`. When `C` reduces, the serial structure
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
remain valid inside Goal and Anchor argument lists.

```subsea
Value = [x] -> 42          // invalid: primitive body
Zero  = [x] -> @host       // valid: Anchor/0; x is unused
Call  = [x] -> @host(x)    // valid: Anchor/1
Bad   = [x] -> (y) -> y    // invalid: function arrow is never inline
```

A bare Anchor receives no implicit Goal parameters. Its host metadata must
confirm arity zero. Serial and parallel elements follow the same structural
restriction, so a value cannot stand beside Goals merely because it parses as
an expression.

The square-bracket arrow remains structural and may appear inline in Goal
composition. By contrast, a function arrow exists only as the complete leaf
implementation of a named Goal:

```subsea
Add = (x, y) -> x + y
Notify = ({x, y}) -> { @C(x); @D(y) }
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
mismatches are evaluation errors.

A function arrow is never a value. It cannot be anonymous inline content,
aliased, passed, returned, stored in a map, used as an argument, or inserted as
a stage such as `[Goal1, (x) -> ..., Goal2]`.

Its body is the terminal content of its Goal and may use parameters, literals,
operators, ordinary maps/lookups, and host calls written with Anchors. It may
not reference or call another Subsea Goal at any depth. Therefore `C(x)` and
`C[x]` are both invalid in a function body; host calls must be written as
`@C(x)` and `@D(y)`. This keeps all Subsea-level composition in Goal arrows and
pushes executable functions to reduction's lowest layer. Those Anchor calls do
not create additional Subsea Goal nodes.

Subsea defines structure, not execution policy. Serial and parallel composition
specify dependency edges, independence, value routing, and result keys. They do
not specify success criteria, failure propagation, all/any/quorum completion,
retry, cancellation, timeout, fire-and-forget behavior, or error aggregation.
Those decisions belong to the Scheduler. A dependent evaluation instance can
become eligible only when the Scheduler considers its upstream structure
satisfied and supplies every value that the instance structurally requires.

---

## The Program Is a Goal DAG

The structure reachable from the one Root is a directed acyclic graph (DAG),
not necessarily a tree. Source expressions use tree-shaped notation, but repeated
references to the same resolved Goal definition and arity point to one shared
structural Goal node. They add incoming dependency edges; they do not clone the
node.

Serial and parallel placement, argument routing, and resolving keys belong to
edges and composite structure. Because recursion is currently unsupported, no
edge may introduce a direct or mutual cycle.

Sharing a Goal node does not combine incoming values or create an implicit
all-parent barrier. Each edge keeps its own routing and may create a separate
evaluation instance. Multiple upstream results feed one evaluation instance
only when an explicit structure such as a resolving map combines them.

## Reduction Preserves Lineages

Reduction is not substitution, and lineage is not node identity.

When a goal is reduced, its own name is carried onto every sub-goal as a qualified prefix.

```
PrepareOrder = [userId, orderInfo] ->
    { GetUserInfo[userId], ValidateOrder[orderInfo] }

PrepareOrder[10, {...}]
```

reduces to

```
{ PrepareOrder/2.GetUserInfo/1[10],
  PrepareOrder/2.ValidateOrder/1[{...}] }
```

not to bare `GetUserInfo` / `ValidateOrder` Goals.

Each path segment contains the Goal's name and arity. The dotted `Name/Arity`
form is explanatory pretty-printing of one Root-to-node lineage held by the
Vessel. It is not `.subsea` source syntax, a unique node address, or reparsable
reduction output. Path `.` and `/arity` are not source-language syntax.

Each incoming lineage is extended across outgoing reduction edges, whether
reduction is deferred (`[]`) or immediate (`()`); the bracket only decides
timing. Function parameters, map values, and literals remain lexically scoped
and inherit the active lineage set as context.

---

## Node Identity, Lineage, and Evaluation Are Different

A structural Goal node is identified by its resolved Goal definition and arity,
not by its parent, source occurrence, lineage, or argument values. The Vessel
expands that `GoalNodeId` once and structurally shares the node.
Deferred `Goal[...]` and eager `Goal(...)` references resolve to the same node;
the suffix changes timing, not structural identity.

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

```
Expansion   → shared by GoalNodeId       (Vessel)
Lineage     → one or more Root paths     (Vessel)
Evaluation  → distinguished by arguments (Scheduler)
```

This is the same expansion/evaluation split, seen from the naming side.

---

## Leaves

Reduction bottoms out in exactly two kinds of leaf.

* an arrow-function leaf belonging to a named Goal
* a reference anchor

An anchor, written `@`, always refers to a host function—an implementation provided by a consuming language.

Subsea Cable has no native effects of its own. Anything that touches reality is a host function behind an anchor.

```
@send
@"registry.example.com/pkg/Join@1.2.3"
```

An anchor is opaque. It is never expanded. It inherits the active goal
lineages as context.

---

## Names, Anchors, and Imports

There is only one naming law, and it is positional.

Whatever sits immediately before `[...]` is read by case.

```
Something[...]   uppercase → a Goal
something[...]   lowercase → a map
```

A lowercase map access takes exactly one key. `something[]` and
`something[first, second]` are invalid; Goals may take zero or more arguments.

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

Key equality uses normalized semantic values rather than source spelling. Thus
`1` and `1.0` are the same numeric key, as are `0` and `-0`; string escapes are
decoded before comparison. String keys are case-sensitive.

`true` and `false` are reserved Boolean literals. There is no truthiness:
`!`, `&&`, and `||` accept only Boolean operands, while equality and comparison
produce Boolean values. Boolean map keys are supported and remain distinct from
strings, so `true` and `"true"` are different keys.

`&&` and `||` short-circuit from left to right. `false && rhs` and `true || rhs`
do not select `rhs`, so eager Goal or Anchor calls found only there do not join
the resulting dependency/evaluation structure. This is Boolean value selection,
not failure handling; execution policy remains with the Scheduler.

Ordinary lookup maps are selective routing structures. `map[key]` checks an
exact normalized key first and then `_`; only the selected entry participates
in the resulting dependency/value structure. Unselected entries do not. If no
entry matches, lookup reports `KeyNotFound`—as a validation error when the miss
is statically known, otherwise as an evaluation error. Resolving maps are
different: their concrete keyed entries declare independent branches and
explicit key-to-result relationships.

Nothing else in the language depends on case.

Top-level bindings form one order-independent scope. A binding may refer to a
name declared later in the file. Non-Goal names may be bound once; local Goal
definitions of either implementation kind may share a base name only when their
arities differ. A Goal and a non-Goal binding cannot share a base name. There is
no reassignment, same-name/same-arity redefinition, or last-declaration-wins
behavior.

Recursion is not currently supported. Direct and mutual cycles in the binding
dependency graph are semantic errors. The design issues that must be resolved
before recursion is enabled are tracked in [Recursion.md](Recursion.md).

Names must be unique within one Goal parameter list or destructuring pattern.
Each arrow creates a lexical scope. A nested structural arrow may shadow a
parameter or top-level binding from an enclosing scope.

Goal identity is `Name/Arity`. Local Goals may share a name when their arities
differ, and `Goal[...]` or `Goal(...)` selects the sole implementation by
argument count. Values, types, patterns, and guards do not participate in
overload selection. Default and variadic parameters are not supported. Imported
Goals must publish all supported name/arity signatures as metadata.

A binding whose right-hand side is `[params] -> goal-body` defines a composite
Goal. A binding whose right-hand side is `(params) -> body` defines a Goal with
an arrow-function leaf implementation.
Both names begin with uppercase after leading underscores are ignored, and both
participate in the same `Name/Arity` namespace. Any other permitted right-hand
side defines an immutable non-Goal value. A function arrow is never a value and
cannot be transported or rebound. A string binding remains an ordinary value
until it is used as `@alias` or as an imported Goal, at which point it must be a
valid resolvable location. The same string may still be used as a normal value
elsewhere. An Anchor itself cannot be bound directly: `name = @host` is invalid.

There are exactly two call forms. `Goal(...)` eagerly evaluates a Subsea Goal;
`@anchor(...)` invokes a host function. Lowercase values, maps, pipelines,
groups, call results, and every other value are not callable. Calls cannot be
chained. Inside an arrow-function leaf implementation, Subsea Goal calls are
forbidden and only the Anchor form may be used.

A location alias is therefore a string value binding. The binding itself never
carries `@`.

```
join = "registry.example.com/pkg/Join@1.2.3"
```

How it is used decides what it is.

```
@join          a host function anchor
ImportedGoal   a goal imported from elsewhere, used bare and reduced
```

Because `@` marks a host function leaf, a name may never be bound directly to an anchor.

```
Add = [a, b] -> @plus(a, b)   a real goal that reduces to a leaf
Add = (a, b) -> a + b         a named Goal with an arrow-function leaf
Add = @plus                   forbidden — a leaf disguised as a goal
```

An Anchor leaf must be reached through structural Goal reduction. The dedicated
function-arrow binding is the sole form that gives a Goal a direct leaf
implementation.

---

## Bring Your Own Scheduler

Subsea Cable intentionally ships without an official scheduler.

Reference implementations exist only as examples.

Every project is free to provide execution strategies that fit its own runtime.

---

## Philosophy

Programs describe intent.

Schedulers execute intent.

Functions implement intent.

Subsea Cable connects them.

Not by replacing existing languages—

but by giving them a common representation of programs.
