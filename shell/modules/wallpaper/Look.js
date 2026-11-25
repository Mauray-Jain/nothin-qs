.pragma library

// forOutput merges the shared wallpaper settings with one monitor's
// overrides. light comes back as 0..1 for the shader.
function forOutput(w, name) {
    const o = (w.monitors || {})[name] || {}
    const pick = (v, fallback) => v === null || v === undefined ? fallback : v
    return {
        path: o.path ? o.path : w.path,
        effect: pick(o.effect, w.effect),
        dotSize: pick(o.dot_size, w.dot_size),
        light: pick(o.light, w.light) / 100
    }
}
