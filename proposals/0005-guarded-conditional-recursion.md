# SCP-0005 — Guarded conditional recursion

- Status: Accepted
- Author(s): Codex (agent) for on-the-ground
- Created: 2026-09-18
- Updated: 2026-09-20
- Requires owner decision: yes
- External implementation ADRs: pending
- Evidence repositories/revisions: owner reproduction in the language design review
- Activation pull request: [#10](https://github.com/on-the-ground/subsea_cable_language/pull/10)
- Effective language revision: the commit on `main` produced by squash-merging PR #10
- Supersedes: the blanket rule that every recursive Goal-definition cycle is `CycleDetected`
- Superseded by: —

## Summary

Subsea Cable permits a pure selector expression followed by a keyed conditional
branch map as one structural pipeline:

```subsea
CountDown = [n] -> [
    n == 0,
    {
        true: Done[],
        false: CountDown[n - 1],
    },
]
```

Carousel evaluates the selector through Host primitive semantics and exposes
exactly the selected branch. Unselected branches create no occurrences and
perform no alias or value observations. A selected recursive branch creates a
fresh child occurrence; it does not add a back-edge to an earlier occurrence.

A recursive definition component is valid when every definition-level cycle is
guarded by such a conditional selection and the guarding map has at least one
branch that exits the recursive component. An unconditional cycle, or a
conditional cycle with no exit branch, remains `CycleDetected`.

Crossing any selected conditional branch edge is an explicit-demand boundary.
Carousel may commit the selection and expose the symbolic child, but speculative
replenishment MUST NOT demand or deduce it, whether or not local analysis
classifies the edge as recursive. This prevents both statically visible and late
alias-assembled recursive paths that have not yet published a Touchdown from
bypassing SCP-0001's backpressure indefinitely.

## Motivation and reproduction

The specification already says that ordinary lookup selection contributes only
the selected branch to resulting structure, but it simultaneously rejects every
direct or mutual Goal-definition cycle. It also restricts serial pipeline stages
to Goal structure, so the selector and branch map in the reproduction above do
not parse as a conditional structural stage.

Those rules confuse two graphs:

```text
definition graph:  CountDown -> CountDown
occurrence graph:  CountDown[2] -> CountDown[1] -> CountDown[0] -> Done
```

The first is recursive. The second is an acyclic realized Cable because every
selected recursive reduction creates a new occurrence. Rejecting the definition
cycle prevents the selective branch from ever reaching its exit and contradicts
the demand-driven occurrence model.

## Existing invariant under pressure

- A Voyage Plan currently rejects direct and mutual binding cycles.
- A serial pipeline currently accepts only Goal stages, not a pure selector
  expression followed by a conditional map.
- Ordinary map lookup is described as selective structural routing, but the
  binding and routing contract for structure-valued ordinary maps remains open.
- A realized Cable is a DAG of occurrences, while `GoalNodeId` may be shared by
  multiple occurrences with different arguments and lineages.

The last invariant supplies the correction: recursion reuses a resolved Goal
definition while creating fresh occurrences. It need not create a cyclic
occurrence graph.

## Classification

This is a language-level syntax, structural-semantics, identity, and diagnostic
decision. It cannot be implemented as Scheduler policy because branch selection
changes which Goal structure exists. It is not a Host Anchor contract because
the Host supplies only the pure selector operation; Carousel owns branch
selection, occurrence creation, and deduction commit.

## Proposed specification

### Conditional structural pipeline

The form is:

```text
[ selector-expression, conditional-branch-map ]
```

An optional trailing comma is permitted. The selector expression:

- is evaluated during deduction through the active Host primitive-semantics
  profile;
- may contain parameters, immutable values, ordinary value maps/lookups,
  literals, and primitive operators;
- must not contain a Goal occurrence, eager Goal call, Anchor occurrence, or
  Anchor call; and
- produces one Subsea-representable value used only as the branch key.

This pipeline has exactly two elements: the selector and its branch map. To
continue serially after the selected branch, nest the conditional pipeline as
one stage:

```subsea
[
    [selector, {true: Left[], false: Right[]}],
    Next,
]
```

`[selector, {true: Left[], false: Right[]}, Next]` is a syntax error. A bare
uppercase Goal name is not a value selector; unless a value binding of that
name exists, value lookup reports `UnboundName`.

The conditional branch map:

- is contextual structure, not an ordinary map value and not a resolving map;
- contains one or more keyed Goal-structure branches;
- uses ordinary normalized key identity, exact-match precedence, and optional
  `_` fallback;
- selects exactly one branch or reports `KeyNotFound` in the existing phase;
  and
- exports the selected branch's output state.

Every branch is structurally validated, but only the selected branch creates
occurrences, resolves aliases, observes values, carries its occurrence policies
into the realized Cable, or contributes Touchdowns. The selector expression
creates no Goal occurrence or Scheduler work.

The conservative value barrier applies before branch selection. If evaluation
of the selector requires an unresolved routed value, the containing deduction
MUST remain uncommitted: no key is selected, no branch occurrence or alias/value
observation is created, and no placeholder is stored. Explicit demand reports
`DeductionBlocked(pendingValue)`; speculative consideration reports the
corresponding `PrefetchBlocked` reason. Selection occurs atomically only after
the required value is resolved.

The conditional pipeline may appear wherever Goal structure is permitted,
including as a Goal-arrow body or a serial/parallel stage. It receives no
implicit upstream value. To branch on an upstream value, an enclosing Goal
arrow must bind that value explicitly.

### Guarded recursive definitions

Validation computes strongly connected components over local Goal-definition
references. A component is accepted as guarded recursion only when:

1. every cycle through the component crosses at least one recursive reference
   located inside a conditional branch; and
2. each conditional map used as that guard has at least one branch whose
   reachable local Goal references leave the component without re-entering it.

The exit need only be structurally possible. Validation does not prove that a
particular input reaches it or that the voyage terminates.

An SCC that does not satisfy both rules remains `CycleDetected`. This preserves
the existing diagnostic for unconditional structural cycles while permitting
direct and mutual guarded recursion.

Local SCC analysis cannot see cycles introduced later by Codebase alias
selection. When a Goal resolves to a `GoalNodeId` already present on that
occurrence's ancestor chain, Carousel MUST inspect the intervening
root-to-child segment before committing the new occurrence:

- if the segment contains at least one committed conditional branch selection,
  the re-entry is guarded, MUST NOT be rejected as `CycleDetected`, and uses a
  fresh occurrence if deduction otherwise succeeds;
- if the segment contains no committed conditional branch selection and the
  occurrence was explicitly demanded, deduction fails atomically with
  `CycleDetected`;
- if the segment contains no committed conditional branch selection and the
  occurrence was reached by speculative replenishment, Carousel abandons that
  path without committing an occurrence and without reporting a diagnostic,
  leaving the classification to the later explicit demand.

This rule applies to unqualified aliases and any other cycle that could not be
classified from the local definition graph. It detects a late unguarded cycle
without reverting to the blanket “same `GoalNodeId` means cycle” rule that
would reject every valid recursive step. Keeping the diagnostic itself at
explicit demand matters for portability: a speculative `CycleDetected` would
let two Runtimes with different prefetch targets disagree about whether the
same voyage fails, since a path that is never demanded never has to be
classified. A selected guard still does not prove termination.

### Deduction and identity

When a recursive branch is selected:

- Carousel creates a fresh child occurrence with its own `occurrenceId`,
  arguments, lineage, policies, and deduction record;
- the unqualified Goal reference remains symbolic until that child is demanded;
- the child may resolve to the same `GoalNodeId` as an ancestor without becoming
  the same occurrence;
- the committed edge points from the parent occurrence to the new child, never
  back to the ancestor occurrence; and
- later alias changes affect only still-undeduced recursive occurrences.

Every child selected through a conditional branch is a demand boundary.
Publishing or exposing that symbolic child does not authorize Carousel to
deduce it while replenishing the Touchdown window. The Scheduler MUST issue
explicit demand for the child, whether or not local analysis classifies the edge
as recursive. One recursive step then commits normally and may expose the next
symbolic child.

The realized occurrence graph therefore remains a DAG. Definition recursion is
not represented as an occurrence back-edge.

Each selected recursive step is an ordinary atomic deduction. Earlier records
remain immutable. Fully Touchdown Cable order follows the committed structural
occurrence order established by SCP-0004.

### Non-termination and bounds

Failure to reach an exit branch is not a validation error. It is observable
non-termination or resource exhaustion of a voyage. Because speculative
replenishment MUST stop at every selected conditional child, only an explicit
sequence of Scheduler demands can continue an unbounded recursive path,
including one assembled by late alias resolution. Scheduler cancellation or an
explicit Runtime deduction-work budget may stop that sequence. No layer may
fabricate an exit, retarget a committed occurrence, or classify non-termination
as `CycleDetected` after valid guarded recursion has begun.

The mandatory conditional-branch demand boundary is the portable safety rule.
Runtime budgets remain additional profile safeguards; this SCP defines no
portable numeric default or new budget-exhaustion diagnostic.

Tail-recursion optimization is permitted only if all logical occurrences,
deduction records, lineages, and Cable provenance remain observable as though no
physical frame reuse occurred. It is not required by this SCP.

### Selector provenance and incremental reuse

The selector result is a value observation of the containing conditional
occurrence under SCP-0004. Provenance MUST assign it a stable value slot and
record its canonical value digest together with the active Host primitive
profile. A selected branch segment is reusable in a later voyage only when that
slot's digest and all other SCP-0004 identity inputs match. Equal selected keys
alone are insufficient: two distinct selector values may choose the same `_`
fallback while representing different deduction evidence.

Every `ConditionalBranchSelected` trace event MUST carry at least:

```text
occurrenceId
selectorValueSlot
selectorValueDigest
selectedKey
primitiveProfile
```

The raw selector value may be redacted, but the canonical digest, selected
normalized key, and primitive profile remain auditable. Unselected branches
contribute no selector or branch-local value observations.

## Alternatives

| Alternative | Benefits | Costs/reason rejected |
|---|---|---|
| Reject all definition cycles | Simple finite validation | Confuses shared definitions with occurrences and prevents conditional escape |
| Permit every recursive definition | Minimal validation | Admits accidental unconditional structural cycles without an explicit branching boundary |
| Apply the demand boundary only to locally classified recursive edges | Preserves prefetch through visibly non-recursive selections | Late alias resolution can turn such an edge into recursion after speculative occurrences have already committed |
| Require static termination proof | Strong termination guarantee | Undecidable in general and unlike ordinary programming-language behavior |
| Use a Scheduler `@loop` policy | Avoids syntax changes | Topology and routed arguments would be hidden in execution policy |
| Use an Anchor for the loop | Easy to implement | Hides dependency structure and defeats Carousel deduction/provenance |
| Make no language change | No migration | Leaves the intended program invalid and the selective-routing model inconsistent |

## Philosophy and boundary audit

- Conditional selection is structure because it determines which occurrence
  exists; it is not Scheduler policy.
- Host primitive semantics computes the selector value but cannot choose or
  commit Goal topology.
- Carousel selects the branch and commits each new recursive occurrence.
- Scheduler remains responsible for evaluation eligibility, cancellation,
  attempts, and policies.
- Function leaves remain terminal and cannot call Subsea Goals.
- Policy erasure preserves the same selected topology when artifact, arguments,
  and primitive results are held constant.
- Unqualified recursive aliases remain lazy per occurrence, and completed
  deductions remain immutable.
- Branch input routing is lexical and explicit; the conditional map receives no
  implicit value other than its selector key.

## Compatibility and migration

- Previously valid source affected: none.
- Previously invalid source newly accepted: conditional structural pipelines
  and guarded direct or mutual Goal recursion.
- Stored artifact/hash impact: conditional pipelines and guarded recursive terms
  require a new language/profile revision and new authored/structural hashes.
- Diagnostic impact: `CycleDetected` narrows to unguarded definition cycles and
  late ancestor re-entry with no intervening conditional selection; valid
  guarded recursion no longer reports it.
- Migration strategy: replace hidden Host loops or recursion with an explicit
  selector and branch map when the dependency structure should be visible.
- Version/profile requirement: consumers must advertise SCP-0005 support.

## Grammar and conformance impact

- `README.md`: define conditional structural pipelines and guarded recursion.
- ANTLR/EBNF: add a selector-expression plus conditional-branch-map alternative
  to serial pipeline syntax.
- valid cases: direct countdown recursion, mutual guarded recursion, exact and
  wildcard branch selection, and nested continuation after a conditional stage.
- invalid semantic cases: unconditional direct/mutual cycles, recursive
  conditional maps with no exit, an apparent exit that re-enters its component,
  effectful selectors, uppercase Goal names used as value selectors, and
  statically evident `KeyNotFound` without `_`.
- Runtime cases: selected-branch-only occurrence creation, fresh recursive
  occurrence identity, explicit demand at every conditional branch edge, dynamic
  ancestor-chain cycle detection, unresolved-selector value barriers,
  selector-value reuse fingerprints, and immutable deduction records.

## Reference experiment

The existing external POC blocks structure-valued selection and recursion. It
must add this path only after pinning the owner-confirmed language revision.
The first experiment should reproduce countdown, mutual guarded recursion, an
unselected missing alias, and a deliberately non-terminating input under a
deduction-work budget. Its current same-`GoalNodeId` ancestor check must be
replaced by the intervening-conditional-selection rule, and replenishment must
yield at every selected conditional child until explicit demand arrives.

## Unresolved questions

- A portable default deduction-work budget and its diagnostic remain a
  Runtime-profile question; the conditional demand boundary does not depend on
  either.
- A future SCP may standardize compressed recursive lineage display; the full
  logical lineage remains normative meanwhile.
- General reusable structure-valued ordinary map bindings remain separate from
  this contextual conditional-map form.

## Owner decision record

- Decision requested on: 2026-09-18
- Maintainer/agent recommendation: accept contextual conditional pipelines and
  distinguish guarded definition recursion from occurrence cycles
- Owner response (accepted core): recursive structure must be permitted when a
  child branch map provides a possible exit; the conditional countdown form
  must not be rejected as a compile-time cycle
- Decision date: 2026-09-18
- Conditions on accepted core: selected branches alone enter the realized
  structure; recursive steps create fresh occurrences so the realized Cable
  remains a DAG
- Accepted in full on 2026-09-20: every item below was confirmed after the PR #6
  review rounds and is now normative in `README.md`, `Recursion.md`,
  `implementation/RUNTIME_CONTRACT.md`, `conformance/DEDUCTION.md` §§9–15 and
  `conformance/cases.tsv`
- Previously pending, now confirmed: local SCC/exit analysis, the ancestor-chain
  late-cycle rule, selector purity and value barriers, explicit demand at each
  selected conditional branch edge, selector trace/reuse fields, and concrete
  conformance cases

## Activation record

- Canonical documents synchronized: `README.md`, `Recursion.md`, `implementation/RUNTIME_CONTRACT.md` §2.2, `AGENTS.md`, `FOR_AGENTS.md`
- Grammar projections synchronized: `SubseaCable.g4` and `SubseaCable.ebnf` carry the conditional-pipeline production, activated with the core in PR #6; this pull request adds no production change
- Diagnostics and examples synchronized: `CycleDetected`, `KeyNotFound` and `UnboundName` wording for conditional positions in `README.md`
- Conformance cases synchronized: `conformance/DEDUCTION.md` §§9–15, `conformance/cases.tsv`, and the conditional fixtures
- Compatibility and migration notes synchronized: SCP compatibility section; no previously valid source changes meaning
- Verification commands and results: `python .github/scripts/validate_scp_activation.py` passes; `python .github/scripts/test_validate_scp_activation.py` passes; `mkdocs build --strict` passes; every markdown link resolves and every `conformance/cases.tsv` path exists

## Final rationale

The detailed contract remains in Discussion. Its accepted core rationale is
that Subsea Cable deduces occurrences, not a static definition graph. A
recursive definition guarded by selective structure can unfold into a finite or
infinite sequence of fresh occurrences without ever creating a cyclic realized
Cable. Rejecting that definition solely because its name recurs discards the
language's central distinction between shared Goal identity and occurrence
identity.
