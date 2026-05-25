import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import qs
import qs.services
import qs.modules.common
import qs.modules.common.widgets
import qs.modules.common.functions as CF

Item {
    id: root
    property real contentPadding: 8
    property int currentPage: 0
    property real scrollPos: -1
    property string pendingSearch: ""

    Connections {
        target: GlobalStates
        function onSettingsPageChanged() {
            if (GlobalStates.settingsPage === "") return
            
            let parts = GlobalStates.settingsPage.split(":");
            let pageIndex = parseInt(parts[0]);
            let searchTerm = parts.length > 1 ? parts[1] : "";

            if (!isNaN(pageIndex) && pageIndex >= 0 && pageIndex < root.pages.length) {
                if (root.currentPage === pageIndex) {
                    if (searchTerm !== "") {
                        Qt.callLater(() => {
                            SearchRegistry.currentSearch = searchTerm;
                        });
                    }
                } else {
                    root.currentPage = pageIndex;
                    if (searchTerm !== "") {
                        // Store search term and apply it once the page is loaded
                        root.pendingSearch = searchTerm;
                    }
                }
            }
            GlobalStates.settingsPage = "";
        }
    }

    property var pages: [
        { name: Translation.tr("Quick"),      icon: "instant_mix",    component: "../../settings/QuickConfig.qml" },
        { name: Translation.tr("General"),    icon: "browse",         component: "../../settings/GeneralConfig.qml" },
        { name: Translation.tr("Bar"),        icon: "toast",          iconRotation: 180, component: "../../settings/BarConfig.qml" },
        { name: Translation.tr("Background"), icon: "texture",        component: "../../settings/BackgroundConfig.qml" },
        { name: Translation.tr("Interface"),  icon: "bottom_app_bar", component: "../../settings/InterfaceConfig.qml" },
        { name: Translation.tr("Services"),   icon: "api",            component: "../../settings/ServicesConfig.qml" },
        { name: Translation.tr("Advanced"),   icon: "construction",   component: "../../settings/AdvancedConfig.qml" },
        { name: Translation.tr("Hyprland"),   icon: "wysiwyg",        component: "../../settings/HyprlandConfig.qml" },
        { name: Translation.tr("About"),      icon: "info",           component: "../../settings/About.qml" }
    ]

    Component.onCompleted: {
        MaterialThemeLoader.reapplyTheme()
        Config.readWriteDelay = 0
    }

    ColumnLayout {
        anchors {
            fill: parent
            margins: contentPadding
        }

        RowLayout {
            Layout.alignment: Qt.AlignCenter
            Layout.fillWidth: true
            Layout.fillHeight: false

            StyledText {
                id: titleText
                color: Appearance.colors.colOnLayer0
                text: Translation.tr("Settings")
                Layout.leftMargin: 20
                font {
                    family: Appearance.font.family.title
                    pixelSize: Appearance.font.pixelSize.title
                    variableAxes: Appearance.font.variableAxes.title
                }
            }

            Item { Layout.fillWidth: true }

            RowLayout {
                id: searchBox
                MaterialShapeWrappedMaterialSymbol {
                    iconSize: Appearance.font.pixelSize.huge
                    shape: MaterialShape.Shape.Ghostish
                    text: "search"
                }
                ToolbarTextField {
                    id: searchInput
                    Layout.topMargin: 4
                    Layout.bottomMargin: 4
                    font.pixelSize: Appearance.font.pixelSize.small
                    placeholderText: Translation.tr("Search all settings..")
                    implicitWidth: Appearance.sizes.searchWidth

                    onTextChanged: {
                        SearchRegistry.currentSearch = text;
                    }

                    onAccepted: {
                        const result = SearchRegistry.getResultsRanked(text);
                        if (result && result.length > 0) {
                            root.currentPage = result[0].pageIndex;
                        }
                    }
                }
            }

            Item { Layout.fillWidth: true }

            RippleButton {
                buttonRadius: Appearance.rounding.full
                implicitWidth: 35
                implicitHeight: 35
                onClicked: GlobalStates.settingsOpen = false
                Layout.rightMargin: 10
                contentItem: MaterialSymbol {
                    anchors.centerIn: parent
                    text: "close"
                    iconSize: 20
                }
            }
        }

        RowLayout {
            Layout.fillWidth: true
            Layout.fillHeight: true
            spacing: contentPadding

            Item {
                id: navRailWrapper
                Layout.fillHeight: true
                Layout.margins: 5
                implicitWidth: navRail.expanded ? 150 : fab.baseSize
                Behavior on implicitWidth {
                    animation: Appearance.animation.elementMoveFast.numberAnimation.createObject(this)
                }

                NavigationRail {
                    id: navRail
                    anchors { left: parent.left; top: parent.top; bottom: parent.bottom }
                    spacing: 10
                    expanded: root.width > 900

                    NavigationRailExpandButton {
                        focus: GlobalStates.settingsOpen
                    }

                    FloatingActionButton {
                        id: fab
                        property bool justCopied: false
                        iconText: justCopied ? "check" : "edit"
                        buttonText: justCopied ? Translation.tr("Path copied") : Translation.tr("Config file")
                        expanded: navRail.expanded
                        downAction: () => {
                            Qt.openUrlExternally(`${Directories.config}/illogical-impulse/config.json`);
                        }
                        altAction: () => {
                            Quickshell.clipboardText = CF.FileUtils.trimFileProtocol(`${Directories.config}/illogical-impulse/config.json`);
                            fab.justCopied = true;
                            revertTextTimer.restart()
                        }
                        Timer {
                            id: revertTextTimer
                            interval: 1500
                            onTriggered: fab.justCopied = false
                        }
                        StyledToolTip {
                            text: Translation.tr("Open the shell config file\nAlternatively right-click to copy path")
                        }
                    }

                    NavigationRailTabArray {
                        currentIndex: root.currentPage
                        expanded: navRail.expanded
                        Repeater {
                            model: root.pages
                            NavigationRailButton {
                                required property var index
                                required property var modelData
                                toggled: root.currentPage === index
                                onPressed: root.currentPage = index
                                expanded: navRail.expanded
                                buttonIcon: modelData.icon
                                buttonIconRotation: modelData.iconRotation || 0
                                buttonText: modelData.name
                                showToggledHighlight: false
                            }
                        }
                    }
                }
            }

            Rectangle {
                Layout.fillWidth: true
                Layout.fillHeight: true
                color: Appearance.m3colors.m3surfaceContainerLow
                radius: Appearance.rounding.windowRounding

                Loader {
                    id: pageLoader
                    anchors.fill: parent
                    anchors.topMargin: 0
                    opacity: 1.0
                    source: root.pages[root.currentPage].component
                    active: Config.ready

                    onLoaded: {
                        if (root.pendingSearch !== "") {
                            delayedSearchTimer.restart();
                        }
                    }

                    Timer {
                        id: delayedSearchTimer
                        interval: 150
                        onTriggered: {
                            if (root.pendingSearch !== "") {
                                SearchRegistry.currentSearch = root.pendingSearch;
                                root.pendingSearch = "";
                            }
                        }
                    }

                    Connections {
                        target: root
                        function onCurrentPageChanged() {
                            switchAnim.complete();
                            switchAnim.start();
                        }
                    }

                    SequentialAnimation {
                        id: switchAnim

                        NumberAnimation {
                            target: pageLoader
                            properties: "opacity"
                            from: 1
                            to: 0
                            duration: 100
                            easing.type: Appearance.animation.elementMoveExit.type
                            easing.bezierCurve: Appearance.animationCurves.emphasizedFirstHalf
                        }
                        ParallelAnimation {
                            PropertyAction {
                                target: pageLoader
                                property: "source"
                                value: root.pages[root.currentPage].component
                            }
                        }
                        ParallelAnimation {
                            NumberAnimation {
                                target: pageLoader
                                properties: "opacity"
                                from: 0
                                to: 1
                                duration: 200
                                easing.type: Appearance.animation.elementMoveEnter.type
                                easing.bezierCurve: Appearance.animationCurves.emphasizedLastHalf
                            }
                            NumberAnimation {
                                target: pageLoader
                                properties: "anchors.topMargin"
                                from: 20
                                to: 0
                                duration: 200
                                easing.type: Appearance.animation.elementMoveEnter.type
                                easing.bezierCurve: Appearance.animationCurves.emphasizedLastHalf
                            }
                        }
                    }
                }
            }
        }
    }
}
