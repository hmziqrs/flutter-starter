#!/usr/bin/env python3
"""Drives the real runner's tray on an empty virtual desktop, for Desktop smoke.

Run it inside Xvfb and its own D-Bus session, never on a desktop someone is using:

    xvfb-run -a -s '-screen 0 1280x800x24' dbus-run-session -- \
        python3 linux/ci/drive_tray.py <mode> --executable <bundle/starter> --out <dir>

Modes:
    full      the panel is up: the menu, close to tray, handover, Quit
    no-host   the tray item exists, but nothing on the desktop shows it
    no-tray   the build or the machine has no AppIndicator library

It fails on anything the contract promises, and writes report.txt and PNGs.
"""

from __future__ import annotations

import argparse
import json
import os
import re
import shutil
import subprocess
import sys
import time
from pathlib import Path

APP_ID = "com.example.starter"
SAMPLE = {
    "schema": 1,
    "title": "Surface sample & co",
    "subtitle": "Build running é",
    "value": "72%",
    "valueLabel": "Complete",
    "progress": 0.72,
    "status": "active",
    "updatedAt": "2026-11-05T01:00:00.000Z",
    "route": "/",
    "actions": [
        {"label": "Pricing", "route": "/pricing"},
        {"label": "Settings", "route": "/settings"},
    ],
}


