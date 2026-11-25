.pragma library
.import "Calc.js" as Calc
.import "Rank.js" as Rank
.import "EmojiData.js" as EmojiData

// build lists what the launcher shows for query. ctx: { apps, scores,
// windows, files (the daemon's paths for fileQuery(query)), searchUrl, home }.
//   ":name"  emoji        "/name"  files        "?words"  web search
//   anything else: a calculator answer, up to 8 apps, up to 5 open windows,
//   and a web search row last.
function build(query, ctx) {
    if (query.startsWith(":"))
        return emoji(query.slice(1))
    if (query.startsWith("/"))
        return ctx.files.map(p => file(p, ctx.home))
    if (query.startsWith("?"))
        return query.slice(1).trim() ? [web(query.slice(1), ctx.searchUrl)] : []

    const out = []
    const v = Calc.evaluate(query)
    if (v !== null)
        out.push({ kind: "calc", icon: "calculate", title: Calc.format(v), subtitle: "= copy result" })
    for (const a of Rank.apps(query, ctx.apps, ctx.scores).slice(0, 8))
        out.push({ kind: "app", app: a, title: a.name, subtitle: a.genericName || "app" })
    const q = query.trim().toLowerCase()
    if (q) {
        for (const w of ctx.windows.filter(w => (w.title + " " + w.app_id).toLowerCase().includes(q)).slice(0, 5))
            out.push({ kind: "window", win: w, icon: "select_window", title: w.title, subtitle: "window · " + w.app_id })
        out.push(web(query, ctx.searchUrl))
    }
    return out
}

// fileQuery is what to ask the daemon for, or "" when query isn't a file search.
function fileQuery(query) {
    return query.startsWith("/") ? query.slice(1).trim() : ""
}

function emoji(words) {
    const ws = words.trim().toLowerCase().split(/\s+/).filter(w => w)
    if (ws.length === 0)
        return []
    return EmojiData.list
        .filter(e => ws.every(w => e[1].includes(w)))
        .slice(0, 40)
        .map(e => ({ kind: "emoji", emoji: e[0], icon: "mood", title: e[0] + "   " + e[1], subtitle: "copy" }))
}

function file(path, home) {
    const slash = path.lastIndexOf("/")
    let dir = path.slice(0, slash) || "/"
    if (home && (dir === home || dir.startsWith(home + "/")))
        dir = "~" + dir.slice(home.length)
    return { kind: "file", path: path, icon: "description", title: path.slice(slash + 1), subtitle: dir }
}

function web(words, searchUrl) {
    const q = words.trim()
    return { kind: "web", url: searchUrl.replace("%s", encodeURIComponent(q)), icon: "travel_explore",
             title: "Search the web for " + q, subtitle: "web" }
}
