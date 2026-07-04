import QtQuick
import Quickshell
import Quickshell.Hyprland
import qs.services
import qs.modules.common
import qs

QtObject {
    id: root

    required property var screen
    property bool workspaceTriggerActive: false

    // Monitor active workspace of the current screen
    readonly property var hMonitor: Hyprland.monitorFor(root.screen)
    readonly property int activeWorkspaceId: hMonitor?.activeWorkspace?.id ?? -1

    property bool _initialized: false

    onActiveWorkspaceIdChanged: {
        if (!_initialized) {
            _initialized = true;
            return;
        }
        if (!Config.ready || !Config.options.bar.dynamicIsland.notchMode.enable) return;
        root.workspaceTriggerActive = true;
        workspaceTriggerTimer.restart();
    }

    property Timer workspaceTriggerTimer: Timer {
        id: workspaceTriggerTimer
        interval: (Config.ready && Config.options.bar.dynamicIsland.notchMode.workspaceSwitchDuration) || 2000
        onTriggered: root.workspaceTriggerActive = false
    }

    function isWidgetActive(widgetId) {
        if (widgetId === "music_player") {
            return MprisController.isPlaying;
        }
        if (widgetId === "workspaces") {
            return root.workspaceTriggerActive;
        }
        if (widgetId === "clock") {
            return true;
        }
        return false;
    }

    function isWidgetInLayout(widgetId) {
        if (!Config.ready) return false;
        const center = Config.options.bar.layouts.center;
        if (!center) return false;
        for (let i = 0; i < center.length; i++) {
            if (center[i].id === widgetId) return true;
        }
        return false;
    }

    readonly property bool isOsdOpenHere: {
        if (!GlobalStates.osdVolumeOpen) return false;
        const focusedScreenName = (Quickshell.screens.find(s => s.name === Hyprland.focusedMonitor?.name) ?? Quickshell.screens[0])?.name;
        return root.screen && root.screen.name === focusedScreenName;
    }

    readonly property bool isNotificationActiveHere: {
        if (Notifications.popupList.length === 0) return false;
        const targetScreen = Quickshell.screens.find(s => Config.options.notifications.monitor.enable ? s.name === Config.options.notifications.monitor.name : s.name === Hyprland.focusedMonitor?.name) ?? null;
        return root.screen && targetScreen && root.screen.name === targetScreen.name;
    }

    readonly property string _calculatedMode: {
        if (!Config.ready) return "clock";
        
        // 1. OSD is always highest priority
        if (isOsdOpenHere) return "osd";

        // 2. Notifications (if any active popup on this screen)
        if (isNotificationActiveHere) return "notification";

        // 3. Workspaces trigger (transient workspace change)
        if (root.workspaceTriggerActive) return "workspaces";

        const list = Config.options.bar.dynamicIsland.notchMode.priorityList;
        if (!list) return "clock";

        for (let i = 0; i < list.length; i++) {
            const modeId = list[i];
            // Skip workspaces here since we handled it above with higher priority
            if (modeId === "workspaces") continue;

            if (isWidgetActive(modeId) && isWidgetInLayout(modeId)) {
                return modeId;
            }
        }
        // Fallback: clock only if it's in the layout
        if (isWidgetInLayout("clock")) return "clock";
        return "";
    }

    readonly property string resolvedMode: _calculatedMode
}
