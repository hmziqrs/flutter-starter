# Native surfaces

Widgets and menus that live outside the app window. Dart decides what they say,
and each platform only draws it.

| Platform | Surfaces |
|---|---|
| iOS | Home screen widgets, lock screen widgets, Live Activity |
| Android | Home screen widgets, lock screen live update notification |
| macOS | Menu bar item, desktop and Notification Center widgets |
| Windows | System tray item, Windows 11 Widgets Board |
| Linux | Tray item where the desktop supports it |

## The channel

`MethodChannel('starter/native_surfaces')`, standard codec. Every snapshot
argument is one JSON string.

| Method | Direction | Argument | Returns |
|---|---|---|---|
| `publish` | Dart to native | snapshot JSON | nothing |
| `startLive` | Dart to native | snapshot JSON | `bool`: did it start |
| `updateLive` | Dart to native | snapshot JSON | nothing |
| `endLive` | Dart to native | none | nothing |
| `takeLaunchRoute` | Dart to native | none | `String?`, then null until the next launch |
| `openRoute` | native to Dart | route `String` | nothing |

A platform with no live surface returns `false` from `startLive`, and does nothing
for `updateLive` and `endLive`.

`publish` must store the JSON where the surfaces read it, then ask them to redraw.
Implement the channel in the platform's runner, not a separate plugin. Text must
never be hardcoded per platform, except the fallback below.

## The snapshot

```json
{
  "schema": 1,
  "title": "Starter",
  "subtitle": "Build running",
  "value": "72%",
  "valueLabel": "Complete",
  "progress": 0.72,
  "status": "active",
  "updatedAt": "2026-11-05T01:00:00.000Z",
  "route": "/",
  "actions": [{ "label": "Pricing", "route": "/pricing" }]
}
```

- `value`, `valueLabel` and `progress` can be null. Hide what is missing.
- `status` is `idle`, `active`, `success`, `warning` or `failure`.
- Ignore a snapshot whose `schema` is newer than you know, and use the fallback.
- Fallback when nothing has been published: title `Starter`, subtitle
  `Open the app to get started`, status `idle`.

## Storage

| Platform | Where |
|---|---|
| iOS, macOS | `UserDefaults(suiteName: "group.com.example.starter")`, key `surface.snapshot` |
| Android | `SharedPreferences` file `native_surfaces`, key `snapshot` |
| Windows, Linux | Local app data folder, file `native_surfaces.json` |

`tool/rename_app.py` rewrites `com.example.starter`, so keep identifiers in that
form and add any new native files it must rewrite to its lists.

## Opening the app

Tapping a surface opens the app at the snapshot's `route`, or an action's route.
Use the URL `starter-surface://open?route=<percent-encoded route>` where a URL is
needed. If the app is running, call `openRoute`. If this launched it, hold the
route for `takeLaunchRoute`. Dart checks every route against an allowlist, so
native code passes it through without validating it.

## Look

Follow the brand kit's live surfaces, in
`packages/brand-svelte/src/lib/components/live-widget.svelte`,
`live-activity.svelte` and `live-notification.svelte` in the brand repo, with
photographs in `build/brand-refs/custom-live-*.png`.

- Dark page `#0A0A0A` with text `#FAFAFA`, muted `#A1A1A1`, line `#262626`.
- Light page `#FFFFFF` with text `#0A0A0A`, muted `#737373`, line `#E5E5E5`.
- Accent: `#F38230` on dark, `#AA530A` on light. Status: success `#4ADE80` and
  `#15803D`, warning `#FACC15` and `#A16207`, failure `#F87171` and `#B91C1C`.
- Onest where the platform can use bundled fonts, otherwise the system font.
  Medium weight for titles, nothing heavier than semibold.
- Nothing moves except the progress itself. Support both modes where the platform
  lets you.

## Trying it

In a development build, open **Brand gallery**, then **Native surfaces**, to
publish sample snapshots and start and end a live session.
