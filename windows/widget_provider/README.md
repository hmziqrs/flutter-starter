# Windows 11 Widgets Board provider

Optional, and separate from the app: `flutter build windows` never builds this folder,
and the app runs without it. It shows `native_surfaces.json`, which the app writes, on
the Widgets Board. See `docs/native_surfaces.md`.

Windows only registers widget providers from a packaged app, so this is a C# COM server
in its own MSIX, on the Windows App SDK.

```powershell
windows/widget_provider/build.ps1 -OutDir build/widget_provider -Sign
```

`-Sign` makes a throwaway certificate for a test machine. To try it there, trust
`StarterWidgetsTest.cer` in Local Machine, Trusted People, install the Windows App
Runtime this NuGet version names, install `StarterWidgets.msix`, then pin **Starter**
from the Widgets Board. A release needs your own certificate, with its subject passed as
`-Publisher`.

The app registers `starter-surface:` the first time it runs, and widget taps go through
that URL, so taps do nothing until the app has been opened once.

## Status

Unproven. This code has never been compiled, packaged or run, on any machine.
`Package/Assets/Screenshot*.png` come from a browser preview of the card rather than the
Widgets Board, and have square corners where the picker asks for transparent rounded ones.
