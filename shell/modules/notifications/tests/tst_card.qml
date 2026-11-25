import QtQuick
import QtTest
import "../"

Item {
    width: 400
    height: 300

    property var n: ({
        appName: "Firefox", summary: "Download finished", body: "nothin.tar.gz", urgency: 1,
        dismissed: false, invoked: "",
        actions: [ { identifier: "open", text: "Open", invoke() { n.invoked = "open" } } ],
        dismiss() { this.dismissed = true }
    })

    NotificationCard { id: card; width: 360; notification: n }

    TestCase {
        name: "NotificationCard"
        when: windowShown

        function test_shows_app_summary_and_body() {
            compare(card.header, "FIREFOX")
            compare(card.summaryText, "Download finished")
            compare(card.bodyText, "nothin.tar.gz")
        }

        function test_action_buttons_invoke() {
            const button = findChild(card, "action-open")
            verify(button)
            mouseClick(button)
            compare(n.invoked, "open")
        }

        function test_close_dismisses() {
            mouseClick(findChild(card, "close"))
            verify(n.dismissed)
        }
    }
}
