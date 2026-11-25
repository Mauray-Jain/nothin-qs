.pragma library

// parse reads `cliphist list` output: one "id<TAB>preview" per line.
function parse(output) {
    const out = []
    for (const line of String(output).split("\n")) {
        const tab = line.indexOf("\t")
        if (tab < 1)
            continue
        const text = line.slice(tab + 1)
        out.push({ id: line.slice(0, tab), text: text, image: /^\[\[ binary data .* \]\]$/.test(text) })
    }
    return out
}

function filter(entries, query) {
    const q = query.trim().toLowerCase()
    return q ? entries.filter(e => e.text.toLowerCase().includes(q)) : entries
}
