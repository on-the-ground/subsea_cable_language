package syntax

import (
	"fmt"
	"strconv"
	"strings"

	"github.com/on-the-ground/subsea_cable_language/carousel/diag"
)

// Expr is any parsed expression.
type Expr interface {
	Pos() diag.Span
	exprNode()
}

// Params is a Goal or function parameter list.
type Params struct {
	Names       []string
	Destructure bool // [{a, b}] or ({a, b}); Names holds the requested keys
	Span        diag.Span
}

// Arity is the number of positional arguments the params accept.
func (p Params) Arity() int {
	if p.Destructure {
		return 1
	}
	return len(p.Names)
}

// SuffixKind distinguishes `Name`, `Name[...]`, and `Name(...)`.
type SuffixKind int

const (
	NoSuffix SuffixKind = iota
	BracketSuffix
	CallSuffix
)

type (
	// GoalArrow is `[params] -> body`.
	GoalArrow struct {
		Params Params
		Body   Expr
		Span   diag.Span
	}
	// FuncArrow is `(params) -> body`, only valid as a binding right-hand side.
	FuncArrow struct {
		Params Params
		Body   []Expr // len>1 means a `{a; b}` function composite
		Span   diag.Span
	}
	// Serial is `[a, b, ...]`.
	Serial struct {
		Stages []Expr
		Span   diag.Span
	}
	// Parallel is `{a, b, ...}` without keys.
	Parallel struct {
		Stages []Expr
		Span   diag.Span
	}
	// MapLit is `{k: v, ...}`; a resolving map when it is a Goal-arrow body.
	MapLit struct {
		Entries []MapEntry
		Span    diag.Span
	}
	// Name is an identifier with an optional hash qualifier and suffix.
	Name struct {
		Ident  string
		Hash   string
		Suffix SuffixKind
		Args   []Expr
		Span   diag.Span
	}
	// Anchor is `$name` or `$name(args)`.
	Anchor struct {
		Ident  string
		Called bool
		Args   []Expr
		Span   diag.Span
	}
	// Policied is `@p ... target`.
	Policied struct {
		Policies []Policy
		Target   Expr
		Span     diag.Span
	}
	NumberLit struct {
		Text string
		Span diag.Span
	}
	StringLit struct {
		Raw   string
		Value string
		// EscapeErr is set when a \u{...} escape is out of range; reported by
		// validation as InvalidUnicodeEscape.
		EscapeErr string
		Span      diag.Span
	}
	BoolLit struct {
		Value bool
		Span  diag.Span
	}
	Unary struct {
		Op   string
		X    Expr
		Span diag.Span
	}
	Binary struct {
		Op   string
		L, R Expr
		Span diag.Span
	}
	Group struct {
		X    Expr
		Span diag.Span
	}
)

// Policy is one `@identifier(args)` prefix.
type Policy struct {
	Ident   string
	Args    []Expr
	HasArgs bool
	Span    diag.Span
}

// MapKeyKind classifies a map key.
type MapKeyKind int

const (
	KeyIdent MapKeyKind = iota
	KeyString
	KeyNumber
	KeyBool
	KeyWildcard
)

// MapKey is a static map key.
type MapKey struct {
	Kind MapKeyKind
	Text string // identifier text, decoded string, signed number text, or bool text
	Span diag.Span
}

// MapEntry is one key/value pair.
type MapEntry struct {
	Key   MapKey
	Value Expr
}

func (e *GoalArrow) Pos() diag.Span { return e.Span }
func (e *FuncArrow) Pos() diag.Span { return e.Span }
func (e *Serial) Pos() diag.Span    { return e.Span }
func (e *Parallel) Pos() diag.Span  { return e.Span }
func (e *MapLit) Pos() diag.Span    { return e.Span }
func (e *Name) Pos() diag.Span      { return e.Span }
func (e *Anchor) Pos() diag.Span    { return e.Span }
func (e *Policied) Pos() diag.Span  { return e.Span }
func (e *NumberLit) Pos() diag.Span { return e.Span }
func (e *StringLit) Pos() diag.Span { return e.Span }
func (e *BoolLit) Pos() diag.Span   { return e.Span }
func (e *Unary) Pos() diag.Span     { return e.Span }
func (e *Binary) Pos() diag.Span    { return e.Span }
func (e *Group) Pos() diag.Span     { return e.Span }

func (*GoalArrow) exprNode() {}
func (*FuncArrow) exprNode() {}
func (*Serial) exprNode()    {}
func (*Parallel) exprNode()  {}
func (*MapLit) exprNode()    {}
func (*Name) exprNode()      {}
func (*Anchor) exprNode()    {}
func (*Policied) exprNode()  {}
func (*NumberLit) exprNode() {}
func (*StringLit) exprNode() {}
func (*BoolLit) exprNode()   {}
func (*Unary) exprNode()     {}
func (*Binary) exprNode()    {}
func (*Group) exprNode()     {}

// Binding is `Name = rhs`.
type Binding struct {
	Name  string
	Value Expr // *FuncArrow for function-leaf Goal implementations
	Span  diag.Span
}

// Program is one parsed source unit.
type Program struct {
	Bindings []*Binding
	Roots    []Expr // every non-binding statement
}

