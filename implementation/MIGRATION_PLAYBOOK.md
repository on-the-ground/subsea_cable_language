# Real-Program Migration Playbook

This playbook turns one existing open-source program slice into a controlled
Subsea Cable experiment. Its purpose is to test the language boundary and discover
policies, not to rewrite an entire application.

## 1. Select the target deliberately

Choose a repository and one bounded slice with:

- a license that permits inspection, modification, and test execution;
- a reproducible test command;
- a public entrypoint with observable input/output or effects;
- dependency/orchestration logic substantial enough to model;
- replaceable external dependencies or useful test doubles;
- a size that one agent can understand and migrate completely.

For the first experiment, prefer deterministic local code. Avoid GUI workflows,
large distributed deployments, timing-sensitive integration suites, and code
whose tests require unavailable credentials. Later experiments should
deliberately add parallelism, effects, failure, cancellation, and recovery.

Record why the target adds a failure model not already covered by prior
experiments.

## 2. Establish the untouched baseline

Before migration:

1. pin the exact upstream repository revision;
2. record language/toolchain versions;
3. run the original tests without modification;
4. record pass/fail/skip counts and duration;
5. identify nondeterministic or environment-dependent tests;
6. retain the command and raw result as evidence.

Do not begin from an already failing baseline unless the failure is fully
explained and outside the selected slice.

Classify tests:

- **black-box behavioral** — must remain unchanged whenever possible;
- **contract/integration** — preserve assertions, adapters may change;
- **white-box structural** — may require adaptation because the implementation
  shape intentionally changes;
- **unusable** — requires unavailable infrastructure; document, never silently
  drop.

## 3. Draw the original behavior map

Read the selected entrypoint and its transitive orchestration. Produce a table:

| Original construct | Inputs | Outputs/effects | Dependency | Failure behavior | Initial classification |
|---|---|---|---|---|---|
| function/call/site | values | value/effect | before/after/independent | observed/unknown | structure/leaf/candidate |

Do not classify every function as a Goal. A Goal is structural intent. Pure
implementation detail belongs inside a leaf. Conversely, do not leave ordering,
fan-out, fan-in, routing, retry loops, or fallback selection hidden inside a
large leaf.

Initial classifications are:

- **Goal structure** — dependency or decomposition visible to Subsea;
- **value expression** — small routing-time computation using Host primitive
  semantics;
- **arrow-function leaf** — inline Subsea body evaluated by the Host;
- **Host Anchor** — opaque named capability resolved and invoked by the Host;
- **policy candidate** — execution behavior that does not change topology;
- **unsupported/unclear** — requires an explicit design review.

## 4. Create the Subsea structural model

Model the happy-path dependency structure before adding policy semantics.

Required checks:

- every serial edge represents a real data or ordering dependency;
- every parallel product contains genuinely independent occurrences;
- upstream values are routed explicitly;
- parallel results needed downstream use resolving keys;
- unkeyed parallel results are intentionally discarded;
- function arrows remain named terminal Goal implementations;
- `$Anchor` leaves correspond to focused implementations or effects;
- no arrow function appears as intermediate structure;
- repeated Goal occurrences and shared nodes remain distinguishable.

Maintain an Anchor inventory:

| Anchor | Arity | Input contract | Output contract | Effect boundary | Original source location |
|---|---:|---|---|---|---|

At this stage, an original retry/timeout/fallback loop may be recorded as an
unresolved behavior. Do not immediately turn its framework name into `@policy`.

## 5. Preserve the original test entrypoint

Build a thin adapter so the original public entrypoint invokes the external
Subsea Runtime and returns the expected public result. Keep black-box tests
unchanged.

The adapter MAY:

- translate public inputs to Subsea values;
- select or instantiate the Root input;
- register focused Host Anchors;
- translate the final result or error to the public API.

The adapter MUST NOT:

- reproduce the dependency graph in host-language control flow;
- catch failures and implement hidden retry/fallback policy;
- invoke the old orchestrator behind a single Anchor;
- fabricate a result solely to satisfy an assertion;
- discard policy or lineage metadata.

## 6. Run the happy-path differential test

Run the unchanged behavioral suite against both paths when practical:

```text
original entrypoint ─┐
                    ├─ same inputs → compare results and observable effects
Subsea adapter ──────┘
```

