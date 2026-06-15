import QtQuick
import QtQuick.Controls
import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland
import qs
import qs.services
import qs.modules.common
import qs.modules.common.widgets
import qs.modules.waffle.looks
import qs.modules.waffle.notificationCenter

Scope {
    id: notificationPopup

    PanelWindow {
        id: root
        visible: (Notifications.popupList.length > 0) && !GlobalStates.screenLocked
        screen: Quickshell.screens.find(s => s.name === Hyprland.focusedMonitor?.name) ?? null

        property string position: Config.options.notifications.position ?? "top_right"
        property bool isTop: position.startsWith("top")
        property bool isBottom: position.startsWith("bottom")
        property bool isLeft: position.endsWith("left")
        property bool isRight: position.endsWith("right")

        WlrLayershell.namespace: "quickshell:notificationPopup"
        WlrLayershell.layer: WlrLayer.Overlay
        exclusiveZone: 0

        anchors {
            top: true
            bottom: true
            left: true
            right: true
        }

        mask: Region {
            item: listview
        }

        color: "transparent"

        WListView {
            id: listview
            anchors {
                left: root.isLeft ? parent.left : undefined
                right: root.isRight ? parent.right : undefined
                horizontalCenter: (!root.isLeft && !root.isRight) ? parent.horizontalCenter : undefined
                top: root.isTop ? parent.top : undefined
                bottom: root.isBottom ? parent.bottom : undefined
            }
            leftMargin: 16
            rightMargin: 16
            topMargin: 16
            bottomMargin: 16

            height: Math.min(contentItem.height + topMargin + bottomMargin, parent.height)
            width: 396
            spacing: 12

            verticalLayoutDirection: root.isBottom ? ListView.BottomToTop : ListView.TopToBottom

            model: ScriptModel {
                values: Notifications.popupList
            }
            delegate: WSingleNotification {
                required property var modelData
                notification: modelData
                width: ListView.view.width - ListView.view.leftMargin - ListView.view.rightMargin
            }
        }
    }
}
