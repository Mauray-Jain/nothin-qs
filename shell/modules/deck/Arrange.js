.pragma library

// snap moves a dragged monitor rect {x, y, width, height} (logical pixels)
// against the others: edge to edge, or edges aligned, within `threshold`.
function snap(r, others, threshold) {
    let x = r.x, y = r.y, bestX = threshold + 1, bestY = threshold + 1
    for (const o of others) {
        for (const cx of [o.x + o.width, o.x - r.width, o.x, o.x + o.width - r.width]) {
            const d = Math.abs(cx - r.x)
            if (d <= threshold && d < bestX) { bestX = d; x = cx }
        }
        for (const cy of [o.y + o.height, o.y - r.height, o.y, o.y + o.height - r.height]) {
            const d = Math.abs(cy - r.y)
            if (d <= threshold && d < bestY) { bestY = d; y = cy }
        }
    }
    return { x: x, y: y }
}

function modeValue(m) {
    return m.width + "x" + m.height + "@" + parseFloat(m.refresh.toFixed(3))
}

// modes lists an output's modes once each, biggest and fastest first:
// [{ value: "2560x1440@165.08", label: "2560×1440 · 165 HZ" }]
function modes(output) {
    const seen = {}
    return (output.modes || [])
        .slice()
        .sort((a, b) => b.width * b.height - a.width * a.height || b.refresh - a.refresh)
        .filter(m => !seen[modeValue(m)] && (seen[modeValue(m)] = true))
        .map(m => ({ value: modeValue(m), label: m.width + "×" + m.height + " · " + Math.round(m.refresh) + " HZ" }))
}

function currentMode(output) {
    const m = (output.modes || [])[output.current_mode]
    return m ? modeValue(m) : ""
}
