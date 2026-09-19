# Contributing to the Subsea Cable Language

Subsea Cable grows through independent implementations. Contributors are
expected to build Hosts and Runtimes in their own repositories, pressure the
language with real programs, and bring the resulting design evidence back here.

## What this repository accepts

- corrections and clarifications to the language specification;
- ANTLR/EBNF grammar changes kept in sync;
- valid and invalid conformance cases;
- reference algorithms that define language behavior without becoming a Runtime;
- philosophy and terminology corrections;
- Subsea Cable Proposals under `proposals/`;
- links to independently maintained ecosystem implementations.

## What this repository does not accept

- production Carousel, Host, Scheduler, or complete Vessel (Consumer Runtime)
  implementations;
- language-specific SDKs, adapters, registries, or deployment backends;
- framework integrations;
- policy implementations without an accepted language proposal;
- changes that make one implementation's convenience normative by accident.

Maintain those projects independently. This keeps the language neutral and
allows competing implementation strategies.

## If implementation work finds a missing concept

Do not silently implement a private semantic extension and present it as
Subsea Cable-compatible.

1. Preserve the smallest reproduction, original behavior, tests, and normalized
   traces in the implementation repository.
2. Write an implementation ADR there describing the issue and local options.
3. Decide whether the issue is an implementation-profile choice or a language
   design question.
4. For a language question, open a Draft Subsea Cable Proposal here using
   `proposals/TEMPLATE.md`; link the external ADR and evidence.
5. Keep the affected implementation path explicitly experimental or blocked
   while the proposal is undecided and while an approving decision awaits
   activation.
6. After an approving owner decision, prepare one activation pull request that
   updates the SCP to Accepted together with every affected specification,
   grammar, diagnostic, example, compatibility note, and conformance case.
7. Claim the behavior as Subsea Cable semantics only after that complete pull
   request merges. Proposal-only merges and owner approval without activation
   have no semantic effect.

An implementation may continue unrelated work. It must not hide the issue behind
a fallback, feature flag, permissive parser, Host special case, or undocumented
Scheduler default.

## Pull-request types

### Editorial

Clarifies wording without changing accepted programs or observable semantics.
State why behavior is unchanged.

### Conformance correction

Adds or fixes cases for already documented behavior. Identify the normative text
that supports every expected result.

### Language change

Requires a proposal. Include:

- motivating implementation evidence;
- the invariant under pressure;
- alternatives and rejected classifications;
- effect on philosophy and layer boundaries;
- grammar and semantic changes;
- compatibility impact;
- conformance additions.

### Ecosystem listing

Adds an external project to `ECOSYSTEM.md`. The project must identify its
supported Subsea Cable specification/profile and expose its own license, source, and
test status. Listing is not endorsement.

## Review standard

Every pull request is covered by `CODEOWNERS`. The protected `main` branch
requires the language owner's review, a passing `validate` check, and resolved
review conversations. Agents and external implementers may prepare evidence and
proposals, but they cannot merge new language behavior by themselves.

A maintainer bypass is reserved for repository recovery and owner-approved
changes. It still requires a pull request so the decision and diff remain
auditable.

A language-changing PR is reviewed in this order:

1. Does the problem have reproducible evidence?
2. Is it actually structure rather than Host or Scheduler behavior?
3. Does it preserve the separation of intent, implementation, and execution?
4. Can multiple languages and infrastructures implement it?
5. Does it preserve explicit value routing and occurrence ownership?
6. Does it preserve demand-time alias selection and already committed
   deductions?
7. Is the smallest compatible change proposed?
8. Are grammar, semantics, examples, errors, and conformance synchronized?

Passing one Runtime's tests is evidence, not sufficient proof of a good language
change.

## Required synchronization

When applicable, one activation pull request updates:

- `README.md`;
- `BRAND.md` when public naming, file extension, or identifiers change;
- `SubseaCable.g4`;
- `SubseaCable.ebnf`;
- `conformance/`;
- `METAPHORS.md` or `FOR_AGENTS.md` when concepts change;
- the proposal status to Accepted, its activation pull request and effective
  revision, and its final rationale and compatibility notes.

The status transition and every required projection must merge atomically. An
owner-approved proposal remains Discussion until this synchronization is
complete. See [Language Governance](GOVERNANCE.md#merge-decision-and-activation)
for the distinction between a merged record, a decision, and effective language.

Run all available conformance and grammar-generation checks. `git diff --check`
must pass.

## Documentation and publication

Repository Markdown, grammar, and conformance files are canonical because
agents are the first users of the language base. Documentation-site code may
render those files through an explicit route/navigation manifest, but it must
not introduce separately maintained copies of their content. A reader must be
able to understand and implement the language from a repository checkout
without building or browsing the website.

Website-only presentation, search, diagrams, and interactive explanations are
welcome when they preserve links back to the canonical source. Generated site
artifacts are not language authority.

Unless explicitly stated otherwise, contributions submitted to this repository
are provided under the [Apache License 2.0](LICENSE).

## No implementation ownership transfer

Opening a proposal or listing an implementation does not transfer maintenance of
that Host/Runtime to this repository. External maintainers own releases,
security, support, compatibility claims, and implementation ADRs.
