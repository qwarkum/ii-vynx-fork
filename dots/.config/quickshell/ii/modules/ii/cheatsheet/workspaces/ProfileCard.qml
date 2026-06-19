pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell
import qs.modules.common
import qs.modules.common.widgets
import qs.services

/**
 * ProfileCard — a single saved workspace profile displayed in CheatsheetWorkspaces.
 *
 * Props exposed by the parent via model delegation:
 *   slug, name, emoji, description, createdAt, windowCount, workspaceIds, hasDuplicateClasses
 */
Item {
    id: root

    // ── required props ──────────────────────────────────────────────────────
    required property string slug
    required property string name
    required property string emoji
    required property string description
    required property int    createdAt
    required property int    windowCount
    required property string workspaceIdsJson
    required property string windowsJson
    required property bool   hasDuplicateClasses
    required property bool   closeOthers
 
    // ── internal state ──────────────────────────────────────────────────────
    property bool isRestoring: WorkspaceProfileService.restoring
    property bool restoreSuccess: false
    property bool restorePartial: false
    property bool showDeleteConfirm: false
    property bool isEditing: false
    property string editNameValue: root.name
    property bool expanded: false
    property bool showAddAppForm: false
    property string newAppClass: ""
    property string newAppWorkspace: "1"
    property bool newAppAutolaunch: true
    property string newAppLaunchCmd: ""

    // ── signals ──────────────────────────────────────────────────────────────
    signal restoreRequested()
    signal deleteRequested()
    signal renameRequested(string newName)
    signal toggleExpandedRequested()

    readonly property var workspaceIds: {
        try { return JSON.parse(workspaceIdsJson); } catch(e) { return []; }
    }

    readonly property var windowsList: {
        try { return JSON.parse(windowsJson); } catch(e) { return []; }
    }

    // Height driven by content
    implicitHeight: cardBg.implicitHeight

    // ── colours (from M3 tokens) ─────────────────────────────────────────────
    readonly property color colBg:          Appearance.colors.colSurfaceContainer
    readonly property color colBgHover:     Appearance.colors.colSurfaceContainerHigh
    readonly property color colBorder:      Appearance.colors.colOutlineVariant
    readonly property color colOnSurface:   Appearance.colors.colOnSurface
    readonly property color colSubtle:      Appearance.colors.colOnSurfaceVariant
    readonly property color colPrimary:     Appearance.colors.colPrimary
    readonly property color colOnPrimary:   Appearance.colors.colOnPrimary
    readonly property color colChipBg:      Appearance.colors.colSecondaryContainer
    readonly property color colChipText:    Appearance.colors.colOnSecondaryContainer
    readonly property color colWarnBg:      Appearance.colors.colTertiaryContainer
    readonly property color colWarnText:    Appearance.colors.colOnTertiaryContainer
    readonly property color colErrorBg:     Appearance.colors.colErrorContainer
    readonly property color colErrorText:   Appearance.colors.colOnErrorContainer
    readonly property color colSuccessBg:   Appearance.m3colors.m3primaryContainer



    // ── reset feedback state when signals arrive ─────────────────────────────
    Connections {
        target: WorkspaceProfileService

        function onRestoreFinished(success, errors) {
            if (root.isRestoring) {
                root.restoreSuccess = success && errors === 0;
                root.restorePartial = !root.restoreSuccess;
                feedbackResetTimer.restart();
            }
        }
    }

    Timer {
        id: feedbackResetTimer
        interval: 2500
        onTriggered: {
            root.restoreSuccess = false;
            root.restorePartial = false;
        }
    }

    HoverHandler { id: hoverHandler }

    // ── card background ───────────────────────────────────────────────────────
    Rectangle {
        id: cardBg
        anchors { left: parent.left; right: parent.right; top: parent.top }
        radius: Appearance.rounding.large
        color: hoverHandler.hovered ? root.colBgHover : root.colBg
        border { width: 1; color: root.colBorder }
        implicitHeight: cardLayout.implicitHeight + 28

        Behavior on color {
            ColorAnimation { duration: Appearance.animation.elementMoveFast.duration }
        }

        ColumnLayout {
            id: cardLayout
            anchors {
                left: parent.left; right: parent.right; top: parent.top
                margins: 16
            }
            spacing: 10

            // ── header row ──────────────────────────────────────────────────
            RowLayout {
                Layout.fillWidth: true
                spacing: 10

                // emoji badge
                Rectangle {
                    implicitWidth: 38; implicitHeight: 38
                    radius: Appearance.rounding.normal
                    color: Appearance.colors.colPrimaryContainer

                    StyledText {
                        anchors.centerIn: parent
                        text: root.emoji
                        font.pixelSize: 20
                    }
                }

                // name display layout
                ColumnLayout {
                    visible: !root.isEditing
                    Layout.fillWidth: true
                    spacing: 1

                    StyledText {
                        text: root.name
                        font {
                            pixelSize: Appearance.font.pixelSize.normal
                            weight: Font.DemiBold
                        }
                        color: root.colOnSurface
                        elide: Text.ElideRight
                        Layout.fillWidth: true
                    }
                    StyledText {
                        visible: root.createdAt > 0
                        text: root.createdAt > 0 ? _dateString(root.createdAt) : ""
                        font.pixelSize: Appearance.font.pixelSize.smaller
                        color: root.colSubtle
                    }
                }

                // Edit name text field
                MaterialTextField {
                    visible: root.isEditing
                    Layout.fillWidth: true
                    text: root.editNameValue
                    placeholderText: "Profile name…"
                    onTextChanged: root.editNameValue = text
                    font.pixelSize: Appearance.font.pixelSize.normal
                    implicitHeight: 38
                    onVisibleChanged: {
                        if (visible) {
                            forceActiveFocus();
                        }
                    }

                    Keys.onReturnPressed: {
                        if (root.editNameValue.trim().length > 0) {
                            root.renameRequested(root.editNameValue.trim());
                            root.isEditing = false;
                        }
                    }
                    Keys.onEscapePressed: root.isEditing = false
                }

                // action buttons (always visible; hidden when editing)
                RowLayout {
                    spacing: 4
                    visible: !root.isEditing

                    // rename button
                    RippleButton {
                        implicitWidth: 32; implicitHeight: 32
                        buttonRadius: Appearance.rounding.full
                        colBackground: Appearance.colors.colSecondaryContainer
                        colBackgroundHover: Appearance.colors.colSecondaryContainerHover
                        onClicked: {
                            root.editNameValue = root.name;
                            root.isEditing = true;
                        }
                        StyledToolTip { text: "Rename" }
                        MaterialSymbol {
                            anchors.centerIn: parent
                            text: "edit"
                            iconSize: Appearance.font.pixelSize.small
                            color: Appearance.colors.colOnSecondaryContainer
                        }
                    }

                    // delete button (shows confirm inline)
                    RippleButton {
                        implicitWidth: 32; implicitHeight: 32
                        buttonRadius: Appearance.rounding.full
                        colBackground: root.showDeleteConfirm
                            ? Appearance.colors.colError
                            : Appearance.colors.colErrorContainer
                        colBackgroundHover: root.showDeleteConfirm
                            ? Appearance.colors.colErrorHover
                            : Appearance.colors.colErrorContainerHover
                        onClicked: {
                            if (root.showDeleteConfirm) {
                                root.deleteRequested();
                            } else {
                                root.showDeleteConfirm = true;
                                deleteConfirmResetTimer.restart();
                            }
                        }
                        StyledToolTip { text: root.showDeleteConfirm ? "Confirm delete" : "Delete profile" }
                        MaterialSymbol {
                            anchors.centerIn: parent
                            text: root.showDeleteConfirm ? "warning" : "delete"
                            iconSize: Appearance.font.pixelSize.small
                            color: root.showDeleteConfirm
                                ? Appearance.colors.colOnError
                                : Appearance.colors.colOnErrorContainer
                        }

                        Timer {
                            id: deleteConfirmResetTimer
                            interval: 3000
                            onTriggered: root.showDeleteConfirm = false
                        }
                    }
                }

                // confirm / cancel when editing name
                RowLayout {
                    spacing: 4
                    visible: root.isEditing

                    RippleButton {
                        implicitWidth: 32; implicitHeight: 32
                        buttonRadius: Appearance.rounding.full
                        colBackground: Appearance.colors.colPrimary
                        colBackgroundHover: Appearance.colors.colPrimaryHover
                        enabled: root.editNameValue.trim().length > 0
                        onClicked: {
                            root.renameRequested(root.editNameValue.trim());
                            root.isEditing = false;
                        }
                        MaterialSymbol {
                            anchors.centerIn: parent
                            text: "check"
                            iconSize: Appearance.font.pixelSize.small
                            color: Appearance.colors.colOnPrimary
                        }
                    }
                    RippleButton {
                        implicitWidth: 32; implicitHeight: 32
                        buttonRadius: Appearance.rounding.full
                        colBackground: Appearance.colors.colLayer2
                        onClicked: root.isEditing = false
                        MaterialSymbol {
                            anchors.centerIn: parent
                            text: "close"
                            iconSize: Appearance.font.pixelSize.small
                            color: root.colSubtle
                        }
                    }
                }
            }

            // ── description (optional) ───────────────────────────────────────
            StyledText {
                visible: root.description.length > 0 && !root.isEditing
                Layout.fillWidth: true
                Layout.leftMargin: 2
                text: root.description
                font.pixelSize: Appearance.font.pixelSize.smaller
                color: root.colSubtle
                wrapMode: Text.WordWrap
            }

            // ── workspace chips row + duplicate warning ───────────────────────
            RowLayout {
                Layout.fillWidth: true
                spacing: 6

                Repeater {
                    model: root.workspaceIds
                    delegate: Rectangle {
                        required property var modelData
                        radius: Appearance.rounding.full
                        color: root.colChipBg
                        implicitWidth: chipLabel.implicitWidth + 16
                        implicitHeight: 22

                        StyledText {
                            id: chipLabel
                            anchors.centerIn: parent
                            text: root.getWorkspaceApps(modelData)
                            font.pixelSize: Appearance.font.pixelSize.smaller
                            color: root.colChipText
                        }
                    }
                }

                // duplicate-class warning badge
                Rectangle {
                    visible: root.hasDuplicateClasses
                    radius: Appearance.rounding.full
                    color: root.colWarnBg
                    implicitWidth: warnRow.implicitWidth + 14
                    implicitHeight: 22

                    HoverHandler { id: warnHover }

                    RowLayout {
                        id: warnRow
                        anchors.centerIn: parent
                        spacing: 3

                        MaterialSymbol {
                            text: "info"
                            iconSize: Appearance.font.pixelSize.smaller
                            color: root.colWarnText
                        }
                        StyledText {
                            text: "best-effort"
                            font.pixelSize: Appearance.font.pixelSize.smaller
                            color: root.colWarnText
                        }
                    }

                    StyledToolTip {
                        extraVisibleCondition: warnHover.hovered
                        text: "Some apps share a window class (e.g. two terminals). " +
                              "Restore will match by workspace proximity—result may vary."
                    }
                }

                Item { Layout.fillWidth: true }

                // window count chip
                StyledText {
                    text: `${root.windowCount} window${root.windowCount !== 1 ? "s" : ""}`
                    font.pixelSize: Appearance.font.pixelSize.smaller
                    color: root.colSubtle
                }

                // age
                StyledText {
                    text: root.createdAt > 0 ? _ageString(root.createdAt) : ""
                    font.pixelSize: Appearance.font.pixelSize.smaller
                    color: root.colSubtle
                }
            }

            // ── restore button row ────────────────────────────────────────────
            RowLayout {
                Layout.fillWidth: true
                spacing: 8

                // settings button to expand
                RippleButton {
                    implicitWidth: 32; implicitHeight: 32
                    buttonRadius: Appearance.rounding.full
                    colBackground: root.expanded
                        ? Appearance.colors.colSecondaryContainer
                        : Appearance.colors.colLayer2
                    onClicked: root.toggleExpandedRequested()
                    StyledToolTip { text: root.expanded ? "Collapse details" : "Configure autolaunch & windows" }
                    MaterialSymbol {
                        anchors.centerIn: parent
                        text: root.expanded ? "expand_less" : "settings"
                        iconSize: Appearance.font.pixelSize.normal
                        color: root.colOnSurface
                    }
                }

                Item { Layout.fillWidth: true }

                // feedback states
                RowLayout {
                    spacing: 6
                    visible: root.restoreSuccess || root.restorePartial
                    opacity: visible ? 1 : 0
                    Behavior on opacity { NumberAnimation { duration: 200 } }

                    MaterialSymbol {
                        text: root.restoreSuccess ? "check_circle" : "warning"
                        iconSize: Appearance.font.pixelSize.normal
                        color: root.restoreSuccess
                            ? Appearance.m3colors.m3primary
                            : Appearance.m3colors.m3tertiary
                        fill: 1
                    }
                    StyledText {
                        text: root.restoreSuccess
                            ? "Restored"
                            : "Partially restored"
                        font.pixelSize: Appearance.font.pixelSize.smaller
                        color: root.restoreSuccess
                            ? Appearance.m3colors.m3primary
                            : Appearance.m3colors.m3tertiary
                    }
                }

                // loading indicator while restoring
                MaterialLoadingIndicator {
                    visible: WorkspaceProfileService.restoring
                    implicitWidth: 24; implicitHeight: 24
                }

                // restore button
                RippleButtonWithIcon {
                    id: restoreBtn
                    materialIcon: "play_arrow"
                    materialIconFill: true
                    mainText: "Restore"
                    enabled: !WorkspaceProfileService.restoring
                    colText: Appearance.colors.colOnPrimary
                    colBackground: Appearance.colors.colPrimary
                    colBackgroundHover: Appearance.colors.colPrimaryHover
                    buttonRadius: Appearance.rounding.full
                    implicitHeight: 34

                    onClicked: root.restoreRequested()
                }
            }

            // ── expanded window settings section ──────────────────────────────
            ColumnLayout {
                visible: root.expanded
                Layout.fillWidth: true
                spacing: 8
                Layout.topMargin: 4
                Layout.bottomMargin: 4

                // Section divider line
                Rectangle {
                    Layout.fillWidth: true
                    height: 1
                    color: root.colBorder
                }

                StyledText {
                    text: "Configure Windows & Autolaunch"
                    font {
                        pixelSize: Appearance.font.pixelSize.small
                        weight: Font.Bold
                    }
                    color: root.colOnSurface
                    Layout.leftMargin: 2
                }

                RowLayout {
                    Layout.fillWidth: true
                    spacing: 8
                    Layout.leftMargin: 2
                    Layout.rightMargin: 2

                    StyledText {
                        text: "Close all other windows on restore"
                        font.pixelSize: Appearance.font.pixelSize.small
                        color: root.colOnSurface
                        Layout.fillWidth: true
                    }

                    StyledSwitch {
                        checked: root.closeOthers
                        onCheckedChanged: {
                            if (checked !== root.closeOthers) {
                                WorkspaceProfileService.updateProfileOptions(root.slug, checked)
                            }
                        }
                    }
                }

                // Sub-divider or spacer
                Item { Layout.preferredHeight: 4 }

                // Repeater of windows
                Repeater {
                    model: root.windowsList
                    delegate: RowLayout {
                        id: windowRow
                        required property int index
                        required property var modelData
                        Layout.fillWidth: true
                        spacing: 12

                        // Window identification (class name)
                        ColumnLayout {
                            Layout.alignment: Qt.AlignVCenter
                            spacing: 2
                            Layout.preferredWidth: 140
                            Layout.fillWidth: true

                            StyledText {
                                text: modelData.class || "unknown"
                                font {
                                    pixelSize: Appearance.font.pixelSize.small
                                    weight: Font.DemiBold
                                }
                                color: root.colOnSurface
                                elide: Text.ElideRight
                                Layout.fillWidth: true
                            }
                            StyledText {
                                visible: modelData.floating
                                text: "Floating"
                                font.pixelSize: Appearance.font.pixelSize.smaller
                                color: root.colSubtle
                            }
                        }

                        // Target Workspace ID field
                        RowLayout {
                            Layout.alignment: Qt.AlignVCenter
                            spacing: 6
                            StyledText {
                                text: "WS"
                                font.pixelSize: Appearance.font.pixelSize.small
                                color: root.colSubtle
                            }
                            MaterialTextField {
                                implicitWidth: 55
                                implicitHeight: 36
                                font.pixelSize: Appearance.font.pixelSize.small
                                horizontalAlignment: TextInput.AlignHCenter
                                verticalAlignment: TextInput.AlignVCenter
                                topPadding: 0
                                bottomPadding: 0
                                text: modelData.workspaceId.toString()
                                validator: IntValidator { bottom: 1; top: 20 }
                                onEditingFinished: {
                                    let val = parseInt(text);
                                    if (!isNaN(val) && val !== modelData.workspaceId) {
                                        WorkspaceProfileService.updateWindowWorkspace(
                                            root.slug,
                                            index,
                                            val
                                        );
                                    }
                                }
                            }
                        }

                        // Autolaunch switch
                        RowLayout {
                            Layout.alignment: Qt.AlignVCenter
                            spacing: 6
                            StyledText {
                                text: "Autolaunch"
                                font.pixelSize: Appearance.font.pixelSize.small
                                color: root.colSubtle
                            }
                            StyledSwitch {
                                checked: modelData.autolaunch || false
                                onCheckedChanged: {
                                    if (checked !== (modelData.autolaunch || false)) {
                                        WorkspaceProfileService.updateWindowOptions(
                                            root.slug,
                                            index,
                                            checked,
                                            cmdField.text
                                        )
                                    }
                                }
                            }
                        }

                        // Launch command text field
                        MaterialTextField {
                            id: cmdField
                            Layout.alignment: Qt.AlignVCenter
                            Layout.fillWidth: true
                            Layout.preferredWidth: 200
                            implicitHeight: 36
                            font.pixelSize: Appearance.font.pixelSize.small
                            verticalAlignment: TextInput.AlignVCenter
                            topPadding: 0
                            bottomPadding: 0
                            text: modelData.launchCmd || ""
                            placeholderText: activeFocus ? "" : ("Custom command/args for " + root.cleanAppName(modelData.initialClass || modelData.class))
                            enabled: modelData.autolaunch || false

                            onEditingFinished: {
                                if (text !== (modelData.launchCmd || "")) {
                                    WorkspaceProfileService.updateWindowOptions(
                                        root.slug,
                                        index,
                                        modelData.autolaunch || false,
                                        text
                                    )
                                }
                            }
                        }

                        // Delete window button
                        RippleButton {
                            id: delBtn
                            Layout.alignment: Qt.AlignVCenter
                            implicitWidth: 36; implicitHeight: 36
                            buttonRadius: Appearance.rounding.full
                            colBackground: "transparent"
                            colBackgroundHover: Appearance.colors.colErrorContainer
                            onClicked: {
                                WorkspaceProfileService.deleteWindow(root.slug, index);
                            }
                            StyledToolTip { text: "Delete window entry" }
                            MaterialSymbol {
                                anchors.centerIn: parent
                                text: "delete"
                                iconSize: Appearance.font.pixelSize.normal
                                color: delBtn.hovered ? Appearance.colors.colOnErrorContainer : root.colSubtle
                            }
                        }
                    }
                }

                // Add App button / form
                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 8

                    // The Add App button (shown when form is closed)
                    RippleButtonWithIcon {
                        visible: !root.showAddAppForm
                        Layout.alignment: Qt.AlignLeft
                        materialIcon: "add"
                        mainText: "Add App"
                        colText: root.colOnSurface
                        colBackground: Appearance.colors.colLayer2
                        colBackgroundHover: Appearance.colors.colLayer2Hover
                        buttonRadius: Appearance.rounding.full
                        implicitHeight: 34
                        onClicked: {
                            root.newAppClass = "";
                            root.newAppWorkspace = "1";
                            root.newAppAutolaunch = true;
                            root.newAppLaunchCmd = "";
                            root.showAddAppForm = true;
                        }
                    }

                    // The inline form (shown when form is open)
                    RowLayout {
                        visible: root.showAddAppForm
                        Layout.fillWidth: true
                        spacing: 10

                        // Class input
                        MaterialTextField {
                            id: newClassField
                            Layout.alignment: Qt.AlignVCenter
                            Layout.fillWidth: true
                            Layout.preferredWidth: 160
                            implicitHeight: 36
                            font.pixelSize: Appearance.font.pixelSize.small
                            verticalAlignment: TextInput.AlignVCenter
                            topPadding: 0
                            bottomPadding: 0
                            placeholderText: activeFocus ? "" : "App class (e.g. kitty)"
                            text: root.newAppClass
                            onTextChanged: root.newAppClass = text
                        }

                        // Workspace input
                        RowLayout {
                            Layout.alignment: Qt.AlignVCenter
                            spacing: 4
                            StyledText {
                                text: "WS"
                                font.pixelSize: Appearance.font.pixelSize.small
                                color: root.colSubtle
                            }
                            MaterialTextField {
                                implicitWidth: 55
                                implicitHeight: 36
                                font.pixelSize: Appearance.font.pixelSize.small
                                horizontalAlignment: TextInput.AlignHCenter
                                verticalAlignment: TextInput.AlignVCenter
                                topPadding: 0
                                bottomPadding: 0
                                text: root.newAppWorkspace
                                onTextChanged: root.newAppWorkspace = text
                                validator: IntValidator { bottom: 1; top: 20 }
                            }
                        }

                        // Autolaunch switch for the new app
                        RowLayout {
                            Layout.alignment: Qt.AlignVCenter
                            spacing: 4
                            StyledText {
                                text: "Auto"
                                font.pixelSize: Appearance.font.pixelSize.small
                                color: root.colSubtle
                            }
                            StyledSwitch {
                                checked: root.newAppAutolaunch
                                onCheckedChanged: root.newAppAutolaunch = checked
                            }
                        }

                        // Launch command text field
                        MaterialTextField {
                            id: newCmdField
                            Layout.alignment: Qt.AlignVCenter
                            Layout.fillWidth: true
                            Layout.preferredWidth: 160
                            implicitHeight: 36
                            font.pixelSize: Appearance.font.pixelSize.small
                            verticalAlignment: TextInput.AlignVCenter
                            topPadding: 0
                            bottomPadding: 0
                            placeholderText: activeFocus ? "" : "Launch cmd (optional)"
                            text: root.newAppLaunchCmd
                            onTextChanged: root.newAppLaunchCmd = text
                            enabled: root.newAppAutolaunch
                        }

                        // Action buttons
                        RowLayout {
                            Layout.alignment: Qt.AlignVCenter
                            spacing: 6

                            // Confirm/Add button
                            RippleButton {
                                implicitWidth: 36; implicitHeight: 36
                                buttonRadius: Appearance.rounding.full
                                colBackground: Appearance.colors.colPrimary
                                colBackgroundHover: Appearance.colors.colPrimaryHover
                                enabled: root.newAppClass.trim().length > 0 && root.newAppWorkspace.trim().length > 0
                                onClicked: {
                                    let ws = parseInt(root.newAppWorkspace.trim());
                                    if (isNaN(ws)) ws = 1;
                                    WorkspaceProfileService.addWindow(
                                        root.slug,
                                        root.newAppClass.trim(),
                                        ws,
                                        root.newAppAutolaunch,
                                        root.newAppLaunchCmd.trim()
                                    );
                                    root.showAddAppForm = false;
                                }
                                MaterialSymbol {
                                    anchors.centerIn: parent
                                    text: "check"
                                    iconSize: Appearance.font.pixelSize.small
                                    color: Appearance.colors.colOnPrimary
                                }
                            }

                            // Cancel button
                            RippleButton {
                                implicitWidth: 36; implicitHeight: 36
                                buttonRadius: Appearance.rounding.full
                                colBackground: Appearance.colors.colLayer2
                                onClicked: root.showAddAppForm = false
                                MaterialSymbol {
                                    anchors.centerIn: parent
                                    text: "close"
                                    iconSize: Appearance.font.pixelSize.small
                                    color: root.colSubtle
                                }
                            }
                        }
                    }
                }
            }
        }
    }

    // ── helpers ───────────────────────────────────────────────────────────────

    function cleanAppName(cls) {
        if (!cls) return "";
        let name = cls.toLowerCase();
        if (name === "brave-browser" || name === "brave") return "Brave";
        if (name === "google-chrome" || name === "chrome") return "Chrome";
        if (name === "kitty") return "Kitty";
        if (name === "code" || name === "visual-studio-code") return "VS Code";
        if (name === "firefox") return "Firefox";
        if (name === "discord") return "Discord";
        if (name === "spotify") return "Spotify";
        if (name === "steam") return "Steam";
        if (name === "obs") return "OBS Studio";
        if (name === "thunderbird") return "Thunderbird";
        if (name === "dolphin") return "Dolphin";
        if (name === "thunar") return "Thunar";
        if (name === "nautilus") return "Files";
        if (name === "vlc") return "VLC";
        if (name === "mpv") return "mpv";
        if (name === "gimp") return "GIMP";
        if (name === "inkscape") return "Inkscape";
        if (name === "libreoffice-writer") return "Writer";
        if (name === "libreoffice-calc") return "Calc";
        
        name = name.replace(/[-_]/g, " ");
        return name.charAt(0).toUpperCase() + name.slice(1);
    }

    function getWorkspaceApps(wsId) {
        let apps = [];
        for (const w of root.windowsList) {
            if (w.workspaceId === wsId) {
                let cleanName = cleanAppName(w.class || w.initialClass);
                if (cleanName && !apps.includes(cleanName)) {
                    apps.push(cleanName);
                }
            }
        }
        return apps.length > 0 ? apps.join(", ") : `ws ${wsId}`;
    }

    function getDefaultLaunchCmd(cls) {
        if (!cls) return "command";
        let name = cls.toLowerCase();
        if (name === "brave-browser" || name === "brave") return "brave";
        if (name === "google-chrome" || name === "chrome") return "google-chrome-stable";
        if (name === "navigator" || name === "firefox-esr") return "firefox";
        return cls;
    }

    function _dateString(epoch) {
        const d = new Date(epoch * 1000);
        return d.toLocaleDateString(Qt.locale(), "dd MMM yyyy");
    }

    function _ageString(epoch) {
        const now   = Math.floor(Date.now() / 1000);
        const delta = now - epoch;
        if (delta < 60)        return "just now";
        if (delta < 3600)      return `${Math.floor(delta / 60)}m ago`;
        if (delta < 86400)     return `${Math.floor(delta / 3600)}h ago`;
        if (delta < 86400 * 7) return `${Math.floor(delta / 86400)}d ago`;
        return _dateString(epoch);
    }
}
