import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Services.UPower
import qs
import qs.services
import qs.modules.common
import qs.modules.common.widgets
import qs.modules.common.functions

Item {
    id: root
    property bool borderless: Config.options.bar.borderless
    property bool showDate: Config.options.bar.verbose
    property bool vertical: Config.options.bar.vertical
    property bool isMaterial: true // Forced expressive

    implicitWidth: vertical ? Appearance.sizes.verticalBarWidth : pill.implicitWidth
    implicitHeight: vertical ? flow.implicitHeight + 6 : pill.implicitHeight

    MouseArea {
        id: mouseArea
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onPressed: {
            GlobalStates.sidebarRightOpen = !GlobalStates.sidebarRightOpen;
        }
    }

    Canvas {
        id: pill
        visible: root.isMaterial
        anchors.centerIn: parent

        property color pillColor: GlobalStates.sidebarRightOpen 
            ? Appearance.colors.colPrimary 
            : (mouseArea.containsMouse ? Appearance.colors.colLayer4Hover : Appearance.colors.colSecondaryContainer)

        property color borderColor: GlobalStates.sidebarRightOpen 
            ? "transparent" 
            : Appearance.colors.colPrimary

        property real borderWidth: GlobalStates.sidebarRightOpen ? 0 : 1.5
        property real dashLength: GlobalStates.sidebarRightOpen ? 0 : 6
        property real gapLength: GlobalStates.sidebarRightOpen ? 0 : 4
        property real radius: Config.options.bar.barGroupStyle === 1 ? Appearance.rounding.windowRounding : Appearance.rounding.full

        implicitWidth: root.vertical ? Appearance.sizes.verticalBarWidth - 6 : flow.implicitWidth + 16
        implicitHeight: root.vertical ? flow.implicitHeight + 14 : flow.implicitHeight + 8

        onPillColorChanged: requestPaint()
        onBorderColorChanged: requestPaint()
        onWidthChanged: requestPaint()
        onHeightChanged: requestPaint()

        Behavior on pillColor {
            ColorAnimation { duration: 150 }
        }

        onPaint: {
            if (width <= 0 || height <= 0) return;
            var ctx = getContext("2d");
            ctx.clearRect(0, 0, width, height);

            var w = width;
            var h = height;
            var bw = borderWidth;
            var r = Math.min(radius, (w - 2 * bw) / 2, (h - 2 * bw) / 2);

            ctx.save();

            ctx.beginPath();
            ctx.moveTo(bw + r, bw);
            ctx.arcTo(w - bw, bw, w - bw, h - bw, r);
            ctx.arcTo(w - bw, h - bw, bw, h - bw, r);
            ctx.arcTo(bw, h - bw, bw, bw, r);
            ctx.arcTo(bw, bw, w - bw, bw, r);
            ctx.closePath();

            ctx.fillStyle = pillColor;
            ctx.fill();

            ctx.strokeStyle = borderColor;
            ctx.lineWidth = bw;
            ctx.setLineDash([dashLength, gapLength]);
            ctx.stroke();

            ctx.restore();
        }
    }

    Flow {
        id: flow
        anchors.centerIn: parent
        flow: root.vertical ? Flow.TopToBottom : Flow.LeftToRight
        spacing: isMaterial ? 6 : 10

        Revealer {
            reveal: Config.options.bar.dashboardButton.showVolume
            ExpressiveIconWrapper {
                id: volumeWrapper
                MaterialSymbol {
                    text: Audio.sink?.audio?.muted ? "volume_off" : "volume_up"
                    iconSize: Appearance.font.pixelSize.larger
                    color: volumeWrapper.toggled ? Appearance.colors.colPrimary : Appearance.colors.colOnLayer0
                    anchors.centerIn: parent
                }
            }
        }
        Revealer {
            reveal: Config.options.bar.dashboardButton.showMic && (Audio.source?.audio?.muted ?? false)
            ExpressiveIconWrapper {
                id: micWrapper
                MaterialSymbol {
                    text: "mic_off"
                    iconSize: Appearance.font.pixelSize.larger
                    color: micWrapper.toggled ? Appearance.colors.colPrimary : Appearance.colors.colOnLayer0
                    anchors.centerIn: parent
                }
            }
        }
        Revealer {
            reveal: Config.options.bar.dashboardButton.showNetwork
            ExpressiveIconWrapper {
                id: netWrapper
                MaterialSymbol {
                    text: Network.materialSymbol
                    iconSize: Appearance.font.pixelSize.larger
                    color: netWrapper.toggled ? Appearance.colors.colPrimary : Appearance.colors.colOnLayer0
                    anchors.centerIn: parent
                }
            }
        }
        Revealer {
            reveal: Config.options.bar.dashboardButton.showBluetooth && BluetoothStatus.available
            ExpressiveIconWrapper {
                id: btWrapper
                MaterialSymbol {
                    text: BluetoothStatus.connected ? "bluetooth_connected" : BluetoothStatus.enabled ? "bluetooth" : "bluetooth_disabled"
                    iconSize: Appearance.font.pixelSize.larger
                    color: btWrapper.toggled ? Appearance.colors.colPrimary : Appearance.colors.colOnLayer0
                    anchors.centerIn: parent
                }
            }
        }
        Revealer {
            reveal: Config.options.bar.dashboardButton.showNotifications && (Notifications.silent || Notifications.unread > 0)
            ExpressiveIconWrapper {
                id: notifWrapper
                Loader {
                    id: notifLoader
                    source: "ExpressiveNotificationUnreadCount.qml"
                    anchors.centerIn: parent
                    Binding {
                        target: notifLoader.item
                        property: "color"
                        value: notifWrapper.toggled ? Appearance.colors.colPrimary : Appearance.colors.colOnLayer0
                        when: notifLoader.item !== null
                    }
                    Binding {
                        target: notifLoader.item
                        property: "iconSize"
                        value: Appearance.font.pixelSize.larger
                        when: notifLoader.item !== null
                    }
                }
            }
        }
    }
}

