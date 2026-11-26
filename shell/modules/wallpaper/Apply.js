.pragma library

// changes turns a picker choice into config writes: the shared [wallpaper]
// keys, or with thisMonitor that monitor's [wallpaper.monitors.<name>].
// A file inside the wallpaper folder is saved by name, others by path.
function changes(choice, dir, monitor) {
    const base = choice.thisMonitor ? "wallpaper.monitors." + monitor + "." : "wallpaper."
    const file = dir && choice.path.startsWith(dir.replace(/\/$/, "") + "/") ? choice.path.slice(dir.replace(/\/$/, "").length + 1) : choice.path
    return [
        [base + "file", file],
        [base + "effect", choice.effect],
        [base + "dot_size", choice.dotSize],
        [base + "light", choice.light]
    ]
}
