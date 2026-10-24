.pragma library

// Small helpers shared by the ForkYard interface.

function withAlpha(hex, alpha) {
    // QML only understands the #AARRGGBB notation, so the transparency is
    // folded into the colour string instead of using a CSS rgba() value.
    var h = String(hex).replace("#", "")
    if (h.length === 3)
        h = h.charAt(0) + h.charAt(0) + h.charAt(1) + h.charAt(1) + h.charAt(2) + h.charAt(2)
    var r = h.substring(0, 2)
    var g = h.substring(2, 4)
    var b = h.substring(4, 6)
    var a = Math.round(Math.max(0, Math.min(1, alpha)) * 255).toString(16)
    if (a.length < 2)
        a = "0" + a
    return "#" + a + r + g + b
}

function mix(first, second, amount) {
    var a = first
    var b = second
    if (a.charAt(0) === "#")
        a = a.replace("#", "")
    if (b.charAt(0) === "#")
        b = b.replace("#", "")
    if (a.length === 3)
        a = a.charAt(0) + a.charAt(0) + a.charAt(1) + a.charAt(1) + a.charAt(2) + a.charAt(2)
    if (b.length === 3)
        b = b.charAt(0) + b.charAt(0) + b.charAt(1) + b.charAt(1) + b.charAt(2) + b.charAt(2)
    var r = Math.round(parseInt(a.substring(0, 2), 16) * (1 - amount) + parseInt(b.substring(0, 2), 16) * amount)
    var g = Math.round(parseInt(a.substring(2, 4), 16) * (1 - amount) + parseInt(b.substring(2, 4), 16) * amount)
    var bl = Math.round(parseInt(a.substring(4, 6), 16) * (1 - amount) + parseInt(b.substring(4, 6), 16) * amount)
    return "#" + ((1 << 24) + (r << 16) + (g << 8) + bl).toString(16).slice(1)
}
