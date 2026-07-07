import qs.modules.common
import qs.modules.common.widgets
import qs.modules.common.utils
import qs.services
import qs
import qs.modules.common.functions
import QtQuick
import QtQuick.Layouts
import Qt5Compat.GraphicalEffects
import Quickshell.Services.Mpris
import Quickshell
import Quickshell.Io

MouseArea {
    id: root

    readonly property int artSize: Appearance.sizes.verticalBarWidth - Appearance.rounding.small * 2
    readonly property int barWidth: Math.max(4, Math.min(8, artSize / 5))
    readonly property int visualizerWidth: 4 * barWidth + 3 * 1
    readonly property int spacing: Appearance.rounding.small

    readonly property MprisPlayer activePlayer: MprisController.activePlayer
    readonly property bool hasTrack: (activePlayer?.trackTitle ?? "").length > 0
    readonly property bool playing: activePlayer ? activePlayer.playbackState === MprisPlaybackState.Playing : false

    readonly property string artUrl: MprisController.artUrl
    readonly property bool isLocalArt: artUrl.startsWith("file://")
    property string artDownloadLocation: Directories.coverArt
    property string artFileName: Qt.md5(artUrl)
    property string artFilePath: `${artDownloadLocation}/${artFileName}`
    property bool artDownloaded: false
    readonly property string artSource: {
        if (!artUrl) return "";
        if (isLocalArt) return artUrl;
        return artDownloaded ? Qt.resolvedUrl(artFilePath) : artUrl;
    }

    Layout.fillHeight: true
    implicitWidth: Appearance.sizes.verticalBarWidth
    implicitHeight: columnLayout.implicitHeight + Appearance.rounding.small * 2
    visible: hasTrack

    cursorShape: Qt.PointingHandCursor
    acceptedButtons: Qt.MiddleButton | Qt.BackButton | Qt.ForwardButton | Qt.RightButton | Qt.LeftButton
    hoverEnabled: !Config.options.bar.tooltips.clickToShow
    onEntered: {
        GlobalStates.setMediaWidgetHovered(true);
        if (hoverEnabled) {
            var globalPos = root.mapToItem(null, 0, 0);
            GlobalStates.mediaPopupRect = Qt.rect(globalPos.x, globalPos.y, root.width, root.height);
            GlobalStates.mediaControlsOpen = true;
        }
    }
    onExited: {
        GlobalStates.setMediaWidgetHovered(false);
    }
    onPressed: event => {
        if (event.button === Qt.MiddleButton) {
            activePlayer.togglePlaying();
        } else if (event.button === Qt.BackButton) {
            activePlayer.previous();
        } else if (event.button === Qt.ForwardButton || event.button === Qt.RightButton) {
            activePlayer.next();
        } else if (event.button === Qt.LeftButton) {
            if (!hoverEnabled) {
                var globalPos = root.mapToItem(null, 0, 0);
                GlobalStates.mediaPopupRect = Qt.rect(globalPos.x, globalPos.y, root.width, root.height);
                GlobalStates.mediaControlsOpen = !GlobalStates.mediaControlsOpen;
            }
        }
    }

    onArtFilePathChanged: {
        if (!artUrl || artUrl.length === 0) {
            artDownloaded = false;
            return;
        }
        if (isLocalArt) {
            artDownloaded = true;
            return;
        }
        artDownloaded = false;
        artDownloader.command = ["bash", "-c", `[ -f '${artFilePath}' ] || (mkdir -p '${artDownloadLocation}' && curl -4 -sSL '${artUrl}' -o '${artFilePath}.tmp' && mv '${artFilePath}.tmp' '${artFilePath}')`]
        artDownloader.running = true;
    }

    Process {
        id: artDownloader
        running: false
        onExited: {
            artDownloaded = true;
        }
    }

    Timer {
        running: activePlayer?.playbackState == MprisPlaybackState.Playing
        interval: Config.options.resources.updateInterval
        repeat: true
        onTriggered: activePlayer.positionChanged()
    }

    // Real Cava Visualizer integration
    property var visualizerPoints: []

    readonly property real bar0Val: visualizerPoints.length > 5 ? visualizerPoints[3] / 1000.0 : 0
    readonly property real bar1Val: visualizerPoints.length > 11 ? visualizerPoints[9] / 1000.0 : 0
    readonly property real bar2Val: visualizerPoints.length > 18 ? visualizerPoints[16] / 1000.0 : 0
    readonly property real bar3Val: visualizerPoints.length > 28 ? visualizerPoints[25] / 1000.0 : 0

    function getBarHeight(index) {
        let minH = barWidth;
        if (!root.playing)
            return minH; // Reset to perfect circle when paused
        let val = 0;
        if (index === 0)
            val = bar0Val;
        else if (index === 1)
            val = bar1Val;
        else if (index === 2)
            val = bar2Val;
        else if (index === 3)
            val = bar3Val;

        let norm = Math.min(1.0, Math.max(0.0, val));
        let maxH = root.artSize - 10;
        return minH + norm * (maxH - minH);
    }

    Process {
        id: cavaProc
        running: root.playing
        command: ["cava", "-p", `${FileUtils.trimFileProtocol(Directories.scriptPath)}/cava/raw_output_config.txt`]
        stdout: SplitParser {
            onRead: data => {
                let points = data.split(";").map(p => parseFloat(p.trim())).filter(p => !isNaN(p));
                root.visualizerPoints = points;
            }
        }
    }

    ColumnLayout {
        id: columnLayout
        anchors.centerIn: parent
        spacing: root.spacing

        // Album Art in 12-sided shape
        Item {
            id: albumArtVert
            Layout.alignment: Qt.AlignHCenter
            Layout.preferredWidth: root.artSize
            Layout.preferredHeight: root.artSize

            MaterialShape {
                id: compactCookieMask
                anchors.fill: parent
                shapeString: "Cookie12Sided"
                color: Appearance.colors.colPrimaryContainer
                visible: false
            }

            Item {
                anchors.fill: parent
                layer.enabled: true
                layer.effect: OpacityMask {
                    maskSource: compactCookieMask
                }

                Image {
                    anchors.fill: parent
                    source: root.artSource
                    fillMode: Image.PreserveAspectCrop
                    visible: root.artSource !== ""
                    cache: false
                    antialiasing: true
                    sourceSize.width: root.artSize
                    sourceSize.height: root.artSize
                }

                MaterialSymbol {
                    anchors.centerIn: parent
                    text: "music_note"
                    iconSize: Appearance.font.pixelSize.normal
                    color: Appearance.colors.colOnSecondaryContainer
                    visible: root.artSource === ""
                }
            }
        }

        // Cava Visualizer
        Item {
            id: audioVisualizerVert
            Layout.alignment: Qt.AlignHCenter
            Layout.preferredWidth: root.visualizerWidth
            Layout.preferredHeight: root.artSize

            Row {
                id: compactVisualizerRow
                anchors.centerIn: parent
                height: parent.height
                spacing: 1

                Repeater {
                    model: 4
                    Rectangle {
                        required property int index
                        anchors.verticalCenter: parent.verticalCenter
                        width: root.barWidth
                        height: root.getBarHeight(index)
                        radius: root.barWidth / 2
                        color: Appearance.colors.colPrimary

                        Behavior on height {
                            NumberAnimation {
                                duration: 85
                                easing.type: Easing.OutCubic
                            }
                        }
                    }
                }
            }
        }
    }
}
