.pragma library

// rectFrom gives the rectangle between two drag points, whichever way it went.
function rectFrom(a, b) {
    return { x: Math.min(a.x, b.x), y: Math.min(a.y, b.y), width: Math.abs(b.x - a.x), height: Math.abs(b.y - a.y) }
}

// toPixels turns a logical rectangle into whole image pixels.
function toPixels(r, scale) {
    return { x: Math.round(r.x * scale), y: Math.round(r.y * scale), width: Math.round(r.width * scale), height: Math.round(r.height * scale) }
}

// arrowHead gives the two back corners of an arrow from (x1,y1) to (x2,y2).
function arrowHead(x1, y1, x2, y2, size) {
    const a = Math.atan2(y2 - y1, x2 - x1)
    return [
        { x: x2 - size * Math.cos(a - Math.PI / 7), y: y2 - size * Math.sin(a - Math.PI / 7) },
        { x: x2 - size * Math.cos(a + Math.PI / 7), y: y2 - size * Math.sin(a + Math.PI / 7) }
    ]
}

function pad(n) {
    return n < 10 ? "0" + n : String(n)
}

// fileName: "nothin-2026-11-26-150409.png"
function fileName(d) {
    return "nothin-" + d.getFullYear() + "-" + pad(d.getMonth() + 1) + "-" + pad(d.getDate()) + "-" +
        pad(d.getHours()) + pad(d.getMinutes()) + pad(d.getSeconds()) + ".png"
}
