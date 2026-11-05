#!/usr/bin/env python3
"""Rename this starter into your own app, across every platform.

    python3 tool/rename_app.py --name "Sightline" --id com.acme.sightline
    python3 tool/rename_app.py --name "Sightline" --id com.acme.sightline --dart-package sightline
    just rename "Sightline" com.acme.sightline

Dry run by default: add --apply to write. It changes the display name, the
bundle and application ids, the Android Kotlin package and its folder, and,
with --dart-package, the Dart package and all its imports. Commit first so the
result reads as one reviewable diff.

Afterwards redraw the icons with `just brand-assets <two letters> <name>`.
"""

from __future__ import annotations

import argparse
import re
import shutil
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
OLD_ID = "com.example.starter"
OLD_NAME = "Starter"
OLD_PACKAGE = "starter"
OLD_TEAM = "4H4RFUBJJN"

SKIPPED_DIRS = {
    ".claude", ".git", ".dart_tool", "build", "Pods", ".gradle", ".symlinks", "node_modules",
}
TEXT_SUFFIXES = {
    ".appxmanifest", ".cc", ".cmake", ".cpp", ".cs", ".dart", ".entitlements", ".example", ".gradle", ".h",
    ".json", ".kt", ".kts", ".md", ".manifest", ".pbxproj", ".plist", ".ps1", ".py", ".rc", ".sh",
    ".swift", ".txt", ".xcconfig", ".xcscheme", ".xml", ".yaml", ".yml",
}

# Where the display name and the binary name appear, as exact text. A blanket
# replacement of "starter" would rewrite prose, so these stay explicit.
NAME_EDITS: dict[str, list[tuple[str, str]]] = {
    "ios/Runner/Info.plist": [("<string>Starter</string>", "<string>{name}</string>")],
    "tvos/Runner/Info.plist": [("<string>Starter</string>", "<string>{name}</string>")],
    "macos/Runner/Info.plist": [("<string>Starter</string>", "<string>{name}</string>")],
    "ios/StarterSurfaces/Info.plist": [("<string>Starter</string>", "<string>{name}</string>")],
    "macos/SurfaceWidgets/Info.plist": [("<string>Starter</string>", "<string>{name}</string>")],
    "macos/Runner/Configs/AppInfo.xcconfig": [("PRODUCT_NAME = starter", "PRODUCT_NAME = {binary}")],
    "linux/CMakeLists.txt": [('set(BINARY_NAME "starter")', 'set(BINARY_NAME "{binary}")')],
    "linux/runner/my_application.cc": [('"Starter"', '"{name}"')],
    "windows/CMakeLists.txt": [
        ("project(starter LANGUAGES CXX)", "project({binary} LANGUAGES CXX)"),
        ('set(BINARY_NAME "starter")', 'set(BINARY_NAME "{binary}")'),
    ],
    "windows/runner/main.cpp": [('L"Starter"', 'L"{name}"')],
    "windows/runner/surface_snapshot.cpp": [('L"Starter"', 'L"{name}"')],
    "windows/runner/native_surfaces.cpp": [('L"URL:Starter surface"', 'L"URL:{name} surface"')],
    "linux/runner/native_surfaces.cc": [('"Starter"', '"{name}"')],
    "windows/widget_provider/src/SurfaceCard.cs": [('"Starter"', '"{name}"')],
    "windows/widget_provider/Package/AppxManifest.xml": [
        ("<DisplayName>Starter widgets</DisplayName>", "<DisplayName>{name} widgets</DisplayName>"),
        ("<PublisherDisplayName>Starter</PublisherDisplayName>", "<PublisherDisplayName>{name}</PublisherDisplayName>"),
        ('DisplayName="Starter widgets"', 'DisplayName="{name} widgets"'),
        ('Description="Widgets for Starter"', 'Description="Widgets for {name}"'),
        ('DisplayName="Starter"', 'DisplayName="{name}"'),
    ],
    "windows/runner/Runner.rc": [
        ('VALUE "ProductName", "Starter"', 'VALUE "ProductName", "{name}"'),
        ('VALUE "CompanyName", "com.example"', 'VALUE "CompanyName", "{company}"'),
    ],
    "android/app/src/main/res/values/strings.xml": [(">Starter<", ">{name}<")],
    "web/manifest.json": [('"Starter"', '"{name}"')],
    "web/index.html": [('content="Starter"', 'content="{name}"'), ("<title>Starter</title>", "<title>{name}</title>")],
    "lib/i18n/en.i18n.json": [('"name": "Starter"', '"name": "{name}"')],
}


