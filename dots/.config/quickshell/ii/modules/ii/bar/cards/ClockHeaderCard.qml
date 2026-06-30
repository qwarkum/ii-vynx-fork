import QtQuick
import QtQuick.Layouts
import Qt5Compat.GraphicalEffects
import qs.modules.common
import qs.modules.common.widgets
import qs.services

Rectangle {
    id: root

    Layout.fillWidth: true
    Layout.preferredHeight: 200
    implicitHeight: 200

    radius: Appearance.rounding.large
    color: Appearance.colors.colPrimaryContainer

    // Clip content to card's rounded borders using OpacityMask
    layer.enabled: true
    layer.smooth: true
    layer.effect: OpacityMask {
        maskSource: Rectangle {
            width: root.width
            height: root.height
            radius: root.radius
            antialiasing: true
        }
    }

    // Left-side clock circle (approx 306px, centered on screen layout)
    Rectangle {
        id: clockCircle
        width: parent.height * 1.53
        height: width
        radius: width / 2
        color: Appearance.colors.colPrimary
        anchors {
            left: parent.left
            leftMargin: -width * 0.52
            verticalCenter: parent.verticalCenter
        }

        // Rotating clock ticks Canvas
        Canvas {
            id: ticksCanvas
            anchors.fill: parent
            antialiasing: true
            z: 1

            onPaint: {
                var ctx = getContext("2d");
                ctx.reset();
                ctx.strokeStyle = Qt.rgba(255, 255, 255, 0.45); // Semi-transparent white ticks
                ctx.lineWidth = 2.5;

                var cx = width / 2;
                var cy = height / 2;
                var r = width / 2;
                var r1 = r * 0.78; // Proportional inner tick radius
                var r2 = r * 0.95; // Proportional outer tick radius
                var count = 90; // Density of clock ticks

                for (var i = 0; i < count; i++) {
                    var angle = i * (2 * Math.PI / count);
                    ctx.beginPath();
                    ctx.moveTo(cx + r1 * Math.cos(angle), cy + r1 * Math.sin(angle));
                    ctx.lineTo(cx + r2 * Math.cos(angle), cy + r2 * Math.sin(angle));
                    ctx.stroke();
                }
            }

            // Continuous rotation animation
            RotationAnimation on rotation {
                from: 0
                to: 360
                duration: 40000 // 40 seconds per full turn
                loops: Animation.Infinite
            }
        }

        // Fixed horizontal tertiary hand pointing right, positioned inside clockCircle
        Rectangle {
            id: clockHand
            width: parent.width * 0.183
            height: 4
            color: Appearance.colors.colTertiary
            radius: 2
            z: 10 // Force rendering on top of the ticks canvas

            // Positioned relative to clockCircle center using simple local coordinates:
            // Proportional and extends slightly outside the circle
            x: parent.width - width + (parent.width * 0.06)
            y: parent.height / 2 - height / 2
        }
    }

    // Right-side time & date information
    ColumnLayout {
        anchors {
            right: parent.right
            rightMargin: 24
            left: parent.left
            leftMargin: clockCircle.width + clockCircle.anchors.leftMargin + 34 // Ensure layout doesn't collide with the clock face dynamically
            verticalCenter: parent.verticalCenter
        }
        spacing: -20

        // Time row separating digits from AM/PM suffix
        RowLayout {
            Layout.alignment: Qt.AlignHCenter
            spacing: 4

            // Time digits (HH:MM) - Custom Maximum Bold Weight (1000 wght axis)
            StyledText {
                text: {
                    const timeStr = DateTime.time;
                    const match = timeStr.match(/^(\d{1,2}:\d{2})(?:\s*(AM|PM|am|pm))?$/);
                    return match ? match[1] : timeStr;
                }
                font.pixelSize: Math.min(72, root.width * 0.17)
                font.family: Appearance.font.family.title
                font.variableAxes: ({
                        "wght": 800
                    }) // Maximum bold weight for variable font
                color: Appearance.colors.colOnPrimaryContainer
            }

            // AM/PM suffix - Smaller & Thin (200 wght axis)
            StyledText {
                text: {
                    const timeStr = DateTime.time;
                    const match = timeStr.match(/^(\d{1,2}:\d{2})(?:\s*(AM|PM|am|pm))?$/);
                    return (match && match[2]) ? match[2] : "";
                }
                visible: text !== ""
                font.pixelSize: Math.min(20, root.width * 0.048) // Smaller size
                font.family: Appearance.font.family.title
                font.variableAxes: ({
                        "wght": 400
                    }) // Thin weight for variable font
                color: Appearance.colors.colOnPrimaryContainer
                Layout.alignment: Qt.AlignBottom
                Layout.bottomMargin: Math.min(14, root.width * 0.033) // Align baseline to bottom of time digits
            }
        }

        // Date row centered underneath
        RowLayout {
            Layout.alignment: Qt.AlignHCenter
            spacing: 6

            StyledText {
                text: Qt.locale().toString(DateTime.clock.date, "dddd")
                font.pixelSize: Math.min(20, root.width * 0.048)
                font.family: Appearance.font.family.title
                font.weight: Font.Normal
                color: Appearance.colors.colOnPrimaryContainer
            }

            StyledText {
                text: Qt.locale().toString(DateTime.clock.date, "dd MMMM")
                font.pixelSize: Math.min(20, root.width * 0.048)
                font.family: Appearance.font.family.title
                font.weight: Font.Normal
                color: Appearance.colors.colOnPrimaryContainer
            }
        }
    }
}
