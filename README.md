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

## Reduction Preserves Lineage

Reduction is not substitution.

When a goal is reduced, its own name is carried onto every sub-goal as a qualified prefix.

```
CreateOrder = [userId, orderInfo] ->
    [ GetUserInfo[userId], (userInfo) -> RegisterOrder[userInfo, orderInfo] ]

CreateOrder[10, {...}]
```

reduces to

```
[ CreateOrder.GetUserInfo[10],
  (userInfo) -> CreateOrder.RegisterOrder[userInfo, {...}] ]
```

not to a bare `GetUserInfo` / `RegisterOrder`.

The prefix accumulates transitively, so every leaf that reaches the seafloor carries its full ancestry—its position in the goal tree.

Prefixing applies to the reduced goal, whether reduction is deferred (`[]`) or immediate (`()`); the bracket only decides timing. It does not apply to values—function parameters like `(userInfo)`, map values, or literals—which are lexically scoped and inherit the enclosing goal path implicitly.

---

## A Path Is a Structure, Not an Address

A goal path is a logical lineage, not a unique address.

Two occurrences of the same goal under the same parent share the same path. That is deliberate.

The path identifies a reduction structure, so a goal path is expanded once and structurally shared. Arguments flow in only at evaluation time.

```
Expansion   → memoized by path        (Vessel)
Evaluation  → distinguished by value  (Scheduler)
```

This is the same expansion/evaluation split, seen from the naming side.

---

## Leaves

Reduction bottoms out in exactly two kinds of leaf.

* an arrow function
* a reference anchor

An anchor, written `@`, always refers to a host function—an implementation provided by a consuming language.

Subsea Cable has no native effects of its own. Anything that touches reality is a host function behind an anchor.

```
@send
@"registry.example.com/pkg/Join@1.2.3"
```

An anchor is opaque. It is never expanded. It only inherits the goal path it sits under.

---

## Names, Anchors, and Imports

There is only one naming law, and it is positional.

Whatever sits immediately before `[...]` is read by case.

```
Something[...]   uppercase → a Task (Goal)
something[...]   lowercase → a map
```

Nothing else in the language depends on case.

An alias binds a name to a location string. The alias itself never carries `@`.

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
Add = @plus                   forbidden — a leaf disguised as a goal
```

A goal must map to a reduction structure, never directly to a leaf.

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
