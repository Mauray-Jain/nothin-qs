package niri

import (
	"fmt"
	"strings"
)

// node is one KDL node: name, positional arguments, properties and children.
// Values are kept as text (strings unquoted); that's all nothin needs.
type node struct {
	Name     string
	Args     []string
	Props    map[string]string
	Children []node
}

// parseKDL reads the parts of KDL that niri configs use: nodes, arguments,
// key=value properties, children in braces, ";" separators, "quoted" and
// r#"raw"# strings, // and /* */ comments, and /- to comment out a node.
func parseKDL(src string) ([]node, error) {
	p := &kdlParser{src: src}
	nodes, err := p.nodes(false)
	if err != nil {
		return nil, fmt.Errorf("line %d: %w", p.line(), err)
	}
	return nodes, nil
}

type kdlParser struct {
	src string
	pos int
}

func (p *kdlParser) line() int { return strings.Count(p.src[:p.pos], "\n") + 1 }

func (p *kdlParser) peek() byte {
	if p.pos < len(p.src) {
		return p.src[p.pos]
	}
	return 0
}

// skip passes spaces and comments; with newlines it passes those too.
func (p *kdlParser) skip(newlines bool) {
	for p.pos < len(p.src) {
		c := p.src[p.pos]
		switch {
		case c == ' ' || c == '\t' || c == '\r' || c == '\\':
			p.pos++
		case c == '\n' && newlines:
			p.pos++
		case strings.HasPrefix(p.src[p.pos:], "//"):
			for p.pos < len(p.src) && p.src[p.pos] != '\n' {
				p.pos++
			}
		case strings.HasPrefix(p.src[p.pos:], "/*"):
			end := strings.Index(p.src[p.pos+2:], "*/")
			if end < 0 {
				p.pos = len(p.src)
				return
			}
			p.pos += end + 4
		default:
			return
		}
	}
}

func (p *kdlParser) nodes(inBlock bool) ([]node, error) {
	var out []node
	for {
		p.skip(true)
		for p.peek() == ';' {
			p.pos++
			p.skip(true)
		}
		switch c := p.peek(); {
		case c == 0:
			if inBlock {
				return nil, fmt.Errorf("missing }")
			}
			return out, nil
		case c == '}':
			if !inBlock {
				return nil, fmt.Errorf("unexpected }")
			}
			p.pos++
			return out, nil
		}
		dropped := false
		if strings.HasPrefix(p.src[p.pos:], "/-") {
			p.pos += 2
			p.skip(true)
			dropped = true
		}
		n, err := p.node()
		if err != nil {
			return nil, err
		}
		if !dropped {
			out = append(out, n)
		}
	}
}

func (p *kdlParser) node() (node, error) {
	name, err := p.value()
	if err != nil {
		return node{}, err
	}
	n := node{Name: name, Props: map[string]string{}}
	for {
		p.skip(false)
		switch c := p.peek(); {
		case c == 0 || c == '\n' || c == ';' || c == '}':
			return n, nil
		case c == '{':
			p.pos++
			kids, err := p.nodes(true)
			if err != nil {
				return node{}, err
			}
			n.Children = kids
			return n, nil
		case strings.HasPrefix(p.src[p.pos:], "/-"):
			p.pos += 2 // a commented-out argument or block: read it and drop it
			p.skip(false)
			if p.peek() == '{' {
				p.pos++
				if _, err := p.nodes(true); err != nil {
					return node{}, err
				}
			} else if _, err := p.value(); err != nil {
				return node{}, err
			}
		default:
			v, err := p.value()
			if err != nil {
				return node{}, err
			}
			if p.peek() == '=' {
				p.pos++
				pv, err := p.value()
				if err != nil {
					return node{}, err
				}
				n.Props[v] = pv
			} else {
				n.Args = append(n.Args, v)
			}
		}
	}
}

// value reads a bare word, a "string" or a r#"raw string"#.
func (p *kdlParser) value() (string, error) {
	s := p.src[p.pos:]
	switch {
	case strings.HasPrefix(s, `"`):
		var b strings.Builder
		for i := 1; i < len(s); i++ {
			switch s[i] {
			case '\\':
				if i+1 < len(s) {
					i++
					switch s[i] {
					case 'n':
						b.WriteByte('\n')
					case 't':
						b.WriteByte('\t')
					default:
						b.WriteByte(s[i])
					}
				}
			case '"':
				p.pos += i + 1
				return b.String(), nil
			case '\n':
				return "", fmt.Errorf("unterminated string")
			default:
				b.WriteByte(s[i])
			}
		}
		return "", fmt.Errorf("unterminated string")
	case strings.HasPrefix(s, "r#") || strings.HasPrefix(s, "#\"") || strings.HasPrefix(s, `r"`):
		start := strings.IndexByte(s, '"')
		hashes := strings.Count(s[:start], "#")
		end := strings.Index(s[start+1:], `"`+strings.Repeat("#", hashes))
		if end < 0 {
			return "", fmt.Errorf("unterminated raw string")
		}
		p.pos += start + 1 + end + 1 + hashes
		return s[start+1 : start+1+end], nil
	}
	i := 0
	for i < len(s) && !strings.ContainsRune(" \t\r\n;{}=\"", rune(s[i])) {
		i++
	}
	if i == 0 {
		return "", fmt.Errorf("unexpected %q", s[0])
	}
	p.pos += i
	return strings.TrimPrefix(s[:i], "#"), nil // KDL v2 keywords: #true, #null
}
