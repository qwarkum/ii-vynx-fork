pragma ComponentBehavior: Bound
import qs.modules.ii.bar.shared
import qs.modules.ii.bar
import QtQuick
import QtQuick.Layouts
import Quickshell
import qs
import qs.services
import qs.modules.common
import qs.modules.common.widgets
import qs.modules.common.functions
import "island"

Item {
    id: root

    // Required from BarContent
    property var screen
    property bool showBarBackground
    property bool isSearchActiveHere
    property real expectedSearchWidth
    property real frameThickness
    property var leftList
    property var centerList
    property var rightList
    property var activeTheme

    // Expose pill width back to BarContent
    readonly property real pillWidth: barBackground.width
    readonly property var modeState: modeState

    readonly property real verticalTopOffset: Config.options.bar.bottom ? Math.max(0, barBackground.height - parent.height) : 0
    readonly property real verticalBottomOffset: !Config.options.bar.bottom ? Math.max(0, barBackground.height - parent.height) : 0

    IslandModeController {
        id: modeController
        screen: root.screen
    }

    IslandModeState {
        id: modeState
        mode: modeController.resolvedMode
        hoverActive: islandHoverHandler.hovered
    }

    // Determine the actual background color of the bar reactively
    property color actualColor: root.showBarBackground
        ? (Config.options.bar.expressiveColors
            ? root.activeTheme.barBackground
            : Appearance.colors.colLayer0)
        : "transparent"

    Behavior on actualColor {
        animation: Appearance.animation.elementMoveFast.colorAnimation.createObject(root)
    }

    // ── Main Bar Background Pill ─────────────────────────────────────────────
    Rectangle {
        id: barBackground
        clip: true
        color: root.actualColor

        anchors {
            top: !Config.options.bar.bottom ? parent.top : undefined
            bottom: Config.options.bar.bottom ? parent.bottom : undefined
            horizontalCenter: parent.horizontalCenter
        }

        height: {
            const isNotchActive = modeState.notchModeEnabled;
            const isExpanded = modeState.expanded;
            if (isNotchActive && !isExpanded) {
                if (modeState._displayMode === "") return 0;
                if (modeState._displayMode === "osd") {
                    return 72;
                }
                if (modeState._displayMode === "notification") {
                    return 80;
                }
            }
            return parent.height;
        }

        Behavior on height {
            NumberAnimation {
                duration: Config.options.bar.dynamicIsland.notchMode.expandAnimDuration
                easing.type: Easing.OutCubic
            }
        }

        HoverHandler {
            id: islandHoverHandler
        }

        readonly property int islandSectionSpacing: {
            const screenWidth = root.screen ? root.screen.width : 1920;
            const frameThick = root.frameThickness;
            const maxAllowedWidth = screenWidth - 2 * frameThick - 64;
            const leftW = leftSectionLayout.implicitWidth;
            const centerW = centerSectionLayout.implicitWidth;
            const rightW = rightSectionLayout.implicitWidth;
            const remaining = maxAllowedWidth - 32 - leftW - centerW - rightW;
            if (Config.options.bar.dynamicIslandLoadBalance) {
                return Math.min(100, Math.max(16, Math.floor(remaining / 2)));
            } else {
                const preferred = Config.options.bar.dynamicIslandSpacingHorizontal ?? 48;
                const maxSpacing = Math.max(16, Math.floor(remaining / 2));
                return Math.min(preferred, maxSpacing);
            }
        }

        width: {
            const isNotchActive = modeState.notchModeEnabled;
            const isExpanded = modeState.expanded;
            if (isNotchActive && !isExpanded) {
                if (modeState._displayMode === "") return 0;
                if (modeState._displayMode === "osd") {
                    return 380;
                }
                if (modeState._displayMode === "notification") {
                    return 450;
                }
            }
            const minW = (isNotchActive && !isExpanded) ? 80 : 200;
            const baseWidth = Math.max(islandSections.implicitWidth + 32, minW);
            if (GlobalStates.connectModeActive && root.isSearchActiveHere) {
                const requiredWidth = root.expectedSearchWidth + 100;
                return Math.max(baseWidth, requiredWidth);
            }
            return baseWidth;
        }

        property real baseRadius: Math.min(height / 2, Appearance.rounding.windowRounding + 12)
        topLeftRadius:    !Config.options.bar.bottom ? 0 : baseRadius
        topRightRadius:   !Config.options.bar.bottom ? 0 : baseRadius
        bottomLeftRadius:  Config.options.bar.bottom ? 0 : baseRadius
        bottomRightRadius: Config.options.bar.bottom ? 0 : baseRadius

        Behavior on width {
            NumberAnimation {
                duration: {
                    if (modeState.notchModeEnabled) {
                        return Config.options.bar.dynamicIsland.notchMode.expandAnimDuration;
                    }
                    const multiplier = Appearance.animMultiplier ?? 1.0;
                    return Math.round((root.isSearchActiveHere ? 450 : 280) * multiplier);
                }
                easing.type: modeState.notchModeEnabled ? Easing.OutCubic : Easing.OutBack
            }
        }

        // ── Island layout (placed directly inside background to handle hover natively) ─
        RowLayout {
            id: islandSections
            width: parent.width - 32
            anchors.centerIn: parent
            spacing: 0
            opacity: (!modeState.notchModeEnabled || modeState.expanded || (modeState._displayMode !== "" && modeState._displayMode !== "osd" && modeState._displayMode !== "notification")) ? 1.0 : 0.0
            visible: opacity > 0.01
            Behavior on opacity { NumberAnimation { duration: 200 } }

            RowLayout {
                id: leftSectionLayout
                spacing: 4
                opacity: (!modeState.notchModeEnabled || modeState.expanded || (modeState._displayMode === "workspaces" && Config.options.bar.layouts.left.some(e => e.id === "workspaces"))) ? 1.0 : 0.0
                visible: opacity > 0.01
                Behavior on opacity {
                    SequentialAnimation {
                        PauseAnimation {
                            duration: (modeState.notchModeEnabled && modeState.expanded) ? Config.options.bar.dynamicIsland.notchMode.fadeDelay : 0
                        }
                        NumberAnimation {
                            duration: 200
                            easing.type: Easing.OutQuad
                        }
                    }
                }
                Repeater {
                    id: leftRepeater
                    model: Config.options.bar.layouts.left
                    delegate: BarComponent {
                        list: leftRepeater.model
                        barSection: 0
                        modeState: root.modeState
                    }
                }
            }
            Item {
                Layout.fillWidth: !modeState.notchModeEnabled || modeState.expanded
                Layout.preferredWidth: (!modeState.notchModeEnabled || modeState.expanded) ? barBackground.islandSectionSpacing : 0
                visible: Layout.preferredWidth > 0
                Behavior on Layout.preferredWidth {
                    NumberAnimation { duration: 250; easing.type: Easing.OutQuad }
                }
            }
            RowLayout {
                id: centerSectionLayout
                spacing: 4
                Repeater {
                    model: root.leftList
                    delegate: BarComponent {
                        list: Config.options.bar.layouts.center; barSection: 1
                        originalIndex: Config.options.bar.layouts.center.findIndex(e => e.id === modelData.id)
                        modeState: root.modeState
                    }
                }
                Repeater {
                    model: root.centerList
                    delegate: BarComponent {
                        list: Config.options.bar.layouts.center; barSection: 1
                        originalIndex: Config.options.bar.layouts.center.findIndex(e => e.id === modelData.id)
                        modeState: root.modeState
                    }
                }
                Repeater {
                    model: root.rightList
                    delegate: BarComponent {
                        list: Config.options.bar.layouts.center; barSection: 1
                        originalIndex: Config.options.bar.layouts.center.findIndex(e => e.id === modelData.id)
                        modeState: root.modeState
                    }
                }
            }
            Item {
                Layout.fillWidth: !modeState.notchModeEnabled || modeState.expanded
                Layout.preferredWidth: (!modeState.notchModeEnabled || modeState.expanded) ? barBackground.islandSectionSpacing : 0
                visible: Layout.preferredWidth > 0
                Behavior on Layout.preferredWidth {
                    NumberAnimation { duration: 250; easing.type: Easing.OutQuad }
                }
            }
            RowLayout {
                id: rightSectionLayout
                spacing: 8
                opacity: (!modeState.notchModeEnabled || modeState.expanded || (modeState._displayMode === "workspaces" && Config.options.bar.layouts.right.some(e => e.id === "workspaces"))) ? 1.0 : 0.0
                visible: opacity > 0.01
                Behavior on opacity {
                    SequentialAnimation {
                        PauseAnimation {
                            duration: (modeState.notchModeEnabled && modeState.expanded) ? Config.options.bar.dynamicIsland.notchMode.fadeDelay : 0
                        }
                        NumberAnimation {
                            duration: 200
                            easing.type: Easing.OutQuad
                        }
                    }
                }
                Repeater {
                    id: rightRepeater
                    model: Config.options.bar.layouts.right
                    delegate: BarComponent {
                        list: rightRepeater.model
                        barSection: 2
                        modeState: root.modeState
                    }
                }
            }
        }

        // OSD Container
        Loader {
            id: osdLoader
            anchors.fill: parent
            active: modeState.notchModeEnabled && !modeState.expanded && modeState._displayMode === "osd"
            visible: active
            sourceComponent: Component {
                Item {
                    id: osdItem
                    anchors.fill: parent
                    Loader {
                        id: osdIndicatorLoader
                        anchors.fill: parent
                        source: {
                            const item = [
                                { id: "volume", sourceUrl: "indicators/VolumeIndicator.qml" },
                                { id: "brightness", sourceUrl: "indicators/BrightnessIndicator.qml" },
                                { id: "playerVolume", sourceUrl: "indicators/PlayerVolumeIndicator.qml" },
                                { id: "gamma", sourceUrl: "indicators/GammaIndicator.qml" }
                            ].find(i => i.id === GlobalStates.osdCurrentIndicator);
                            if (!item) return "";
                            return Quickshell.shellPath("modules/ii/topLayer/osd/" + item.sourceUrl);
                        }
                    }
                }
            }
        }

        // Notification Container
        RowLayout {
            id: notificationLayout
            anchors.fill: parent
            anchors.leftMargin: 16
            anchors.rightMargin: 16
            anchors.topMargin: 10
            anchors.bottomMargin: 10
            spacing: 12
            visible: modeState.notchModeEnabled && !modeState.expanded && modeState._displayMode === "notification"

            readonly property var latestNotif: Notifications.popupList.length > 0 ? Notifications.popupList[Notifications.popupList.length - 1] : null

            NotificationAppIcon {
                id: notifIcon
                Layout.alignment: Qt.AlignVCenter
                appIcon: notificationLayout.latestNotif ? notificationLayout.latestNotif.appIcon : ""
                summary: notificationLayout.latestNotif ? notificationLayout.latestNotif.summary : ""
                urgency: (notificationLayout.latestNotif && notificationLayout.latestNotif.notification) ? notificationLayout.latestNotif.notification.urgency : 1
                image: notificationLayout.latestNotif ? notificationLayout.latestNotif.image : ""
                implicitSize: 32
            }

            ColumnLayout {
                Layout.fillWidth: true
                Layout.alignment: Qt.AlignVCenter
                spacing: 2

                StyledText {
                    Layout.fillWidth: true
                    Layout.maximumHeight: implicitHeight
                    font.pixelSize: Appearance.font.pixelSize.normal
                    font.bold: true
                    text: notificationLayout.latestNotif ? notificationLayout.latestNotif.summary : ""
                    maximumLineCount: 1
                    wrapMode: Text.NoWrap
                    elide: Text.ElideRight
                }

                StyledText {
                    Layout.fillWidth: true
                    Layout.maximumHeight: implicitHeight
                    font.pixelSize: Appearance.font.pixelSize.smaller
                    text: notificationLayout.latestNotif ? notificationLayout.latestNotif.body : ""
                    maximumLineCount: 2
                    wrapMode: Text.WordWrap
                    elide: Text.ElideRight
                }
            }

            MaterialSymbol {
                text: "close"
                iconSize: 18
                color: Appearance.colors.colOnSurfaceVariant
                Layout.alignment: Qt.AlignVCenter
                MouseArea {
                    anchors.fill: parent
                    onClicked: {
                        if (notificationLayout.latestNotif) {
                            Notifications.discardNotification(notificationLayout.latestNotif.notificationId);
                        }
                    }
                }
            }
        }
    }

    // ── Concave Corners ──────────────────────────────────────────────────────
    // We shift the RoundCorner Items 1px into the bar (via negative anchor margins)
    // instead of using extendHorizontal, because extendHorizontal creates a
    // triangular fill extension at the corner that becomes visible as an overlap
    // line when the bar background has transparency.
    RoundCorner {
        anchors.top: barBackground.top; anchors.right: barBackground.left
        anchors.rightMargin: -1
        implicitSize: barBackground.baseRadius
        color: barBackground.color; corner: RoundCorner.CornerEnum.TopRight
        visible: root.showBarBackground && !Config.options.bar.bottom
        opacity: visible ? 1 : 0; Behavior on opacity { NumberAnimation { duration: 250 } }
        anchors.topMargin: root.frameThickness
    }
    RoundCorner {
        anchors.top: barBackground.top; anchors.left: barBackground.right
        anchors.leftMargin: -1
        implicitSize: barBackground.baseRadius
        color: barBackground.color; corner: RoundCorner.CornerEnum.TopLeft
        visible: root.showBarBackground && !Config.options.bar.bottom
        opacity: visible ? 1 : 0; Behavior on opacity { NumberAnimation { duration: 250 } }
        anchors.topMargin: root.frameThickness
    }
    RoundCorner {
        anchors.bottom: barBackground.bottom; anchors.right: barBackground.left
        anchors.rightMargin: -1
        implicitSize: barBackground.baseRadius
        color: barBackground.color; corner: RoundCorner.CornerEnum.BottomRight
        visible: root.showBarBackground && Config.options.bar.bottom
        opacity: visible ? 1 : 0; Behavior on opacity { NumberAnimation { duration: 250 } }
        anchors.bottomMargin: root.frameThickness
    }
    RoundCorner {
        anchors.bottom: barBackground.bottom; anchors.left: barBackground.right
        anchors.leftMargin: -1
        implicitSize: barBackground.baseRadius
        color: barBackground.color; corner: RoundCorner.CornerEnum.BottomLeft
        visible: root.showBarBackground && Config.options.bar.bottom
        opacity: visible ? 1 : 0; Behavior on opacity { NumberAnimation { duration: 250 } }
        anchors.bottomMargin: root.frameThickness
    }
}