class Driver:
    def __init__(self, args: argparse.Namespace) -> None:
        self.executable = args.executable
        self.out = Path(args.out)
        self.probe = self.out / "probe"
        self.probe.mkdir(parents=True, exist_ok=True)
        self.results = self.probe / "results.jsonl"
        self.report = open(self.out / "report.txt", "a", encoding="utf-8")
        self.failures: list[str] = []
        self.data_home = self.out / "xdg-data"
        self.snapshot_file = self.data_home / APP_ID / "native_surfaces.json"
        self.env = dict(
            os.environ,
            SURFACE_PROBE_DIR=str(self.probe),
            XDG_DATA_HOME=str(self.data_home),
        )

    def log(self, text: str) -> None:
        print(text, flush=True)
        self.report.write(text + "\n")
        self.report.flush()

    def check(self, ok: bool, name: str, detail: str = "") -> bool:
        self.log(f"{'ok  ' if ok else 'FAIL'} {name} {detail}".rstrip())
        if not ok:
            self.failures.append(name)
        return ok

    def run(self, *command: str) -> str:
        done = subprocess.run(command, capture_output=True, text=True, env=self.env, check=False)
        return done.stdout.strip()

    def shot(self, name: str) -> None:
        path = self.out / f"{name}.png"
        done = subprocess.run(["import", "-window", "root", str(path)], capture_output=True, text=True, check=False)
        self.log(f"shot {name}.png" if done.returncode == 0 else f"shot {name} FAILED: {done.stderr}")

    def wait_for(self, condition, seconds: float = 20) -> bool:
        deadline = time.monotonic() + seconds
        while time.monotonic() < deadline:
            if condition():
                return True
            time.sleep(0.2)
        return False

    def events(self, event: str) -> list:
        if not self.results.exists():
            return []
        lines = self.results.read_text(encoding="utf-8").splitlines()
        return [line["value"] for line in map(json.loads, lines) if line["event"] == event]

    def launch(self, *arguments: str) -> subprocess.Popen:
        return subprocess.Popen([self.executable, *arguments], env=self.env)

    def window_visible(self) -> bool:
        return re.search(r"\bStarter$", self.run("wmctrl", "-l"), re.M) is not None

    def close_window(self) -> None:
        self.run("wmctrl", "-c", "Starter")

    def publish(self, snapshot: dict) -> None:
        text = json.dumps(snapshot, ensure_ascii=False)
        temporary = self.probe / "publish.tmp"
        temporary.write_text(text, encoding="utf-8")
        temporary.rename(self.probe / "publish.json")
        before = len(self.events("published"))
        self.check(self.wait_for(lambda: len(self.events("published")) > before or not (self.probe / "publish.json").exists(), 10), "publish returned")
        self.check(self.snapshot_file.exists() and self.snapshot_file.read_text(encoding="utf-8") == text, "native_surfaces.json holds the published JSON", str(self.snapshot_file))

    def start_desktop(self, panel: bool) -> None:
        self.helper = [subprocess.Popen(["xfwm4", "--compositor=off"], env=self.env, stderr=subprocess.DEVNULL)]
        self.wait_for(lambda: self.run("wmctrl", "-m") != "", 10)
        if not panel:
            return
        for path, *values in (
            ("/configver", "int", "2"),
            ("/panels", "int", "1"),
            ("/panels/panel-1/size", "uint", "36"),
            ("/panels/panel-1/length", "uint", "100"),
            ("/panels/panel-1/position", "string", "p=8;x=640;y=780"),
            ("/plugins/plugin-1", "string", "separator"),
            ("/plugins/plugin-1/expand", "bool", "true"),
            ("/plugins/plugin-2", "string", "systray"),
            ("/plugins/plugin-2/square-icons", "bool", "true"),
        ):
            array = ["-a"] if path == "/panels" else []
            self.run("xfconf-query", "-c", "xfce4-panel", "-p", path, "-n", "-t", values[0], "-s", values[1], *array)
        self.run("xfconf-query", "-c", "xfce4-panel", "-p", "/panels/panel-1/plugin-ids", "-n", "-t", "int", "-s", "1", "-t", "int", "-s", "2", "-a")
        self.helper.append(subprocess.Popen(["xfce4-panel", "--disable-wm-check"], env=self.env, stderr=subprocess.DEVNULL))
        self.check(self.wait_for(self.host_registered, 30), "the panel is hosting status items")

    def host_registered(self) -> bool:
        return "true" in self.watcher_property("IsStatusNotifierHostRegistered")

    def watcher_property(self, name: str) -> str:
        return self.run(
            "gdbus", "call", "--session", "--dest", "org.kde.StatusNotifierWatcher",
            "--object-path", "/StatusNotifierWatcher",
            "--method", "org.freedesktop.DBus.Properties.Get",
            "org.kde.StatusNotifierWatcher", name,
        )

    def tray_item(self) -> tuple[str, str] | None:
        match = re.search(r"'([^'/]+)(/[^']+)'", self.watcher_property("RegisteredStatusNotifierItems"))
        return (match.group(1), match.group(2)) if match else None

    def item_property(self, item: tuple[str, str], name: str) -> str:
        return self.run(
            "gdbus", "call", "--session", "--dest", item[0], "--object-path", item[1],
            "--method", "org.freedesktop.DBus.Properties.Get", "org.kde.StatusNotifierItem", name,
        )

    def menu_path(self, item: tuple[str, str]) -> str:
        match = re.search(r"objectpath '([^']+)'", self.item_property(item, "Menu"))
        return match.group(1) if match else ""

    def menu_items(self, item: tuple[str, str]) -> list[tuple[int, str, bool]]:
        layout = self.run(
            "gdbus", "call", "--session", "--dest", item[0], "--object-path", self.menu_path(item),
            "--method", "com.canonical.dbusmenu.GetLayout", "0", "-1", "[]",
        )
        items = []
        for match in re.finditer(r"\((\d+), \{([^{}]*)\}", layout):
            properties = match.group(2)
            label = re.search(r"'label': <['\"](.*?)['\"]>", properties)
            if label:
                items.append((int(match.group(1)), label.group(1), "'enabled': <false>" in properties))
        return items

    def click_menu_item(self, item: tuple[str, str], label: str) -> None:
        identifier = next(i for i, text, _ in self.menu_items(item) if text.replace("__", "_") == label)
        self.run(
            "gdbus", "call", "--session", "--dest", item[0], "--object-path", self.menu_path(item),
            "--method", "com.canonical.dbusmenu.Event", str(identifier), "clicked", "<int32 0>", "0",
        )

    def stop_desktop(self) -> None:
        for helper in getattr(self, "helper", []):
            helper.terminate()

    def launch_probe_and_check_channel(self, *arguments: str) -> subprocess.Popen:
        process = self.launch(*arguments)
        self.check(self.wait_for(lambda: self.events("liveCallsReturned"), 60), "Dart reached the channel")
        self.check(self.events("startLive") == [False], "startLive returns false")
        self.check(self.wait_for(self.window_visible, 30), "window visible after the first frame")
        return process

    # The modes.

    def full(self) -> None:
        self.start_desktop(panel=True)
        self.log("--- launch with a surface URL")
        process = self.launch_probe_and_check_channel("starter-surface://open?route=%2Fpricing")
        self.check(self.events("launchRoute") == ["/pricing"], "takeLaunchRoute returns the launch route")
        self.check(self.events("launchRouteAgain") == [None], "takeLaunchRoute is null the second time")
        time.sleep(2)
        self.shot("01-window-and-tray")

        self.check(self.wait_for(lambda: self.tray_item() is not None, 20), "the tray item registered")
        item = self.tray_item()
        self.log(f"item: {item}")
        self.log(f"icon: {self.item_property(item, 'IconName')} in {self.item_property(item, 'IconThemePath')}")

        self.log("--- fallback, before anything is published")
        items = self.menu_items(item)
        self.log(f"menu: {items}")
        self.check(any(t == "Starter" and off for _, t, off in items), "fallback title")
        self.check(any(t == "Open the app to get started" and off for _, t, off in items), "fallback subtitle")
        self.check([t for _, t, _ in items][-2:] == ["Open", "Quit"], "Open and Quit are last")

        self.log("--- publish")
        self.publish(SAMPLE)
        self.check(self.wait_for(lambda: "Pricing" in [t for _, t, _ in self.menu_items(item)], 10), "the menu follows the snapshot")
        items = self.menu_items(item)
        self.log(f"menu: {items}")
        labels = [t for _, t, _ in items]
        self.check("Surface sample & co" in labels, "title")
        self.check("Build running é" in labels or "Build running \\303\\251" in labels, "subtitle, non-ASCII intact")
        self.check("Pricing" in labels and "Settings" in labels, "each action is listed")
        self.check(labels[-2:] == ["Open", "Quit"], "Open and Quit are last")
        self.log(f"title: {self.item_property(item, 'Title')}")

        self.log("--- the menu on screen")
        self.run("xdotool", "mousemove", "1262", "782", "click", "3")
        time.sleep(2)
        self.shot("02-menu-published")
        self.run("xdotool", "key", "Escape")
        time.sleep(1)

        self.log("--- close keeps the app in the tray")
        self.close_window()
        self.check(self.wait_for(lambda: not self.window_visible(), 5), "closing hides the window")
        time.sleep(1)
        self.check(process.poll() is None, "the process stays alive")
        self.check(self.tray_item() is not None, "the item stays in the tray")
        self.shot("03-closed-to-tray")

        self.log("--- an action restores the window and opens its route")
        self.click_menu_item(item, "Settings")
        self.check(self.wait_for(lambda: "/settings" in self.events("openRoute"), 5), "openRoute carries the action route")
        self.check(self.wait_for(self.window_visible, 5), "the window comes back")
        time.sleep(1)
        self.shot("04-restored-by-action")

        self.log("--- Open goes to the snapshot route")
        self.close_window()
        self.check(self.wait_for(lambda: not self.window_visible(), 5), "hidden again")
        self.click_menu_item(item, "Open")
        self.check(self.wait_for(lambda: "/" in self.events("openRoute"), 5), "Open sends the snapshot route")
        self.check(self.wait_for(self.window_visible, 5), "Open restores the window")

        self.log("--- a second launch hands over")
        self.close_window()
        self.check(self.wait_for(lambda: not self.window_visible(), 5), "hidden again")
        second = self.launch("starter-surface://open?route=%2Fsecond")
        self.check(second.wait(20) == 0, "second instance exits at once")
        self.check(self.wait_for(lambda: "/second" in self.events("openRoute"), 5), "its URL reaches the running app as openRoute")
        self.check(self.wait_for(self.window_visible, 5), "its URL restores the window")
        self.close_window()
        self.check(self.wait_for(lambda: not self.window_visible(), 5), "hidden again")
        third = self.launch()
        self.check(third.wait(20) == 0, "a plain second launch exits at once")
        self.check(self.wait_for(self.window_visible, 5), "a plain second launch restores the window")

        self.log("--- Quit really quits")
        self.click_menu_item(item, "Quit")
        try:
            code = process.wait(20)
        except subprocess.TimeoutExpired:
            process.kill()
            code = "still running"
        self.check(code == 0, "Quit ends the process cleanly", f"exit={code}")
        self.check(self.wait_for(lambda: self.tray_item() is None, 10), "the item is gone")
        self.shot("05-after-quit")

        self.log("--- a newer schema falls back")
        self.snapshot_file.write_text('{"schema":99,"title":"From the future","actions":[]}', encoding="utf-8")
        self.results.unlink()
        process = self.launch_probe_and_check_channel()
        self.check(self.wait_for(lambda: self.tray_item() is not None, 20), "the tray item registered")
        labels = [t for _, t, _ in self.menu_items(self.tray_item())]
        self.log(f"menu: {labels}")
        self.check("Starter" in labels and "From the future" not in labels, "a newer schema shows the fallback")
        self.click_menu_item(self.tray_item(), "Quit")
        process.wait(20)

    def no_tray_common(self) -> None:
        process = self.launch_probe_and_check_channel()
        self.check(self.tray_item() is None, "no item is registered")
        self.publish(SAMPLE)
        self.close_window()
        try:
            code = process.wait(20)
        except subprocess.TimeoutExpired:
            process.kill()
            code = "still running"
        self.check(code == 0, "closing the window quits, since no tray could bring it back", f"exit={code}")

    def no_host(self) -> None:
        self.start_desktop(panel=False)
        self.no_tray_common()

    def no_tray(self) -> None:
        self.start_desktop(panel=True)
        self.no_tray_common()


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("mode", choices=["full", "no-host", "no-tray"])
    parser.add_argument("--executable", required=True)
    parser.add_argument("--out", required=True)
    args = parser.parse_args()
    shutil.rmtree(Path(args.out) / "probe", ignore_errors=True)
    Path(args.out).mkdir(parents=True, exist_ok=True)

    driver = Driver(args)
    driver.log(f"=== mode {args.mode}")
    try:
        getattr(driver, args.mode.replace("-", "_"))()
    finally:
        driver.stop_desktop()
    if driver.failures:
        driver.log(f"FAILED: {'; '.join(driver.failures)}")
        return 1
    driver.log("all checks passed")
    return 0


if __name__ == "__main__":
    sys.exit(main())
