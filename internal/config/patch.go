package config

import (
	"bytes"
	"encoding/json"
	"errors"
	"fmt"
	"regexp"
	"slices"
	"strings"

	"github.com/pelletier/go-toml/v2/unstable"
)

// Patch sets the key at the dotted path to a JSON value, editing doc in place
// so comments, order and formatting elsewhere survive. It refuses to touch a
// document that doesn't load, and refuses a result that doesn't load.
func Patch(doc []byte, path string, value []byte) ([]byte, error) {
	if _, err := Load(doc); err != nil {
		return nil, fmt.Errorf("config.toml has an error, fix it before saving: %w", err)
	}
	val, err := encode(value)
	if err != nil {
		return nil, fmt.Errorf("%s: %w", path, err)
	}
	keys := strings.Split(path, ".")
	table, key := keys[:len(keys)-1], keys[len(keys)-1]
	line := []byte(bareOrQuoted(key) + " = " + val + "\n")

	var out []byte
	l := layout(doc)
	switch kv := find(doc, keys); {
	case kv != nil:
		out = splice(doc, kv.start, kv.end, []byte(bareOrQuoted(key)+" = "+val))
	case len(table) == 0 && l.rootEnd >= 0:
		out = splice(doc, lineEnd(doc, l.rootEnd), lineEnd(doc, l.rootEnd), line)
	case len(table) == 0 && l.firstTable >= 0:
		out = splice(doc, l.firstTable, l.firstTable, line)
	case len(table) == 0:
		out = appendLines(doc, line)
	default:
		t := l.table(table)
		if t == nil {
			header := "[" + strings.Join(mapKeys(table), ".") + "]\n"
			if len(bytes.TrimSpace(doc)) > 0 {
				header = "\n" + header
			}
			out = appendLines(doc, append([]byte(header), line...))
		} else {
			at := lineEnd(doc, t.last)
			out = splice(doc, at, at, line)
		}
	}
	if _, err := Load(out); err != nil {
		return nil, err
	}
	return out, nil
}

type keyValue struct {
	path       []string
	start, end int // byte range of `key = value`
	line       int
}

type table struct {
	path []string
	last int // offset just past the header, or past the table's last key/value
}

type docLayout struct {
	kvs        []keyValue
	tables     []*table
	rootEnd    int // end of the last top-level key/value, -1 if none
	firstTable int // start of the first table header line, -1 if none
}

func (l docLayout) table(path []string) *table {
	for _, t := range l.tables {
		if slices.Equal(t.path, path) {
			return t
		}
	}
	return nil
}

// layout walks the expressions of a document that is known to parse.
func layout(doc []byte) docLayout {
	l := docLayout{rootEnd: -1, firstTable: -1}
	var cur *table
	p := unstable.Parser{}
	p.Reset(doc)
	for p.NextExpression() {
		e := p.Expression()
		var parts []string
		start := -1
		for it := e.Key(); it.Next(); {
			k := it.Node()
			if start < 0 {
				start = int(k.Raw.Offset)
			}
			parts = append(parts, string(k.Data))
		}
		switch e.Kind {
		case unstable.Table, unstable.ArrayTable:
			cur = &table{path: parts, last: start}
			l.tables = append(l.tables, cur)
			if l.firstTable < 0 {
				l.firstTable = bytes.LastIndexByte(doc[:start], '\n') + 1
			}
		case unstable.KeyValue:
			end := int(e.Raw.Offset + e.Raw.Length)
			kv := keyValue{start: int(e.Raw.Offset), end: end, line: p.Shape(e.Raw).Start.Line}
			if cur == nil {
				kv.path = parts
				l.rootEnd = end
			} else {
				kv.path = append(slices.Clone(cur.path), parts...)
				cur.last = end
			}
			l.kvs = append(l.kvs, kv)
		}
	}
	return l
}

func find(doc []byte, path []string) *keyValue {
	for _, kv := range layout(doc).kvs {
		if slices.Equal(kv.path, path) {
			return &kv
		}
	}
	return nil
}

// lineEnd returns the offset just past the newline ending the line at off.
func lineEnd(doc []byte, off int) int {
	if i := bytes.IndexByte(doc[off:], '\n'); i >= 0 {
		return off + i + 1
	}
	return len(doc)
}

func splice(doc []byte, start, end int, insert []byte) []byte {
	if start == len(doc) && start > 0 && doc[start-1] != '\n' {
		insert = append([]byte("\n"), insert...)
	}
	out := slices.Clone(doc[:start])
	out = append(out, insert...)
	return append(out, doc[end:]...)
}

func appendLines(doc, lines []byte) []byte {
	return splice(doc, len(doc), len(doc), lines)
}

var bareKey = regexp.MustCompile(`^[A-Za-z0-9_-]+$`)

func bareOrQuoted(k string) string {
	if bareKey.MatchString(k) {
		return k
	}
	q, _ := json.Marshal(k)
	return string(q)
}

func mapKeys(ks []string) []string {
	out := make([]string, len(ks))
	for i, k := range ks {
		out[i] = bareOrQuoted(k)
	}
	return out
}

// encode turns a JSON scalar or array into TOML value text.
func encode(value []byte) (string, error) {
	d := json.NewDecoder(bytes.NewReader(value))
	d.UseNumber()
	var v any
	if err := d.Decode(&v); err != nil {
		return "", err
	}
	return encodeValue(v)
}

func encodeValue(v any) (string, error) {
	switch v := v.(type) {
	case string:
		var b bytes.Buffer
		e := json.NewEncoder(&b)
		e.SetEscapeHTML(false)
		e.Encode(v)
		return strings.TrimSuffix(b.String(), "\n"), nil
	case json.Number:
		return v.String(), nil
	case bool:
		return fmt.Sprint(v), nil
	case []any:
		parts := make([]string, len(v))
		for i, x := range v {
			s, err := encodeValue(x)
			if err != nil {
				return "", err
			}
			parts[i] = s
		}
		return "[" + strings.Join(parts, ", ") + "]", nil
	}
	return "", errors.New("only strings, numbers, booleans and arrays can be set")
}
