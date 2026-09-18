# Subsea Cable Manifesto

## The Function Was Never Meant To Carry The Program

For decades, programming languages have asked functions to do something they were never designed to do.

Functions are implementation units.

Yet today they are also responsible for expressing the dependency structure of entire programs.

Those are fundamentally different concerns.

---

As programmers, we naturally begin thinking in terms of function calls.

```
A()

↓

B()

↓

C()
```

Execution order becomes the program itself.

Eventually we stop asking a more important question:

**What is the structure of the problem?**

---

A program is not an execution trace.

A program is a structure of goals.

Execution is only one possible interpretation of that structure.

---

Subsea Cable exists to separate those ideas.

Programs describe goals.

Functions implement goals.

Schedulers decide execution.

No single layer should own all three.

The authored Program is a Voyage Plan. Inside the Vessel—the complete Consumer
Runtime—the Carousel realizes its Cable lazily: each demanded deduction
commits the artifact chosen for one occurrence and the structure produced by
its reduction rule. Human-readable aliases remain mutable for occurrences that
have not yet been deduced, while committed history stays fixed.

---

This is not about performance.

It is not about parallelism.

It is not about replacing existing languages.

Those are consequences, not motivations.

The motivation is much simpler.

Programs deserve a first-class representation independent of execution.

---

Imagine being able to serialize an entire program.

Visualize it.

Inspect it.

Transform it.

Reduce it.

Generate infrastructure from it.

Execute it on completely different runtimes.

Without rewriting business logic.

Without changing languages.

Without coupling execution strategy to implementation.

That is the purpose of Subsea Cable.

---

Subsea Cable is not another runtime.

It is not another virtual machine.

It is not another compiler.

It is a common representation of executable intent.

Programs should outlive schedulers.

Programs should outlive infrastructures.

Programs should outlive languages.

Subsea Cable is an attempt to make that possible.

Its visual short mark is `__C`; its source files use `.vyg`. The name remains
Subsea Cable.
