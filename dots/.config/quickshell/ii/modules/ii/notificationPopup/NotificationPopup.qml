import qs
import qs.modules.common
import qs.modules.common.widgets
import qs.services
import QtQuick
import QtQuick.Controls
import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland

Scope {
    id: notificationPopup

    PanelWindow {
        id: root
        visible: (Notifications.popupList.length > 0) && !GlobalStates.screenLocked
        screen: Quickshell.screens.find(s => Config.options.notifications.monitor.enable ? s.name === Config.options.notifications.monitor.name : s.name === Hyprland.focusedMonitor?.name) ?? null

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

        NotificationListView {
            id: listview
            anchors {
                left: root.isLeft ? parent.left : undefined
                right: root.isRight ? parent.right : undefined
                horizontalCenter: (!root.isLeft && !root.isRight) ? parent.horizontalCenter : undefined
                top: root.isTop ? parent.top : undefined
                bottom: root.isBottom ? parent.bottom : undefined

                leftMargin: root.isLeft ? Math.max(Appearance.sizes.hyprlandGapsOut, Appearance.rounding.windowRounding * 0.5) : 0
                rightMargin: root.isRight ? Math.max(Appearance.sizes.hyprlandGapsOut, Appearance.rounding.windowRounding * 0.5) : 0
                topMargin: Math.max(Appearance.sizes.hyprlandGapsOut, Appearance.rounding.windowRounding * 0.5)
                bottomMargin: Math.max(Appearance.sizes.hyprlandGapsOut, Appearance.rounding.windowRounding * 0.5)
            }
            width: Appearance.sizes.notificationPopupWidth
            popup: true
            height: Math.min(contentItem.height + topMargin + bottomMargin, parent.height)
            verticalLayoutDirection: root.isBottom ? ListView.BottomToTop : ListView.TopToBottom
        }
    }
}
