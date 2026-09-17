# External Implementation Decision Records

This directory provides the ADR template and required topics. Actual Phase 0 and
iteration ADRs live in each external implementation repository. Copy
`TEMPLATE.md` there and name records `NNNN-short-title.md` in decision order.

A record has one of four statuses:

- `proposed` — under review;
- `accepted` — binding for the named external Runtime profile;
- `superseded` — replaced by a later record;
- `blocked` — requires an explicit owner decision before the dependent phase.

Decision records define an implementation profile, not automatically the Subsea
Cable language. A decision becomes language-level only when the normative language
documents and conformance corpus are intentionally updated.

An ADR is mandatory whenever an experiment exposes more than one reasonable
answer or an answer would change a language/architecture invariant. Such an ADR
remains `proposed` or `blocked` until the owner explicitly decides it. Agents may
recommend strongly, but must not mark an owner-required decision `accepted` on
their own or encode it implicitly in implementation behavior.

The affected implementation path stays frozen while the ADR is unresolved.
Unrelated paths may proceed.

When an ADR identifies a language-level issue, open an SCP in the language
repository using `../../proposals/TEMPLATE.md` and link the external ADR. Do not
submit the Host/Runtime code as the proposed language change.

Phase 0 requires records for:

1. reference language and build system;
2. canonical artifact encoding and hash algorithm;
3. occurrence-ID, codebase-revision, and deduction-record identity;
4. Runtime/Vessel/Host/Scheduler API shape;
5. Codebase transaction model;
6. Host primitive-semantics profile;
7. baseline test Scheduler profile;
8. first migration target and bounded slice.
