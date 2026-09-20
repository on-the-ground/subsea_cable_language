# Evidence-Driven Policy Discovery

This document governs how a behavior observed during migration becomes a
Subsea Cable `@policy`. It prevents the first Runtime, Scheduler, Host, or source
framework from defining policy semantics by accident. Scheduler-addressed and
Host-addressed candidates follow the same evidence discipline, but they are
declared and interpreted by different addressees.

## 1. What exists before concrete policies

The language already guarantees:

- `@policy` attaches to exactly the following structural occurrence;
- stacked policies preserve source order;
- policy arguments are ordinary validated values;
- policy metadata does not change topology or routing;
- policies belong to occurrences/edges, never shared Goal definitions;
- erasing policies yields the same structural projection;
- the Runtime resolves each identifier against the pinned Scheduler registry and
  Host capability declaration;
- the resolved addressee alone owns policy-specific interpretation;
- eligibility, attempt lifecycle, and scope outcomes remain Scheduler-owned;
- policies never inherit or copy to descendant occurrences; and
- identifiers claimed by neither declaration are rejected explicitly.

Nothing else is assumed. In particular, there is no default addressee,
precedence, retry model, timeout clock, success rule, or unspecified
same-addressee composition rule.

## 2. Promotion stages

### Observed

One original program exhibits a behavior under a reproducible test or injected
fault. Record the behavior without assigning a final policy name.

### Candidate

The behavior survives classification as policy rather than structure, value
routing, or an Anchor contract. Classify its addressee: Scheduler-addressed when
it changes eligibility, the attempt lifecycle, or a scope outcome;
Host-addressed when it changes only what happens inside one grounded leaf
invocation. Define the smallest testable model and target. Open a proposed ADR.
Candidate status does not authorize implementation or language documentation
changes.

### Provisional

The external Runtime implements the candidate behind a versioned Scheduler
registry entry or Host capability declaration, according to its addressee.
Conformance cases cover success, failure, target scoping, erasure, and
unsupported combinations. Documentation clearly marks unresolved interactions.
Promotion to Provisional requires the owner's explicit acceptance of the ADR.

### Stable

At least two independent workloads require the semantics, or an accepted
external contract supplies equivalent evidence. The definition is portable
across implementation languages and across implementations of its declared
addressee.

## 3. Required policy specification

A Provisional policy document must state:

```text
Identifier and version
Motivating evidence
Addressee and declaration surface
Valid target occurrence kinds
Argument schema and validation
Observable state machine
Clock or attempt model, if any
Host outcomes consumed
Scheduler actions permitted (Scheduler-addressed only)
Host invocation behavior (Host-addressed only)
Result/failure exposed downstream
Cancellation behavior
Duplicate/replay behavior
Trace events and required fields
Unsupported combinations
Interaction with stacked policies
Policy-erasure invariant
Conformance cases
```

If any field is unknown, mark it unknown. Do not substitute framework defaults.

## 4. Minimality tests

Before accepting a Candidate, answer:

1. Can corrected Goal structure express the behavior?
2. Can explicit value routing express it?
3. Is it actually an Anchor signature or effect contract?
4. Is it merely a choice of the baseline Scheduler or Host capability profile?
5. Does it preserve the same policy-erased graph?
6. Can another implementation of the same addressee implement it without
   imitating the first Runtime's internal control flow?

A “yes” to 1–4 rejects or reclassifies the policy. A “no” to 5–6 rejects it as a
portable policy.

## 5. Naming rules

Name a policy after its portable contract, not the source framework mechanism.
Do not stabilize names such as a library annotation or middleware class unless
that name already denotes a broadly accepted semantic contract.

Policy identifiers remain ASCII. Versioning belongs to the policy registry or
profile contract; do not invent source syntax for versions without a separate
language decision.

## 6. Composition discipline

Stacking syntax records order but does not itself define composition. For each
pair used in an experiment, specify whether the combination is:

- supported with a defined nesting/order;
- commutative with evidence;
- rejected as `PolicyConflict`;
- unresolved and therefore unsupported.

Never infer that outer textual order means retry wraps timeout or timeout wraps
retry. Those are concrete composition semantics requiring evidence and tests.
Inheritance is not a candidate semantic: no policy becomes a child's policy.

## 7. Required tests

Every Provisional policy needs:

- target acceptance and rejection cases;
- argument validation cases;
- a happy-path trace;
- every evidenced failure path;
- cancellation and duplicate delivery cases when applicable;
- stacked-policy cases for every supported pairing;
- explicit rejection for unresolved pairings;
- policy-erasure graph equality;
- two identical Goal occurrences showing policy isolation by occurrence;
- unsupported-policy behavior proving it is never silently ignored.

## 8. Evidence quality

Strong evidence is, in descending order:

1. unchanged black-box original tests plus controlled fault injection;
2. documented public behavior of the migrated project;
3. multiple independent production-like examples;
4. explicit owner decision establishing a new contract;
5. implementation convenience.

Implementation convenience alone cannot promote a policy.

Any choice of policy target within the language's fixed constraints, state
machine, downstream outcome, stacking, or same-addressee conflict behavior is a
design decision. Descendant inheritance and cross-addressee precedence are not
available choices. The discovering agent must present evidence and a
recommendation, but the owner decides before that behavior is implemented.

## 9. Policy declaration layout

When the first Candidate exists, create a dedicated directory. Record whether
the identifier belongs to the Scheduler registry or the Host capability:

```text
policies/
  README.md
  <policy-name>/
    SPEC.md
    conformance/
    evidence/
```

Do not create placeholder policy specifications before evidence exists. The
absence of this directory initially is intentional.
