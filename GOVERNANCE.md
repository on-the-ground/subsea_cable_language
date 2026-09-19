# Language Governance

## Purpose

This repository governs the Subsea Cable language, not its implementations. Its
job is to preserve a coherent language base while independent Vessels and the
Carousels, Hosts, and Schedulers they carry explore different ecosystems.

The repository contains:

- philosophy and architectural boundaries;
- source language and structural semantics;
- grammar and lexical rules;
- stable diagnostics and conformance cases;
- accepted language proposals;
- implementation-neutral consumer contracts and methodology.

Runtime code remains external.

## Sources of language authority

| Area | Canonical source |
|---|---|
| philosophy and boundaries | `MANIFESTO.md`, `TheProblem.md`, `METAPHORS.md` |
| public naming and mark usage | `BRAND.md` |
| structural semantics and usage | `README.md` |
| executable syntax | `SubseaCable.g4` |
| neutral grammar projection | `SubseaCable.ebnf` |
| observable acceptance/errors | `conformance/` |
| design history | accepted records in `proposals/` |

If these disagree, the conflict is a design issue. Implementations must not pick
a winner silently.

## Roles

### Language maintainers

Maintain coherence, review proposals against the design philosophy, decide
proposal status, and ensure normative projections stay synchronized.

### Implementers

Build and maintain external consumer/Host/Runtime projects, publish supported
profiles, retain implementation ADRs, and contribute evidence and proposals.

### Contributors

Improve specification, grammar, conformance, explanations, and proposals without
assuming responsibility for external implementations.

One person or agent may occupy multiple roles, but the artifacts and decisions
remain separated.

## Proposal process

Substantial language changes use a Subsea Cable Proposal (SCP), analogous to a
PEP. The proposal lives under `proposals/NNNN-short-name.md` and uses
`proposals/TEMPLATE.md`.

Statuses:

- **Draft** — evidence and design are being developed;
- **Discussion** — sufficiently complete for focused review;
- **Accepted** — the owner's decision has been incorporated into every affected
  canonical projection and conformance case, and the activating pull request
  has merged;
- **Rejected** — considered and declined, with reasons retained;
- **Deferred** — valid question lacking evidence or current need;
- **Withdrawn** — author no longer proposes it;
- **Superseded** — replaced by another SCP.

Workflow:

1. An external implementation records a local ADR and reproduction.
2. A Draft SCP is opened here and links that evidence.
3. Review first classifies the problem: structure, value, Anchor, Scheduler
   profile, policy, or deferred feature.
4. The author presents alternatives, recommendation, compatibility, and
   conformance effects.
5. Language maintainers request the owner's design decision where required and
   record its exact scope, rationale, conditions, and date in the SCP.
6. An approving owner decision does not by itself make the SCP Accepted. While
   integration is pending, the SCP remains Discussion and no implementation may
   present the proposed behavior as standard Subsea Cable.
7. The activation pull request synchronizes the SCP, every affected canonical
   source, compatibility and migration notes, diagnostics, examples, and
   conformance cases. It also changes the SCP status to Accepted and records the
   activation pull request and effective language revision. Before merge, the
   latter may be written as "the commit produced by merging PR #NN"; that
   reference identifies the exact revision once the pull request merges.
8. The SCP becomes Accepted, and its behavior becomes effective language, only
   when that complete activation pull request merges. A merge that leaves an SCP
   Draft or Discussion records design work only and has no semantic effect.

### Merge, decision, and activation

These are deliberately separate events:

- **Merge is a record.** Merging a Draft or Discussion SCP preserves the
  proposal, evidence, and review history. It neither approves nor activates the
  proposed language behavior.
- **Owner approval is a decision.** It authorizes a precisely scoped direction
  for integration. The decision is recorded in the SCP, which remains
  Discussion until activation.
- **Accepted is effective.** The only pull request that may change an SCP to
  Accepted is the activation pull request containing all applicable canonical
  and conformance changes. Acceptance and effectiveness begin at that pull
  request's merge commit.

The activation change must be atomic from `main`'s perspective: the status
change to Accepted must not merge before or after its required normative and
conformance projections. If an SCP was previously merged for discussion, the
activation pull request updates that same SCP alongside those projections.

If the owner approves only part of an SCP, the approved scope must be separated
from pending normative questions before activation. Move the pending portion to
a follow-up Draft or Discussion SCP, or keep the entire original SCP in
Discussion. An Accepted SCP may identify future extensions, but it must not mix
its effective contract with undecided requirements inside that contract.

An SCP is a decision and design-history record, not a substitute for the
canonical sources listed above. If an Accepted SCP and a canonical projection
disagree, that is a repository defect; implementations follow neither silently
and must report the conflict. The effective revision recorded in the SCP is the
first revision at which implementations may claim the new behavior as Subsea
Cable semantics.

Proposal discussion may use prototype implementations, but prototypes remain in
external repositories.

## Decision principles

Proposals are judged by these invariants:

- Subsea represents structure and intent, not a mandatory execution strategy.
- Goal composition remains distinct from function implementation.
- Scheduler policy does not rewrite dependency topology.
- Host Anchors remain explicit boundaries to externally resolved implementation.
- value routing is explicit; implicit expansion is rejected.
- shared Goal identity, occurrence identity, lineage, and evaluation remain
  distinct.
- unqualified `Name/Arity` occurrences remain symbolic until their own demand;
  every completed deduction is an immutable commit.
- syntax must remain portable across consumer languages and infrastructures.
- real implementation evidence outranks hypothetical convenience, but one
  implementation does not define the language.

Maintainers may reject a useful feature if it belongs in an external Runtime
profile rather than the language.

## Compatibility

Every accepted semantic proposal must state:

- whether previously valid source changes meaning or becomes invalid;
- whether previously invalid source becomes valid;
- artifact/hash and stored-codebase implications;
- diagnostic changes;
- migration guidance;
- implementation and conformance version requirements.

Until an explicit versioning proposal is accepted, implementations must publish
the exact language revision/commit and Runtime profile they support rather than
claiming unqualified compatibility.

## External implementation policy

There is no official Carousel, Host, Scheduler, or complete Vessel in this
repository.
External projects own their code, releases, security, licensing, support, and
implementation-specific behavior.

The language project may list them in `ECOSYSTEM.md`, cite their experiments, and
accept proposals derived from them. Listing, proposal acceptance, or conformance
claims do not transfer maintenance and do not make an implementation official.

Competing implementations are desirable. Disagreement should become evidence,
ADRs, and proposals—not hidden dialects presented under one compatibility label.
