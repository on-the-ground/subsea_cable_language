grammar SubseaCableLanguage;

/*
 * ============================================================
 * SubseaCable Language — ANTLR4 Parser Specification
 * ============================================================
 * NOTE: 
 * This grammar assumes that the input has already passed
 * through the SSoT lexical preprocessing pipeline.
 *
 * Specifically, the following Lexical Conventions from the SSoT:
 * - Comment removal
 * - Expression continuation (Bracket depth & Dangling operators)
 * - Logical TERMINATOR emission
 *
 * MUST BE implemented by a custom TokenSource implementation
 * or a separate lexical preprocessing stage, NOT by this pure grammar.
 * ============================================================
 */

/*
 * ============================================================
 * Semantic Model
 * ------------------------------------------------------------
 * Interpreted by the Vessel (reduction) and Scheduler (evaluation),
 * NOT enforced by this grammar. Recorded here as the single source of truth.
 * ============================================================
 *
 * NAMING LAW (the only one):
 *   The identifier immediately before `[...]` is read by case:
 *       Something[...]   uppercase -> Task (Goal)
 *       something[...]   lowercase -> map
 *   No other casing rule exists in the language. In particular, alias/import
 *   targets are NOT constrained by case (a host language may expose either).
 *
 * REDUCTION PRESERVES LINEAGE (prefixing, not substitution):
 *   When a Goal reduces, its own name is prepended to each sub-goal as a
 *   dotted prefix:
 *       CreateOrder[10, {..}]
 *         reduces to
 *       [ CreateOrder.GetUserInfo[10],
 *         (userInfo) -> CreateOrder.RegisterOrder[userInfo, {..}] ]
 *   NOT to a bare GetUserInfo / RegisterOrder. The prefix accumulates
 *   transitively, so every seafloor leaf carries its full ancestry (its
 *   position in the goal tree).
 *   Prefixing applies to the *reduced Goal* — deferred `[]` or eager-call `()`
 *   alike; the bracket is only reduction timing. It does NOT apply to values
 *   (fn params `(x)->`, map values, literals): those are lexically scoped and
 *   inherit the enclosing goal path implicitly.
 *
 * PATH = LOGICAL LINEAGE = EXPANSION MEMOIZATION KEY:
 *   A goal path identifies a *reduction structure*, not a runtime value. Two
 *   occurrences of the same goal under the same parent share ONE path — on
 *   purpose. A path is expanded once and structurally shared; arguments flow in
 *   only at evaluation time. Expansion is memoized by path (Vessel); evaluation
 *   is distinguished by value (Scheduler).
 *   (Open: data-dependent expansion, where structure branches on a value, would
 *   break path-only memoization. Deferred until recursion/conditionals.)
 *
 * LEAVES (exactly two kinds):
 *   Reduction bottoms out in either an arrow function or a reference anchor.
 *   There are NO native effects. An anchor `@` ALWAYS names a host function
 *   (an implementation supplied by a consuming language); it is opaque, never
 *   expanded, and only inherits its goal path as context.
 *
 * ALIAS / IMPORT:
 *   An alias binds a name to a location string; the alias itself carries no `@`:
 *       join = "registry.example.com/pkg/Join@1.2.3"
 *   Use decides meaning:
 *       @join           -> host-function anchor (leaf)
 *       ImportedGoal    -> a goal imported from elsewhere, used bare & reduced
 *   A name may NOT be bound directly to an anchor (semantic rule, not syntactic):
 *       Add = [a,b] -> @plus(a,b)   OK  — a real goal reducing to a leaf
 *       Add = @plus                 FORBIDDEN — a leaf disguised as a goal
 *   A Goal must map to a reduction structure, never directly to a leaf.
 * ============================================================
 */

// ------------------------------------------------------------
// 1. Parser Rules (Syntax Rules)
// ------------------------------------------------------------

// Non-Empty Constraint: A file must contain at least one statement and must be fully parsed to EOF.
program
    : TERMINATOR? statementList EOF
    ;

statementList
    : statement (TERMINATOR statement)* TERMINATOR?
    ;

statement
    : binding
    | expression
    ;

/* --- Bindings --- */
binding
    : IDENTIFIER '=' expression
    ;

/* --- Expressions --- */
expression
    : arrow
    | logicalOr
    ;

arrow
    : arrowParams '->' expression
    ;

arrowParams
    : goalParams
    | fnParams
    ;

goalParams
    : '[' paramList? ']'
    ;

fnParams
    : '(' pattern? ')'
    ;

