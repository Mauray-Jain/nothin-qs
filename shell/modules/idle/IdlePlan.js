.pragma library

// plan turns [idle] into the timings to use now: the times for AC or battery,
// the fade before the idle lock folded in, and the suspend command.
// All in seconds; 0 means that step is off.
function plan(idle, onBattery) {
    const t = onBattery ? idle.battery : idle.ac
    let fadeAt = 0, fadeFor = 0
    if (t.lock > 0) {
        fadeAt = Math.max(1, t.lock - idle.fade)
        fadeFor = t.lock - fadeAt
    }
    return {
        fadeAt: fadeAt,     // idle this long: start fading, then lock after fadeFor
        fadeFor: fadeFor,
        screenOff: t.screen_off,
        suspend: t.suspend,
        lockScreenOff: t.lock_screen_off,
        suspendCommand: ["systemctl", idle.suspend_mode]
    }
}
