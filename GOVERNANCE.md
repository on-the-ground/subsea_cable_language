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
- **Accepted** — approved language direction, pending or including normative
  changes;
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
5. Language maintainers request the owner's design decision where required.
6. No semantic implementation is treated as standard before acceptance.
7. Acceptance is completed by synchronized normative text, grammar, and
   conformance changes.

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
