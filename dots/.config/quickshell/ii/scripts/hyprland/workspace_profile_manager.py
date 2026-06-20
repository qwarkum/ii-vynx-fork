#!/usr/bin/env python3
"""
Workspace Profile Manager — backend helper for Quickshell.

Commands:
  list                          → JSON array of profile metadata (one line per entry)
  snapshot <json_str>           → capture current layout, write file, print slug
  restore  <slug>               → dispatch hyprctl commands to restore layout
  delete   <slug>               → delete profile file
  rename   <old_slug> <new_name>→ rename file + update name field, print new slug
"""

import json
import os
import re
import shutil
import subprocess
import sys
import time
from pathlib import Path

PROFILES_DIR = Path.home() / ".config" / "illogical-impulse" / "workspace_profiles"


# ─── helpers ──────────────────────────────────────────────────────────────────

def workspace_sort_key(ws_val):
    if isinstance(ws_val, int):
        return (0, ws_val)
    elif isinstance(ws_val, str):
        if ws_val.isdigit():
            return (0, int(ws_val))
        return (1, ws_val)
    return (2, str(ws_val))


def is_special_workspace(ws) -> bool:
    if isinstance(ws, str):
        return ws.startswith("special")
    if isinstance(ws, int):
        return ws < 0
    return False


def get_dispatcher_workspace(ws_val, clients_list) -> str:
    if isinstance(ws_val, int):
        if ws_val < 0:
            for c in clients_list:
                ws = c.get("workspace", {})
                if ws.get("id") == ws_val and ws.get("name"):
                    return f'"{ws["name"]}"'
            return '"special:special"'
        return str(ws_val)
    elif isinstance(ws_val, str):
        return f'"{ws_val}"'
    return str(ws_val)


def slugify(name: str) -> str:
    slug = name.lower().strip()
    slug = re.sub(r"[^\w\s-]", "", slug)
    slug = re.sub(r"[\s_-]+", "_", slug)
    slug = slug.strip("_")
    return slug or "profile"


def unique_slug(name: str, exclude: str = None) -> str:
    """Return a filename slug that does not collide with existing files."""
    base = slugify(name)
    slug = base
    i = 1
    while (PROFILES_DIR / f"{slug}.json").exists() and slug != exclude:
        slug = f"{base}_{i}"
        i += 1
    return slug


def load_profile(slug: str) -> dict:
    path = PROFILES_DIR / f"{slug}.json"
    with open(path) as f:
        return json.load(f)


def write_profile(profile: dict, slug: str) -> None:
    PROFILES_DIR.mkdir(parents=True, exist_ok=True)
    path = PROFILES_DIR / f"{slug}.json"
    with open(path, "w") as f:
        json.dump(profile, f, indent=2, ensure_ascii=False)


def hyprctl(*args) -> tuple[int, str, str]:
    result = subprocess.run(
        ["hyprctl"] + list(args),
        capture_output=True, text=True
    )
    return result.returncode, result.stdout, result.stderr


def live_clients() -> list[dict]:
    rc, stdout, _ = hyprctl("clients", "-j")
    if rc != 0:
        print("[error] hyprctl clients -j failed", file=sys.stderr)
        sys.exit(1)
    return json.loads(stdout)


# ─── commands ─────────────────────────────────────────────────────────────────

def cmd_list() -> None:
    PROFILES_DIR.mkdir(parents=True, exist_ok=True)
    results = []
    for path in sorted(PROFILES_DIR.glob("*.json")):
        try:
            with open(path) as f:
                data = json.load(f)
            windows = data.get("windows", [])
            workspace_ids = sorted(set(w["workspaceId"] for w in windows), key=workspace_sort_key)
            results.append({
                "slug":        path.stem,
                "id":          data.get("id", path.stem),
                "name":        data.get("name", path.stem),
                "emoji":       data.get("emoji", "🗂️"),
                "description": data.get("description", ""),
                "createdAt":   data.get("createdAt", 0),
                "closeOthers": data.get("closeOthers", False),
                "windowCount": len(windows),
                "workspaceIdsJson": json.dumps(workspace_ids),
                "windowsJson": json.dumps(windows),
                "hasDuplicateClasses": _has_duplicate_classes(windows),
            })
        except Exception as e:
            print(f"[warn] could not load {path}: {e}", file=sys.stderr)
    print(json.dumps(results))


