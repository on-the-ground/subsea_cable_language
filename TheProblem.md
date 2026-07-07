# The Problem

Modern programming languages ask functions to play two fundamentally different roles.

A function is supposed to describe **how** a piece of computation is implemented.

Yet, in practice, functions also become the primary mechanism for expressing **the dependency structure of a program**.

This conflates two independent concerns.

---

Because functions are treated as value transformations, programmers naturally think in terms of

```
request  → top-down
response → bottom-up
strict evaluation
```

Every function call is assumed to immediately invoke another computation and return its result.

As a consequence, the dependency graph of the problem becomes inseparable from the execution strategy chosen by the programmer.

---

However, these are fundamentally different things.

A program first describes **what goals exist** and **how those goals depend on one another**.

Only afterwards should a scheduler decide **how** those goals are executed.

When separated, the program itself becomes nothing more than a declarative dependency graph.

Execution order, evaluation strategy, parallelism, batching, cancellation, locality, and resource allocation become responsibilities of the scheduler—not of the program.

---

Once this distinction is made, programming changes fundamentally.

Instead of writing execution order, we describe goals.

Instead of manually orchestrating evaluation, we declare dependencies.

Instead of embedding scheduling decisions into business logic, we inject schedulers that implement different execution strategies.

The same program can then execute sequentially, in parallel, lazily, eagerly, locally, remotely, or in a distributed environment without changing its logical structure.

---

Subsea Cable is built on this separation.

Programs describe dependency structures.

Schedulers execute them.

A program is not an instruction sequence.

It is a cable waiting to be laid.
