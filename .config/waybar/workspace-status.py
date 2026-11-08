#!/usr/bin/env python3
"""Publish workspace button styles when Hyprland reports a workspace change."""
import fcntl
import json
import os
from pathlib import Path
import signal
import socket
import subprocess
import sys

STATE = Path(os.environ.get("XDG_STATE_HOME", Path.home() / ".local/state")) / "hypr-panel/workspaces"


def ipc_path(name):
    return Path(os.environ["XDG_RUNTIME_DIR"]) / "hypr" / os.environ["HYPRLAND_INSTANCE_SIGNATURE"] / name


def refresh(notify=True):
    with socket.socket(socket.AF_UNIX, socket.SOCK_STREAM) as connection:
        connection.settimeout(2)
        connection.connect(str(ipc_path(".socket.sock")))
        connection.sendall(b"j/monitors")
        chunks = []
        while data := connection.recv(65536):
            chunks.append(data)
    monitors = json.loads(b"".join(chunks))
    visible = {m["activeWorkspace"]["id"] for m in monitors}
    focused = {m["activeWorkspace"]["id"] for m in monitors if m["focused"]}
    STATE.mkdir(parents=True, exist_ok=True)
    for workspace in range(1, 11):
        classes = ["workspace-button"]
        if workspace in visible:
            classes.append("active")
        if workspace in focused:
            classes.append("focused")
        value = {"text": str(workspace), "class": classes,
                 "tooltip": f"Switch to workspace {workspace}"}
        temporary = STATE / f".{workspace}.{os.getpid()}.tmp"
        temporary.write_text(json.dumps(value) + "\n")
        temporary.replace(STATE / f"{workspace}.json")
    if notify:
        # A real-time signal terminates Waybar before its handler is installed.
        # Startup already publishes the initial state, so only notify ready bars.
        update_signal = signal.SIGRTMIN + 8
        processes = subprocess.run(
            ["pgrep", "-u", str(os.getuid()), "-x", "waybar"],
            capture_output=True, text=True, check=False,
        )
        for pid in processes.stdout.split():
            try:
                status = (Path("/proc") / pid / "status").read_text()
                caught = next(line.split()[1] for line in status.splitlines()
                              if line.startswith("SigCgt:"))
                if int(caught, 16) & (1 << (update_signal - 1)):
                    os.kill(int(pid), update_signal)
            except (FileNotFoundError, ProcessLookupError, PermissionError):
                pass


def main():
    STATE.mkdir(parents=True, exist_ok=True)
    if "--init" in sys.argv:
        refresh(notify=False)
        return
    with (STATE / "watcher.lock").open("w") as lock:
        try:
            fcntl.flock(lock, fcntl.LOCK_EX | fcntl.LOCK_NB)
        except BlockingIOError:
            return
        with socket.socket(socket.AF_UNIX, socket.SOCK_STREAM) as events:
            events.connect(str(ipc_path(".socket2.sock")))
            refresh()
            with events.makefile() as stream:
                for event in stream:
                    if event.partition(">>")[0] in {
                        "workspace", "workspacev2", "focusedmon", "focusedmonv2",
                        "moveworkspace", "moveworkspacev2", "monitoradded", "monitorremoved",
                    }:
                        refresh()


if __name__ == "__main__":
    main()
