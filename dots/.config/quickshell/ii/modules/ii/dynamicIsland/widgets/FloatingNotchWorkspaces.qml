import QtQuick
import QtQuick.Layouts
import qs
import qs.modules.common
import qs.modules.common.widgets
import qs.services

Item {
    id: root
    anchors.fill: parent
    property bool isExpanded: false

    readonly property string workspaceStyle: Config.options.bar.styles.workspaces ?? "default"

    Loader {
        id: loader
        anchors.centerIn: parent
        scale: root.isExpanded ? 1.15 : 1.0
        
        Behavior on scale {
            NumberAnimation {
                duration: 250
                easing.type: Easing.OutCubic
            }
        }

        source: {
            if (root.workspaceStyle === "minimal") return "../../bar/widgets/workspaces/MinimalWorkspaces.qml";
            if (root.workspaceStyle === "expressive") return "../../bar/widgets/workspaces/ExpressiveWorkspaces.qml";
            return "../../bar/widgets/workspaces/Workspaces.qml";
        }
        onLoaded: {
            if (item) {
                if (item.hasOwnProperty("vertical")) {
                    item.vertical = false;
                }
            }
        }
    }

    implicitWidth: loader.item ? (loader.item.implicitWidth * (root.isExpanded ? 1.15 : 1.0)) : 150

    Component.onCompleted: {
        // Expose root to DynamicIslandPanel
        var p = root.parent;
        while (p && !p.hasOwnProperty("workspaceWidgetRef")) {
            p = p.parent;
        }
        if (p) {
            p.workspaceWidgetRef = root;
        }
    }
}
