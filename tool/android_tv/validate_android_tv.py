#!/usr/bin/env python3
"""Validate Android TV packaging without changing the Android build."""

from __future__ import annotations

import argparse
import struct
import sys
import xml.etree.ElementTree as ET
from pathlib import Path

ANDROID_NAMESPACE = "http://schemas.android.com/apk/res/android"
ANDROID_ATTRIBUTE = f"{{{ANDROID_NAMESPACE}}}"
MAIN_ACTION = "android.intent.action.MAIN"
MOBILE_LAUNCHER = "android.intent.category.LAUNCHER"
TV_LAUNCHER = "android.intent.category.LEANBACK_LAUNCHER"

MAIN_ACTIVITY = "MainActivity"
TV_ACTIVITY = "TvActivity"
EXPECTED_APP_LABEL = "@string/app_name"
EXPECTED_MOBILE_ICON = "@mipmap/ic_launcher"
EXPECTED_TV_ICON = "@mipmap/ic_launcher_tv"
EXPECTED_TV_BANNER = "@drawable/tv_banner"
EXPECTED_TV_LAUNCH_THEME = "@style/TvLaunchTheme"
EXPECTED_TV_NORMAL_THEME = "@style/TvNormalTheme"

REQUIRED_TV_CONFIG_CHANGES = {
    "density",
    "fontScale",
    "keyboard",
    "keyboardHidden",
    "layoutDirection",
    "locale",
    "navigation",
    "orientation",
    "screenLayout",
    "screenSize",
    "smallestScreenSize",
    "uiMode",
}

OPTIONAL_FEATURES = {
    "android.hardware.touchscreen",
    "android.software.leanback",
}

HARDWARE_FEATURE_PREFIXES = (
    "android.hardware.camera",
    "android.hardware.location",
    "android.hardware.sensor",
    "android.hardware.telephony",
)

HARDWARE_FEATURES_THAT_MUST_BE_OPTIONAL = {
    "android.hardware.faketouch",
    "android.hardware.microphone",
    "android.hardware.nfc",
    "android.hardware.touchscreen",
    "android.hardware.wifi",
}

EXPECTED_PNGS = {
    "mipmap-xhdpi/ic_launcher_tv.png": (160, 160),
    "drawable-xhdpi/tv_banner.png": (320, 180),
    "drawable-en-xhdpi/tv_banner.png": (320, 180),
    "drawable-ar-xhdpi/tv_banner.png": (320, 180),
    "drawable-zh-rCN-xhdpi/tv_banner.png": (320, 180),
}


class Validation:
    def __init__(self) -> None:
        self.errors: list[str] = []

    def require(self, condition: bool, message: str) -> None:
        if not condition:
            self.errors.append(message)


def android_attribute(element: ET.Element, name: str) -> str | None:
    return element.get(f"{ANDROID_ATTRIBUTE}{name}")


def activity_name(element: ET.Element) -> str:
    return android_attribute(element, "name") or ""


def is_named_activity(element: ET.Element, simple_name: str) -> bool:
    name = activity_name(element)
    return name == f".{simple_name}" or name.endswith(f".{simple_name}")


def launch_filters(element: ET.Element) -> list[tuple[set[str], set[str]]]:
    filters: list[tuple[set[str], set[str]]] = []
    for intent_filter in element.findall("intent-filter"):
        actions = {
            android_attribute(action, "name") or ""
            for action in intent_filter.findall("action")
        }
        categories = {
            android_attribute(category, "name") or ""
            for category in intent_filter.findall("category")
        }
        filters.append((actions, categories))
    return filters


def has_launcher(element: ET.Element, category: str) -> bool:
    return any(
        MAIN_ACTION in actions and category in categories
        for actions, categories in launch_filters(element)
    )