def _has_duplicate_classes(windows: list) -> bool:
    seen = set()
    for w in windows:
        cls = w.get("class", "")
        if cls in seen:
            return True
        seen.add(cls)
    return False


def cmd_snapshot(meta_json: str) -> None:
    meta = json.loads(meta_json)
    clients = live_clients()

    # Per-class override data (autolaunch, launchCmd) keyed by class name
    overrides: dict = meta.get("windowOverrides", {})

    windows = []
    for w in clients:
        ws = w.get("workspace", {})
        ws_id = ws.get("id", 0)
        ws_name = ws.get("name", "")
        if ws_id == 0:          # skip invalid/empty workspaces
            continue
        
        # Save negative IDs or special names as string "special:special"
        if ws_name.startswith("special:") or ws_id < 0:
            target_ws = ws_name if ws_name else "special:special"
        else:
            target_ws = ws_id
        cls = w.get("class", "")
        ov = overrides.get(cls, {})
        launch_cmd = ov.get("launchCmd", "")
        if not launch_cmd:
            pid = w.get("pid")
            if pid:
                try:
                    with open(f"/proc/{pid}/cmdline", "rb") as f:
                        cmdline_parts = f.read().split(b'\0')
                        if cmdline_parts and cmdline_parts[0]:
                            detected_cmd = cmdline_parts[0].decode("utf-8")
                            if not detected_cmd.startswith("/tmp/"):
                                launch_cmd = detected_cmd
                except Exception:
                    pass

        if not launch_cmd:
            raw_cmd = w.get("initialClass") or w.get("class") or ""
            cls_lower = raw_cmd.lower()
            guesses = [
                raw_cmd,
                cls_lower.replace(' ', '-'),
                cls_lower.replace(' ', ''),
                cls_lower.split()[0] if cls_lower else ""
            ]
            for guess in guesses:
                if guess and shutil.which(guess):
                    launch_cmd = guess
                    break

        windows.append({
            "class":        cls,
            "initialClass": w.get("initialClass", cls),
            "workspaceId":  ws_id,
            "x":            w["at"][0],
            "y":            w["at"][1],
            "width":        w["size"][0],
            "height":       w["size"][1],
            "floating":     w.get("floating", False),
            "autolaunch":   ov.get("autolaunch", True),
            "launchCmd":    launch_cmd,
        })

    profile = {
        "name":        meta["name"],
        "emoji":       meta.get("emoji", "🗂️"),
        "description": meta.get("description", ""),
        "createdAt":   int(time.time()),
        "closeOthers": meta.get("closeOthers", False),
        "windows":     windows,
    }

    slug = unique_slug(meta["name"])
    profile["id"] = f"{slug}_{hex(int(time.time()))[2:]}"
    write_profile(profile, slug)
    print(slug)