// IsUpper applies the casing law: leading underscores are ignored and the first
// ASCII letter decides. ok is false for identifiers containing no letter.
func IsUpper(ident string) (upper, ok bool) {
	for i := 0; i < len(ident); i++ {
		c := ident[i]
		if c == '_' {
			continue
		}
		if c >= 'A' && c <= 'Z' {
			return true, true
		}
		if c >= 'a' && c <= 'z' {
			return false, true
		}
		return false, false
	}
	return false, false
}

// Canonical renders a deterministic, reparsable-enough structural encoding
// used for artifact hashing and traces. erasePolicies drops @policy metadata.
// resolve, when non-nil, may replace a hash-qualified Name with a full hash.
func Canonical(e Expr, erasePolicies bool, resolve func(*Name) string) string {
	var b strings.Builder
	writeCanon(&b, e, erasePolicies, resolve)
	return b.String()
}

func writeList(b *strings.Builder, xs []Expr, sep string, erase bool, resolve func(*Name) string) {
	for i, x := range xs {
		if i > 0 {
			b.WriteString(sep)
		}
		writeCanon(b, x, erase, resolve)
	}
}

func writeParams(b *strings.Builder, p Params) {
	if p.Destructure {
		b.WriteString("{" + strings.Join(p.Names, ",") + "}")
	} else {
		b.WriteString(strings.Join(p.Names, ","))
	}
}

func writeCanon(b *strings.Builder, e Expr, erase bool, resolve func(*Name) string) {
	switch x := e.(type) {
	case *GoalArrow:
		b.WriteString("(garrow [")
		writeParams(b, x.Params)
		b.WriteString("] ")
		writeCanon(b, x.Body, erase, resolve)
		b.WriteString(")")
	case *FuncArrow:
		b.WriteString("(farrow (")
		writeParams(b, x.Params)
		b.WriteString(") ")
		writeList(b, x.Body, "; ", erase, resolve)
		b.WriteString(")")
	case *Serial:
		b.WriteString("(serial ")
		writeList(b, x.Stages, " ", erase, resolve)
		b.WriteString(")")
	case *Parallel:
		b.WriteString("(parallel ")
		writeList(b, x.Stages, " ", erase, resolve)
		b.WriteString(")")
	case *MapLit:
		b.WriteString("(map")
		for _, en := range x.Entries {
			b.WriteString(" ")
			b.WriteString(CanonicalKey(en.Key))
			b.WriteString("=")
			writeCanon(b, en.Value, erase, resolve)
		}
		b.WriteString(")")
	case *Name:
		upper, _ := IsUpper(x.Ident)
		switch {
		case x.Hash != "" && resolve != nil:
			b.WriteString(x.Ident + "#" + resolve(x))
		case x.Hash != "":
			b.WriteString(x.Ident + "#" + x.Hash)
		default:
			b.WriteString(x.Ident)
		}
		if upper && x.Suffix != NoSuffix {
			fmt.Fprintf(b, "/%d", len(x.Args))
		}
		switch x.Suffix {
		case BracketSuffix:
			b.WriteString("[")
			writeList(b, x.Args, ",", erase, resolve)
			b.WriteString("]")
		case CallSuffix:
			b.WriteString("(")
			writeList(b, x.Args, ",", erase, resolve)
			b.WriteString(")")
		}
	case *Anchor:
		b.WriteString("$" + x.Ident)
		b.WriteString("(")
		writeList(b, x.Args, ",", erase, resolve)
		b.WriteString(")")
	case *Policied:
		if !erase {
			for _, p := range x.Policies {
				b.WriteString("@" + p.Ident + "(")
				writeList(b, p.Args, ",", erase, resolve)
				b.WriteString(") ")
			}
		}
		writeCanon(b, x.Target, erase, resolve)
	case *NumberLit:
		b.WriteString("n:" + NormalizeNumberText(x.Text))
	case *StringLit:
		b.WriteString("s:" + strconv.Quote(x.Value))
	case *BoolLit:
		fmt.Fprintf(b, "b:%t", x.Value)
	case *Unary:
		b.WriteString("(" + x.Op + " ")
		writeCanon(b, x.X, erase, resolve)
		b.WriteString(")")
	case *Binary:
		b.WriteString("(" + x.Op + " ")
		writeCanon(b, x.L, erase, resolve)
		b.WriteString(" ")
		writeCanon(b, x.R, erase, resolve)
		b.WriteString(")")
	case *Group:
		writeCanon(b, x.X, erase, resolve)
	default:
		fmt.Fprintf(b, "?%T", e)
	}
}

// CanonicalKey returns the structural identity of a static map key.
func CanonicalKey(k MapKey) string {
	switch k.Kind {
	case KeyIdent, KeyString:
		return "s:" + k.Text
	case KeyNumber:
		return "n:" + NormalizeNumberText(k.Text)
	case KeyBool:
		return "b:" + k.Text
	default:
		return "_"
	}
}

// NormalizeNumberText implements the structural numeric key rule without
// numeric evaluation: drop trailing fractional zeros, an empty decimal point,
// and the sign of zero.
func NormalizeNumberText(t string) string {
	neg := strings.HasPrefix(t, "-")
	t = strings.TrimPrefix(t, "-")
	if strings.Contains(t, ".") {
		t = strings.TrimRight(t, "0")
		t = strings.TrimSuffix(t, ".")
	}
	if t == "0" || t == "" {
		return "0"
	}
	if neg {
		return "-" + t
	}
	return t
}
