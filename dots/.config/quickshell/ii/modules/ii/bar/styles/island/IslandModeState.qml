import QtQuick
import qs.modules.common

QtObject {
    id: root

    required property string mode
    required property bool hoverActive

    property string _displayMode: mode
    property bool _modeStable: true

    readonly property bool notchModeEnabled: Config.ready && Config.options.bar.dynamicIsland.notchMode.enable
    readonly property bool expandOnHoverEnabled: Config.ready && Config.options.bar.dynamicIsland.notchMode.expandOnHover

    property bool _hoverExpanded: false

    onHoverActiveChanged: {
        if (!expandOnHoverEnabled) return;
        
        if (hoverActive) {
            hoverCollapseTimer.stop();
            _hoverExpanded = true;
        } else {
            hoverCollapseTimer.restart();
        }
    }

    property Timer hoverCollapseTimer: Timer {
        id: hoverCollapseTimer
        interval: 2000 // Keep expanded for 2 seconds
        onTriggered: {
            root._hoverExpanded = false;
        }
    }

    readonly property bool expanded: !notchModeEnabled || (expandOnHoverEnabled && _hoverExpanded)

    onModeChanged: {
        _modeStable = false;
        swapTimer.restart();
    }

    property Timer swapTimer: Timer {
        id: swapTimer
        interval: 280 // swap duration
        onTriggered: {
            root._displayMode = root.mode;
            root._modeStable = true;
        }
    }
}