def cmd_restore(slug: str) -> None:
    profile = load_profile(slug)
    saved_windows: list[dict] = profile.get("windows", [])

    if not saved_windows:
        print("ok")
        return

    # ── Step 1: gather live clients with their addresses ──────────────────────
    clients = live_clients()

    # Group live windows by class → list of {address, workspace_id}
    live_by_class: dict[str, list[dict]] = {}
    for c in clients:
        cls = c.get("class", "")
        live_by_class.setdefault(cls, []).append({
            "address":      c["address"],
            "workspace_id": c.get("workspace", {}).get("id", 0),
            "workspace_name": c.get("workspace", {}).get("name", ""),
            "width":        c["size"][0],
            "height":       c["size"][1],
        })

    # ── Step 2: group saved entries by class ──────────────────────────────────
    saved_by_class: dict[str, list[dict]] = {}
    for sw in saved_windows:
        saved_by_class.setdefault(sw["class"], []).append(sw)

    # ── Step 3a: identify missing windows & launch them simultaneously ────────
    missing_to_launch = []
    for cls, saved_list in saved_by_class.items():
        # How many windows of this class are currently running?
        available_count = len(live_by_class.get(cls, []))
        needed_count = len(saved_list)
        missing_count = max(0, needed_count - available_count)

        if missing_count > 0:
            # Find the launch commands for the missing windows
            for sw in saved_list:
                if sw.get("autolaunch") and missing_count > 0:
                    launch_cmd = sw.get("launchCmd")
                    if not launch_cmd:
                        raw_cmd = sw.get("initialClass") or sw.get("class") or ""
                        class_mappings = {
                            "brave-browser": "brave",
                            "Brave-browser": "brave",
                            "Navigator": "firefox",
                            "firefox-esr": "firefox",
                            "google-chrome": "google-chrome-stable",
                            "chrome": "google-chrome-stable",
                            "dev.zed.Zed": "zeditor",
                        }
                        launch_cmd = class_mappings.get(raw_cmd)
                        
                        if not launch_cmd:
                            cls_lower = raw_cmd.lower()
                            guesses = [
                                raw_cmd,
                                cls_lower.replace(' ', '-'),
                                cls_lower.replace(' ', ''),
                                cls_lower.split()[0] if cls_lower else ""
                            ]
                            for guess in guesses:
                                if guess and shutil.which(guess):
                                    launch_cmd = guess
                                    break
                                    
                        if not launch_cmd:
                            launch_cmd = raw_cmd
                    
                    if launch_cmd:
                        missing_to_launch.append(launch_cmd)
                        missing_count -= 1

    # Launch all missing windows in parallel
    for launch_cmd in missing_to_launch:
        subprocess.Popen(
            launch_cmd,
            shell=True,
            stdout=subprocess.DEVNULL,
            stderr=subprocess.DEVNULL,
            stdin=subprocess.DEVNULL,
            start_new_session=True
        )

    # Poll once for all launched windows (up to 3.0 seconds)
    if missing_to_launch:
        for _ in range(15):
            time.sleep(0.2)
            fresh = live_clients()
            
            # Rebuild live_by_class
            live_by_class.clear()
            for c in fresh:
                c_cls = c.get("class", "")
                live_by_class.setdefault(c_cls, []).append({
                    "address":      c["address"],
                    "workspace_id": c.get("workspace", {}).get("id", 0),
                    "workspace_name": c.get("workspace", {}).get("name", ""),
                    "width":        c["size"][0],
                    "height":       c["size"][1],
                })
            
            # Check if we have enough windows now
            all_found = True
            for cls, saved_list in saved_by_class.items():
                if len(live_by_class.get(cls, [])) < len(saved_list):
                    all_found = False
                    break
            
            if all_found:
                break

    # ── Step 3b: pair saved → live (address used only during this session) ────
    assigned: set[str] = set()
    pairs: list[tuple[dict, str]] = []   # (saved_window, live_address)

    for cls, saved_list in saved_by_class.items():
        available = [lw for lw in live_by_class.get(cls, [])
                     if lw["address"] not in assigned]

        for sw in saved_list:
            if not available:
                print(f"[warn] no live window for class '{cls}', skipping",
                      file=sys.stderr)
                continue

            target_ws = sw["workspaceId"]
            saved_area = sw["width"] * sw["height"]

            def score(lw):
                lw_special = lw["workspace_id"] < 0
                target_special = is_special_workspace(target_ws)
                
                if lw_special != target_special:
                    ws_dist = 100
                else:
                    if target_special:
                        if isinstance(target_ws, str):
                            ws_dist = 0 if lw["workspace_name"] == target_ws else 10
                        else:
                            ws_dist = abs(lw["workspace_id"] - target_ws)
                    else:
                        ws_dist = abs(lw["workspace_id"] - target_ws)
                area_diff = abs(lw["width"] * lw["height"] - saved_area)
                return (ws_dist, area_diff)

            best = min(available, key=score)
            assigned.add(best["address"])
            available.remove(best)
            pairs.append((sw, best["address"]))

    # ── Step 4: dispatch using ephemeral addresses ────────────────────────────
    errors = 0
    for sw, addr in pairs:
        target_ws = sw["workspaceId"]
        addr_clean = addr if addr.startswith("0x") else f"0x{addr}"
        addr_sel = f"address:{addr_clean}"

        ws_param = get_dispatcher_workspace(target_ws, clients)

        # 1. Move to workspace (silent = don't focus that workspace)
        rc, _, err = hyprctl("dispatch", f'hl.dsp.window.move({{ workspace = {ws_param}, window = "{addr_sel}", follow = false }})')
        if rc != 0:
            print(f"[warn] hl.dsp.window.move failed for {addr_sel}: {err.strip()}",
                  file=sys.stderr)
            errors += 1
            continue

        time.sleep(0.04)

        # 2. Float status enforcement
        float_action = "set" if sw.get("floating") else "disable"
        rc, _, err = hyprctl("dispatch", f'hl.dsp.window.float({{ action = "{float_action}", window = "{addr_sel}" }})')
        if rc != 0:
            print(f"[warn] hl.dsp.window.float ({float_action}) failed for {addr_sel}: {err.strip()}",
                  file=sys.stderr)
            errors += 1
            continue

        time.sleep(0.04)

        # 3. Resize window
        rc, _, err = hyprctl("dispatch", f'hl.dsp.window.resize({{ x = {sw["width"]}, y = {sw["height"]}, relative = false, window = "{addr_sel}" }})')
        if rc != 0:
            print(f"[warn] hl.dsp.window.resize failed for {addr_sel}: {err.strip()}",
                  file=sys.stderr)
            errors += 1
            continue

        time.sleep(0.04)

        # 4. Reposition floating windows
        if sw.get("floating"):
            rc, _, err = hyprctl("dispatch", f'hl.dsp.window.move({{ x = {sw["x"]}, y = {sw["y"]}, relative = false, window = "{addr_sel}" }})')
            if rc != 0:
                print(f"[warn] hl.dsp.window.move coordinates failed for {addr_sel}: {err.strip()}",
                      file=sys.stderr)
                errors += 1
                continue

    # ── Step 5: optionally close all other windows ────────────────────────────
    if profile.get("closeOthers", False):
        final_clients = live_clients()
        assigned_clean = {a if a.startswith("0x") else f"0x{a}" for a in assigned}
        for c in final_clients:
            addr = c["address"]
            addr_clean = addr if addr.startswith("0x") else f"0x{addr}"
            if addr_clean not in assigned_clean:
                ws_id = c.get("workspace", {}).get("id", 0)
                if ws_id >= 1:
                    addr_sel = f"address:{addr_clean}"
                    hyprctl("dispatch", f'hl.dsp.window.close({{ window = "{addr_sel}" }})')
                    time.sleep(0.02)

    if errors == 0:
        print("ok")
    else:
        print(f"partial:{errors}")