paramList
    : param (',' param)* ','?
    ;

param
    : IDENTIFIER
    ;

pattern
    : scopeDestructure
    | IDENTIFIER
    ;

scopeDestructure
    : '{' destructureFieldList? '}'
    ;

destructureFieldList
    : IDENTIFIER (',' IDENTIFIER)* ','?
    ;

/* --- Core Operators (Precedence & Associativity) --- */
logicalOr
    : logicalAnd ('||' logicalAnd)*
    ;

logicalAnd
    : equality ('&&' equality)*
    ;

equality
    : comparison (('==' | '!=') comparison)*
    ;

comparison
    : additive (('<=' | '>=' | '<' | '>') additive)*
    ;

additive
    : multiplicative (('+' | '-') multiplicative)*
    ;

multiplicative
    : unary (('*' | '/' | '%') unary)*
    ;

unary
    : '!' unary
    | postfix
    ;

postfix
    : primary suffix*
    ;

// The two suffix forms carry DIFFERENT semantics, not just different brackets:
//
//   Goal[n]  (bracket suffix) is NOT "evaluate this". It is a REDUCTION
//            directive: it declares this position is a goal still to be reduced.
//            [ Goal[n], ... ] means "this slot must, at some point, be reduced
//            into a leaf node." It records that reduction work remains here —
//            nothing is evaluated yet.
//
//   Goal(n)  (paren suffix) IS a call / evaluation: feed the value n into Goal,
//            reduce it now, run it through the pipeline, yield a value. This is
//            the legitimate "evaluate now" form.
//
// Both are valid grammar; the distinction is interpreted by the Vessel
// (reduction) and the Scheduler (evaluation), not enforced syntactically.
suffix
    : '[' argList? ']'
    | '(' argList? ')'
    ;

argList
    : expression (',' expression)* ','?
    ;

/* --- Primary --- */
primary
    : pipeline
    | map
    | group
    | NUMBER
    | STRING_LITERAL
    | placeholder
    | WILDCARD
    | IDENTIFIER
    ;

// A Placeholder names an Anchor, and an Anchor ALWAYS refers to a host function
// (an implementation provided by a consuming language). There is no other kind
// of anchor and no native effect. `@` is applied to either an alias identifier
// bound to a location string (join = "...url..."  ->  @join) or an inline
// location string (@"https://registry.example.com/pkg/Join@1.2.3"). A URL always
// resolves to a function inside a host package, never to a Subsea goal. Subsea
// goals are referenced by Goal import (a bare aliased name used as a Goal), not
// by an anchor. See the Semantic Model header.
placeholder
    : '@' ( IDENTIFIER | STRING_LITERAL )
    ;

pipeline
    : '[' pipelineStageList? ']'
    ;

pipelineStageList
    : expression (',' expression)* ','?
    ;

map
    : '{' mapEntryList? '}'
    ;

mapEntryList
    : mapEntry (',' mapEntry)* ','?
    ;

mapEntry
    : mapKey ':' expression
    ;

mapKey
    : NUMBER
    | WILDCARD
    | STRING_LITERAL
    | IDENTIFIER
    ;

group
    : '(' expression ')'
    ;


// ------------------------------------------------------------
// 2. Lexer Rules (Token Definitions and Preprocessing)
// ------------------------------------------------------------

WILDCARD : '_';

IDENTIFIER
    : IDENT_START IDENT_REST*
    ;

fragment IDENT_START : [a-zA-Z_];
fragment IDENT_REST  : [a-zA-Z0-9_];

NUMBER
    : '-'? INT_PART FRAC_PART?
    ;

fragment INT_PART  : '0' | [1-9] [0-9]*;
fragment FRAC_PART : '.' [0-9]+;

STRING_LITERAL
    : '"' STRING_CHAR* '"'
    ;

fragment STRING_CHAR
    : ~["\\]
    | ESCAPE_SEQ
    ;

fragment ESCAPE_SEQ
    : '\\' ['"nt\\] 
    ;

TERMINATOR
    : ( '\n' | '\r\n' )+
    ;

// ------------------------------------------------------------
// 3. Skip & Hidden Channels (Whitespace and Comment Handling)
// ------------------------------------------------------------

WHITESPACE
    : [ \t]+ -> channel(HIDDEN)
    ;

LINE_COMMENT
    : '//' ~[\r\n]* -> channel(HIDDEN)
    ;

BLOCK_COMMENT
    : '/*' .*? '*/' -> channel(HIDDEN)
    ;