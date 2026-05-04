pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import qs.modules.common
import qs.modules.common.widgets
import qs.services

Item {
    id: root

    readonly property color colBg: Appearance.colors.colLayer0
    readonly property color colTitle: Appearance.colors.colOnSurface
    readonly property color colSubtitle: Appearance.colors.colOnSurfaceVariant
    readonly property color colAccent: Appearance.colors.colPrimary
    readonly property color colAccentHover: Appearance.colors.colPrimaryHover
    readonly property color colOnAccent: Appearance.colors.colOnPrimary

    property string activeTag: ""
    property string searchText: ""
    property var allTags: []
    property var filteredIndices: {
        const q = root.searchText.toLowerCase();
        const tag = root.activeTag;
        const model = CommandsService.commandsModel;
        const result = [];
        for (let i = 0; i < model.count; i++) {
            const item = model.get(i);
            let tagMatch = tag === "";
            if (!tagMatch) {
                for (let t = 0; t < item.tags.count; t++) {
                    if (item.tags.get(t).modelData === tag) { tagMatch = true; break; }
                }
            }
            const textMatch = q === ""
                || item.command.toLowerCase().includes(q)
                || item.description.toLowerCase().includes(q);
            if (tagMatch && textMatch) result.push(i);
        }
        return result;
    }

    onFocusChanged: focus => {
        if (focus) filterField.forceActiveFocus();
    }

    function refreshTags() {
        allTags = CommandsService.allTags();
    }

    Connections {
        target: CommandsService.commandsModel
        function onCountChanged() { root.refreshTags(); }
    }

    Component.onCompleted: root.refreshTags()

    Rectangle {
        anchors.fill: parent
        color: root.colBg
        radius: Appearance.rounding.windowRounding
        antialiasing: true
    }

    Item {
        id: inboxContent
        anchors.fill: parent

        opacity: (commandForm.isOpen || commandForm.isAnimating) ? 0.0 : 1.0
        scale: (commandForm.isOpen || commandForm.isAnimating) ? 0.95 : 1.0
        enabled: !commandForm.isOpen && !commandForm.isAnimating

        Behavior on opacity { NumberAnimation { duration: 350; easing.type: Easing.OutCubic } }
        Behavior on scale { NumberAnimation { duration: 350; easing.type: Easing.OutCubic } }

        ColumnLayout {
            anchors.fill: parent
            spacing: 0

            RowLayout {
                Layout.fillWidth: true
                Layout.topMargin: 14
                Layout.leftMargin: 20
                Layout.rightMargin: 16
                Layout.bottomMargin: 4
                spacing: 12

                ColumnLayout {
                    spacing: 1
                    StyledText {
                        text: "CHEATSHEET"
                        font.pixelSize: Appearance.font.pixelSize.smaller
                        color: root.colSubtitle
                        font.family: Appearance.font.family.main
                    }
                    StyledText {
                        text: qsTr("Commands")
                        font.pixelSize: Appearance.font.pixelSize.huge
                        font.weight: Font.Bold
                        color: root.colTitle
                    }
                }

                Item { Layout.fillWidth: true }

                ButtonGroup {
                    spacing: 4
                    padding: 0

                    SelectionGroupButton {
                        buttonText: qsTr("All")
                        toggled: root.activeTag === ""
                        onClicked: root.activeTag = ""
                        leftmost: true
                        rightmost: root.allTags.length === 0
                    }

                    Repeater {
                        model: root.allTags
                        delegate: SelectionGroupButton {
                            required property string modelData
                            required property int index
                            buttonText: modelData
                            toggled: root.activeTag === modelData
                            onClicked: root.activeTag = (root.activeTag === modelData ? "" : modelData)
                            leftmost: false
                            rightmost: index === root.allTags.length - 1
                        }
                    }
                }

                RippleButton {
                    implicitHeight: 44
                    implicitWidth: addRow.implicitWidth + 24
                    buttonRadius: Appearance.rounding.full
                    colBackground: root.colAccent
                    colBackgroundHover: root.colAccentHover
                    onClicked: {
                        commandForm.mode = "add";
                        commandForm.editId = "";
                        commandForm.editCommand = "";
                        commandForm.editDescription = "";
                        commandForm.editTags = "";
                        commandForm.isOpen = true;
                    }

                    RowLayout {
                        id: addRow
                        anchors.centerIn: parent
                        spacing: 6
                        MaterialSymbol {
                            text: "add"
                            horizontalAlignment: Text.AlignHCenter
                            iconSize: Appearance.font.pixelSize.large
                            color: root.colOnAccent
                        }
                        StyledText {
                            text: qsTr("Add command")
                            font.weight: Font.Bold
                            color: root.colOnAccent
                        }
                    }
                }
            }

            StyledText {
                Layout.leftMargin: 20
                Layout.bottomMargin: 8
                text: root.filteredIndices.length + " " + qsTr("commands")
                font.pixelSize: Appearance.font.pixelSize.smaller
                color: root.colSubtitle
            }

            StyledFlickable {
                Layout.fillWidth: true
                Layout.fillHeight: true
                contentHeight: cardGrid.implicitHeight + 16
                clip: true

                GridLayout {
                    id: cardGrid
                    width: parent.width - 32
                    x: 16
                    columns: 2
                    columnSpacing: 10
                    rowSpacing: 10

                    Repeater {
                        model: root.filteredIndices
                        delegate: CommandCard {
                            required property int modelData
                            readonly property var cmdItem: CommandsService.commandsModel.get(modelData)

                            Layout.fillWidth: true

                            commandId:   cmdItem?.id ?? ""
                            command:     cmdItem?.command ?? ""
                            description: cmdItem?.description ?? ""
                            tags: {
                                if (!cmdItem) return [];
                                const arr = [];
                                for (let t = 0; t < cmdItem.tags.count; t++)
                                    arr.push(cmdItem.tags.get(t).modelData);
                                return arr;
                            }

                            onEditClicked: {
                                const item = cmdItem;
                                if (!item) return;
                                const tagArr = [];
                                for (let t = 0; t < item.tags.count; t++)
                                    tagArr.push(item.tags.get(t).modelData);

                                commandForm.mode = "edit";
                                commandForm.editId = item.id;
                                commandForm.editCommand = item.command;
                                commandForm.editDescription = item.description;
                                commandForm.editTags = tagArr.join(", ");
                                commandForm.isOpen = true;
                            }

                            onDeleteClicked: CommandsService.deleteCommand(commandId)
                        }
                    }
                }
            }

            Toolbar {
                id: extraOptions
                z: 1
                Layout.alignment: Qt.AlignHCenter
                Layout.bottomMargin: 40

                ToolbarTextField {
                    id: filterField
                    placeholderText: focus ? qsTr("Filter commands") : qsTr("Hit \"/\" to filter")
                    clip: true
                    font.pixelSize: Appearance.font.pixelSize.small
                    onTextChanged: root.searchText = text
                }

                IconToolbarButton {
                    implicitWidth: height
                    onClicked: root.searchText = filterField.text = ''
                    text: "close"
                    StyledToolTip { text: qsTr("Clear filter") }
                }
            }
        }

        PagePlaceholder {
            anchors.centerIn: parent
            shown: root.filteredIndices.length === 0
            icon: (root.searchText !== "" || root.activeTag !== "") ? "search_off" : "terminal"
            description: (root.searchText !== "" || root.activeTag !== "") ? qsTr("No results") : qsTr("No commands yet.\nClick \"Add command\" to get started.")
            shape: MaterialShape.Shape.Ghostish
            descriptionHorizontalAlignment: Text.AlignHCenter
        }
    }

    CommandForm {
        id: commandForm
        anchors.fill: parent
        z: 10
        visible: isOpen || isAnimating
        onCloseRequested: refreshTags()
    }
}
