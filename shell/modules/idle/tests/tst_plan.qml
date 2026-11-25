import QtQuick
import QtTest
import "../IdlePlan.js" as IdlePlan

TestCase {
    name: "IdlePlan"

    readonly property var idle: ({
        suspend_mode: "suspend", fade: 5,
        ac: { lock: 300, screen_off: 600, suspend: 0, lock_screen_off: 60 },
        battery: { lock: 180, screen_off: 300, suspend: 840, lock_screen_off: 60 }
    })

    function test_ac() {
        const p = IdlePlan.plan(idle, false)
        compare(p.fadeAt, 295)   // fade starts 5 s before the lock time
        compare(p.fadeFor, 5)
        compare(p.screenOff, 600)
        compare(p.suspend, 0)    // off
        compare(p.lockScreenOff, 60)
        compare(p.suspendCommand, ["systemctl", "suspend"])
    }

    function test_battery() {
        const p = IdlePlan.plan(idle, true)
        compare(p.fadeAt, 175)
        compare(p.suspend, 840)
    }

    function test_no_fade_and_short_lock() {
        compare(IdlePlan.plan(Object.assign({}, idle, { fade: 0 }), false).fadeAt, 300)
        const p = IdlePlan.plan(Object.assign({}, idle, { ac: { lock: 3, screen_off: 0, suspend: 0, lock_screen_off: 0 } }), false)
        compare(p.fadeAt, 1)     // never earlier than 1 s
        compare(p.fadeFor, 2)
    }

    function test_lock_off() {
        const p = IdlePlan.plan(Object.assign({}, idle, { ac: { lock: 0, screen_off: 600, suspend: 0, lock_screen_off: 60 } }), false)
        compare(p.fadeAt, 0)
    }

    function test_suspend_modes() {
        compare(IdlePlan.plan(Object.assign({}, idle, { suspend_mode: "suspend-then-hibernate" }), false).suspendCommand,
                ["systemctl", "suspend-then-hibernate"])
    }
}