def text_files():
    for path in ROOT.rglob("*"):
        if any(part in SKIPPED_DIRS for part in path.relative_to(ROOT).parts):
            continue
        if path.is_file() and path.suffix in TEXT_SUFFIXES:
            yield path


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description=__doc__.splitlines()[0])
    parser.add_argument("--name", required=True, help='Display name, such as "Sightline".')
    parser.add_argument("--id", required=True, help="Reverse-domain id, such as com.acme.sightline.")
    parser.add_argument("--dart-package", help="New Dart package name. Leave out to keep 'starter'.")
    parser.add_argument("--team", default="", help="Your Apple Team ID. Leave out to clear the starter's.")
    parser.add_argument("--apply", action="store_true", help="Write the changes. Without it, only list them.")
    args = parser.parse_args()
    if not re.fullmatch(r"[a-z][a-z0-9_]*(\.[a-z][a-z0-9_]*)+", args.id):
        parser.error(f"--id must look like com.acme.app, got {args.id!r}")
    if args.dart_package and not re.fullmatch(r"[a-z][a-z0-9_]*", args.dart_package):
        parser.error(f"--dart-package must be lower_snake_case, got {args.dart_package!r}")
    if '"' in args.name or "\\" in args.name:
        parser.error("--name cannot contain quotes or backslashes")
    return args


def main() -> int:
    args = parse_args()
    binary = args.id.rsplit(".", 1)[-1]
    company = args.id.rsplit(".", 1)[0]
    values = {"name": args.name, "binary": binary, "company": company}
    changes: dict[Path, str] = {}

    def edited(path: Path) -> str:
        return changes.get(path, path.read_text(encoding="utf-8"))

    for path in text_files():
        # This script and the validators' test data keep the old id as data.
        if path == Path(__file__).resolve():
            continue
        original = path.read_text(encoding="utf-8", errors="surrogateescape")
        updated = original.replace(OLD_ID, args.id).replace(
            OLD_ID.replace(".", "/"), args.id.replace(".", "/")
        )
        if args.dart_package:
            updated = updated.replace(f"package:{OLD_PACKAGE}/", f"package:{args.dart_package}/")
        if updated != original:
            changes[path] = updated

    for relative, edits in NAME_EDITS.items():
        path = ROOT / relative
        if not path.exists():
            continue
        text = edited(path)
        for old, new in edits:
            if old not in text:
                print(f"  note: {relative}: did not find {old!r}, leaving it as it is")
                continue
            text = text.replace(old, new.format(**values))
        changes[path] = text

    # The starter's own Apple team must not follow an app built from it.
    team = f'"{args.team}"' if args.team else '""'
    for relative in ("ios", "macos", "tvos"):
        project = ROOT / relative / "Runner.xcodeproj/project.pbxproj"
        if project.exists():
            changes[project] = edited(project).replace(
                f"DEVELOPMENT_TEAM = {OLD_TEAM};", f"DEVELOPMENT_TEAM = {team};"
            )

    if args.dart_package:
        pubspec = ROOT / "pubspec.yaml"
        changes[pubspec] = re.sub(
            r"^name: starter$", f"name: {args.dart_package}", edited(pubspec), count=1, flags=re.M
        )

    old_kotlin = ROOT / "android/app/src/main/kotlin" / Path(*OLD_ID.split("."))
    new_kotlin = ROOT / "android/app/src/main/kotlin" / Path(*args.id.split("."))

    for path in sorted(changes):
        print(f"  {'write' if args.apply else 'would change'} {path.relative_to(ROOT)}")
    print(f"  {'move' if args.apply else 'would move'} {old_kotlin.relative_to(ROOT)} -> {new_kotlin.relative_to(ROOT)}")

    if not args.apply:
        print("\nDry run. Add --apply to write these changes.")
        return 0

    for path, text in changes.items():
        path.write_text(text, encoding="utf-8", errors="surrogateescape")
    if old_kotlin.exists() and old_kotlin != new_kotlin:
        new_kotlin.parent.mkdir(parents=True, exist_ok=True)
        shutil.move(str(old_kotlin), str(new_kotlin))
        parent = old_kotlin.parent
        while parent != ROOT and not any(parent.iterdir()):
            parent.rmdir()
            parent = parent.parent

    print(
        "\nDone. Next:\n"
        "  just gen\n"
        "  dart fix --apply  # a new package name can change the import order\n"
        f"  just brand-assets {args.name[:2].capitalize()} {args.name!r}\n"
        "  just analyze && just test"
    )
    return 0


if __name__ == "__main__":
    sys.exit(main())
