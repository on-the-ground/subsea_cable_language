# Agent Instructions

Agents are the first users of this repository. Treat the repository Markdown,
grammar, and conformance files as the canonical, directly consumable knowledge
base. A documentation website may index, arrange, or render these sources, but
must not move the authoritative content into a website-only format, introduce a
second editable copy, or make understanding the language depend on a site build.

Before implementing a Subsea Cable consumer/runtime, read these files in order:

1. `README.md` — normative structural semantics.
2. `METAPHORS.md` — the precise Cable, Sea, Carousel, deduction, and Touchdown
   model.
3. `SubseaCable.g4` and `SubseaCable.ebnf` — executable and neutral grammar.
4. `conformance/README.md` — preprocessing and conformance requirements.
5. `implementation/README.md` — phased execution strategy and completion gates.
6. `implementation/RUNTIME_CONTRACT.md` — component boundaries and mandatory
   runtime behavior.
7. `implementation/CAROUSEL_ENGINE_PLAN.md` — the owner-directed deduction
   engine objective, Touchdown prefetch plan, and unresolved contract decisions.
8. `implementation/MIGRATION_PLAYBOOK.md` — how to migrate a real project and
   discover policies from evidence.

Use **Subsea Cable** as the language name, **`__C`** only as its visual short
mark, `.subc` for source files, and `subsea-cable` for portable slugs/language
IDs. Never call the language “SubC” or use `__C` as a code identifier.

Build the Host/Runtime in a separate repository. This language repository does
not accept production Host, Vessel, Scheduler, adapter, or complete Runtime
implementation code. Changes here are limited to language specification,
grammar, conformance, philosophy, governance, and design proposals.

Do not begin with policy design. Preserve `@policy` annotations as opaque,
ordered occurrence metadata and reject unsupported policies explicitly. Add
concrete policy semantics only through the discovery process in the migration
playbook.

Keep these terms separate:

- **Consumer Runtime**: frontend, validator, codebase, Vessel, Scheduler port,
  and Host port taken together.
- **Reduction**: the structural rule encoded by a resolved Goal artifact.
- **Deduction**: demand-time alias resolution plus application and commit of one
  occurrence's reduction rule.
- **Vessel**: lazy deduction, structural reduction, occurrences, routing,
  lineages, and the frontier.
- **Host**: primitive semantics, arrow-function leaf evaluation, and `$Anchor`
  resolution/invocation.
- **Scheduler**: execution eligibility, outcomes, and `@policy` only.

Never resolve an unqualified Goal reference to a hash merely because its parent
was parsed, stored, or deduced. It remains a symbolic `Name/Arity` occurrence
until that occurrence is demanded. Deduction atomically records the selected
full hash and resulting structure; later alias changes affect only undeduced
occurrences.

Never hide existing orchestration behind one large Anchor merely to pass an
original test suite. Move dependency structure into Subsea, keep only genuine
leaf implementation behind `$`, and record every discovered semantic gap.

When the specification, grammar, and conformance corpus disagree, stop that
implementation path, record the discrepancy, and repair or escalate the
language contract. Never choose one behavior silently in the reference runtime.

When an iteration exposes a design issue, do not absorb a convenient answer into
code, tests, or documentation. Freeze the affected path, create a proposed ADR
with reproduction evidence, affected invariants, viable alternatives, a
recommendation, and compatibility impact, then explicitly request the owner's
design decision. Keep that ADR in the external implementation repository and
open a Subsea Cable Proposal here when the issue is language-level. Continue
only unrelated work. The owner must decide any change
to source syntax, structural semantics, identity, layer ownership, error phase,
policy targeting/composition, or the Host/Vessel/Scheduler boundary.

Every completed phase must satisfy its gate in `implementation/README.md` and
leave reproducible tests or evidence. Implementation convenience is not language
semantics.
