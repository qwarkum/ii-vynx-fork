import QtQuick
import QtQuick.Layouts
import qs
import qs.modules.common
import qs.modules.common.widgets
import qs.services
import Quickshell

Item {
    id: root
    anchors.fill: parent
    property bool isExpanded: false

    // Fetch the drag status from DynamicIslandPanel via parent traversal
    readonly property bool isDragActive: {
        var p = root.parent;
        while (p && !p.hasOwnProperty("isDragOverNotch")) {
            p = p.parent;
        }
        return p ? p.isDragOverNotch : false;
    }

    // Contracted view: simple state display
    RowLayout {
        id: contractedLayout
        anchors.fill: parent
        anchors.leftMargin: 12
        anchors.rightMargin: 12
        spacing: 8
        opacity: !root.isExpanded ? 1.0 : 0.0
        visible: opacity > 0.01
        Behavior on opacity { NumberAnimation { duration: 150 } }

        MaterialSymbol {
            id: statusIcon
            Layout.alignment: Qt.AlignVCenter
            text: root.isDragActive ? "attachment" : (LocalSend.currentTransfer !== null ? "cloud_download" : (LocalSend.sending ? "sync" : "share"))
            iconSize: 16
            color: root.isDragActive ? Appearance.colors.colPrimary : Appearance.colors.colOnSurface

            RotationAnimation on rotation {
                running: LocalSend.sending && !root.isExpanded
                loops: Animation.Infinite
                from: 0
                to: 360
                duration: 2000
            }
        }

        StyledText {
            Layout.fillWidth: true
            Layout.alignment: Qt.AlignVCenter
            font.pixelSize: Appearance.font.pixelSize.smaller
            font.bold: true
            color: root.isDragActive ? Appearance.colors.colPrimary : Appearance.colors.colOnSurface
            text: {
                if (root.isDragActive) {
                    return Translation.tr("Drop files to share");
                }
                if (LocalSend.currentTransfer !== null) {
                    return Translation.tr("Incoming: %1").arg(LocalSend.currentTransfer.sender);
                }
                if (LocalSend.sending) {
                    return Translation.tr("Sending files...");
                }
                if (LocalSend.droppedFiles.length > 0) {
                    return LocalSend.droppedFiles.length === 1
                        ? Translation.tr("1 file attached")
                        : Translation.tr("%1 files attached").arg(LocalSend.droppedFiles.length);
                }
                return Translation.tr("LocalSend Share");
            }
            elide: Text.ElideRight
            maximumLineCount: 1
            wrapMode: Text.NoWrap
        }

        // Mini clear button if files are attached
        RippleButton {
            visible: LocalSend.droppedFiles.length > 0 && !root.isDragActive
            Layout.alignment: Qt.AlignVCenter
            implicitWidth: 18
            implicitHeight: 18
            buttonRadius: Appearance.rounding.full
            colBackground: "transparent"
            onClicked: LocalSend.clearDroppedFiles()
            contentItem: MaterialSymbol {
                text: "close"
                iconSize: 12
                color: Appearance.colors.colSubtext
            }
        }
    }

    // Expanded view
    ColumnLayout {
        id: expandedLayout
        anchors.fill: parent
        anchors.margins: 8
        spacing: 4
        opacity: root.isExpanded ? 1.0 : 0.0
        visible: opacity > 0.01
        Behavior on opacity { NumberAnimation { duration: 150 } }

        // --- INCOMING FILE TRANSFER PROMPT ---
        ColumnLayout {
            visible: LocalSend.currentTransfer !== null
            Layout.fillWidth: true
            Layout.fillHeight: true
            spacing: 6

            RowLayout {
                Layout.fillWidth: true
                spacing: 6

                MaterialSymbol {
                    text: "cloud_download"
                    iconSize: 16
                    color: Appearance.colors.colPrimary
                }

                StyledText {
                    text: Translation.tr("Incoming Transfer")
                    font.pixelSize: Appearance.font.pixelSize.smaller
                    font.bold: true
                    color: Appearance.colors.colPrimary
                    Layout.fillWidth: true
                }

                StyledText {
                    text: LocalSend.currentTransfer ? LocalSend.currentTransfer.senderIp : ""
                    font.pixelSize: 9
                    color: Appearance.colors.colSubtext
                }
            }

            // Sender description & file counts
            Rectangle {
                Layout.fillWidth: true
                Layout.fillHeight: true
                radius: Appearance.rounding.small
                color: Appearance.colors.colSurfaceContainerLow
                border.width: 0
                border.color: Appearance.colors.colLayer0Border
                clip: true

                ColumnLayout {
                    anchors.fill: parent
                    anchors.margins: 8
                    spacing: 4

                    StyledText {
                        text: Translation.tr("From: %1").arg(LocalSend.currentTransfer ? LocalSend.currentTransfer.sender : "")
                        font.pixelSize: Appearance.font.pixelSize.smaller
                        font.bold: true
                        color: Appearance.colors.colOnSurface
                        elide: Text.ElideRight
                        Layout.fillWidth: true
                    }

                    StyledText {
                        text: {
                            if (!LocalSend.currentTransfer) return "";
                            const files = LocalSend.currentTransfer.files;
                            if (files.length === 0) return Translation.tr("No files");
                            if (files.length === 1) return files[0].name + " (" + LocalSend.formatFileSize(files[0].size) + ")";
                            return Translation.tr("%1 files").arg(files.length);
                        }
                        font.pixelSize: Appearance.font.pixelSize.smaller
                        color: Appearance.colors.colSubtext
                        elide: Text.ElideMiddle
                        Layout.fillWidth: true
                    }
                }
            }

            // Action Buttons
            RowLayout {
                Layout.fillWidth: true
                spacing: 8

                RippleButton {
                    Layout.fillWidth: true
                    implicitHeight: 28
                    buttonRadius: Appearance.rounding.small
                    colBackground: Appearance.colors.colSuccess || "#2e7d32"
                    onClicked: LocalSend.acceptTransfer()
                    contentItem: StyledText {
                        text: Translation.tr("Accept")
                        font.pixelSize: Appearance.font.pixelSize.smaller
                        font.bold: true
                        color: "#ffffff"
                        horizontalAlignment: Text.AlignHCenter
                    }
                }

                RippleButton {
                    Layout.fillWidth: true
                    implicitHeight: 28
                    buttonRadius: Appearance.rounding.small
                    colBackground: Appearance.colors.colError || "#d32f2f"
                    onClicked: LocalSend.denyTransfer()
                    contentItem: StyledText {
                        text: Translation.tr("Decline")
                        font.pixelSize: Appearance.font.pixelSize.smaller
                        font.bold: true
                        color: "#ffffff"
                        horizontalAlignment: Text.AlignHCenter
                    }
                }
            }
        }

        // --- OUTGOING SEND SHARE ---
        ColumnLayout {
            visible: LocalSend.currentTransfer === null
            Layout.fillWidth: true
            Layout.fillHeight: true
            spacing: 6

            RowLayout {
                Layout.fillWidth: true
                spacing: 6

                MaterialSymbol {
                    text: "share"
                    iconSize: 16
                    color: Appearance.colors.colPrimary
                }

                StyledText {
                    text: Translation.tr("LocalSend Share")
                    font.pixelSize: Appearance.font.pixelSize.smaller
                    font.bold: true
                    color: Appearance.colors.colPrimary
                    Layout.fillWidth: true
                }

                // Discovered count or scanning notice
                StyledText {
                    text: LocalSend.sending ? Translation.tr("Sending...") : (LocalSend.scanning ? Translation.tr("Scanning...") : Translation.tr("Ready"))
                    font.pixelSize: 9
                    color: Appearance.colors.colSubtext
                }
            }

            // File list status box
            Rectangle {
                Layout.fillWidth: true
                implicitHeight: 30
                radius: Appearance.rounding.small
                color: Appearance.colors.colSurfaceContainerLow
                border.width: 0
                border.color: Appearance.colors.colLayer0Border

                RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: 8
                    anchors.rightMargin: 8
                    spacing: 6

                    MaterialSymbol {
                        text: "attach_file"
                        iconSize: 14
                        color: Appearance.colors.colPrimary
                    }

                    StyledText {
                        Layout.fillWidth: true
                        font.pixelSize: Appearance.font.pixelSize.smaller
                        color: Appearance.colors.colOnSurface
                        text: {
                            if (LocalSend.droppedFiles.length === 0) {
                                return Translation.tr("Drag files here to send");
                            }
                            return LocalSend.droppedFiles.length === 1
                                ? Translation.tr("1 file attached")
                                : Translation.tr("%1 files attached").arg(LocalSend.droppedFiles.length);
                        }
                        elide: Text.ElideRight
                    }

                    RippleButton {
                        visible: LocalSend.droppedFiles.length > 0
                        implicitWidth: 50
                        implicitHeight: 22
                        buttonRadius: Appearance.rounding.small
                        colBackground: "transparent"
                        onClicked: LocalSend.clearDroppedFiles()
                        contentItem: StyledText {
                            text: Translation.tr("Clear")
                            font.pixelSize: 9
                            color: Appearance.colors.colError || "#d32f2f"
                            horizontalAlignment: Text.AlignHCenter
                        }
                    }
                }
            }

            // Discovered Devices view
            Rectangle {
                Layout.fillWidth: true
                Layout.fillHeight: true
                radius: Appearance.rounding.small
                color: Appearance.colors.colSurfaceContainerLow
                border.width: 0
                border.color: Appearance.colors.colLayer0Border
                clip: true

                ListView {
                    id: deviceList
                    anchors.fill: parent
                    anchors.margins: 4
                    model: LocalSend.discoveredDevices
                    spacing: 4
                    clip: true

                    delegate: Rectangle {
                        width: parent.width
                        implicitHeight: 30
                        radius: Appearance.rounding.small
                        color: Appearance.colors.colSurfaceContainer
                        border.width: 0
                        border.color: Appearance.colors.colLayer0Border

                        RowLayout {
                            anchors.fill: parent
                            anchors.leftMargin: 8
                            anchors.rightMargin: 8
                            spacing: 8

                            MaterialSymbol {
                                text: "smartphone"
                                iconSize: 14
                                color: Appearance.colors.colPrimary
                            }

                            ColumnLayout {
                                Layout.fillWidth: true
                                spacing: 0
                                Layout.alignment: Qt.AlignVCenter

                                StyledText {
                                    text: modelData.name
                                    font.pixelSize: Appearance.font.pixelSize.smaller
                                    font.bold: true
                                    color: Appearance.colors.colOnSurface
                                    elide: Text.ElideRight
                                    Layout.fillWidth: true
                                }
                            }

                            RippleButton {
                                implicitWidth: 50
                                implicitHeight: 22
                                buttonRadius: Appearance.rounding.small
                                colBackground: Appearance.colors.colPrimary
                                colBackgroundHover: Appearance.colors.colPrimaryHover
                                enabled: !LocalSend.sending && LocalSend.droppedFiles.length > 0
                                onClicked: LocalSend.sendToDevice(modelData.ip)

                                contentItem: StyledText {
                                    text: Translation.tr("Send")
                                    font.pixelSize: 9
                                    font.bold: true
                                    color: Appearance.colors.colOnPrimary
                                    horizontalAlignment: Text.AlignHCenter
                                    verticalAlignment: Text.AlignVCenter
                                }
                            }
                        }
                    }

                    // Empty State Notice
                    StyledText {
                        visible: LocalSend.discoveredDevices.length === 0
                        anchors.centerIn: parent
                        text: Translation.tr("No devices found")
                        font.pixelSize: 9
                        color: Appearance.colors.colSubtext
                    }
                }
            }
        }
    }
}
