pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Bluetooth
import qs.modules.common
import qs.services

Singleton {
    id: root

    // Dictionary to store active modes by device MAC address
    property var deviceModes: ({})

    // Supported headphone devices list
    readonly property var supportedDevices: [
        {
            name: "Soundcore Life Q30",
            mac: "E8:EE:CC:96:31:3A",
            type: "soundcore"
        },
        {
            name: "Pedro's Buds FE",
            mac: "40:35:E6:31:8B:AC",
            type: "galaxybuds"
        }
    ]

    readonly property var activeDevice: {
        for (let d of BluetoothStatus.connectedDevices) {
            let match = supportedDevices.find(sd => sd.mac === d.address || sd.name === d.name);
            if (match) {
                return match;
            }
        }
        return null;
    }

    property bool isConnected: activeDevice !== null
    property string targetDeviceName: activeDevice ? activeDevice.name : "None"
    property string macAddress: activeDevice ? activeDevice.mac : ""
    property string deviceType: activeDevice ? activeDevice.type : ""

    // Backward compatibility property for unified Quick Toggle bindings
    readonly property string currentMode: {
        let dummy = deviceModes; // Force dependency tracking on the deviceModes object
        return activeDevice ? getModeForMac(activeDevice.mac) : "Normal";
    }

    readonly property string soundcoreScriptPath: Quickshell.shellPath("scripts/soundcore/soundcore_anc.sh")
    readonly property string budsScriptPath: Quickshell.shellPath("scripts/buds/core.js")

    function getModeForMac(mac) {
        return deviceModes[mac] || "Normal";
    }

    function updateDeviceMode(mac, mode) {
        let copy = Object.assign({}, deviceModes);
        copy[mac] = mode;
        deviceModes = copy; // Trigger QML property updates
    }

    function setMode(mac, mode) {
        // Support single argument calls like setMode(mode) by defaulting to activeDevice.mac
        if (arguments.length === 1 || mode === undefined) {
            mode = mac;
            mac = activeDevice ? activeDevice.mac : "";
        }

        if (!mac)
            return;

        let dev = supportedDevices.find(sd => sd.mac === mac);
        if (!dev)
            return;

        if (dev.type === "soundcore") {
            Quickshell.execDetached([soundcoreScriptPath, "set", mac, mode]);
        } else if (dev.type === "galaxybuds") {
            Quickshell.execDetached(["gjs", "-m", budsScriptPath, "set", mac, mode.toLowerCase()]);
        }

        // Optimistic update for immediate visual feedback
        updateDeviceMode(mac, mode);
    }

    function refreshMode(mac) {
        if (mac === undefined) {
            refreshAllConnected();
            return;
        }

        let dev = supportedDevices.find(sd => sd.mac === mac);
        if (!dev)
            return;

        // Spawn a lightweight, isolated process to poll the specific headset
        processComponent.createObject(root, {
            "mac": mac,
            "deviceType": dev.type
        });
    }

    function refreshAllConnected() {
        for (let d of BluetoothStatus.connectedDevices) {
            let match = supportedDevices.find(sd => sd.mac === d.address || sd.name === d.name);
            if (match) {
                refreshMode(match.mac);
            }
        }
    }

    // Isolated dynamic process component to handle concurrent polling without race conditions
    Component {
        id: processComponent
        Process {
            id: proc
            property string mac: ""
            property string deviceType: ""

            command: deviceType === "soundcore" ? [soundcoreScriptPath, "get", mac] : ["gjs", "-m", budsScriptPath, "get", mac]
            running: true

            stdout: StdioCollector {
                onStreamFinished: {
                    let trimmed = text.trim();
                    if (trimmed.length > 0) {
                        root.updateDeviceMode(proc.mac, trimmed);
                    }
                    proc.destroy(); // Auto-free memory upon completion
                }
            }
        }
    }

    onIsConnectedChanged: {
        if (isConnected) {
            refreshAllConnected();
        }
    }
}
