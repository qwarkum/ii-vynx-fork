import QtQuick
import QtQuick.Layouts
import qs.modules.common
import qs.modules.common.widgets
import qs.services

Rectangle {
    id: root

    Layout.fillWidth: true
    Layout.preferredHeight: implicitHeight
    implicitHeight: columnLayout.implicitHeight + 32
    radius: Appearance.rounding.large
    color: Appearance.colors.colLayer2
    clip: true

    Behavior on implicitHeight {
        NumberAnimation {
            duration: 250
            easing.type: Easing.OutCubic
        }
    }

    property string mode: "list" // "list", "add", "edit"
    property int editingIndex: -1
    property bool deleteMode: false

    // Edit form states
    property string editTimeHour: "08"
    property string editTimeMinute: "00"
    property string editLabel: ""
    property var editDays: [false, false, false, false, false, false, false]

    function openEdit(index, alarm) {
        root.editingIndex = index;
        root.editTimeHour = alarm.time.split(":")[0] || "08";
        root.editTimeMinute = alarm.time.split(":")[1] || "00";
        root.editLabel = alarm.label || "";
        root.editDays = [...alarm.days];
        root.deleteMode = false;
        root.mode = "edit";
    }

    function openAdd() {
        let now = new Date();
        root.editingIndex = -1;
        root.editTimeHour = now.getHours().toString().padStart(2, '0');
        root.editTimeMinute = now.getMinutes().toString().padStart(2, '0');
        root.editLabel = "";
        root.editDays = [false, false, false, false, false, false, false];
        root.deleteMode = false;
        root.mode = "add";
    }

    ColumnLayout {
        id: columnLayout
        anchors {
            left: parent.left
            right: parent.right
            top: parent.top
            margins: 16
        }
        spacing: 16

        // LIST MODE
        ColumnLayout {
            Layout.fillWidth: true
            spacing: 16
            visible: root.mode === "list"

            // Header Row
            RowLayout {
                Layout.fillWidth: true
                spacing: 12

                MaterialSymbol {
                    text: "alarm"
                    iconSize: 24
                    color: AlarmService.ringingAlarmIndex !== -1 ? Appearance.colors.colError : Appearance.colors.colPrimary
                }

                ColumnLayout {
                    spacing: 1
                    StyledText {
                        text: Translation.tr("Alarms")
                        font.weight: Font.Bold
                        font.pixelSize: Appearance.font.pixelSize.normal
                        color: Appearance.colors.colOnSurface
                    }

                    StyledText {
                        text: AlarmService.alarms ? AlarmService.alarms.length + " " + Translation.tr("Alarms") : "0 " + Translation.tr("Alarms")
                        font.weight: Font.Light
                        font.pixelSize: Appearance.font.pixelSize.small
                        color: Appearance.colors.colSubtext
                    }
                }

                Item {
                    Layout.fillWidth: true
                }

                // Delete (red/toggle) button
                RippleButton {
                    id: deleteButton
                    Layout.preferredWidth: 32
                    Layout.preferredHeight: 32
                    buttonRadius: 16
                    colBackground: root.deleteMode ? Appearance.colors.colError : Appearance.colors.colErrorContainer
                    colBackgroundHover: root.deleteMode ? Appearance.colors.colErrorHover : Appearance.colors.colErrorContainerHover

                    MaterialSymbol {
                        anchors.centerIn: parent
                        text: "delete"
                        iconSize: 16
                        color: root.deleteMode ? Appearance.colors.colOnError : Appearance.colors.colOnErrorContainer
                    }

                    onClicked: {
                        root.deleteMode = !root.deleteMode;
                    }
                }

                // Add (blue) button
                RippleButton {
                    id: addButton
                    Layout.preferredWidth: 32
                    Layout.preferredHeight: 32
                    buttonRadius: 16
                    colBackground: Appearance.colors.colPrimaryContainer
                    colBackgroundHover: Appearance.colors.colPrimaryContainerHover

                    MaterialSymbol {
                        anchors.centerIn: parent
                        text: "add"
                        iconSize: 16
                        color: Appearance.colors.colOnPrimaryContainer
                    }

                    onClicked: {
                        root.openAdd();
                    }
                }
            }

            // Horizontal list of alarm cards
            ListView {
                id: listView
                Layout.fillWidth: true
                Layout.preferredHeight: count > 0 ? 96 : 0
                orientation: ListView.Horizontal
                spacing: 12
                clip: true
                model: AlarmService.alarms

                add: Transition {
                    NumberAnimation { properties: "scale,opacity"; from: 0; to: 1.0; duration: 250; easing.type: Easing.OutQuad }
                }
                remove: Transition {
                    NumberAnimation { properties: "scale,opacity"; to: 0; duration: 200; easing.type: Easing.OutQuad }
                }
                displaced: Transition {
                    NumberAnimation { properties: "x,y"; duration: 250; easing.type: Easing.OutQuad }
                }

                delegate: Rectangle {
                    id: alarmCard
                    width: listView.count >= 2 ? (listView.width > 0 ? listView.width * 0.85 : 320) : (listView.width > 0 ? listView.width : 380)
                    height: 96
                    radius: Appearance.rounding.large
                    color: AlarmService.ringingAlarmIndex === index ? Appearance.colors.colErrorContainer : Appearance.colors.colLayer3
                    clip: true

                    opacity: AlarmService.ringingAlarmIndex === index ? 1.0 : (modelData.enabled ? 1.0 : 0.6)
                    Behavior on opacity {
                        id: opacityBehavior
                        enabled: AlarmService.ringingAlarmIndex !== index
                        NumberAnimation { duration: 200; easing.type: Easing.InOutQuad }
                    }

                    required property var modelData
                    required property int index

                    // Clickable area for editing (on label & time side)
                    MouseArea {
                        anchors {
                            left: parent.left
                            right: controlsColumn.left
                            top: parent.top
                            bottom: parent.bottom
                        }
                        onClicked: {
                            if (!root.deleteMode && AlarmService.ringingAlarmIndex === -1) {
                                root.openEdit(alarmCard.index, alarmCard.modelData);
                            }
                        }
                    }

                    ColumnLayout {
                        anchors {
                            left: parent.left
                            leftMargin: 20
                            verticalCenter: parent.verticalCenter
                        }
                        spacing: 4

                        StyledText {
                            text: alarmCard.modelData.label || Translation.tr("Alarm")
                            font.pixelSize: Appearance.font.pixelSize.small
                            color: AlarmService.ringingAlarmIndex === index ? Appearance.colors.colOnErrorContainer : Appearance.colors.colSubtext
                        }

                        StyledText {
                            text: alarmCard.modelData.time
                            font.pixelSize: Math.min(36, alarmCard.width * 0.1)
                            font.family: Appearance.font.family.title
                            font.weight: Font.Bold
                            color: AlarmService.ringingAlarmIndex === index ? Appearance.colors.colOnErrorContainer : Appearance.colors.colOnSurface
                        }
                    }

                    // Switch, Delete, or STOP button column
                    ColumnLayout {
                        id: controlsColumn
                        anchors {
                            right: parent.right
                            rightMargin: 20
                            verticalCenter: parent.verticalCenter
                        }
                        spacing: 12
                        Layout.alignment: Qt.AlignRight

                        Loader {
                            id: controlLoader
                            Layout.alignment: Qt.AlignRight
                            Layout.preferredWidth: item ? (item.width > 0 ? item.width : item.implicitWidth) : 0
                            Layout.preferredHeight: item ? (item.height > 0 ? item.height : item.implicitHeight) : 0
                            sourceComponent: {
                                if (AlarmService.ringingAlarmIndex === alarmCard.index) {
                                    return stopButtonComponent;
                                }
                                if (root.deleteMode) {
                                    return deleteItemButtonComponent;
                                }
                                return switchComponent;
                            }
                        }

                        // 7 Weekday dots (hidden when ringing or deleting to keep tidy)
                        RowLayout {
                            spacing: 4
                            Layout.alignment: Qt.AlignRight
                            visible: AlarmService.ringingAlarmIndex !== alarmCard.index && !root.deleteMode

                            Repeater {
                                model: 7
                                delegate: Rectangle {
                                    width: 8
                                    height: 8
                                    radius: 4
                                    color: alarmCard.modelData.days[index] ? Appearance.colors.colPrimary : Appearance.colors.colSubtext
                                    opacity: alarmCard.modelData.days[index] ? 1.0 : 0.2
                                }
                            }
                        }
                    }

                    // Pulse animation for ringing card
                    SequentialAnimation {
                        running: AlarmService.ringingAlarmIndex === alarmCard.index
                        loops: Animation.Infinite

                        NumberAnimation {
                            target: alarmCard
                            property: "opacity"
                            from: 1.0
                            to: 0.5
                            duration: 500
                            easing.type: Easing.InOutQuad
                        }
                        NumberAnimation {
                            target: alarmCard
                            property: "opacity"
                            from: 0.5
                            to: 1.0
                            duration: 500
                            easing.type: Easing.InOutQuad
                        }
                        onStopped: {
                            alarmCard.opacity = 1.0;
                        }
                    }

                    Component {
                        id: stopButtonComponent
                        RippleButton {
                            width: 64
                            height: 32
                            buttonRadius: 16
                            colBackground: Appearance.colors.colError
                            colBackgroundHover: Appearance.colors.colErrorHover

                            contentItem: StyledText {
                                text: Translation.tr("STOP")
                                horizontalAlignment: Text.AlignHCenter
                                verticalAlignment: Text.AlignVCenter
                                font.weight: Font.Bold
                                font.pixelSize: Appearance.font.pixelSize.small
                                color: Appearance.colors.colOnError
                            }

                            onClicked: {
                                AlarmService.stopRinging();
                            }
                        }
                    }

                    Component {
                        id: deleteItemButtonComponent
                        RippleButton {
                            width: 32
                            height: 32
                            buttonRadius: 16
                            colBackground: Appearance.colors.colErrorContainer
                            colBackgroundHover: Appearance.colors.colErrorContainerHover

                            MaterialSymbol {
                                anchors.centerIn: parent
                                text: "delete"
                                iconSize: 16
                                color: Appearance.colors.colOnErrorContainer
                            }

                            onClicked: {
                                AlarmService.deleteAlarm(alarmCard.index);
                            }
                        }
                    }

                    Component {
                        id: switchComponent
                        StyledSwitch {
                            checked: alarmCard.modelData.enabled
                            sizeScale: 0.75
                            onCheckedChanged: {
                                if (alarmCard.modelData.enabled !== checked) {
                                    AlarmService.toggleAlarm(alarmCard.index);
                                }
                            }
                        }
                    }
                }
            }

            StyledText {
                visible: listView.count === 0
                Layout.alignment: Qt.AlignHCenter
                text: Translation.tr("No alarms set")
                font.pixelSize: Appearance.font.pixelSize.small
                color: Appearance.colors.colSubtext
            }
        }

        // ADD / EDIT INLINE MODE
        ColumnLayout {
            id: editLayout
            Layout.fillWidth: true
            spacing: 12
            visible: root.mode !== "list"

            StyledText {
                text: root.mode === "add" ? Translation.tr("Add Alarm") : Translation.tr("Edit Alarm")
                font.weight: Font.Bold
                font.pixelSize: Appearance.font.pixelSize.normal
                color: Appearance.colors.colOnSurface
            }

            // Input Row: Hour : Minute | Label
            RowLayout {
                Layout.fillWidth: true
                spacing: 8

                // Hour Field
                MaterialTextField {
                    id: hourInput
                    Layout.preferredWidth: 64
                    placeholderText: "HH"
                    text: root.editTimeHour
                    inputMethodHints: Qt.ImhDigitsOnly
                }

                StyledText {
                    text: ":"
                    font.weight: Font.Bold
                    font.pixelSize: Appearance.font.pixelSize.large
                    color: Appearance.colors.colOnSurface
                }

                // Minute Field
                MaterialTextField {
                    id: minuteInput
                    Layout.preferredWidth: 64
                    placeholderText: "MM"
                    text: root.editTimeMinute
                    inputMethodHints: Qt.ImhDigitsOnly
                }

                // Label Field
                MaterialTextField {
                    id: labelInput
                    Layout.fillWidth: true
                    placeholderText: Translation.tr("Alarm Label")
                    text: root.editLabel
                }
            }

            // Weekday dot selector buttons
            RowLayout {
                Layout.fillWidth: true
                spacing: 4
                Layout.alignment: Qt.AlignHCenter

                Repeater {
                    model: 7
                    delegate: RippleButton {
                        id: dayButton
                        Layout.preferredWidth: 32
                        Layout.preferredHeight: 32
                        buttonRadius: 16

                        property bool selected: root.editDays[index]
                        property string dayText: {
                            const letters = [
                                Translation.tr("S"),
                                Translation.tr("M"),
                                Translation.tr("T"),
                                Translation.tr("W"),
                                Translation.tr("T"),
                                Translation.tr("F"),
                                Translation.tr("S")
                            ];
                            return letters[index];
                        }

                        colBackground: selected ? Appearance.colors.colPrimary : Appearance.colors.colSurfaceContainerHighest
                        colBackgroundHover: selected ? Appearance.colors.colPrimaryHover : Appearance.colors.colSurfaceContainerHighestHover

                        contentItem: StyledText {
                            text: dayButton.dayText
                            horizontalAlignment: Text.AlignHCenter
                            verticalAlignment: Text.AlignVCenter
                            font.weight: Font.Bold
                            font.pixelSize: Appearance.font.pixelSize.small
                            color: dayButton.selected ? Appearance.colors.colOnPrimary : Appearance.colors.colOnSurface
                        }

                        onClicked: {
                            let temp = [...root.editDays];
                            temp[index] = !temp[index];
                            root.editDays = temp;
                        }
                    }
                }
            }

            // Save / Cancel / Delete controls
            RowLayout {
                Layout.fillWidth: true
                spacing: 12
                Layout.topMargin: 4

                // Delete button in edit form
                RippleButton {
                    visible: root.mode === "edit"
                    Layout.preferredWidth: 36
                    Layout.preferredHeight: 36
                    buttonRadius: 18
                    colBackground: Appearance.colors.colErrorContainer
                    colBackgroundHover: Appearance.colors.colErrorContainerHover

                    MaterialSymbol {
                        anchors.centerIn: parent
                        text: "delete"
                        iconSize: 18
                        color: Appearance.colors.colOnErrorContainer
                    }

                    onClicked: {
                        AlarmService.deleteAlarm(root.editingIndex);
                        root.mode = "list";
                    }
                }

                Item {
                    visible: root.mode === "edit"
                    Layout.fillWidth: true
                }

                 RippleButton {
                    colBackground: Appearance.colors.colSurfaceContainerHighest
                    colBackgroundHover: Appearance.colors.colSurfaceContainerHighestHover
                    Layout.preferredWidth: 110
                    Layout.preferredHeight: 40
                    buttonRadius: 20

                    contentItem: RowLayout {
                        spacing: 6
                        RowLayout {
                            Layout.alignment: Qt.AlignCenter
                            spacing: 6
                            MaterialSymbol {
                                text: "close"
                                iconSize: 18
                                color: Appearance.colors.colOnSurface
                            }
                            StyledText {
                                text: Translation.tr("Cancel")
                                font.weight: Font.Medium
                                color: Appearance.colors.colOnSurface
                            }
                        }
                    }

                    onClicked: {
                        root.mode = "list";
                    }
                }

                RippleButton {
                    colBackground: Appearance.colors.colPrimaryContainer
                    colBackgroundHover: Appearance.colors.colPrimaryContainerHover
                    Layout.fillWidth: root.mode === "add"
                    Layout.preferredWidth: root.mode === "edit" ? 110 : -1
                    Layout.preferredHeight: 40
                    buttonRadius: 20

                    contentItem: RowLayout {
                        spacing: 6
                        RowLayout {
                            Layout.alignment: Qt.AlignCenter
                            spacing: 6
                            MaterialSymbol {
                                text: "check"
                                iconSize: 18
                                color: Appearance.colors.colOnPrimaryContainer
                            }
                            StyledText {
                                text: Translation.tr("Save")
                                font.weight: Font.Bold
                                color: Appearance.colors.colOnPrimaryContainer
                            }
                        }
                    }

                    onClicked: {
                        // JS Validation
                        let h = parseInt(hourInput.text);
                        let m = parseInt(minuteInput.text);

                        if (isNaN(h) || h < 0 || h > 23 || isNaN(m) || m < 0 || m > 59) {
                            console.log("Invalid alarm time input:", hourInput.text, ":", minuteInput.text);
                            return;
                        }

                        let timeStr = h.toString().padStart(2, '0') + ":" + m.toString().padStart(2, '0');
                        let labelStr = labelInput.text.trim();

                        if (root.mode === "add") {
                            AlarmService.addAlarm(timeStr, labelStr, root.editDays);
                        } else {
                            AlarmService.editAlarm(root.editingIndex, timeStr, labelStr, root.editDays);
                        }
                        root.mode = "list";
                    }
                }
            }
        }
    }
}
