import QtQuick
import QtQuick.Layouts

import qs.modules.common
import qs.modules.common.widgets

Rectangle {
    id: root

    Layout.fillWidth: true
    implicitHeight: 64
    radius: Appearance.rounding.full

    color: containerColor

    property string shapeString: "Circle"
    property int shapeSize: 40
    property string icon: ""

    property color containerColor: Appearance.colors.colSecondaryContainer
    property color shapeColor: Appearance.colors.colSecondary
    property color symbolColor: Appearance.colors.colOnSecondary
    property color textColor: Appearance.colors.colOnSecondaryContainer
    
    // Internal animation control
    property bool startAnim: false
    
    onStartAnimChanged: {
        if (startAnim) {
            // Reset elements
            shapeTranslate.x = -30;
            shapeItem.scale = 0.8;
            shapeItem.rotation = -10;
            pillText.opacity = 0.0;
            textContainer.opacity = 0.0;
            
            // Start animations
            Qt.callLater(function() {
                shapeAnim.start();
                textAnim.start();
            });
        }
    }

    default property alias shapeContent: shapeItem.children
    property alias text: pillText.text
    property alias textContent: textContainer.children

    Item {
        id: shapeContainer
        width: root.shapeSize
        height: root.shapeSize
        anchors {
            left: parent.left
            leftMargin: 12
            verticalCenter: parent.verticalCenter
        }
        
        transform: Translate {
            id: shapeTranslate
            x: 0
        }
        
        SequentialAnimation {
            id: shapeAnim
            PauseAnimation { duration: 60 }
            ParallelAnimation {
                NumberAnimation { target: shapeTranslate; property: "x"; from: -30; to: 0; duration: 350; easing.type: Easing.OutCubic }
                NumberAnimation { target: shapeItem; property: "scale"; from: 0.8; to: 1.0; duration: 350; easing.type: Easing.OutBack }
                NumberAnimation { target: shapeItem; property: "rotation"; from: -10; to: 0; duration: 350; easing.type: Easing.OutCubic }
            }
        }

        MaterialShape {
            id: shapeItem
            shapeString: root.shapeString
            implicitSize: root.shapeSize
            color: root.shapeColor
            anchors.centerIn: parent
            scale: 1.0
            rotation: 0

            MaterialSymbol {
                id: iconSymbol
                visible: root.icon !== "" && shapeItem.children.length <= 1
                anchors.centerIn: parent
                text: root.icon
                iconSize: Appearance.font.pixelSize.large
                color: root.symbolColor
            }
        }
    }

    Item {
        id: textContainer
        anchors {
            verticalCenter: parent.verticalCenter
            horizontalCenter: parent.horizontalCenter
            horizontalCenterOffset: 9
        }
        opacity: 1.0
        
        SequentialAnimation {
            id: textAnim
            PauseAnimation { duration: 120 }
            NumberAnimation { target: textContainer; property: "opacity"; from: 0.0; to: 1.0; duration: 250 }
        }

        StyledText {
            id: pillText
            anchors.centerIn: parent
            font.pixelSize: Appearance.font.pixelSize.large
            font.family: Appearance.font.family.title
            font.weight: Font.Bold
            color: root.textColor
            visible: text !== "" && textContainer.children.length <= 1
        }
    }
}

