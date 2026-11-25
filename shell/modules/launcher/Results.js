.pragma library
.import "Calc.js" as Calc
.import "Rank.js" as Rank

// build lists what the launcher shows for query: a calculator answer first,
// then up to 8 apps, then up to 5 open windows whose title or app matches.
function build(query, apps, scores, windows) {
    const out = []
    const v = Calc.evaluate(query)
    if (v !== null)
        out.push({ kind: "calc", icon: "calculate", title: Calc.format(v), subtitle: "= COPY RESULT" })
    for (const a of Rank.apps(query, apps, scores).slice(0, 8))
        out.push({ kind: "app", app: a, iconName: a.icon, title: a.name, subtitle: a.genericName || "APP" })
    const q = query.trim().toLowerCase()
    if (q)
        for (const w of windows.filter(w => (w.title + " " + w.app_id).toLowerCase().includes(q)).slice(0, 5))
            out.push({ kind: "window", win: w, icon: "select_window", title: w.title, subtitle: "WINDOW · " + w.app_id })
    return out
}
