# Recursion — Deferred Design Notes

## Current Status

Recursion is not part of the current Subsea Cable language.

Direct self-reference and every form of mutual cycle in the binding dependency
graph are semantic errors. Forward references remain valid as long as the
resulting graph is acyclic.

This restriction is intentional. Recursion cannot be added as a local syntax
feature because it affects the identity, expansion, evaluation, and
observability of the entire Goal structure.

## Why It Is Deferred

Expansion is currently shared by `GoalNodeId`, the resolved Goal-definition
identity plus arity, while evaluation instances are distinguished by their
routed arguments. A Goal node may have multiple incoming edges and therefore
multiple lineage paths. Ordinary reduction extends each incoming lineage across
outgoing edges.

The current Program structure is a DAG. Enabling recursion would add a back-edge
to an existing Goal node and turn that DAG into a cyclic graph. Traversing such
a cycle naively would produce an unbounded lineage:

```text
Loop/1
Loop/1.Loop/1
Loop/1.Loop/1.Loop/1
...
```

A value-dependent base case also means that continued traversal can depend on
runtime data. That conflicts with definition-based structural expansion and
with the current separation between the Vessel, which never evaluates, and the
Scheduler, which sees only grounded evaluation instances.

## Questions That Must Be Resolved

### 1. Supported recursion forms

- Direct recursion only, or mutual recursion as well?
- May imported Goals participate in a recursive component?
- Are recursive edges limited to statically named Goals, or may imported Goal
  aliases participate? Function arrows remain terminal leaf implementations;
  they cannot carry or invoke recursive Subsea Goal structure.

### 2. Branching and termination

- What language construct selects the base case?
- Does selection depend on a runtime value?
- If a map or future conditional selects the branch, which layer performs that
  selection without collapsing expansion into evaluation?

### 3. Recursive Goal identity

- A back-edge can reuse an existing `GoalNodeId`; how is each logical recursive
  invocation distinguished from that structurally shared node?
- Does each traversal of the back-edge append another logical lineage segment,
  or is recursive lineage represented in a compressed form?

### 4. Expansion memoization

- Can `GoalNodeId` remain the complete structural expansion key in a cyclic
  graph?
- Does recursive expansion additionally need lexical environment or structural
  recursion context?
- Which data may influence expansion without making the Vessel evaluate values?

### 5. Evaluation identity

- How does the Scheduler distinguish recursive invocations with different
  argument values?
- When may two invocations share evaluation results?
- How are concurrent invocations, retries, and cancellation isolated?

### 6. Incremental expansion

- How much of a recursive structure may the Vessel unfold ahead of demand?
- What backpressure or depth boundary prevents unbounded expansion?
- Which component requests the next increment?

### 7. Tail-call optimization

- What is a tail position in a pipeline, resolving-map branch, and nested Goal
  arrow?
- Does TCO reuse an evaluation frame, a structural Goal node, or both?
- How is complete logical lineage retained for tracing when physical frames are
  reused?
- Is TCO guaranteed by the specification or merely permitted for a Vessel or
  Scheduler implementation?

### 8. Errors and resource limits

- How are non-terminating expansion and non-terminating evaluation reported
  separately?
- Are depth, step, time, or memory limits part of the language contract or a
  Scheduler policy?
- What lineage is attached to an error after optimized tail calls?

### 9. Serialization and observability

- How are recursive back-edges represented in inspection and visualization
  formats?
- How are logical call histories displayed when one shared Goal node has
  multiple lineages and a cycle may extend them without bound?
- Can a finite recursive structure be serialized without serializing runtime
  invocation history?

### 10. Determinism

- Must the same `GoalNodeId` always expand to the same recursive structure?
- How do runtime-dependent branches interact with replay, caching, distributed
  scheduling, and retries?

## Minimum Acceptance Criteria

Recursion should not be enabled until the specification provides:

1. A finite structural representation for recursive Goals.
2. A precise identity model for expansion nodes and runtime invocations.
3. A branching model that preserves the Vessel/Scheduler separation.
4. Defined memoization behavior for recursive and value-dependent structures.
5. Termination, cancellation, resource-limit, and error semantics.
6. A precise definition of tail position and the status of TCO guarantees.
7. Stable inspection and tracing semantics that retain logical lineage.
8. Conformance tests for direct recursion, mutual recursion, base cases,
   non-termination, incremental expansion, and tail calls.