def cmd_delete(slug: str) -> None:
    path = PROFILES_DIR / f"{slug}.json"
    path.unlink(missing_ok=True)


def cmd_update_window(slug: str, idx_str: str, autolaunch_str: str, launch_cmd: str) -> None:
    profile = load_profile(slug)
    windows = profile.get("windows", [])
    try:
        idx = int(idx_str)
    except ValueError:
        print("[error] invalid window index", file=sys.stderr)
        sys.exit(1)

    if idx < 0 or idx >= len(windows):
        print("[error] window index out of range", file=sys.stderr)
        sys.exit(1)

    autolaunch = autolaunch_str.lower() in ("true", "1", "yes")
    windows[idx]["autolaunch"] = autolaunch
    windows[idx]["launchCmd"] = launch_cmd.strip()

    write_profile(profile, slug)
    print("ok")


def cmd_update_profile(slug: str, close_others_str: str) -> None:
    profile = load_profile(slug)
    close_others = close_others_str.lower() in ("true", "1", "yes")
    profile["closeOthers"] = close_others
    write_profile(profile, slug)
    print("ok")


def cmd_add_window(slug: str, class_name: str, workspace_str: str, autolaunch_str: str, launch_cmd: str) -> None:
    profile = load_profile(slug)
    windows = profile.get("windows", [])
    try:
        ws = int(workspace_str)
    except ValueError:
        ws = workspace_str.strip()
    autolaunch = autolaunch_str.lower() in ("true", "1", "yes")
    windows.append({
        "class": class_name.strip(),
        "initialClass": class_name.strip(),
        "workspaceId": ws,
        "x": 100,
        "y": 100,
        "width": 1200,
        "height": 800,
        "floating": False,
        "autolaunch": autolaunch,
        "launchCmd": launch_cmd.strip()
    })
    write_profile(profile, slug)
    print("ok")


