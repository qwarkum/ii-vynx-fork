import QtQuick
import Quickshell
PanelWindow {
    id: win
    function hide() { print("hide called"); }
    Item {
        id: item
        Component.onCompleted: {
            let w = item.Window.window;
            w.hide();
            Quickshell.exit(0);
        }
    }
}
