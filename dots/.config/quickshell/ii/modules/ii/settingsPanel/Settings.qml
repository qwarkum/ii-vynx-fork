import Quickshell.Io
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland
import qs
import qs.services
import qs.modules.common
import qs.modules.common.widgets
import qs.modules.common.functions as CF

Scope {
    id: root

    Component.onCompleted: {
        GlobalStates.settingsOpen = false;
        console.log("[Settings] Initialized integrated settings panel from modules/ii/settingsPanel/Settings.qml");
    }

    PanelWindow {
        id: panelWindow
        visible: GlobalStates.settingsOpen

        function hide() {
            GlobalStates.settingsOpen = false;
        }

        exclusiveZone: 0
        WlrLayershell.namespace: "quickshell:settings"
        WlrLayershell.layer: WlrLayer.Overlay
        WlrLayershell.keyboardFocus: GlobalStates.settingsOpen ? WlrKeyboardFocus.OnDemand : WlrKeyboardFocus.None
        color: "transparent"

        anchors {
            top: true
            bottom: true
            left: true
            right: true
        }

        onVisibleChanged: {
            if (visible) {
                GlobalFocusGrab.addDismissable(panelWindow);
            } else {
                GlobalFocusGrab.removeDismissable(panelWindow);
            }
        }

        Connections {
            target: GlobalFocusGrab
            function onDismissed() {
                panelWindow.hide();
            }
        }

        Rectangle {
            anchors.fill: parent
            color: "transparent"
            opacity: GlobalStates.settingsOpen ? 1 : 0
            z: 0
            Behavior on opacity {
                NumberAnimation { duration: 200; easing.type: Easing.OutCubic }
            }
            MouseArea {
                anchors.fill: parent
                propagateComposedEvents: false
                onClicked: panelWindow.hide()
            }
        }

        Rectangle {
            id: settingsWindow
            anchors.centerIn: parent
            width: Math.min(parent.width - 80, 1100)
            height: Math.min(parent.height - 80, 750)
            color: Appearance.colors.colLayer0
            border.width: 1
            border.color: Appearance.colors.colLayer0Border
            radius: Appearance.rounding.windowRounding

            opacity: GlobalStates.settingsOpen ? 1 : 0
            scale: GlobalStates.settingsOpen ? 1 : 0.95

            Behavior on opacity {
                NumberAnimation { duration: 200; easing.type: Easing.OutCubic }
            }
            Behavior on scale {
                NumberAnimation { duration: 200; easing.type: Easing.OutCubic }
            }

            Keys.onPressed: (event) => {
                if (event.key === Qt.Key_Escape) {
                    panelWindow.hide();
                }
            }

            SettingsContent {
                anchors.fill: parent
            }
        }
    }

    IpcHandler {
        target: "settings"
        function toggle() { GlobalStates.settingsOpen = !GlobalStates.settingsOpen; }
        function open()   { GlobalStates.settingsOpen = true; }
        function close()  { GlobalStates.settingsOpen = false; }
        function openPage(data: string) {
            console.log("[Settings] IPC openPage received:", data);
            GlobalStates.settingsOpen = true;
            GlobalStates.settingsPage = data;
        }
    }

    GlobalShortcut {
        name: "settingsToggle"
        description: "Toggles settings panel"
        onPressed: GlobalStates.settingsOpen = !GlobalStates.settingsOpen;
    }
}
