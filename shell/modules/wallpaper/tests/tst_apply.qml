import QtQuick
import QtTest
import "../Apply.js" as Apply

TestCase {
    name: "WallpaperApply"

    function test_all_monitors() {
        compare(Apply.changes({ path: "/home/a/Pictures/Wallpapers/sea.jpg", effect: "color", dotSize: 12, light: 60, thisMonitor: false },
                              "/home/a/Pictures/Wallpapers", "eDP-1"),
                [["wallpaper.file", "sea.jpg"], ["wallpaper.effect", "color"], ["wallpaper.dot_size", 12], ["wallpaper.light", 60]])
    }

    function test_this_monitor_only() {
        compare(Apply.changes({ path: "/home/a/Pictures/Wallpapers/sea.jpg", effect: "dots", dotSize: 17, light: 50, thisMonitor: true },
                              "/home/a/Pictures/Wallpapers", "HDMI-A-1"),
                [["wallpaper.monitors.HDMI-A-1.file", "sea.jpg"], ["wallpaper.monitors.HDMI-A-1.effect", "dots"],
                 ["wallpaper.monitors.HDMI-A-1.dot_size", 17], ["wallpaper.monitors.HDMI-A-1.light", 50]])
    }

    function test_file_outside_the_folder_keeps_its_path() {
        compare(Apply.changes({ path: "/tmp/x.png", effect: "none", dotSize: 17, light: 50, thisMonitor: false }, "/home/a/w", "eDP-1")[0],
                ["wallpaper.file", "/tmp/x.png"])
    }
}
