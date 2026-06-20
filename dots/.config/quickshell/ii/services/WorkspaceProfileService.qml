pragma Singleton
pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Io
import qs.modules.common

/**
 * WorkspaceProfileService
 *
 * Manages per-file workspace profiles stored in
 * ~/.config/illogical-impulse/workspace_profiles/<slug>.json
 *
 * Each public function delegates to workspace_profile_manager.py.
 */
Singleton {
    id: root

    // ── public state ────────────────────────────────────────────────────────
    property ListModel profilesModel: ListModel {}
    property bool loading:  false
    property bool restoring: false
    property string restoringSlug: ""

    // ── signals ─────────────────────────────────────────────────────────────
    signal snapshotFinished(bool success, string slug)
    signal restoreStarted(string profileName)
    signal restoreFinished(bool success, int errors)
    signal renameFinished(bool success, string newSlug)
    signal deleteFinished(bool success)

    // ── paths ────────────────────────────────────────────────────────────────
    readonly property string scriptPath: `${Directories.scriptPath}/hyprland/workspace_profile_manager.py`

    // ── public API ───────────────────────────────────────────────────────────

    function refresh() {
        listProc.command = ["python3", root.scriptPath, "list"];
        listProc.running = true;
    }

    function snapshot(name, emoji, description, windowOverrides) {
        const meta = JSON.stringify({
            name,
            emoji:          emoji       || "🗂️",
            description:    description || "",
            windowOverrides: windowOverrides || {}
        });
        snapshotProc.command = ["python3", root.scriptPath, "snapshot", meta];
        snapshotProc.running = true;
    }

    function restoreProfile(slug) {
        if (root.restoring) return;
        
        // Find the name for the signal
        for (let i = 0; i < root.profilesModel.count; i++) {
            if (root.profilesModel.get(i).slug === slug) {
                root.restoreStarted(root.profilesModel.get(i).name);
                break;
            }
        }
        root.restoringSlug = slug;
        root.restoring = true;
        restoreProc.command = ["python3", root.scriptPath, "restore", slug];
        restoreProc.running = true;
    }

    function deleteProfile(slug) {
        deleteProc.command = ["python3", root.scriptPath, "delete", slug];
        deleteProc.running = true;
    }

    function renameProfile(oldSlug, newName) {
        renameProc.command = ["python3", root.scriptPath, "rename", oldSlug, newName];
        renameProc.running = true;
    }

    function updateWindowOptions(slug, index, autolaunch, launchCmd) {
        updateWindowProc.command = [
            "python3", root.scriptPath, "update_window",
            slug, index.toString(), autolaunch ? "true" : "false", launchCmd || ""
        ];
        updateWindowProc.running = true;
    }

    function updateProfileOptions(slug, closeOthers) {
        updateProfileProc.command = [
            "python3", root.scriptPath, "update_profile",
            slug, closeOthers ? "true" : "false"
        ];
        updateProfileProc.running = true;
    }

    function addWindow(slug, className, workspace, autolaunch, launchCmd) {
        addWindowProc.command = [
            "python3", root.scriptPath, "add_window",
            slug, className, workspace.toString(), autolaunch ? "true" : "false", launchCmd || ""
        ];
        addWindowProc.running = true;
    }

    function deleteWindow(slug, index) {
        deleteWindowProc.command = [
            "python3", root.scriptPath, "delete_window",
            slug, index.toString()
        ];
        deleteWindowProc.running = true;
    }

    function updateWindowWorkspace(slug, index, workspace) {
        updateWindowWorkspaceProc.command = [
            "python3", root.scriptPath, "update_window_workspace",
            slug, index.toString(), workspace.toString()
        ];
        updateWindowWorkspaceProc.running = true;
    }

    // ── internal processes ───────────────────────────────────────────────────

    // list
    Process {
        id: listProc
        onRunningChanged: if (running) root.loading = true
        stdout: StdioCollector {
            id: listCollector
            onStreamFinished: {
                root.loading = false;
                try {
                    const arr = JSON.parse(listCollector.text);
                    root.profilesModel.clear();
                    for (const p of arr) {
                        root.profilesModel.append(p);
                    }
                } catch (e) {
                    console.warn("[WorkspaceProfileService] list parse error:", e,
                                 listCollector.text.substring(0, 200));
                }
            }
        }
    }

    // snapshot
    Process {
        id: snapshotProc
        stdout: StdioCollector {
            id: snapshotCollector
            onStreamFinished: {
                const slug = snapshotCollector.text.trim();
                if (slug && !slug.startsWith("[error]")) {
                    root.snapshotFinished(true, slug);
                    root.refresh();
                } else {
                    root.snapshotFinished(false, "");
                }
            }
        }
    }

    // restore
    Process {
        id: restoreProc
        stdout: StdioCollector {
            id: restoreCollector
            onStreamFinished: {
                root.restoringSlug = "";
                root.restoring = false;
                const out = restoreCollector.text.trim();
                if (out === "ok") {
                    root.restoreFinished(true, 0);
                } else if (out.startsWith("partial:")) {
                    root.restoreFinished(false, parseInt(out.split(":")[1]) || 1);
                } else {
                    root.restoreFinished(false, -1);
                }
            }
        }
    }

    // delete — always treat completion as success (script uses missing_ok=True)
    Process {
        id: deleteProc
        onRunningChanged: {
            if (!running) {
                root.deleteFinished(true);
                root.refresh();
            }
        }
    }

    // rename
    Process {
        id: renameProc
        stdout: StdioCollector {
            id: renameCollector
            onStreamFinished: {
                const newSlug = renameCollector.text.trim();
                const ok = newSlug.length > 0 && !newSlug.startsWith("[error]");
                root.renameFinished(ok, ok ? newSlug : "");
                if (ok) root.refresh();
            }
        }
    }

    Process {
        id: updateWindowProc
        stdout: StdioCollector {
            id: updateWindowCollector
            onStreamFinished: {
                const out = updateWindowCollector.text.trim();
                if (out === "ok") {
                    root.refresh();
                }
            }
        }
    }

    Process {
        id: updateProfileProc
        stdout: StdioCollector {
            id: updateProfileCollector
            onStreamFinished: {
                const out = updateProfileCollector.text.trim();
                if (out === "ok") {
                    root.refresh();
                }
            }
        }
    }

    Process {
        id: addWindowProc
        stdout: StdioCollector {
            id: addWindowCollector
            onStreamFinished: {
                const out = addWindowCollector.text.trim();
                if (out === "ok") {
                    root.refresh();
                }
            }
        }
    }

    Process {
        id: deleteWindowProc
        stdout: StdioCollector {
            id: deleteWindowCollector
            onStreamFinished: {
                const out = deleteWindowCollector.text.trim();
                if (out === "ok") {
                    root.refresh();
                }
            }
        }
    }

    Process {
        id: updateWindowWorkspaceProc
        stdout: StdioCollector {
            id: updateWindowWorkspaceCollector
            onStreamFinished: {
                const out = updateWindowWorkspaceCollector.text.trim();
                if (out === "ok") {
                    root.refresh();
                }
            }
        }
    }

    // ── init ─────────────────────────────────────────────────────────────────
    Component.onCompleted: {
        // Ensure profiles directory exists
        Quickshell.execDetached(["mkdir", "-p",
            `${Directories.home}/.config/illogical-impulse/workspace_profiles`]);
        Qt.callLater(root.refresh);
    }
}
