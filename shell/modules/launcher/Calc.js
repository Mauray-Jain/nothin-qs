.pragma library

// A small arithmetic parser for the launcher: + - * / % ^, brackets,
// sqrt abs round floor ceil sin cos tan log (base 10) ln, pi and e.
// Nothing is ever passed to eval. evaluate returns null for anything that
// isn't a calculation (including a bare number).

const funcs = {
    sqrt: Math.sqrt, abs: Math.abs, round: Math.round, floor: Math.floor, ceil: Math.ceil,
    sin: Math.sin, cos: Math.cos, tan: Math.tan, log: Math.log10, ln: Math.log
}
const consts = { pi: Math.PI, e: Math.E }

function tokenize(s) {
    const re = /\s*(?:(\d+\.?\d*(?:[eE][+-]?\d+)?|\.\d+)|([a-z]+)|(.))/gy
    const out = []
    let m
    while (re.lastIndex < s.length && (m = re.exec(s)) !== null) {
        if (m[1] !== undefined) out.push({ num: parseFloat(m[1]) })
        else if (m[2] !== undefined) out.push({ name: m[2] })
        else if (m[3] !== undefined && m[3].trim() !== "") out.push({ op: m[3] })
    }
    return out
}

function evaluate(input) {
    const tokens = tokenize(String(input).toLowerCase())
    if (tokens.length < 2)
        return null // empty, or a bare number or word
    let i = 0
    const peek = () => tokens[i]
    const isOp = o => peek() && peek().op === o
    const fail = () => { throw new Error("not math") }

    function expr() {
        let v = term()
        while (isOp("+") || isOp("-"))
            v = tokens[i++].op === "+" ? v + term() : v - term()
        return v
    }
    function term() {
        let v = unary()
        while (isOp("*") || isOp("/") || isOp("%")) {
            const o = tokens[i++].op
            const r = unary()
            v = o === "*" ? v * r : o === "/" ? v / r : v % r
        }
        return v
    }
    function unary() {
        if (isOp("-")) { i++; return -unary() }
        if (isOp("+")) { i++; return unary() }
        return power()
    }
    function power() {
        const b = primary()
        if (isOp("^")) { i++; return Math.pow(b, unary()) }
        return b
    }
    function primary() {
        const t = tokens[i++] || fail()
        if (t.num !== undefined) return t.num
        if (t.op === "(") {
            const v = expr()
            if (!isOp(")")) fail()
            i++
            return v
        }
        if (t.name !== undefined) {
            if (t.name in consts) return consts[t.name]
            if (t.name in funcs && isOp("(")) return funcs[t.name](primary())
        }
        return fail()
    }

    try {
        const v = expr()
        return i === tokens.length && isFinite(v) ? v : null
    } catch (e) {
        return null
    }
}

// format shows up to 10 significant digits without trailing zeros.
function format(v) {
    if (Math.abs(v) >= 1e21) return String(v)
    return String(parseFloat(v.toPrecision(10)))
}
