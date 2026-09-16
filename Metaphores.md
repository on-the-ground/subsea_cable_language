**Each metaphor corresponds to an actual Responsibility.**

---

# 🌊 The Subsea Cable World

## Surface

The world the user sees.

```text
Build User

Send Email

Publish Report
```

There is only Intent here.

No implementation,
no execution,
no parallelism yet.

Just

> **the top-level Goal.**

---

## Marine

This is the core.

**Marine = Program**

It is the space that contains the entire Goal DAG.

```text
Root Goal
   ├── Goal B ──┐
   └── Goal C ──┴── Shared Goal D
                         │
                  Grounded Leaves
```

This entire blue region

> **is the Program.**

A program is not a function.

A program is the space of Goals.

---

## Root

The very top.

What the user wants.

```text
Deploy Product
```

That's it.

There is only one Root.

---

## Seafloor

The world where Goals no longer exist.

Here, there are only **Concrete Leaves** — reference anchors and arrow-function
leaves belonging to named Goals.

A reference anchor names a **host function**, such as

```text
@read()
@send()
@insert()
@open()
```

In other words, these are no longer Goals.

They are host functions, supplied by a consuming language, reached through an Anchor.

Subsea has no native effects of its own — anything that touches reality is a host function behind an anchor.


---

# ⚓ Anchor

The point where a Leaf is bound to a **host function**.

```text
@placeholder
```

is a prime example.

An Anchor is always a reference to a host function — never a native effect and never a Subsea goal (those are reached by Goal import). It is opaque: never expanded, it inherits every active lineage that reaches it. This is where the Goal DAG touches reality.

---

# 🚢 Vessel

A Vessel is **the entity that unfolds the Program.**

Unrolls the cable(the program) down to the seafloor gradualy.

Its responsibilities are limited to

* Expansion
* Reduction
* Lazy Reduction
* TCO (future; see [Recursion.md](Recursion.md))
* Incremental Expansion

only, no evaluation at all.

---

# 🎠 Carousel

A Carousel is the part of the Program that has not yet been unfolded.

```text
██████████████████████░░░░░░░

Touchdown            Carousel
```

In other words, it is the unexpanded region of the Program.

---

# 🛬 Touchdown

Touchdown is not the creation of a program.

The Program exists from the start.

Touchdown is

> **the region where Reduction is complete.**

In other words,

it is the state where the reachable Leaves

has actually

touched the Ground.

---

# 🪢 Touchdown Cable

The part of the Program that has currently been fully expanded.

The Runtime can use it immediately.

---

# 🌊 Incremental Expansion

The Vessel does not unfold the entire Program at once.

```text
Carousel
↓
Unfold a little
↓
Touchdown
↓
Unfold a bit more
↓
Touchdown
```

It keeps expanding.

---

# ⚙ Scheduler

This is where many people get confused.

The Scheduler does not know the entire program.

The Scheduler only knows grounded evaluation instances: a shared structural
Goal node paired with routed arguments and active lineages.

```text
Leaf

↓

Sequential

↓

Parallel

↓

Distributed

↓

GPU
```

That is

the Scheduler's freedom.

---

# 🧭 Program

The most important metaphor.

A Program is not Code.
Not Instructions.
Not Function Calls.

A Program is the **Marine.**

That is, the terrain of Goals.

---

# 🌐 Language Generic

Subsea does not replace any language.

---

# 🏗 Infrastructure Generic

Program

↓

Custom Scheduler, eBPF, 

Programs in Subsea are deployable to any scheduler supports subsea.

---

# 📦 .subsea

This is not source code.
Not an IR.
Not Bytecode.
Not a VM.

This is a **Program Representation.**

---

# 🤯 And...

**The Program itself is the Subsea Cable.**

```text
Program
=
Subsea Cable
```

The Vessel unfolds it.

The Scheduler executes the unfolded Leaves.

The Anchor connects it to reality.

The Carousel is the Program not yet unfolded.

The Touchdown is the process by which the Program gradually makes contact with reality.

---

# 💥 The Most Important Sentence We Finally Arrived At

This could stand as the very first line of the README.

> **A program is not a sequence of function calls. A program is a Subsea Cable.**

And the sentence that follows completes the entire philosophy.

> **Functions implement goals. Schedulers execute goals. Subsea Cable represents goals.**

These three sentences tie together everything you have been talking about for months.

Functions return to implementation, Schedulers return to execution, and **the Program finally stands as an independent entity — "the Program itself."** That is the new layer `Subsea Cable` is trying to represent.