def validate_manifest(path: Path, validation: Validation, label: str) -> None:
    if not path.is_file():
        validation.errors.append(f"{label}: manifest does not exist: {path}")
        return

    try:
        root = ET.parse(path).getroot()
    except ET.ParseError as error:
        validation.errors.append(f"{label}: invalid XML in {path}: {error}")
        return

    application = root.find("application")
    if application is None:
        validation.errors.append(f"{label}: missing <application>")
        return

    validation.require(
        android_attribute(application, "label") == EXPECTED_APP_LABEL,
        f"{label}: application label must be {EXPECTED_APP_LABEL}",
    )
    validation.require(
        android_attribute(application, "icon") == EXPECTED_MOBILE_ICON,
        f"{label}: application icon must remain {EXPECTED_MOBILE_ICON}",
    )

    components = [
        *application.findall("activity"),
        *application.findall("activity-alias"),
    ]
    main_activities = [
        component
        for component in application.findall("activity")
        if is_named_activity(component, MAIN_ACTIVITY)
    ]
    tv_activities = [
        component
        for component in application.findall("activity")
        if is_named_activity(component, TV_ACTIVITY)
    ]

    validation.require(
        len(main_activities) == 1,
        f"{label}: expected exactly one {MAIN_ACTIVITY}, found {len(main_activities)}",
    )
    validation.require(
        len(tv_activities) == 1,
        f"{label}: expected exactly one {TV_ACTIVITY}, found {len(tv_activities)}",
    )

    mobile_launchers = [
        component for component in components if has_launcher(component, MOBILE_LAUNCHER)
    ]
    tv_launchers = [
        component for component in components if has_launcher(component, TV_LAUNCHER)
    ]
    validation.require(
        len(mobile_launchers) == 1,
        f"{label}: expected one ordinary launcher, found {len(mobile_launchers)}",
    )
    validation.require(
        len(tv_launchers) == 1,
        f"{label}: expected one Leanback launcher, found {len(tv_launchers)}",
    )

    if len(main_activities) == 1:
        main_activity = main_activities[0]
        validation.require(
            has_launcher(main_activity, MOBILE_LAUNCHER),
            f"{label}: {MAIN_ACTIVITY} must own MAIN + LAUNCHER",
        )
        validation.require(
            not has_launcher(main_activity, TV_LAUNCHER),
            f"{label}: {MAIN_ACTIVITY} must not own LEANBACK_LAUNCHER",
        )
        validation.require(
            android_attribute(main_activity, "screenOrientation") is None,
            f"{label}: {MAIN_ACTIVITY} must preserve the mobile orientation policy",
        )

    if len(tv_activities) == 1:
        tv_activity = tv_activities[0]
        validation.require(
            has_launcher(tv_activity, TV_LAUNCHER),
            f"{label}: {TV_ACTIVITY} must own MAIN + LEANBACK_LAUNCHER",
        )
        validation.require(
            not has_launcher(tv_activity, MOBILE_LAUNCHER),
            f"{label}: {TV_ACTIVITY} must not own ordinary LAUNCHER",
        )
        validation.require(
            android_attribute(tv_activity, "exported") == "true",
            f"{label}: {TV_ACTIVITY} must be exported",
        )
        validation.require(
            android_attribute(tv_activity, "screenOrientation") == "landscape",
            f"{label}: {TV_ACTIVITY} must be landscape-only",
        )
        validation.require(
            android_attribute(tv_activity, "theme") == EXPECTED_TV_LAUNCH_THEME,
            f"{label}: {TV_ACTIVITY} must use {EXPECTED_TV_LAUNCH_THEME}",
        )
        validation.require(
            android_attribute(tv_activity, "banner") == EXPECTED_TV_BANNER,
            f"{label}: {TV_ACTIVITY} must use {EXPECTED_TV_BANNER}",
        )
        validation.require(
            android_attribute(tv_activity, "icon") == EXPECTED_TV_ICON,
            f"{label}: {TV_ACTIVITY} must use {EXPECTED_TV_ICON}",
        )

        config_changes = set(
            (android_attribute(tv_activity, "configChanges") or "").split("|")
        )
        missing_config_changes = REQUIRED_TV_CONFIG_CHANGES - config_changes
        validation.require(
            not missing_config_changes,
            f"{label}: {TV_ACTIVITY} configChanges is missing "
            f"{', '.join(sorted(missing_config_changes))}",
        )

        normal_theme_entries = [
            metadata
            for metadata in tv_activity.findall("meta-data")
            if android_attribute(metadata, "name")
            == "io.flutter.embedding.android.NormalTheme"
        ]
        validation.require(
            len(normal_theme_entries) == 1
            and android_attribute(normal_theme_entries[0], "resource")
            == EXPECTED_TV_NORMAL_THEME,
            f"{label}: {TV_ACTIVITY} must declare {EXPECTED_TV_NORMAL_THEME} "
            "as Flutter's NormalTheme",
        )

    feature_entries = [
        (
            android_attribute(feature, "name") or "",
            android_attribute(feature, "required"),
        )
        for feature in root.findall("uses-feature")
    ]
    for feature in sorted(OPTIONAL_FEATURES):
        matching_entries = [
            required
            for feature_name, required in feature_entries
            if feature_name == feature
        ]
        validation.require(
            matching_entries == ["false"],
            f"{label}: {feature} must appear exactly once with "
            'android:required="false"',
        )

    for feature, required in sorted(feature_entries):
        must_be_optional = feature in HARDWARE_FEATURES_THAT_MUST_BE_OPTIONAL or any(
            feature.startswith(prefix) for prefix in HARDWARE_FEATURE_PREFIXES
        )
        validation.require(
            not must_be_optional or required == "false",
            f"{label}: television compatibility requires {feature} to be optional",
        )


