.pragma library

// apps matches launcher entries ({id, name, genericName, keywords}) against
// query. Better matches first: the name starts with it, a word in the name
// does, the name contains it, the generic name, keywords or id contain it,
// and last the letters appear in order in the name. Within a tier the most
// used entry (scores: id → frecency) wins, then the name.
function tier(q, a) {
    const name = a.name.toLowerCase()
    if (name.startsWith(q)) return 5
    if (name.split(/[\s\-_.]+/).some(w => w.startsWith(q))) return 4
    if (name.includes(q)) return 3
    const other = [a.genericName || "", a.id || ""].concat(a.keywords || []).map(s => s.toLowerCase())
    if (other.some(s => s.includes(q))) return 2
    let j = 0
    for (const c of name)
        if (c === q[j]) j++
    return j === q.length ? 1 : 0
}

function apps(query, list, scores) {
    const q = query.trim().toLowerCase()
    return list
        .map(a => ({ a: a, t: q ? tier(q, a) : 1, s: scores[a.id] || 0 }))
        .filter(x => x.t > 0)
        .sort((x, y) => y.t - x.t || y.s - x.s || x.a.name.localeCompare(y.a.name))
        .map(x => x.a)
}
