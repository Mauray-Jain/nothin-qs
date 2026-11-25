.pragma library

// The desktop is a 3×3 grid inside a margin. The hero clock and greeting take
// the two top-left cells; widgets fill the other cells in config order. In the
// free layout a widget with a position goes there instead, one cell in size.

const margin = 30
const gap = 20

function cell(i, w, h) {
    const cw = (w - 2 * margin - 2 * gap) / 3
    const ch = (h - 2 * margin - 2 * gap) / 3
    return { x: margin + (i % 3) * (cw + gap), y: margin + Math.floor(i / 3) * (ch + gap), width: cw, height: ch }
}

function hero(w, h) {
    const a = cell(0, w, h), b = cell(1, w, h)
    return { x: a.x, y: a.y, width: b.x + b.width - a.x, height: a.height }
}

function slots(count, withHero) {
    const free = withHero ? [2, 3, 4, 5, 6, 7, 8] : [0, 1, 2, 3, 4, 5, 6, 7, 8]
    return free.slice(0, count)
}

// place gives the rect of widget `name`, the `index`th in desktop.widgets.
function place(desktop, name, index, withHero, w, h) {
    const slot = cell(slots(index + 1, withHero)[index], w, h)
    const p = desktop.layout === "free" ? (desktop.positions || {})[name] : undefined
    if (!p)
        return slot
    return {
        x: Math.max(0, Math.min(w - slot.width, Math.round(p[0] * w))),
        y: Math.max(0, Math.min(h - slot.height, Math.round(p[1] * h))),
        width: slot.width,
        height: slot.height
    }
}
