using System.Diagnostics;
using System.Text.Json;
using Microsoft.Windows.Widgets.Providers;

namespace Starter.Widgets;

/// <summary>
/// Draws docs/native_surfaces.md on the Widgets Board. The app only writes
/// native_surfaces.json, so this watches that file while the host has it running.
/// </summary>
public sealed class WidgetProvider : IWidgetProvider
{
    // Also in Package\AppxManifest.xml, twice.
    public const string ClassId = "F55748D8-A04C-4675-BB30-3C8128234385";

    private const string OpenVerb = "open";

    private static readonly object Gate = new();
    private static readonly HashSet<string> ActiveWidgets = new();
    private static readonly HashSet<string> PinnedWidgets = new();
    private static readonly Lazy<string> Template = new(() =>
        File.ReadAllText(Path.Combine(AppContext.BaseDirectory, "Templates", "surface.json")));

    private static FileSystemWatcher? _watcher;

    public static ManualResetEvent NoWidgetsLeft { get; } = new(false);

    public WidgetProvider()
    {
        // The host may restart this process with widgets already pinned.
        foreach (var info in WidgetManager.GetDefault().GetWidgetInfos() ?? Array.Empty<WidgetInfo>())
        {
            lock (Gate)
            {
                PinnedWidgets.Add(info.WidgetContext.Id);
                if (info.WidgetContext.IsActive)
                {
                    ActiveWidgets.Add(info.WidgetContext.Id);
                }
            }
        }

        WatchSnapshot();
    }

    public void CreateWidget(WidgetContext context)
    {
        lock (Gate)
        {
            PinnedWidgets.Add(context.Id);
            ActiveWidgets.Add(context.Id);
        }

        Update(context.Id);
    }

    public void DeleteWidget(string widgetId, string customState)
    {
        bool empty;
        lock (Gate)
        {
            PinnedWidgets.Remove(widgetId);
            ActiveWidgets.Remove(widgetId);
            empty = PinnedWidgets.Count == 0;
        }

        if (empty)
        {
            NoWidgetsLeft.Set();
        }
    }

    public void Activate(WidgetContext context)
    {
        lock (Gate)
        {
            ActiveWidgets.Add(context.Id);
        }

        Update(context.Id);
    }

    public void Deactivate(string widgetId)
    {
        lock (Gate)
        {
            ActiveWidgets.Remove(widgetId);
        }
    }

    public void OnWidgetContextChanged(WidgetContextChangedArgs contextChangedArgs)
    {
        // The template picks its layout from $host.widgetSize, and only needs resending.
        Update(contextChangedArgs.WidgetContext.Id);
    }

    public void OnActionInvoked(WidgetActionInvokedArgs actionInvokedArgs)
    {
        if (actionInvokedArgs.Verb != OpenVerb || string.IsNullOrEmpty(actionInvokedArgs.Data))
        {
            return;
        }

        using var data = JsonDocument.Parse(actionInvokedArgs.Data);
        if (data.RootElement.TryGetProperty("route", out var route) && route.ValueKind == JsonValueKind.String)
        {
            // The app checks every route against its allowlist.
            var url = "starter-surface://open?route=" + Uri.EscapeDataString(route.GetString()!);
            Process.Start(new ProcessStartInfo(url) { UseShellExecute = true })?.Dispose();
        }
    }

    private static void Update(string widgetId)
    {
        WidgetManager.GetDefault().UpdateWidget(new WidgetUpdateRequestOptions(widgetId)
        {
            Template = Template.Value,
            Data = SurfaceCard.DataFor(ReadSnapshot()),
        });
    }

    private static string? ReadSnapshot()
    {
        try
        {
            return File.ReadAllText(SurfaceCard.SnapshotPath);
        }
        catch (IOException)
        {
            return null;
        }
        catch (UnauthorizedAccessException)
        {
            return null;
        }
    }

    private static void WatchSnapshot()
    {
        lock (Gate)
        {
            if (_watcher != null)
            {
                return;
            }

            var folder = Path.GetDirectoryName(SurfaceCard.SnapshotPath)!;
            Directory.CreateDirectory(folder);
            _watcher = new FileSystemWatcher(folder, Path.GetFileName(SurfaceCard.SnapshotPath))
            {
                NotifyFilter = NotifyFilters.LastWrite | NotifyFilters.FileName | NotifyFilters.Size,
            };

            // The app replaces the file by renaming a temporary one over it.
            FileSystemEventHandler changed = (_, _) => UpdateActiveWidgets();
            _watcher.Changed += changed;
            _watcher.Created += changed;
            _watcher.Renamed += (_, _) => UpdateActiveWidgets();
            _watcher.EnableRaisingEvents = true;
        }
    }

    private static void UpdateActiveWidgets()
    {
        string[] active;
        lock (Gate)
        {
            active = ActiveWidgets.ToArray();
        }

        foreach (var widgetId in active)
        {
            Update(widgetId);
        }
    }
}