def png_dimensions(path: Path) -> tuple[int, int] | None:
    try:
        with path.open("rb") as image:
            header = image.read(24)
    except OSError:
        return None

    if (
        len(header) != 24
        or header[:8] != b"\x89PNG\r\n\x1a\n"
        or header[12:16] != b"IHDR"
    ):
        return None
    return struct.unpack(">II", header[16:24])


def resource_items(style: ET.Element) -> dict[str, str]:
    return {
        item.get("name") or "": (item.text or "").strip()
        for item in style.findall("item")
    }


def validate_style_file(
    path: Path,
    validation: Validation,
    expected_launch_background: str,
    expected_normal_background: str,
) -> None:
    if not path.is_file():
        validation.errors.append(f"resources: missing {path}")
        return

    try:
        root = ET.parse(path).getroot()
    except ET.ParseError as error:
        validation.errors.append(f"resources: invalid XML in {path}: {error}")
        return

    styles = {style.get("name") or "": style for style in root.findall("style")}
    launch_theme = styles.get("TvLaunchTheme")
    normal_theme = styles.get("TvNormalTheme")
    validation.require(
        launch_theme is not None,
        f"resources: {path} must define TvLaunchTheme",
    )
    validation.require(
        normal_theme is not None,
        f"resources: {path} must define TvNormalTheme",
    )

    if launch_theme is not None:
        items = resource_items(launch_theme)
        validation.require(
            items.get("android:windowBackground") == expected_launch_background,
            f"resources: TvLaunchTheme in {path} must use "
            f"{expected_launch_background}",
        )
        validation.require(
            items.get("android:windowIsTranslucent") == "false",
            f"resources: TvLaunchTheme in {path} must be opaque",
        )

    if normal_theme is not None:
        items = resource_items(normal_theme)
        validation.require(
            items.get("android:windowBackground") == expected_normal_background,
            f"resources: TvNormalTheme in {path} must use "
            f"{expected_normal_background}",
        )
        validation.require(
            items.get("android:windowIsTranslucent") == "false",
            f"resources: TvNormalTheme in {path} must be opaque",
        )


