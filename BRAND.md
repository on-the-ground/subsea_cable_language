# Subsea Cable Brand Contract

This file keeps public naming consistent without turning branding into language
semantics.

| Role | Canonical form |
|---|---|
| Official language name | **Subsea Cable** |
| Visual short mark | **`__C`** |
| Source extension | **`.subc`** |
| Portable slug/language ID | **`subsea-cable`** |
| Markdown code-fence alias | **`subsea`** |

## Usage

Use **Subsea Cable** in prose, speech, package descriptions, search metadata,
and the first textual occurrence on a page. `__C` may stand beside it as a
wordmark:

```text
__C — Subsea Cable
```

Use `.subc` only for Subsea Cable source files, for example `deploy.subc`.
External implementations may choose their own executable and package names; the
language does not reserve `subc` as a CLI.

## Guardrails

- Do not rename the language “SubC.” That spelling is not the short name.
- Do not use `__C` as a source identifier, namespace, package, API symbol,
  generated symbol, CLI command, URL slug, or machine-readable language ID.
- Do not make semantic meaning depend on the visual mark.
- In plain-text contexts that can lose underscores, write **Subsea Cable**.
- Image alt text and accessibility labels use **Subsea Cable**, not only `__C`.

The two underscores evoke *sub* and *subsea*. `C` carries *sea* and *cable*;
the mark can also be read as “C for agents.” These are brand associations, not
grammar or runtime contracts.
