# SCP-0003 — Explicit staging of value-producing calls

- Status: Accepted
- Author(s): Claude and Codex (agents) for on-the-ground
- Created: 2026-09-17
- Updated: 2026-09-17
- Requires owner decision: yes (Owner decision R3)
- External implementation ADRs: [subsea_cable_runtime `docs/decisions/0006-argument-position-call-staging.md`](https://github.com/on-the-ground/subsea_cable_runtime/blob/main/docs/decisions/0006-argument-position-call-staging.md)
- Evidence repositories/revisions: `on-the-ground/subsea_cable_runtime` Carousel POC; [language issue #2](https://github.com/on-the-ground/subsea_cable_language/issues/2)
- Supersedes: `draft-argument-position-call-staging.md`
- Superseded by: —

## Summary

Outside an arrow-function leaf body, a value-producing eager Goal call
`Goal(...)` or Anchor call `$anchor(...)` must occupy a direct structural
occurrence position. It may not be nested inside another Goal/Anchor argument,
policy argument, lookup key, operator operand, or ordinary value container.
Hidden evaluation dependencies are rejected as `InvalidStructuralContext`.

Primitive expressions such as `B[x + 1]` remain valid deduction-time value
expressions because they create no occurrence, Scheduler work, or effect.
Inside an arrow-function leaf body, nested `$anchor(...)` calls remain valid and
are evaluated by the Host as part of that one leaf; Subsea Goal calls remain
forbidden there.

## Motivation and reproduction

The source language admitted programs such as:

```subsea
C = (x) -> x + 1
D = [y] -> $d(y)
Root = [x] -> D[C(x)]
Root[1]

E = [x] -> D[$f(x)]
```

Deducing the enclosing `D[...]` occurrence needs a value that only a separate
Scheduler/Host evaluation can produce. The language did not say whether to
invent a preceding occurrence, keep a deduction open across evaluation, or
commit a placeholder. The external POC correctly froze both paths as
`UnsupportedByProfile` rather than silently choosing a topology.

## Existing invariant under pressure

- Deduction is one atomic commit with actual arguments.
- Carousel never evaluates grounded leaves.
- Host effects occur only in Scheduler-dispatched leaf evaluation.
- Dependency structure and value routing must be visible in source.
- Primitive evaluation during deduction is effect-free and creates no node.

## Classification

This is a structural-language question because it determines whether source
contains a visible dependency occurrence. It cannot be delegated to a Host or
Scheduler profile without allowing different Runtimes to materialize different
Goal graphs from the same valid source.

## Proposed specification

### Direct structural occurrence positions

Outside a function-arrow leaf, `Goal(...)` and `$anchor(...)` are valid only
when the call itself is the complete occurrence selected for one of these
positions:

- the direct body of a Goal arrow;
- one element of a serial or unkeyed parallel composition;
- one concrete branch of a resolving map.

Structure-valued ordinary lookup maps remain a separate unresolved proposal;
this SCP neither accepts nor rejects them.

Ordered `@policy` prefixes may decorate that occurrence. They do not make a call
nested.

Examples:

```subsea
Root = [x] -> C(x)
Root = [x] -> [C(x), D]
Root = [x] -> {left: C(x), right: $f(x)}
```

### Forbidden hidden calls

A structural value-producing call may not occur inside:

- a Goal or Anchor argument;
- a policy argument;
- an operator operand, including a short-circuit operand;
- a lookup key;
- an ordinary value Map or any other value container;
- the argument of another call.

These are validation errors of kind `InvalidStructuralContext`:

```subsea
D[C(x)]
D[$f(x)]
D[x + C(1)]
@policy(C(x)) D[x]
routes[C(x)]
```

Authors express the dependency as an explicit stage:

```subsea
[C[x], D]
[C(x), [v] -> D[v]]
[$f(x), [v] -> D[v]]
```

### Primitive expressions and function leaves

Effect-free primitive expressions remain valid wherever ordinary values are
accepted:

```subsea
A = [x] -> B[x + 1]
```

Inside a named function-arrow leaf, `$anchor(...)` may remain nested at any
value-expression depth. It is a Host call site within that already-grounded
leaf and does not create a Subsea occurrence. `Goal(...)` and `Goal[...]` remain
forbidden at every depth in a function leaf.

Boolean short-circuiting remains value evaluation. Outside function leaves its
operands cannot hide Goal or Anchor calls. Inside a function leaf, an Anchor in
an unselected right operand is not invoked.

## Alternatives

| Alternative | Benefits | Costs/reason rejected |
|---|---|---|
| Hoist nested calls automatically | Preserves source acceptance | Invents occurrence IDs and routing absent from source; selection and lineage become implicit |
| Keep deduction open in two phases | Avoids synthetic source stages | Breaks “deduction is the commit” and complicates replay and alias timing |
| Commit placeholders | Allows early topology | Deduction record lacks actual arguments and can expose failures after a false commit |
| Runtime-profile choice | Easy for each implementation | Same source produces incompatible structures |
| **Accepted: require explicit stages** | Preserves visible dependencies and atomic commits | Some previously valid source must be rewritten |

## Philosophy and boundary audit

- Structure remains explicit rather than manufactured by validation.
- Goal calls do not leak into function implementation.
- Policy metadata cannot hide an evaluation dependency in its arguments.
- Carousel commits structure, Scheduler dispatches leaves, and Host evaluates
  them; no layer crosses the boundary to obtain a nested argument secretly.
- Every unqualified Goal occurrence still resolves its alias on its own demand.
- Value routing is visible in serial stages or keyed maps.
- The restriction is portable and requires no coroutine or continuation model.

## Compatibility and migration

- Previously valid source affected: source with a Goal/Anchor call nested in a
  non-function value expression becomes invalid.
- Previously invalid source newly accepted: none.
- Stored artifact/hash impact: newly invalid source cannot be committed; already
  stored artifacts require validation/migration before use with this revision.
- Diagnostic impact: `InvalidStructuralContext` covers the forbidden positions.
- Migration strategy: extract each nested call into an explicit serial stage or
  resolving-map branch and route its result explicitly.
- Version/profile requirement: consumers must identify a language revision that
  includes SCP-0003 before claiming this restriction.

## Grammar and conformance impact

- `README.md`: defines direct call positions and migration examples.
- ANTLR/EBNF: parser productions remain unchanged; synchronized semantic
  comments describe the validation restriction.
- valid cases: direct eager Goal and Anchor stages remain valid; primitive
  arguments remain valid.
- invalid semantic cases: nested eager Goal and nested Anchor arguments produce
  `InvalidStructuralContext`.
- runtime cases: no staging behavior is required because invalid source never
  reaches deduction.

## Reference experiment

The external POC rejected both nested forms before run start and again guarded
against lazily loaded pre-revision artifacts. After this proposal, the former
profile refusal becomes a portable validation rule.

## Unresolved questions

None. Recursion and controlled data-dependent structural expansion remain
separate deferred topics.

## Owner decision record

- Decision requested on: 2026-09-17
- Maintainer/agent recommendation: option C — require explicit stages.
- Owner response: accepted
- Decision date: 2026-09-17
- Conditions: primitive expressions such as `B[x + 1]` remain valid; nested
  Host Anchor calls remain valid inside function-arrow leaf bodies.

## Final rationale

Subsea Cable is a structure language. If evaluation must happen before another
Goal can receive a value, that dependency belongs in the visible Cable. Requiring
an explicit stage preserves atomic deduction, occurrence identity, lineage, and
the Host/Carousel/Scheduler separation with the smallest rule.
