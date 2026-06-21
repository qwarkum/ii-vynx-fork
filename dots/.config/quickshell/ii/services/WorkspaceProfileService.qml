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
    signal updateDescriptionFinished(bool success)
    signal deleteFinished(bool success)

    // ── paths ────────────────────────────────────────────────────────────────
    readonly property string scriptPath: `${Directories.scriptPath}/hyprland/workspace_profile_manager`

    // ── public API ───────────────────────────────────────────────────────────

    function refresh() {
        listProc.command = [root.scriptPath, "list"];
        listProc.running = true;
    }

    function snapshot(name, emoji, description, windowOverrides) {
        const meta = JSON.stringify({
            name,
            emoji:          emoji       || "🗂️",
            description:    description || "",
            windowOverrides: windowOverrides || {}
        });
        snapshotProc.command = [root.scriptPath, "snapshot", meta];
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
        restoreProc.command = [root.scriptPath, "restore", slug];
        restoreProc.running = true;
    }

    function deleteProfile(slug) {
        deleteProc.command = [root.scriptPath, "delete", slug];
        deleteProc.running = true;
    }

    function renameProfile(oldSlug, newName) {
        renameProc.command = [root.scriptPath, "rename", oldSlug, newName];
        renameProc.running = true;
    }

    function updateEmoji(slug, newEmoji) {
        updateEmojiProc.command = [root.scriptPath, "update_emoji", slug, newEmoji];
        updateEmojiProc.running = true;
    }

    function updateDescription(slug, newDescription) {
        let updateDescProc = Qt.createQmlObject('import Quickshell.Io; Process {}', root, "updateDescProc");
        updateDescProc.command = [scriptPath, "update_description", slug, newDescription];
        let ok = false;
        updateDescProc.stdout = Qt.createQmlObject('import Quickshell.Io; StdioCollector {}', updateDescProc);
        updateDescProc.stdout.onStreamFinished.connect(() => {
            if (updateDescProc.stdout.text.trim() === "ok") {
                ok = true;
                refresh(); // refresh UI
            }
            root.updateDescriptionFinished(ok);
            updateDescProc.destroy();
        });
        updateDescProc.start();
    }

    function updateWindowOptions(slug, index, autolaunch, launchCmd) {
        updateWindowProc.command = [
            root.scriptPath, "update_window",
            slug, index.toString(), autolaunch ? "true" : "false", launchCmd || ""
        ];
        updateWindowProc.running = true;
    }

    function updateProfileOptions(slug, closeOthers, killOthers) {
        updateProfileProc.command = [
            root.scriptPath, "update_profile",
            slug, closeOthers ? "true" : "false", killOthers ? "true" : "false"
        ];
        updateProfileProc.running = true;
    }

    function addWindow(slug, className, workspace, autolaunch, launchCmd) {
        addWindowProc.command = [
            root.scriptPath, "add_window",
            slug, className, workspace.toString(), autolaunch ? "true" : "false", launchCmd || ""
        ];
        addWindowProc.running = true;
    }

    function deleteWindow(slug, index) {
        deleteWindowProc.command = [
            root.scriptPath, "delete_window",
            slug, index.toString()
        ];
        deleteWindowProc.running = true;
    }

    function updateWindowWorkspace(slug, index, workspace) {
        updateWindowWorkspaceProc.command = [
            root.scriptPath, "update_window_workspace",
            slug, index.toString(), workspace.toString()
        ];
        updateWindowWorkspaceProc.running = true;
    }

    function togglePin(slug) {
        togglePinProc.command = [
            root.scriptPath, "toggle_pin",
            slug
        ];
        togglePinProc.running = true;
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
                    let oldSlugs = [];
                    for (let i = 0; i < root.profilesModel.count; i++) {
                        oldSlugs.push(root.profilesModel.get(i).slug);
                    }
                    
                    let identicalSet = false;
                    if (arr.length === oldSlugs.length) {
                        let newSlugsArr = arr.map(p => p.slug);
                        identicalSet = oldSlugs.every(s => newSlugsArr.indexOf(s) !== -1);
                    }
                    
                    if (identicalSet) {
                        let newSlugsArr = arr.map(p => p.slug);
                        for (let i = 0; i < newSlugsArr.length; i++) {
                            let targetSlug = newSlugsArr[i];
                            let currentIndex = -1;
                            for (let j = i; j < root.profilesModel.count; j++) {
                                if (root.profilesModel.get(j).slug === targetSlug) {
                                    currentIndex = j;
                                    break;
                                }
                            }
                            if (currentIndex > i) {
                                root.profilesModel.move(currentIndex, i, 1);
                            }
                            root.profilesModel.set(i, arr[i]);
                        }
                    } else {
                        root.profilesModel.clear();
                        for (const p of arr) {
                            root.profilesModel.append(p);
                        }
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

    // update emoji
    Process {
        id: updateEmojiProc
        stdout: StdioCollector {
            id: updateEmojiCollector
            onStreamFinished: {
                const out = updateEmojiCollector.text.trim();
                if (out === "ok") {
                    root.refresh();
                }
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
    Process {
        id: togglePinProc
        stdout: StdioCollector {
            id: togglePinCollector
            onStreamFinished: {
                const out = togglePinCollector.text.trim();
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
