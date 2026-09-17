# Conformance

`cases.tsv` is the language conformance manifest. Each case names its expected
phase and outcome; a conforming implementation must parse every `valid` and
`invalid-semantic` input, reject every `invalid-syntax` input, and then produce
the listed validation kind for each `invalid-semantic` input.

[`DEDUCTION.md`](DEDUCTION.md) contains the complementary Runtime scenarios for
demand-time alias resolution, commit atomicity, recovery, and the Host boundary.
They cannot be expressed by a single source fixture and are normative for a
Runtime claiming deduction conformance.

## Required lexical preprocessing

The ANTLR lexer produces physical `TERMINATOR`, whitespace, and comment tokens.
Before parsing, a token-source wrapper must perform this deterministic pass:

1. Decode the source strictly as UTF-8. Reject malformed input as
   `InvalidSourceEncoding` before lexing.
2. Discard ordinary whitespace and line-comment tokens. The newline following a
   line comment remains a physical `TERMINATOR` token.
3. Replace each block-comment token conceptually with one whitespace boundary.
   Its internal newlines never produce terminators. Because tokenization has
   already occurred, discarding the token must not concatenate its neighbors.
4. Track unmatched opening `(`, `[`, and `{` tokens with a delimiter stack.
5. For each physical `TERMINATOR`, suppress it when the delimiter stack is not
   empty or when the previous significant token is in this exact set:

   ```text
   =  ->  ,  :  @  $
   ||  &&  ==  !=  <=  >=  <  >
   +  -  *  /  %  !
   ```

6. Coalesce consecutive surviving physical newlines into one logical
   `TERMINATOR`, preserving the span of the coalesced source region.
7. Emit all other significant tokens unchanged and finally emit EOF. The parser,
   not this pass, reports unmatched or misordered delimiters.

The “previous significant token” ignores whitespace and comments. A newline
before an operator is not continuation; only a newline after a listed token is.

## Synchronization rule

Any language change is incomplete until all applicable projections agree:

- `README.md`: semantic contract
- `SubseaCable.ebnf`: implementation-neutral syntax and lexical contract
- `SubseaCable.g4`: executable ANTLR4 grammar
- `conformance/cases.tsv` and its source files: observable acceptance/rejection
- `conformance/DEDUCTION.md`: observable demand-time deduction behavior

The ANTLR grammar must generate without warnings or errors, generated Java must
compile against the matching ANTLR runtime, every syntax-valid case must reach
EOF without lexer/parser errors after preprocessing, and every syntax-invalid
case must produce at least one lexer/parser error. Semantic cases require the
stable error `kind` listed in the manifest.

The current grammar has been generation-checked with ANTLR 4.13.2. Generated
artifacts are build output and are not committed.