def validate_resources(resource_root: Path, validation: Validation) -> None:
    for relative_path, expected_dimensions in EXPECTED_PNGS.items():
        path = resource_root / relative_path
        actual_dimensions = png_dimensions(path)
        validation.require(
            actual_dimensions == expected_dimensions,
            f"resources: {relative_path} must be a {expected_dimensions[0]}x"
            f"{expected_dimensions[1]} PNG, found {actual_dimensions}",
        )

    strings_path = resource_root / "values/strings.xml"
    if strings_path.is_file():
        try:
            strings_root = ET.parse(strings_path).getroot()
            app_names = [
                string
                for string in strings_root.findall("string")
                if string.get("name") == "app_name"
            ]
            validation.require(
                len(app_names) == 1 and bool((app_names[0].text or "").strip()),
                "resources: values/strings.xml must define a non-empty app_name",
            )
        except ET.ParseError as error:
            validation.errors.append(
                f"resources: invalid XML in {strings_path}: {error}"
            )
    else:
        validation.errors.append(f"resources: missing {strings_path}")

    colors_path = resource_root / "values/colors.xml"
    if colors_path.is_file():
        try:
            colors_root = ET.parse(colors_path).getroot()
            backgrounds = [
                color
                for color in colors_root.findall("color")
                if color.get("name") == "tv_window_background"
            ]
            validation.require(
                len(backgrounds) == 1
                and (backgrounds[0].text or "").strip().upper() == "#0A0A0A",
                "resources: tv_window_background must match Flutter's #0A0A0A "
                "dark surface",
            )
        except ET.ParseError as error:
            validation.errors.append(
                f"resources: invalid XML in {colors_path}: {error}"
            )
    else:
        validation.errors.append(f"resources: missing {colors_path}")

    launch_background_path = resource_root / "drawable/tv_launch_background.xml"
    if launch_background_path.is_file():
        try:
            launch_background = ET.parse(launch_background_path).getroot()
            drawables = {
                android_attribute(item, "drawable")
                for item in launch_background.findall("item")
            }
            validation.require(
                "@color/tv_window_background" in drawables,
                "resources: tv_launch_background must be an opaque "
                "tv_window_background layer",
            )
        except ET.ParseError as error:
            validation.errors.append(
                f"resources: invalid XML in {launch_background_path}: {error}"
            )
    else:
        validation.errors.append(f"resources: missing {launch_background_path}")

    validate_style_file(
        resource_root / "values/styles.xml",
        validation,
        "@drawable/tv_launch_background",
        "@color/tv_window_background",
    )
    validate_style_file(
        resource_root / "values-night/styles.xml",
        validation,
        "@drawable/tv_launch_background",
        "@color/tv_window_background",
    )


def validate_detector_sources(kotlin_root: Path, validation: Validation) -> None:
    main_activity = kotlin_root / "MainActivity.kt"
    tv_activity = kotlin_root / "TvActivity.kt"
    channel_host = kotlin_root / "PlatformAwareFlutterActivity.kt"
    for path in (main_activity, tv_activity, channel_host):
        validation.require(path.is_file(), f"detector: missing {path}")

    if not all(path.is_file() for path in (main_activity, tv_activity, channel_host)):
        return

    main_source = main_activity.read_text(encoding="utf-8")
    tv_source = tv_activity.read_text(encoding="utf-8")
    host_source = channel_host.read_text(encoding="utf-8")
    validation.require(
        "isAuthoritativeTvLaunch = false" in main_source,
        "detector: MainActivity must use Leanback feature detection",
    )
    validation.require(
        "isAuthoritativeTvLaunch = true" in tv_source,
        "detector: TvActivity launch identity must be authoritative",
    )
    for required_source in (
        '"starter/platform_capabilities"',
        '"isAndroidTv"',
        "PackageManager.FEATURE_LEANBACK",
        "catch (_: RuntimeException)",
    ):
        validation.require(
            required_source in host_source,
            f"detector: PlatformAwareFlutterActivity is missing {required_source}",
        )


def resolve_repo_path(repo_root: Path, raw_path: str) -> Path:
    path = Path(raw_path)
    return path if path.is_absolute() else repo_root / path


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument(
        "--merged-manifest",
        help="also validate an Android Gradle merged manifest",
    )
    arguments = parser.parse_args()

    repo_root = Path(__file__).resolve().parents[2]
    android_main = repo_root / "android/app/src/main"
    validation = Validation()

    source_manifest = android_main / "AndroidManifest.xml"
    validate_manifest(source_manifest, validation, "source")
    validate_resources(android_main / "res", validation)
    validate_detector_sources(
        android_main / "kotlin/com/example/starter",
        validation,
    )

    merged_manifest: Path | None = None
    if arguments.merged_manifest:
        merged_manifest = resolve_repo_path(repo_root, arguments.merged_manifest)
        validate_manifest(merged_manifest, validation, "merged")

    if validation.errors:
        print("Android TV validation failed:", file=sys.stderr)
        for error in validation.errors:
            print(f"  - {error}", file=sys.stderr)
        return 1

    print(f"Android TV source manifest validated: {source_manifest}")
    print(f"Android TV resources validated: {android_main / 'res'}")
    print("Android TV detector channel sources validated")
    if merged_manifest is not None:
        print(f"Android TV merged manifest validated: {merged_manifest}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
