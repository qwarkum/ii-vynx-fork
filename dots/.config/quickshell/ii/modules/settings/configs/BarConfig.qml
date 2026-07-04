import QtQuick
import QtQuick.Layouts
import Quickshell
import qs.services
import qs.modules.common
import qs.modules.common.widgets

// Root Item wraps the scrollable page + the slide-in sub-page overlay.
// The `contentY` alias lets settings.qml search-scroll still work.
Item {
    id: barConfigRoot

    property alias contentY: page.contentY

    // ── Active sub-page URL ("" = none) ───────────────────────────────────
    property url activeSubPage: ""

    // ── Main content page ─────────────────────────────────────────────────
    ContentPage {
        id: page
        anchors.fill: parent
        forceWidth: false
        opacity: subPageOverlay.width > 0 ? (subPageOverlay.x / subPageOverlay.width) : 1
        visible: opacity > 0

        function openWidgetPage(componentId) {
            const compInfo = BarComponentRegistry.getComponent(componentId);
            if (compInfo) {
                if (typeof compInfo.sidebarPage !== "undefined") {
                    var win = barConfigRoot.QsWindow.window;
                    if (win && win.currentPage !== undefined) {
                        if (compInfo.sectionTitle)
                            win.pendingSectionHighlight = Translation.tr(compInfo.sectionTitle);
                        win.currentPage = compInfo.sidebarPage;
                    }
                } else if (compInfo.configPage) {
                    barConfigRoot.activeSubPage = Qt.resolvedUrl("widgets/" + compInfo.configPage);
                }
            }
        }

        // ── Bar Layout Order ──────────────────────────────────────────────
        ContentSection {
            icon: "view_stream"
            title: Translation.tr("Bar Layout Order")

            ContentSubsection {
                title: Translation.tr("Left layout widgets")
                icon: "align_horizontal_left"
                tooltip: Translation.tr("Top layout in vertical mode")
                ConfigListView {
                    barSection: 0
                    listModel: Config.options.bar.layouts.left
                    onUpdated: newList => {
                        Config.options.bar.layouts.left = newList;
                    }
                }
            }
            ContentSubsection {
                title: Translation.tr("Center layout widgets")
                icon: "align_horizontal_center"
                tooltip: Translation.tr("Center the component with the button")
                ConfigListView {
                    barSection: 1
                    listModel: Config.options.bar.layouts.center
                    onUpdated: newList => {
                        Config.options.bar.layouts.center = newList;
                    }
                }
            }
            ContentSubsection {
                title: Translation.tr("Right layout widgets")
                icon: "align_horizontal_right"
                tooltip: Translation.tr("Bottom layout in vertical mode")
                ConfigListView {
                    barSection: 2
                    listModel: Config.options.bar.layouts.right
                    onUpdated: newList => {
                        Config.options.bar.layouts.right = newList;
                    }
                }
            }
        }

        // ── Geometry ──────────────────────────────────────────────────────
        ContentSection {
            icon: "open_in_full"
            title: Translation.tr("Geometry")

            ConfigSpinBox {
                icon: "height"
                text: Translation.tr("Bar height")
                value: Config.options.bar.sizes.height
                from: 30
                to: 50
                stepSize: 1
                onValueChanged: {
                    Config.options.bar.sizes.height = value;
                }
            }
            ConfigSpinBox {
                visible: Config.options.bar.vertical
                icon: "width"
                text: Translation.tr("Bar width")
                value: Config.options.bar.sizes.width
                from: 30
                to: 50
                stepSize: 1
                onValueChanged: {
                    Config.options.bar.sizes.width = value;
                }
            }
        }

        // ── Positioning ───────────────────────────────────────────────────
        ContentSection {
            icon: "spoke"
            title: Translation.tr("Positioning")

            ContentSubsection {
                title: Translation.tr("Bar position")
                icon: "dock"

                ConfigSelectionArray {
                    currentValue: (Config.options.bar.bottom ? 1 : 0) | (Config.options.bar.vertical ? 2 : 0)
                    onSelected: newValue => {
                        Config.options.bar.bottom = (newValue & 1) !== 0;
                        Config.options.bar.vertical = (newValue & 2) !== 0;
                    }
                    options: [
                        { displayName: Translation.tr("Top"),    icon: "arrow_upward",  value: 0 },
                        { displayName: Translation.tr("Left"),   icon: "arrow_back",    value: 2 },
                        { displayName: Translation.tr("Bottom"), icon: "arrow_downward", value: 1 },
                        { displayName: Translation.tr("Right"),  icon: "arrow_forward", value: 3 }
                    ]
                }
            }

            ConfigSwitch {
                buttonIcon: "visibility_off"
                text: Translation.tr("Automatically hide")
                checked: Config.options.bar.autoHide.enable
                onCheckedChanged: {
                    Config.options.bar.autoHide.enable = checked;
                }
            }
        }

        // ── Decorative Styles ─────────────────────────────────────────────
        ContentSection {
            icon: "palette"
            title: Translation.tr("Decorative Styles")

            ContentSubsection {
                title: Translation.tr("Corner style")
                icon: "rounded_corner"

                ConfigSelectionArray {
                    currentValue: Config.options.bar.cornerStyle
                    onSelected: newValue => {
                        Config.options.bar.cornerStyle = newValue;
                    }
                    options: [
                        { displayName: Translation.tr("Hug"),            icon: "line_curve",  value: 0 },
                        { displayName: Translation.tr("Float"),          icon: "page_header", value: 1 },
                        { displayName: Translation.tr("Rect"),           icon: "toolbar",     value: 2 },
                        { displayName: Translation.tr("Dynamic Island"), icon: "water_drop",  value: 3 }
                    ]
                }
            }

            ConfigSlider {
                buttonIcon: "space_bar"
                text: Translation.tr("Dynamic Island spacing")
                visible: Config.options.bar.cornerStyle === 3 && !Config.options.bar.dynamicIslandLoadBalance
                usePercentTooltip: false
                from: Config.options.bar.vertical ? 16 : 48
                to: Config.options.bar.vertical ? 100 : 250
                stepSize: 1
                value: Config.options.bar.vertical ? Config.options.bar.dynamicIslandSpacingVertical : Config.options.bar.dynamicIslandSpacingHorizontal
                onValueChanged: {
                    if (Config.options.bar.vertical) {
                        Config.options.bar.dynamicIslandSpacingVertical = value;
                    } else {
                        Config.options.bar.dynamicIslandSpacingHorizontal = value;
                    }
                }
            }

            ConfigSwitch {
                buttonIcon: "balance"
                text: Translation.tr("Automatic load balancing")
                visible: Config.options.bar.cornerStyle === 3
                checked: Config.options.bar.dynamicIslandLoadBalance
                onCheckedChanged: {
                    Config.options.bar.dynamicIslandLoadBalance = checked;
                }
            }

            ConfigSwitch {
                buttonIcon: "compress"
                text: Translation.tr("Notch Mode")
                visible: Config.options.bar.cornerStyle === 3
                checked: Config.options.bar.dynamicIsland.notchMode.enable
                onCheckedChanged: {
                    Config.options.bar.dynamicIsland.notchMode.enable = checked;
                }
                StyledToolTip {
                    text: Translation.tr("Collapses the Dynamic Island into a smart single-mode pill, expanding on hover")
                }
            }

            ConfigSwitch {
                buttonIcon: "ads_click"
                text: Translation.tr("Notch Expand on hover")
                visible: Config.options.bar.cornerStyle === 3 && Config.options.bar.dynamicIsland.notchMode.enable
                checked: Config.options.bar.dynamicIsland.notchMode.expandOnHover
                onCheckedChanged: {
                    Config.options.bar.dynamicIsland.notchMode.expandOnHover = checked;
                }
            }

            ConfigSpinBox {
                icon: "timer"
                text: Translation.tr("Notch Workspace Switch Duration (ms)")
                visible: Config.options.bar.cornerStyle === 3 && Config.options.bar.dynamicIsland.notchMode.enable
                value: Config.options.bar.dynamicIsland.notchMode.workspaceSwitchDuration
                from: 500
                to: 10000
                stepSize: 250
                onValueChanged: {
                    Config.options.bar.dynamicIsland.notchMode.workspaceSwitchDuration = value;
                }
            }

            ConfigSpinBox {
                icon: "speed"
                text: Translation.tr("Notch Expand Animation Duration (ms)")
                visible: Config.options.bar.cornerStyle === 3 && Config.options.bar.dynamicIsland.notchMode.enable
                value: Config.options.bar.dynamicIsland.notchMode.expandAnimDuration
                from: 100
                to: 2000
                stepSize: 50
                onValueChanged: {
                    Config.options.bar.dynamicIsland.notchMode.expandAnimDuration = value;
                }
            }

            ConfigSpinBox {
                icon: "blur_on"
                text: Translation.tr("Notch Fade Delay (ms)")
                visible: Config.options.bar.cornerStyle === 3 && Config.options.bar.dynamicIsland.notchMode.enable
                value: Config.options.bar.dynamicIsland.notchMode.fadeDelay
                from: 0
                to: 1000
                stepSize: 25
                onValueChanged: {
                    Config.options.bar.dynamicIsland.notchMode.fadeDelay = value;
                }
            }

            ConfigSwitch {
                buttonIcon: "fullscreen"
                text: Translation.tr("Overlay over apps (don't reserve space)")
                visible: Config.options.bar.cornerStyle === 3 && Config.options.bar.dynamicIsland.notchMode.enable
                checked: Config.options.bar.dynamicIsland.notchMode.overlapApps
                onCheckedChanged: {
                    Config.options.bar.dynamicIsland.notchMode.overlapApps = checked;
                }
                StyledToolTip {
                    text: Translation.tr("Lets other maximized applications fill the screen area underneath the bar")
                }
            }

            ContentSubsection {
                title: Translation.tr("Notch Active Triggers")
                icon: "priority_high"
                visible: Config.options.bar.cornerStyle === 3 && Config.options.bar.dynamicIsland.notchMode.enable

                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 2

                    ConfigSwitch {
                        buttonIcon: "music_note"
                        text: Translation.tr("Music Player trigger")
                        checked: Config.options.bar.dynamicIsland.notchMode.priorityList.indexOf("music_player") !== -1
                        onCheckedChanged: {
                            let list = Array.from(Config.options.bar.dynamicIsland.notchMode.priorityList);
                            let idx = list.indexOf("music_player");
                            if (checked) {
                                if (idx === -1) list.unshift("music_player");
                            } else {
                                if (idx !== -1) list.splice(idx, 1);
                            }
                            Config.options.bar.dynamicIsland.notchMode.priorityList = list;
                        }
                    }

                    ConfigSwitch {
                        buttonIcon: "workspaces"
                        text: Translation.tr("Workspaces switch trigger")
                        checked: Config.options.bar.dynamicIsland.notchMode.priorityList.indexOf("workspaces") !== -1
                        onCheckedChanged: {
                            let list = Array.from(Config.options.bar.dynamicIsland.notchMode.priorityList);
                            let idx = list.indexOf("workspaces");
                            if (checked) {
                                if (idx === -1) {
                                    let clockIdx = list.indexOf("clock");
                                    if (clockIdx !== -1) {
                                        list.splice(clockIdx, 0, "workspaces");
                                    } else {
                                        list.push("workspaces");
                                    }
                                }
                            } else {
                                if (idx !== -1) list.splice(idx, 1);
                            }
                            Config.options.bar.dynamicIsland.notchMode.priorityList = list;
                        }
                    }

                    ConfigSwitch {
                        buttonIcon: "nest_clock_farsight_analog"
                        text: Translation.tr("Clock fallback mode")
                        checked: Config.options.bar.dynamicIsland.notchMode.priorityList.indexOf("clock") !== -1
                        onCheckedChanged: {
                            let list = Array.from(Config.options.bar.dynamicIsland.notchMode.priorityList);
                            let idx = list.indexOf("clock");
                            if (checked) {
                                if (idx === -1) list.push("clock");
                            } else {
                                if (idx !== -1) list.splice(idx, 1);
                            }
                            Config.options.bar.dynamicIsland.notchMode.priorityList = list;
                        }
                    }
                }
            }

            ContentSubsection {
                title: Translation.tr("Notch Allowed Widgets")
                icon: "visibility"
                tooltip: Translation.tr("Select widgets that can be displayed when the notch is expanded")
                visible: Config.options.bar.cornerStyle === 3 && Config.options.bar.dynamicIsland.notchMode.enable

                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 2

                    Repeater {
                        model: {
                            let centerLayout = Config.options.bar.layouts.center;
                            let list = [];
                            for (let i = 0; i < centerLayout.length; i++) {
                                let comp = BarComponentRegistry.getComponent(centerLayout[i].id);
                                if (comp) {
                                    list.push(comp);
                                }
                            }
                            return list;
                        }
                        delegate: ConfigSwitch {
                            required property var modelData
                            buttonIcon: modelData.icon
                            text: Translation.tr(modelData.title)
                            checked: Config.options.bar.dynamicIsland.notchMode.visibleWidgets.indexOf(modelData.id) !== -1
                            onCheckedChanged: {
                                let list = Array.from(Config.options.bar.dynamicIsland.notchMode.visibleWidgets);
                                let idx = list.indexOf(modelData.id);
                                if (checked) {
                                    if (idx === -1) {
                                        list.push(modelData.id);
                                        Config.options.bar.dynamicIsland.notchMode.visibleWidgets = list;
                                    }
                                } else {
                                    if (idx !== -1) {
                                        list.splice(idx, 1);
                                        Config.options.bar.dynamicIsland.notchMode.visibleWidgets = list;
                                    }
                                }
                            }
                        }
                    }
                }
            }

            ContentSubsection {
                title: Translation.tr("Group style")
                icon: "group_work"
                tooltip: Translation.tr("Island style makes the group background opaque when bar is transparent")

                ConfigSelectionArray {
                    currentValue: Config.options.bar.barGroupStyle
                    onSelected: newValue => {
                        Config.options.bar.barGroupStyle = newValue;
                    }
                    options: [
                        { displayName: Translation.tr("Pills"),       icon: "location_chip", value: 0 },
                        { displayName: Translation.tr("Island"),      icon: "shadow",        value: 1 },
                        { displayName: Translation.tr("Transparent"), icon: "opacity",       value: 2 }
                    ]
                }
            }

            ContentSubsection {
                title: Translation.tr("Bar background style")
                icon: "format_paint"
                tooltip: Translation.tr("Adaptive style makes the bar background transparent when there are no active windows")

                ConfigSelectionArray {
                    currentValue: Config.options.bar.barBackgroundStyle
                    onSelected: newValue => {
                        Config.options.bar.barBackgroundStyle = newValue;
                    }
                    options: [
                        { displayName: Translation.tr("Visible"),     icon: "visibility",        value: 1 },
                        { displayName: Translation.tr("Adaptive"),    icon: "masked_transitions", value: 2 },
                        { displayName: Translation.tr("Transparent"), icon: "opacity",            value: 0 }
                    ]
                }
            }

            ConfigSwitch {
                buttonIcon: "format_color_fill"
                text: Translation.tr("Expressive bar solid colors")
                checked: Config.options.bar.expressiveColors
                onCheckedChanged: {
                    Config.options.bar.expressiveColors = checked;
                }
                StyledToolTip {
                    text: Translation.tr("Use expressive solid layer colors")
                }
            }

            ContentSubsection {
                title: Translation.tr("Expressive color theme")
                icon: "palette"
                visible: Config.options.bar.expressiveColors

                ConfigSelectionArray {
                    currentValue: Config.options.bar.expressiveColorTheme
                    onSelected: newValue => {
                        Config.options.bar.expressiveColorTheme = newValue;
                    }
                    options: [
                        { displayName: Translation.tr("Content"),   icon: "brush", value: "content" },
                        { displayName: Translation.tr("Vibrant"),   icon: "brush", value: "primary" },
                        { displayName: Translation.tr("Secondary"), icon: "brush", value: "secondary" },
                        { displayName: Translation.tr("Surface"),   icon: "brush", value: "surface" }
                    ]
                }
            }

            ContentSubsection {
                title: Translation.tr("Fake screen rounding")
                icon: "fullscreen_exit"
                Layout.fillWidth: true

                ConfigSelectionArray {
                    currentValue: Config.options.appearance.fakeScreenRounding
                    onSelected: newValue => {
                        Config.options.appearance.fakeScreenRounding = newValue;
                    }
                    options: [
                        {
                            displayName: Translation.tr("No"),
                            icon: "close",
                            value: 0
                        },
                        {
                            displayName: Translation.tr("Yes"),
                            icon: "check",
                            value: 1
                        },
                        {
                            displayName: Translation.tr("When not fullscreen"),
                            icon: "fullscreen_exit",
                            value: 2
                        },
                        {
                            displayName: Translation.tr("Wrapped"),
                            icon: "capture",
                            value: 3
                        },
                        {
                            displayName: Translation.tr("Edge"),
                            icon: "border_bottom",
                            value: 4
                        }
                    ]
                }
            }

            ConfigSpinBox {
                visible: Config.options.appearance.fakeScreenRounding === 3
                icon: "line_weight"
                text: Translation.tr("Wrapped frame thickness")
                value: Config.options.appearance.wrappedFrameThickness
                from: 5
                to: 25
                stepSize: 1
                onValueChanged: {
                    Config.options.appearance.wrappedFrameThickness = value;
                }
            }
        }

        // ── Top Left Brand Icon ───────────────────────────────────────────
        ContentSection {
            icon: "star"
            title: Translation.tr("Top Left Brand Icon")

            ConfigSwitch {
                buttonIcon: "text_fields"
                text: Translation.tr("Use Material Symbol for top-left icon")
                checked: Config.options.bar.useMaterialSymbolForTopLeftIcon
                onCheckedChanged: {
                    Config.options.bar.useMaterialSymbolForTopLeftIcon = checked;
                }
            }

            ConfigTextField {
                text: Translation.tr("Top-left icon identifier")
                icon: "image"
                tooltip: Translation.tr("If not using Material Symbol, enter a preset SVG name (e.g. arch, fedora) or a Material Symbol name if the switch above is on.")
                placeholderText: Translation.tr("Identifier...")

                Component.onCompleted: {
                    inputText = Config.options.bar.topLeftIcon;
                }

                Connections {
                    target: Config.options.bar
                    function onTopLeftIconChanged() {
                        textField.text = Config.options.bar.topLeftIcon;
                    }
                }

                textField.onTextChanged: {
                    var val = textField.text.trim();
                    if (val !== "" && textField.activeFocus) {
                        Config.options.bar.topLeftIcon = val;
                    }
                }
            }
        }

        // ── Scroll Actions ────────────────────────────────────────────────
        ContentSection {
            icon: "mouse"
            title: Translation.tr("Scroll Actions")

            ConfigSwitch {
                buttonIcon: "volume_up"
                text: Translation.tr("Scroll to change volume")
                checked: Config.options.bar.enableVolumeScroll
                onCheckedChanged: {
                    Config.options.bar.enableVolumeScroll = checked;
                }
                StyledToolTip {
                    text: Translation.tr("Enable or disable scrolling on the bar to change volume")
                }
            }

            ConfigSwitch {
                buttonIcon: "brightness_5"
                text: Translation.tr("Scroll to change brightness")
                checked: Config.options.bar.enableBrightnessScroll
                onCheckedChanged: {
                    Config.options.bar.enableBrightnessScroll = checked;
                }
                StyledToolTip {
                    text: Translation.tr("Enable or disable scrolling on the bar to change brightness")
                }
            }
        }

        // ── Tooltips & Popups ─────────────────────────────────────────────
        ContentSection {
            icon: "tooltip"
            title: Translation.tr("Tooltips & Popups")



            ConfigSwitch {
                buttonIcon: "ads_click"
                text: Translation.tr("Click to show tooltips")
                checked: Config.options.bar.tooltips.clickToShow
                onCheckedChanged: {
                    Config.options.bar.tooltips.clickToShow = checked;
                }
                StyledToolTip {
                    text: Translation.tr("You will not be able to use the buttons on some popups if you enable this option.")
                }
            }
            ConfigSwitch {
                buttonIcon: "compress"
                text: Translation.tr("Compact popups")
                checked: Config.options.bar.tooltips.compactPopups
                onCheckedChanged: {
                    Config.options.bar.tooltips.compactPopups = checked;
                }
            }
            ConfigSwitch {
                buttonIcon: "colorize"
                text: Translation.tr("Enable color picker popup")
                checked: Config.options.bar.tooltips.enableColorPickerPopup
                onCheckedChanged: {
                    Config.options.bar.tooltips.enableColorPickerPopup = checked;
                }
            }
            ConfigSwitch {
                buttonIcon: "bluetooth"
                text: Translation.tr("Enable Bluetooth connection popup")
                checked: Config.options.bar.tooltips.enableBluetoothConnectionPopup
                onCheckedChanged: {
                    Config.options.bar.tooltips.enableBluetoothConnectionPopup = checked;
                }
            }
            ConfigSwitch {
                buttonIcon: "keyboard"
                text: Translation.tr("Enable keyboard layout transition popup")
                checked: Config.options.bar.tooltips.enableKeyboardLayoutTransitionPopup
                onCheckedChanged: {
                    Config.options.bar.tooltips.enableKeyboardLayoutTransitionPopup = checked;
                }
            }
        }
    }

    // ── Sub-page overlay (slides in from the right) ───────────────────────
    Item {
        id: subPageOverlay
        width: parent.width
        height: parent.height
        y: 0
        z: 10

        // Open: x=0. Closed: x=width (off-screen right).
        property bool isOpen: barConfigRoot.activeSubPage.toString() !== ""

        // overlayActive stays true during close animation (until x reaches width)
        property bool overlayActive: isOpen
        onXChanged: {
            if (!isOpen && x >= subPageOverlay.width - 1)
                overlayActive = false;
        }
        onIsOpenChanged: {
            if (isOpen) overlayActive = true;
        }

        x: isOpen ? 0 : subPageOverlay.width

        Behavior on x {
            NumberAnimation {
                duration: Appearance.animation.elementMove.duration
                easing.type: Appearance.animation.elementMove.type
                easing.bezierCurve: Appearance.animation.elementMove.bezierCurve
            }
        }

        // Disable input when off-screen
        enabled: isOpen

        Loader {
            id: subPageLoader
            anchors.fill: parent
            source: barConfigRoot.activeSubPage
            active: subPageOverlay.overlayActive

            onLoaded: {
                if (item.hasOwnProperty("showBackButton")) {
                    item.showBackButton = true;
                }
                item.goBack.connect(function() {
                    barConfigRoot.activeSubPage = "";
                });
            }
        }
    }
}