def cmd_delete_window(slug: str, idx_str: str) -> None:
    profile = load_profile(slug)
    windows = profile.get("windows", [])
    try:
        idx = int(idx_str)
    except ValueError:
        print("[error] invalid window index", file=sys.stderr)
        sys.exit(1)
    if idx < 0 or idx >= len(windows):
        print("[error] window index out of range", file=sys.stderr)
        sys.exit(1)
    windows.pop(idx)
    write_profile(profile, slug)
    print("ok")


def cmd_update_window_workspace(slug: str, idx_str: str, workspace_str: str) -> None:
    profile = load_profile(slug)
    windows = profile.get("windows", [])
    try:
        idx = int(idx_str)
    except ValueError:
        print("[error] invalid index", file=sys.stderr)
        sys.exit(1)
    if idx < 0 or idx >= len(windows):
        print("[error] window index out of range", file=sys.stderr)
        sys.exit(1)
    
    try:
        ws = int(workspace_str)
    except ValueError:
        ws = workspace_str.strip()
        
    windows[idx]["workspaceId"] = ws
    write_profile(profile, slug)
    print("ok")


def cmd_rename(old_slug: str, new_name: str) -> None:
    profile = load_profile(old_slug)
    profile["name"] = new_name
    new_slug = unique_slug(new_name, exclude=old_slug)
    # Remove old file first so unique_slug can reuse the old slug if the name
    # didn't actually change (e.g. only capitalisation changed).
    old_path = PROFILES_DIR / f"{old_slug}.json"
    old_path.unlink(missing_ok=True)
    write_profile(profile, new_slug)
    print(new_slug)


# ─── entry point ──────────────────────────────────────────────────────────────

def main() -> None:
    if len(sys.argv) < 2:
        print(__doc__, file=sys.stderr)
        sys.exit(1)

    cmd = sys.argv[1]

    if cmd == "list":
        cmd_list()

    elif cmd == "snapshot" and len(sys.argv) >= 3:
        cmd_snapshot(sys.argv[2])

    elif cmd == "restore" and len(sys.argv) >= 3:
        cmd_restore(sys.argv[2])

    elif cmd == "delete" and len(sys.argv) >= 3:
        cmd_delete(sys.argv[2])

    elif cmd == "rename" and len(sys.argv) >= 4:
        cmd_rename(sys.argv[2], sys.argv[3])

    elif cmd == "update_window" and len(sys.argv) >= 6:
        cmd_update_window(sys.argv[2], sys.argv[3], sys.argv[4], sys.argv[5])

    elif cmd == "update_profile" and len(sys.argv) >= 4:
        cmd_update_profile(sys.argv[2], sys.argv[3])

    elif cmd == "add_window" and len(sys.argv) >= 7:
        cmd_add_window(sys.argv[2], sys.argv[3], sys.argv[4], sys.argv[5], sys.argv[6])

    elif cmd == "delete_window" and len(sys.argv) >= 4:
        cmd_delete_window(sys.argv[2], sys.argv[3])

    elif cmd == "update_window_workspace" and len(sys.argv) >= 5:
        cmd_update_window_workspace(sys.argv[2], sys.argv[3], sys.argv[4])

    else:
        print(f"[error] unknown command or missing args: {sys.argv[1:]}",
              file=sys.stderr)
        sys.exit(1)


if __name__ == "__main__":
    main()
