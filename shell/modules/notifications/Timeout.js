.pragma library

// forPopup gives how long a popup stays, in ms; 0 means until dismissed.
// expireTimeout is the app's request: -1 leaves it to us, 0 means never.
function forPopup(expireTimeout, critical) {
    if (critical || expireTimeout === 0)
        return 0
    return expireTimeout > 0 ? expireTimeout : 5000
}
