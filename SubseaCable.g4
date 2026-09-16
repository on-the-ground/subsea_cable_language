grammar SubseaCable;

/*
 * ============================================================
 * SubseaCable Language — ANTLR4 Parser Specification
 * ============================================================
 * NOTE:
 * The generated lexer emits physical newline and comment tokens. Before the
 * parser consumes them, a REQUIRED lexical preprocessing stage normalizes that
 * raw token stream according to the SSoT lexical conventions below:
 * - Remove a line comment but preserve its terminating physical newline.
 * - Replace an entire block comment, including any internal newlines, with one
 *   ordinary whitespace boundary. Only a newline outside `/* ... */` can emit
 *   a TERMINATOR. Comments never concatenate adjacent tokens.
 * - Block comments do not nest; the first following `*/` closes the comment.
 * - Suppress physical newlines inside unclosed [], {}, or ().
 * - Suppress a physical newline immediately after any token in this exact
 *   continuation set:
 *       =  ->  ,  :  @
 *       ||  &&  ==  !=  <=  >=  <  >
 *       +  -  *  /  %  !
 * - Coalesce the remaining physical newlines and emit logical TERMINATOR tokens.
 *
 * This stage MUST be implemented independently of the grammar, for example as
 * a TokenSource wrapper. The parser rules consume only the normalized stream.
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
 *       Something[...]   uppercase -> Goal
 *       something[...]   lowercase -> map
 *   A map access MUST contain exactly one key: `something[key]`. Empty or
 *   multi-argument lowercase brackets are semantic errors. Goals may retain
 *   zero or more arguments.
 *   Leading underscores do not participate in the case test; the first ASCII
 *   letter decides it (`_Build[...]` -> Goal, `_cache[...]` -> map). An
 *   identifier with no letter at all may not take a bracket suffix.
 *   Inside serial or parallel Goal composition only, a bare Identifier whose
 *   first ASCII letter is uppercase is also a Goal stage. This is the sole
 *   bracket-omission shorthand; a bare lowercase Identifier remains a value.
 *   No other casing rule exists in the language. In particular, alias/import
 *   targets are NOT constrained by case (a host language may expose either).
 *
 * MAP WILDCARD:
 *   `_` is reserved for use as a map key. It is not a general expression and
 *   cannot appear as a pipeline stage, argument, or standalone value.
 *   It is permitted only as the fallback key of an ordinary lookup Map. A
 *   resolving Map that exports parallel branch results MUST use concrete keys;
 *   `_` in a resolving Map is a semantic error because no materialized result
 *   key could satisfy it.
 *   A map may contain at most one `_` entry and may not repeat an explicit key.
 *   An exact explicit-key match always wins, regardless of declaration order;
 *   `_` is selected only when no explicit key matches. Violations are semantic
 *   errors and are not enforced by the grammar.
 *   A bare Identifier key is static shorthand for a String key with the same
 *   spelling; `success` and `"success"` are therefore duplicates. Map keys are
 *   never scope lookups or evaluated expressions. Numeric and String keys are
 *   distinct, so `1` and `"1"` are different keys.
 *   Equality and duplicate detection use normalized semantic values, not source
 *   spelling: `1` equals `1.0`, `0` equals `-0`, and String escapes are decoded
 *   before comparison. String comparison is case-sensitive.
 *   Ordinary lookup Maps are selective routing structures. `map[key]` selects
 *   an exact normalized key first, then `_`; only the selected entry participates
 *   in the resulting dependency/value structure. Unselected entries do not. If
 *   neither exists, lookup raises `KeyNotFound`. A statically evident miss is a
 *   validation error; a runtime-only miss is an evaluation error. A Map literal
 *   is resolving only when it is the direct body of a Goal arrow. Its concrete
 *   keyed entries declare independent Goal branches and explicit key-to-result
 *   relationships. A Map is a value producer, never a Goal stage by itself;
 *   `[A, {x: B, y: C}, D]` is invalid. Wrap it as
 *   `[A, [] -> {x: B, y: C}, D]`, or use a parameterized Goal arrow when
 *   upstream routing is required.
 *
 * LEXICAL PARAMETERS:
 *   Names must be unique within one Goal parameter list or one destructuring
 *   pattern. Each arrow creates a lexical scope. A nested structural arrow may
 *   shadow a name from an enclosing arrow or the top-level scope. Same-scope
 *   duplicates are semantic errors and are not enforced by the grammar.
 *   Both arrow forms have fixed arity. `[x, y]` and `(x, y)` accept exactly two
 *   values; `[]` and `()` accept none. `[{x, y}]` and `({x, y})` each accept
 *   exactly one Map value and destructure it. Defaults and variadic
 *   parameters are unsupported. Destructuring a non-Map or a Map missing any
 *   requested key raises `DestructureMismatch`; unrequested extra keys are
 *   allowed. A mismatch known from structure is a validation error; otherwise
 *   it is an evaluation error.
 *
 * GOAL ARITY:
 *   A Goal's identity is (name, arity). Multiple local Goal definitions may share
 *   a name only when their parameter counts differ; the same name/arity may
 *   have exactly one implementation. A deferred `Goal[...]` reduction or eager
 *   `Goal(...)` call selects that implementation solely by argument count and
 *   MUST match it exactly. Argument values, types, patterns, and guards never
 *   participate in overload selection. Default and variadic parameters are not
 *   supported. An imported Goal MUST expose all supported name/arity signatures
 *   as metadata; an unverifiable signature is a validation error. These checks
 *   are semantic and are not enforced by the grammar.
 *   Context supplies arguments only for a bare uppercase stage in a composition.
 *   An initial serial stage or a parallel sibling with no upstream value is
 *   Goal/0. A later bare serial stage is Goal/1 and receives the immediately
 *   preceding result as its sole argument. A downstream parallel composition
 *   has the all-bare fan-out shorthand defined below. An explicit `Goal[...]`
 *   receives exactly the arguments written inside its brackets; upstream values
 *   are never inserted, appended, or otherwise merged into that list.
 *
 * BINDING KINDS:
 *   A Binding whose right-hand side is a structural arrow
 *   `[params] -> goal-body` defines a composite Goal. A Binding whose
 *   right-hand side is `(params) -> body` defines a Goal with an arrow-function
 *   leaf implementation.
 *   Both are Goal definitions and their names MUST begin with an uppercase
 *   ASCII letter after leading underscores are ignored. Any other permitted
 *   right-hand side creates an immutable non-Goal value binding. There is no
 *   reassignment. A function arrow is never a value: it cannot be aliased,
 *   passed, returned, stored in a Map, or placed in a composition or argument.
 *   A String binding remains an ordinary value, but
 *   when referenced as `@alias` or as an imported Goal it MUST be validated as
 *   a location and resolved in that use context. The same String may still be
 *   read as a normal value elsewhere. A reference anchor itself may never be
 *   bound directly (`name = @host` is invalid), though invoking an anchor may
 *   produce a value that can participate in a larger expression. These rules
 *   are semantic and are not enforced by the grammar.
 *
 * CALLABILITY:
 *   There are exactly two call forms. `Goal(...)` eagerly evaluates a Subsea
 *   Goal selected by Name/Arity; `@anchor(...)` invokes a host function.
 *   A lowercase value identifier followed by `(...)` is invalid. Maps,
 *   pipelines, grouped expressions, call results, and all other values are not
 *   callable. Calls cannot be chained, and callable values do not exist.
 *   Inside an arrow-function leaf implementation, every Subsea Goal call is
 *   forbidden at any depth; only host-function calls written with `@` are
 *   permitted.
 *
 * STRUCTURAL ARROWS VS FUNCTION ARROWS:
 *   `[params] -> goal-body` is a Goal arrow: it defines structural Goal
 *   reduction and may appear inline where Goal structure is required. Its
 *   single-Map destructuring form is `[{x, y}] -> ...`; for example,
 *   `[{x, y}] -> [T1[y], T2[x]]` explicitly routes resolving-map results.
 *   `(params) -> body` is an arrow function, but only as the complete right-hand
 *   side of a named Goal binding such as `Add = (x, y) -> x + y`. It is
 *   not an expression and can never occur inline or between pipeline stages.
 *   Its body is terminal reduction content and MUST NOT contain a structural
 *   arrow, serial/parallel/resolving Goal composition, deferred Goal reference,
 *   or eager Subsea Goal call at any depth. It may use literals, parameters,
 *   operators, ordinary Maps/lookups, and Anchor calls such as `@Plus(x, y)`.
 *   Anchor calls inside the implementation do not create Subsea Goal nodes.
 *       Leaf = ({x, y}) -> { @C(x); @D(y) }   valid
 *       Leaf = (x) -> C(x)                    invalid: Subsea Goal call
 *       [A, (x) -> x + 1, B]                  invalid: inline function arrow
 *   Function parameters are either a comma-separated Identifier list or one
 *   scope-destructuring pattern. Thus `(x, y)` has arity 2, while `({x, y})`
 *   has arity 1 and destructures its single input.
 *   A function composite `{ first; second; ... }` is available only inside that
 *   named leaf implementation. It declares strict left-to-right dependencies,
 *   does not forward non-final values, and exposes the final expression's value.
 *   It is neither a Map nor a parallel Goal composition; `;` has no meaning
 *   outside this composite. Error handling remains Scheduler policy.
 *
 * GOAL BODY VALIDITY:
 *   A Goal arrow body MUST be reduction structure, never a bare primitive or
 *   computed value. Its direct forms are: a deferred/eager Goal reference, an
 *   Anchor leaf/reference call, another Goal arrow, serial composition, unkeyed
 *   parallel composition, a resolving Map, or an ordinary Map lookup whose
 *   selectable results are all valid Goal structure. Goal arguments may still
 *   contain ordinary value expressions.
 *   A bare Anchor is an Anchor/0 leaf; enclosing Goal parameters are never
 *   forwarded implicitly. Host signature metadata MUST confirm its arity.
 *       Value = [x] -> 42          invalid: primitive body
 *       Zero  = [x] -> @host       valid: Anchor/0; x is unused
 *       Call  = [x] -> @host(x)    valid: Anchor/1
 *       Bad   = [x] -> (y) -> y    invalid: function arrow is never inline
 *   Serial and parallel elements obey the same structural restriction. A Map
 *   literal may appear there only behind a Goal arrow as defined above.
 *
 * SERIAL AND PARALLEL GOAL COMPOSITION:
 *   `[A, B]` is serial composition: B depends on A and receives A's result as
 *   its upstream input. `{A, B}` is parallel composition: it creates no
 *   dependency edge between A and B, so a Scheduler may run them concurrently.
 *   Braces permit concurrency but do not require simultaneous execution.
 *   A bare initial/parallel Goal denotes Goal/0. A bare downstream serial Goal
 *   denotes Goal/1 and receives only the preceding result. Explicit brackets
 *   disable that shorthand: `[A[x], B[y]]` still orders B after A, but B receives
 *   only y and A's result is discarded. To forward or augment the upstream
 *   value, use an explicit Goal-arrow stage:
 *       [A[x], [Aresult] -> B[Aresult, y]]
 *   No implicit argument insertion or expansion occurs. Commas therefore mean
 *   serialization inside `[...]`, parallel sibling placement inside `{...}`,
 *   and Map entry separation only when paired with `:`. Semicolons occur only
 *   in a function composite.
 *
 * UPSTREAM FAN-OUT:
 *   A parallel composition in a downstream serial position has exactly two
 *   valid modes. In implicit fan-out mode, EVERY branch expression
 *   is a bare uppercase Goal and resolves to Goal/1; the same single upstream
 *   value is routed as the sole argument to every branch:
 *       [A, {B, C}]
 *         == [A, [i] -> {B[i], C[i]}]
 *   If any bare branch lacks a /1 implementation, or if any branch needs other
 *   arguments, the shorthand is invalid. The author MUST make the whole routing
 *   explicit with an inline Goal arrow:
 *       [A, [i] -> {B[i], C[i, y]}]
 *       [A, [i] -> {B[y], C[i]}]
 *   In explicit mode, no branch is bare and every branch writes its own argument
 *   list; the upstream value is not routed into the parallel composition:
 *       [A, {B[a], C[b]}]
 *   Mixing bare implicit branches with explicit branches is a semantic error.
 *   This shorthand never applies to a resolving Map because a Map cannot occupy
 *   a composition slot. Wrap keyed branches in a Goal arrow and route explicitly:
 *       [A, [i] -> {x: B[i], y: C[i]}]
 *   A zero-parameter wrapper may deliberately ignore upstream output:
 *       [A, [] -> {x: B, y: C}]
 *
 * COMPOSITION OUTPUT:
 *   A serial composition contains at least two elements and exports exactly the
 *   output state of its final element. Thus `[A, B]` exports B's value when B
 *   produces one, and exports `NoOutput` when B does not. Earlier results are
 *   discarded unless explicitly routed. Bare `[]` and singleton `[A]` are not
 *   expressions; `[] -> ...` remains the zero-arity Goal-arrow form, and
 *   `Goal[]` remains a zero-argument deferred Goal reference.
 *   An unkeyed parallel composition also contains at least two elements and
 *   always exports `NoOutput`, regardless of branch results. Singleton `{A}` is
 *   invalid. `{}` remains an ordinary empty Map value, not parallel composition.
 *   `NoOutput` is a structural output state, not a runtime value. It has no
 *   source literal and is not `null`, unit, or an empty Map. It cannot be routed,
 *   bound as a value, destructured, or supplied to a bare downstream Goal/1.
 *   A stage may still depend structurally on a `NoOutput` predecessor when all
 *   of its arguments are explicit:
 *       [{A, B}, C[]]       valid: dependency only; C/0
 *       [{A, B}, C[y]]      valid: y comes from lexical scope
 *       [{A, B}, C]         invalid: bare C requires an upstream value
 *       [{A, B}, [x] -> C[x]] invalid: there is no value to bind to x
 *
 * PARALLEL RESULT EXPORT:
 *   Unkeyed parallel composition `{A, B}` exports no downstream value. When it
 *   precedes another serial element, the structure contains a dependency from
 *   the composite node to that element, but the language does not define when
 *   the composite is considered satisfied. Goal names are never synthesized
 *   into result keys. A following bare unary Goal or parameterized arrow is
 *   invalid because no value is routed; an explicit zero-argument continuation
 *   such as `[{A, B}, C[]]` is structurally valid.
 *   To export branch results, the author MUST make a resolving Map the direct
 *   body of a Goal arrow:
 *       [[] -> {x: A, y: B}, [{x, y}] -> [C[x], D[y]]]
 *   Its entries are independent branches and expose one immutable Map-shaped
 *   result `{x: resultOfA, y: resultOfB}`. That single value may be
 *   scope-destructured by the following Goal arrow. Only explicitly
 *   written concrete keys are exported; wildcard `_` is forbidden here, and
 *   `{A, B}` can never provide values for `[{x, y}]`.
 *   A resolving Map itself is never adjacent to Goals in a composition. Each
 *   branch MUST export a value; a `NoOutput` branch cannot materialize its key.
 *   A singleton resolving Map such as `[] -> {x: A}` is valid. Empty `{}` is
 *   always an ordinary Map value and never a resolving Map.
 *
 * SCHEDULER POLICY BOUNDARY:
 *   The language defines dependency edges, serial/parallel independence, value
 *   routing, and explicit result keys only. It does NOT define success criteria,
 *   failure propagation, all/any/quorum completion, retries, cancellation,
 *   timeouts, fire-and-forget behavior, or error aggregation. Those belong to
 *   the Scheduler. A Scheduler may make a dependent evaluation instance
 *   eligible only when its policy considers the upstream structure satisfied
 *   and every value required by that instance has been supplied accordingly.
 *
 * BOOLEANS:
 *   `true` and `false` are reserved Boolean literals and cannot be rebound as
 *   Identifiers. There is no truthiness conversion: `!`, `&&`, and `||` require
 *   Boolean operands, and equality/comparison operations produce Booleans.
 *   Boolean Map keys are distinct from String keys, so `true` and `"true"` do
 *   not collide.
 *   `&&` and `||` short-circuit from left to right. `false && rhs` and
 *   `true || rhs` do not select the right operand, so any eager Goal or Anchor
 *   call contained only in that operand does not participate in the resulting
 *   dependency/evaluation structure. This is Boolean value-selection semantics,
 *   not a success or failure policy; execution policy remains with the Scheduler.
 *
 * TOP-LEVEL BINDINGS:
 *   The top level is one order-independent scope. Forward references are valid,
 *   A non-Goal name may be bound exactly once. Local Goal definitions of either
 *   implementation kind may share a base name only across distinct arities.
 *   A Goal and a non-Goal binding may not share a base name. Rebinding,
 *   reassignment, same-name/same-arity Goal definitions, and
 *   last-declaration-wins behavior do not exist. An imported Goal alias is one
 *   binding whose metadata may expose multiple arities.
 *   Violations are semantic errors and are not enforced by the grammar.
 *   Recursion is not currently supported. Direct self-reference and every
 *   mutual cycle in the binding dependency graph are semantic errors. The
 *   issues that must be resolved before enabling recursion are recorded in
 *   Recursion.md.
 *
 * ONE PROGRAM, ONE ROOT:
 *   A program contains exactly one top-level statement that is not a Binding.
 *   That expression is the Root and MUST be exactly a deferred Goal reduction:
 *   an Identifier whose first ASCII letter is uppercase, followed by one `[]`
 *   bracket suffix and no call suffix. Bare names, map access, literals, maps,
 *   anchors, arrows, and eager `Goal(...)` calls cannot be Roots. Any number of
 *   Bindings may accompany the Root, but a binding-only file and a file with
 *   multiple Root expressions are semantic errors. Library/module-only files
 *   are not currently part of the language.
 *
 * GOAL DAG:
 *   The structure reachable from the one Root is a directed acyclic graph (DAG),
 *   not necessarily a tree. Source expressions are tree-shaped notation, but
 *   multiple references to the same resolved Goal definition/arity designate
 *   one structural Goal node and add incoming edges to it; they do not clone
 *   that node. Serial/parallel placement, argument routing, and resolving keys
 *   belong to edges and composite structure. Direct and mutual cycles remain
 *   invalid because recursion is unsupported.
 *   Node sharing alone does not combine incoming values or create an all-parent
 *   barrier. Each edge retains its own routing and may produce a separate
 *   evaluation instance. Multiple upstream results feed one instance only when
 *   an explicit structure such as a resolving Map combines them.
 *
 * GOAL NODE IDENTITY, LINEAGE, AND EVALUATION:
 *   GoalNodeId is the resolved Goal-definition identity plus arity. It is
 *   independent of parent, source occurrence, lineage, and argument values.
 *   The Vessel expands each GoalNodeId once and structurally shares that node.
 *   Deferred `Goal[...]` and eager `Goal(...)` references resolve to the same
 *   GoalNodeId; their suffix changes reduction/evaluation timing, not identity.
 *   A lineage path is one Root-to-node traversal, not the node's identity or
 *   memoization key. A node with multiple incoming paths carries multiple
 *   lineages. Reduction extends every incoming lineage across outgoing edges:
 *       PrepareOrder[10, {..}]
 *         reduces to
 *       { PrepareOrder/2.GetUserInfo/1[10],
 *         PrepareOrder/2.ValidateOrder/1[{..}] }
 *   The dotted `Name/Arity` form is explanatory pretty-printing of one lineage,
 *   NOT `.subsea` syntax, a reparsable reduction output, or a unique address.
 *   For example, `Root/0.B/1.D/1` and `Root/0.C/1.D/1` are two lineages of the
 *   same structural D/1 node when B and C both reduce to D. Values such as leaf
 *   parameters, map values, and literals remain lexically scoped and inherit
 *   the active lineage set as context.
 *   Evaluation is separate from expansion: one structural Goal node may have
 *   multiple evaluation instances, distinguished by their routed argument
 *   tuples. Structural sharing does not prescribe execution-result caching or
 *   coalescing; those remain Scheduler policy. Each instance carries the active
 *   lineage or lineages that actually contributed its routed inputs, while the
 *   structural node's lineage set is their union.
 *   Data-dependent expansion, where structure branches on a value, would break
 *   definition-based structural expansion. It is deferred with recursion; see
 *   Recursion.md.
 *
 * LEAVES (exactly two kinds):
 *   Reduction bottoms out in either an arrow-function leaf belonging to a named
 *   Goal or a reference Anchor reached by structural reduction. An arrow
 *   function cannot be hidden in or transported through a value; its enclosing
 *   Goal supplies its Name/Arity and active lineages.
 *   There are NO native effects. An anchor `@` ALWAYS names a host function
 *   (an implementation supplied by a consuming language); it is opaque, never
 *   expanded, and inherits the active goal lineages as context.
 *
 * ALIAS / IMPORT:
 *   A String value binding can be used as a location alias; the binding itself
 *   carries no `@`:
 *       join = "registry.example.com/pkg/Join@1.2.3"
 *   Use decides meaning:
 *       @join           -> host-function anchor (leaf)
 *       ImportedGoal    -> a goal imported from elsewhere, used bare & reduced
 *   A name may NOT be bound directly to an anchor (semantic rule, not syntactic):
 *       Add = [a,b] -> @plus(a,b)   OK  — a real goal reducing to a leaf
 *       Add = (a,b) -> a + b        OK  — a named Goal with a function leaf
 *       Add = @plus                 FORBIDDEN — a leaf disguised as a goal
 *   An Anchor leaf must be reached through structural Goal reduction; only the
 *   dedicated function-arrow binding form may give a Goal a direct leaf
 *   implementation.
 * ============================================================
 */

// ------------------------------------------------------------
// 1. Parser Rules (Syntax Rules)
// ------------------------------------------------------------

// Syntax admits a general statement list; semantic validation requires exactly
// one non-Binding Root expression in the restricted deferred-Goal form defined
// above. The file must be fully parsed to EOF.
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
    : IDENTIFIER '=' functionLeafImplementation
    | IDENTIFIER '=' expression
    ;

// A function arrow is syntax only for a named Goal's leaf implementation. It
// is not an Expression and therefore cannot appear as a value anywhere else.
functionLeafImplementation
    : fnParams '->' fnBody
    ;

/* --- Expressions --- */
expression
    : goalArrow
    | logicalOr
    ;

goalArrow
    : goalParams '->' goalBody
    ;

goalBody
    : goalReference
    | anchorLeaf
    | goalArrow
    | serialPipeline
    | parallelComposition
    | resolvingMap
    ;

// A direct Goal body is not a contextual composition position, so a bare Goal
// name is not shorthand here. Lowercase bracket form is an ordinary Map lookup;
// uppercase bracket/paren forms are deferred/eager Goal references. Case and
// arity constraints remain semantic.
goalReference
    : IDENTIFIER (bracketSuffix | callSuffix)
    ;

anchorLeaf
    : placeholder callSuffix?
    ;

goalParams
    : '[' (paramList | scopeDestructure)? ']'
    ;

fnParams
    : '(' (paramList | scopeDestructure)? ')'
    ;

// A function composite exists only in a named Goal's leaf implementation. It is
// sequential value-level evaluation, not a map and not a parallel Goal
// composition. It contains at least two expressions; the optional final
// semicolon does not add another expression.
fnBody
    : expression
    | functionComposite
    ;

functionComposite
    : '{' expression ';' expression (';' expression)* ';'? '}'
    ;

paramList
    : param (',' param)* ','?
    ;

param
    : IDENTIFIER
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
    : comparison (('==' | '!=') comparison)?
    ;

comparison
    : additive (('<=' | '>=' | '<' | '>') additive)?
    ;

additive
    : multiplicative (('+' | '-') multiplicative)*
    ;

multiplicative
    : unary (('*' | '/' | '%') unary)*
    ;

unary
    : '!' unary
    | '-' unary
    | postfix
    ;

postfix
    : IDENTIFIER (bracketSuffix | callSuffix)?
    | placeholder callSuffix?
    | nonIdentifierPrimary
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
// Square brackets are restricted to a bare identifier so the naming law is
// always defined. Leading underscores are ignored and the first ASCII letter
// decides case; an identifier without a letter may not use this suffix. A
// semantic validator requires exactly one argument for a lowercase map access.
// Parentheses are available only on a bare Identifier or Anchor. Semantic
// validation further restricts them to eager uppercase Goal calls and host
// Anchor calls, and forbids Subsea Goal calls inside leaf implementations.
bracketSuffix
    : '[' argList? ']'
    ;

callSuffix
    : '(' argList? ')'
    ;

argList
    : expression (',' expression)* ','?
    ;

/* --- Primary --- */
nonIdentifierPrimary
    : serialPipeline
    | parallelComposition
    | map
    | group
    | NUMBER
    | BOOLEAN
    | STRING_LITERAL
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

serialPipeline
    : '[' pipelineStageList ']'
    ;

pipelineStageList
    : goalStage ',' goalStage (',' goalStage)* ','?
    ;

goalStage
    : IDENTIFIER (bracketSuffix | callSuffix)?
    | anchorLeaf
    | goalArrow
    | serialPipeline
    | parallelComposition
    ;

// Comma-separated braces without ':' are independent Goal siblings. Requiring
// at least two expressions keeps '{}' unambiguously available as the empty Map.
parallelComposition
    : '{' goalStage ',' goalStage (',' goalStage)* ','? '}'
    ;

// A resolving Map is a non-empty keyed value producer available only as the
// direct body of a Goal arrow. Each entry is an independent Goal branch.
resolvingMap
    : '{' resolvingMapEntry (',' resolvingMapEntry)* ','? '}'
    ;

resolvingMapEntry
    : mapKey ':' goalStage
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
    : '-'? NUMBER
    | BOOLEAN
    | WILDCARD
    | STRING_LITERAL
    | IDENTIFIER
    ;

group
    : '(' expression ')'
    ;


// ------------------------------------------------------------
// 2. Lexer Rules (Raw Token Definitions)
// ------------------------------------------------------------

WILDCARD : '_';

BOOLEAN
    : 'true'
    | 'false'
    ;

IDENTIFIER
    : IDENT_START IDENT_REST*
    ;

fragment IDENT_START : [a-zA-Z_];
fragment IDENT_REST  : [a-zA-Z0-9_];

NUMBER
    : INT_PART FRAC_PART?
    ;

fragment INT_PART  : '0' | [1-9] [0-9]*;
fragment FRAC_PART : '.' [0-9]+;

STRING_LITERAL
    : '"' STRING_CHAR* '"'
    ;

fragment STRING_CHAR
    : ~["\\\r\n]
    | ESCAPE_SEQ
    ;

fragment ESCAPE_SEQ
    : '\\' ['"nt\\] 
    ;

TERMINATOR
    // Physical newline token. The required lexical preprocessor decides
    // whether it survives as a logical statement terminator.
    : ( '\n' | '\r\n' )+
    ;

// ------------------------------------------------------------
// 3. Skip & Hidden Channels (Whitespace and Comment Handling)
// ------------------------------------------------------------

WHITESPACE
    : [ \t]+ -> channel(HIDDEN)
    ;

LINE_COMMENT
    // The terminating newline is deliberately excluded and remains available
    // to the lexical preprocessor.
    : '//' ~[\r\n]* -> channel(HIDDEN)
    ;

BLOCK_COMMENT
    // The whole token, including internal newlines, becomes one ordinary
    // whitespace boundary. Internal newlines never become TERMINATOR tokens.
    // Nesting is forbidden; the first following `*/` closes the token.
    : '/*' .*? '*/' -> channel(HIDDEN)
    ;
