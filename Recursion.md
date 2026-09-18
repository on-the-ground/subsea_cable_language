# Guarded Conditional Recursion

## Status

Guarded direct and mutual Goal recursion is part of Subsea Cable under
[SCP-0005](proposals/0005-guarded-conditional-recursion.md). Unconditional
definition cycles, and recursive conditional components with no structural exit
branch, remain `CycleDetected`.

The governing distinction is:

```text
recursive definition graph  may contain a guarded cycle
realized occurrence Cable   remains a DAG
```

## Conditional deduction

A pure selector expression and a keyed branch map form one conditional
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

Carousel asks the Host primitive-semantics profile to evaluate `n == 0`, then
selects exactly one branch using ordinary normalized map-key rules. Only the
selected branch creates occurrences or performs demand-time observations. The
other branch remains authored structure and does not enter this voyage's
realized Cable.

The selector must be effect-free. Goal and Anchor occurrences or calls are
invalid inside it. If branching depends on an evaluated leaf result, an
enclosing Goal arrow first binds that explicit routed value and then uses it in
the conditional selector.

## Definition recursion is not an occurrence cycle

For input `2`, the example realizes:

```text
CountDown[2]
    -> CountDown[1]
        -> CountDown[0]
            -> Done[]
```

The occurrences may resolve to one shared `CountDown/1` `GoalNodeId`, but each
has its own occurrence identity, arguments, lineage, policies, alias observation,
and deduction record. A recursive reduction creates a fresh child occurrence;
it never points an edge back to the parent or another ancestor occurrence.

This preserves the directed acyclic occurrence graph while allowing the
definition reference graph to be recursive.

## Guard validation

Validation computes strongly connected components over local Goal-definition
references. A recursive component is accepted only when:

1. every cycle crosses a recursive reference located beneath a conditional
   branch map; and
2. that guarding map has at least one branch that leaves the recursive component
   without re-entering it.

The analysis proves the presence of a possible structural exit, not termination
for every input. These remain invalid:

```subsea
A = [] -> A[]                 // unconditional direct cycle
A = [] -> B[]
B = [] -> A[]                 // unconditional mutual cycle
```

A conditional whose every branch returns to the same recursive component is
also `CycleDetected` because it provides no exit.

## Non-termination

A valid guarded recursive voyage may still fail to select its exit. That is
ordinary non-termination, not a source or validation error. Carousel may pause
speculative unfolding at a declared deduction-work budget. Scheduler policy may
cancel or limit the voyage. Neither layer may fabricate a branch or rewrite a
committed deduction.

Subsea Cable does not require static termination proofs.

## Identity, aliases, and replay

Every recursive child follows the ordinary demand-time alias law. An unqualified
`Name/Arity` remains symbolic until that child occurrence is demanded. Two steps
of one recursion may therefore select different `ArtifactHash` values across an
alias update. Each selection and codebase revision is committed independently.

Replay uses those immutable deduction records. Incremental reuse under SCP-0004
also requires stable-slot alias and value observations for recursive segments;
it never edits an earlier voyage.

## Tail recursion

A Carousel may reuse physical frames or storage for a tail-recursive reduction,
but the optimization is invisible to language semantics. Logical occurrences,
lineages, deduction records, selected hashes, and Fully Touchdown Cable
provenance must remain equivalent to an unoptimized unfolding.

No tail-call optimization is required by the language.

## Conformance requirements

A conforming implementation covers at least:

- direct guarded recursion with an exit;
- guarded mutual recursion;
- exact-key and wildcard branch selection;
- unselected branches creating no occurrence or alias observation;
- fresh occurrence identity for every selected recursive step;
- an unconditional direct or mutual cycle remaining `CycleDetected`;
- a conditional recursive component with no exit remaining `CycleDetected`;
- non-termination stopped by an explicit Runtime budget or Scheduler action;
- demand-time alias changes across recursive steps; and
- replay and provenance of the selected branch sequence.
