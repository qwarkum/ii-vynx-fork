import QtQuick
import QtQuick.Layouts
import qs
import qs.modules.common
import qs.modules.common.widgets
import qs.services

Item {
    id: root
    anchors.fill: parent

    property bool isExpanded: false

    // Access local Bluetooth data from DynamicIslandPanel
    readonly property string deviceName: {
        var p = root.parent;
        while (p && !p.hasOwnProperty("btDeviceName")) {
            p = p.parent;
        }
        return p ? p.btDeviceName : "";
    }

    readonly property string action: {
        var p = root.parent;
        while (p && !p.hasOwnProperty("btAction")) {
            p = p.parent;
        }
        return p ? p.btAction : "connected";
    }

    readonly property var device: {
        var p = root.parent;
        while (p && !p.hasOwnProperty("btDevice")) {
            p = p.parent;
        }
        return p ? p.btDevice : null;
    }

    readonly property var activeDevice: device ? device : (BluetoothStatus.connectedDevices.length > 0 ? BluetoothStatus.connectedDevices[0] : null)

    // ==========================================
    // 1. CONTRACTED MODE (Compact visual layout)
    // ==========================================
    RowLayout {
        id: contractedLayout
        anchors.fill: parent
        anchors.leftMargin: 12
        anchors.rightMargin: 12
        spacing: 8
        visible: !root.isExpanded

        MaterialSymbol {
            Layout.alignment: Qt.AlignVCenter
            text: root.action === "connected" ? "bluetooth_connected" : "bluetooth_disabled"
            iconSize: 16
            color: root.action === "connected" ? Appearance.colors.colPrimary : Appearance.colors.colOnSurfaceVariant
        }

        StyledText {
            Layout.fillWidth: true
            Layout.alignment: Qt.AlignVCenter
            font.pixelSize: Appearance.font.pixelSize.smaller
            font.bold: true
            color: Appearance.colors.colOnSurface
            text: {
                const name = root.activeDevice ? (root.activeDevice.name || root.activeDevice.alias) : root.deviceName;
                return name !== "" ? name : Translation.tr("Bluetooth Device");
            }
            elide: Text.ElideRight
            maximumLineCount: 1
            wrapMode: Text.NoWrap
        }

        StyledText {
            visible: root.activeDevice ? root.activeDevice.batteryAvailable : false
            Layout.alignment: Qt.AlignVCenter
            font.pixelSize: Appearance.font.pixelSize.smaller
            font.bold: true
            color: {
                if (root.activeDevice && root.activeDevice.battery <= 0.15)
                    return Appearance.m3colors.m3error;
                return Appearance.colors.colOnSurfaceVariant;
            }
            text: root.activeDevice ? Math.round(root.activeDevice.battery * 100) + "%" : ""
        }
    }

    // ==========================================
    // 2. EXPANDED MODE (Details visual layout)
    // ==========================================
    ColumnLayout {
        id: expandedLayout
        anchors.fill: parent
        anchors.leftMargin: 16
        anchors.rightMargin: 16
        anchors.topMargin: 8
        anchors.bottomMargin: 8
        spacing: 6
        visible: root.isExpanded

        // Top Row: Status + Small Device Name
        RowLayout {
            Layout.fillWidth: true
            spacing: 8

            MaterialSymbol {
                text: root.action === "connected" ? "bluetooth_connected" : "bluetooth_disabled"
                iconSize: 14
                color: root.action === "connected" ? Appearance.colors.colPrimary : Appearance.colors.colOnSurfaceVariant
            }

            StyledText {
                text: root.action === "connected" ? Translation.tr("Connected") : Translation.tr("Disconnected")
                font.pixelSize: Appearance.font.pixelSize.smallest
                color: Appearance.colors.colOnSurfaceVariant
            }

            Item { Layout.fillWidth: true }

            StyledText {
                text: root.activeDevice ? (root.activeDevice.name || root.activeDevice.alias) : root.deviceName
                font.pixelSize: Appearance.font.pixelSize.smaller
                font.weight: Font.Bold
                color: Appearance.colors.colOnSurface
                Layout.maximumWidth: 150
                elide: Text.ElideRight
            }
        }

        // Middle Row: Left (rotating icon), Right (battery + ANC)
        RowLayout {
            Layout.fillWidth: true
            Layout.fillHeight: true
            spacing: 10

            // Rotating Icon Shape
            Item {
                Layout.preferredWidth: 48
                Layout.preferredHeight: 48
                Layout.alignment: Qt.AlignVCenter

                MaterialShape {
                    id: cookieShape
                    anchors.fill: parent
                    shapeString: "Cookie12Sided"
                    color: Appearance.colors.colPrimaryContainer

                    RotationAnimation on rotation {
                        from: 0; to: 360
                        duration: 15000
                        loops: Animation.Infinite
                        running: root.isExpanded
                    }
                }

                // Fallback icon
                MaterialSymbol {
                    anchors.centerIn: parent
                    text: root.activeDevice ? Icons.getBluetoothDeviceMaterialSymbol(root.activeDevice.icon || "") : "headphones"
                    iconSize: 20
                    color: Appearance.colors.colOnPrimaryContainer
                }
            }

            // Right side: Battery & ANC
            ColumnLayout {
                Layout.fillWidth: true
                Layout.alignment: Qt.AlignVCenter
                spacing: 4

                // Battery Bar
                RowLayout {
                    visible: root.activeDevice ? root.activeDevice.batteryAvailable : false
                    Layout.fillWidth: true
                    spacing: 6

                    StyledProgressBar {
                        Layout.fillWidth: true
                        Layout.preferredHeight: 6
                        valueBarHeight: 6
                        from: 0
                        to: 1
                        value: root.activeDevice ? root.activeDevice.battery : 0
                        highlightColor: {
                            const battery = root.activeDevice ? root.activeDevice.battery : 0;
                            if (battery <= 0.15) return Appearance.m3colors.m3error;
                            return Appearance.colors.colPrimary;
                        }
                        trackColor: Appearance.colors.colSurfaceContainerHighest
                    }

                    StyledText {
                        text: root.activeDevice ? Math.round(root.activeDevice.battery * 100) + "%" : ""
                        font.pixelSize: Appearance.font.pixelSize.smallest
                        font.weight: Font.Bold
                        color: {
                            const battery = root.activeDevice ? root.activeDevice.battery : 0;
                            if (battery <= 0.15) return Appearance.m3colors.m3error;
                            return Appearance.colors.colOnSurface;
                        }
                    }
                }

                // ANC mode (copied from popup)
                Loader {
                    active: root.activeDevice && (SoundcoreService.isHeadsetSupported(root.activeDevice) || BudsService.isHeadsetSupported(root.activeDevice))
                    Layout.fillWidth: true
                    sourceComponent: RowLayout {
                        spacing: 4

                        readonly property var service: {
                            if (SoundcoreService.isHeadsetSupported(root.activeDevice)) return SoundcoreService;
                            if (BudsService.isHeadsetSupported(root.activeDevice)) return BudsService;
                            return null;
                        }
                        readonly property string currentMode: service ? service.getModeForMac(root.activeDevice.address) : "Normal"

                        RippleButton {
                            id: ancBtn
                            implicitWidth: 22
                            implicitHeight: 22
                            buttonRadius: 11
                            colBackground: parent.currentMode === "NoiseCanceling" ? Appearance.colors.colPrimary : Appearance.colors.colSurfaceContainerHighest
                            colBackgroundHover: parent.currentMode === "NoiseCanceling" ? Appearance.colors.colPrimaryHover : Appearance.colors.colSurfaceContainerHighestHover
                            onClicked: parent.service.setMode(root.activeDevice.address, "NoiseCanceling")

                            MaterialSymbol {
                                anchors.centerIn: parent
                                text: "noise_control_off"
                                iconSize: 12
                                color: ancBtn.colBackground === Appearance.colors.colPrimary ? Appearance.colors.colOnPrimary : Appearance.colors.colOnSurfaceVariant
                            }
                        }

                        RippleButton {
                            id: normalBtn
                            implicitWidth: 22
                            implicitHeight: 22
                            buttonRadius: 11
                            colBackground: parent.currentMode === "Normal" ? Appearance.colors.colPrimary : Appearance.colors.colSurfaceContainerHighest
                            colBackgroundHover: parent.currentMode === "Normal" ? Appearance.colors.colPrimaryHover : Appearance.colors.colSurfaceContainerHighestHover
                            onClicked: parent.service.setMode(root.activeDevice.address, "Normal")

                            MaterialSymbol {
                                anchors.centerIn: parent
                                text: "hearing"
                                iconSize: 12
                                color: normalBtn.colBackground === Appearance.colors.colPrimary ? Appearance.colors.colOnPrimary : Appearance.colors.colOnSurfaceVariant
                            }
                        }

                        RippleButton {
                            id: transBtn
                            implicitWidth: 22
                            implicitHeight: 22
                            buttonRadius: 11
                            colBackground: parent.currentMode === "Transparency" ? Appearance.colors.colPrimary : Appearance.colors.colSurfaceContainerHighest
                            colBackgroundHover: parent.currentMode === "Transparency" ? Appearance.colors.colPrimaryHover : Appearance.colors.colSurfaceContainerHighestHover
                            onClicked: parent.service.setMode(root.activeDevice.address, "Transparency")

                            MaterialSymbol {
                                anchors.centerIn: parent
                                text: "visibility"
                                iconSize: 12
                                color: transBtn.colBackground === Appearance.colors.colPrimary ? Appearance.colors.colOnPrimary : Appearance.colors.colOnSurfaceVariant
                            }
                        }
                    }
                }
            }
        }

        // Bottom Row: Action Buttons
        RowLayout {
            Layout.fillWidth: true
            spacing: 6

            // Disconnect Button
            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: 26
                radius: Appearance.rounding.full
                color: disconnectMa.containsMouse
                    ? Appearance.colors.colErrorContainerHover
                    : Appearance.m3colors.m3errorContainer

                scale: disconnectMa.pressed ? 0.95 : (disconnectMa.containsMouse ? 1.02 : 1.0)

                Behavior on color {
                    animation: Appearance.animation.elementMoveFast.colorAnimation.createObject(this)
                }
                Behavior on scale { NumberAnimation { duration: 150 } }

                RowLayout {
                    anchors.centerIn: parent
                    spacing: 4
                    MaterialSymbol {
                        text: "bluetooth_disabled"
                        iconSize: 12
                        color: Appearance.m3colors.m3onErrorContainer
                    }
                    StyledText {
                        text: Translation.tr("Disconnect")
                        font.pixelSize: Appearance.font.pixelSize.smallest
                        font.weight: Font.Medium
                        color: Appearance.m3colors.m3onErrorContainer
                    }
                }

                MouseArea {
                    id: disconnectMa
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    hoverEnabled: true
                    onClicked: {
                        if (root.activeDevice) {
                            root.activeDevice.connecting = false;
                            root.activeDevice.connected = false;
                        }
                        var p = root.parent;
                        while (p && !p.hasOwnProperty("btNotifActive")) {
                            p = p.parent;
                        }
                        if (p) p.btNotifActive = false;
                    }
                }
            }

            // Settings Button
            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: 26
                radius: Appearance.rounding.full
                color: settingsMa.containsMouse
                    ? Appearance.colors.colSurfaceContainerHighestHover
                    : Appearance.colors.colSurfaceContainerHighest

                scale: settingsMa.pressed ? 0.95 : (settingsMa.containsMouse ? 1.02 : 1.0)

                Behavior on color {
                    animation: Appearance.animation.elementMoveFast.colorAnimation.createObject(this)
                }
                Behavior on scale { NumberAnimation { duration: 150 } }

                RowLayout {
                    anchors.centerIn: parent
                    spacing: 4
                    MaterialSymbol {
                        text: "settings"
                        iconSize: 12
                        color: Appearance.colors.colOnSurface
                    }
                    StyledText {
                        text: Translation.tr("Settings")
                        font.pixelSize: Appearance.font.pixelSize.smallest
                        font.weight: Font.Medium
                        color: Appearance.colors.colOnSurface
                    }
                }

                MouseArea {
                    id: settingsMa
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    hoverEnabled: true
                    onClicked: {
                        var p = root.parent;
                        while (p && !p.hasOwnProperty("btNotifActive")) {
                            p = p.parent;
                        }
                        if (p) p.btNotifActive = false;
                        Quickshell.execDetached(["blueman-manager"]);
                    }
                }
            }
        }
    }
}