Compare more than return values:

- externally visible effects and their payloads;
- effect ordering where the original contract exposes it;
- number of invocations when observable;
- error category and public shape;
- selected branches;
- Runtime structural and execution traces.

Timing equality is not required unless time is part of the original contract.

Classify every mismatch before changing code:

1. translation or adapter defect;
2. wrong Subsea structure/routing;
3. wrong Anchor contract;
4. baseline Scheduler profile difference;
5. policy candidate;
6. structural-language gap.

Fix categories 1–3 first. Do not use a policy to conceal a structural mistake.
If a correction would alter the language contract or a component-ownership
boundary, stop that path and use the design-decision procedure in
`implementation/README.md`; do not fold the correction into the migration.

## 7. Add controlled fault injection

Happy-path equivalence is necessary but insufficient. Inject faults at stable
Host boundaries while reusing the original assertions or adding parallel
contract tests with the same public API.

Minimum matrix:

| Injection point | Questions |
|---|---|
| before leaf start | Is work retried, skipped, or propagated? |
| after effect, before return | Can the effect be duplicated? How is it identified? |
| after success, before acknowledgement | Is completion replayed or lost? |
| one parallel branch delayed | Does another branch proceed? What waits? |
| one parallel branch failed | What does the original consider sufficient? |
| duplicate invocation/completion | Is coalescing or idempotency expected? |
| cancellation before/during work | Which occurrences observe it? |
| crash at recorded frontier | What can resume from the deduction ledger without rewriting committed deductions? |

The original program may have no explicit answer. Record “unspecified” rather
than inventing one. A Subsea policy is justified only by an observed requirement
or an explicitly accepted new contract.

## 8. Decide whether the gap is really policy

A behavior is a policy candidate only when all are true:

- removing the behavior leaves the same Goal topology and routing;
- it applies to a specific structural occurrence or composite occurrence;
- the Scheduler can enforce it using grounded occurrence information and Host
  outcomes;
- it does not require Carousel to inspect future execution results and create
  new undeclared structure;
- it can be described without referring to the source framework's private API.

Examples that are usually structure, not policy:

- “run B only after A's value”;
- “run C and D independently”;
- “combine two named branch results”;
- “choose a map branch by a computed key.”

Examples that may be policy after evidence:

- retrying one occurrence under a defined failure class;
- imposing a deadline on a composite occurrence;
- controlling duplicate delivery or completion acknowledgement;
- deciding what upstream outcome satisfies a dependent occurrence.

## 9. Keep an evidence ledger

For each gap or policy candidate, record:

- source repository and pinned revision;
- original source location;
- original test or fault-injection reproduction;
- original observable behavior;
- Subsea structural occurrence targeted;
- classification and rejected alternative classifications;
- smallest proposed semantics;
- effect on output, effects, trace, and failure;
- interaction questions deliberately left open.

Use `EXPERIMENT_TEMPLATE.md`. Evidence must be reproducible by another agent.

If the gap admits more than one reasonable language or architectural answer,
the experiment does not choose. Open a proposed ADR, mark the gap
`owner-decision-required`, and ask the owner with a concrete recommendation and
tradeoffs. The experiment may resume that path only after the decision is
recorded.

## 10. Finish the iteration

An iteration is complete only when:

- the original baseline is recorded;
- selected behavioral tests pass through the Subsea adapter;
- all test changes are classified and justified;
- the Subsea program and Anchor inventory are saved;
- fault matrix results and normalized traces are saved;
- every gap has one owner layer;
- policy candidates follow `POLICY_DISCOVERY.md`;
- conformance tests cover every accepted language/runtime correction;
- no unresolved behavior is hidden inside an Anchor or adapter.
- every design issue has a proposed ADR and, where required, an explicit owner
  decision rather than an implicit implementation choice.

## 11. Review traps

Reject the migration as evidence if any of these occurred:

- a whole subsystem was wrapped as one Anchor;
- the adapter retained the original sequencing or concurrency logic;
- tests passed only because assertions were weakened;
- retries or timeouts remained inside leaf implementations without being
  recorded;
- one framework-specific annotation was copied directly into Subsea policy;
- Scheduler behavior was described as language semantics;
- only success paths were tested;
- a discovered structural-language gap was mislabeled as policy to avoid a
  language decision.
