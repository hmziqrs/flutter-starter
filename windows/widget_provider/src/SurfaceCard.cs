using System.Text.Json;
using System.Text.Json.Nodes;

namespace Starter.Widgets;

/// <summary>Turns a stored snapshot into the data Templates\surface.json binds to.</summary>
public static class SurfaceCard
{
    private const int KnownSchema = 1;

    // Medium widgets have room for this many buttons.
    private const int MediumActions = 2;

    // docs/native_surfaces.md. Cards cannot name a colour, but they can show an image.
    private const uint DarkAccent = 0xF38230;
    private const uint DarkLine = 0x262626;
    private const uint LightAccent = 0xAA530A;
    private const uint LightLine = 0xE5E5E5;

    public static string SnapshotPath { get; } = Path.Combine(
        Environment.GetFolderPath(Environment.SpecialFolder.LocalApplicationData),
        "com.example.starter",
        "native_surfaces.json");

    /// <summary>
    /// The card data for snapshot JSON. Null, malformed or newer JSON gets the
    /// fallback from the contract.
    /// </summary>
    public static string DataFor(string? json)
    {
        var card = Read(json) ?? Fallback();
        return card.ToJsonString();
    }

    private static JsonObject Fallback() => Card(
        title: "Starter",
        subtitle: "Open the app to get started",
        value: null,
        valueLabel: null,
        progress: null,
        status: "idle",
        route: null,
        actions: new JsonArray());

    private static JsonObject? Read(string? json)
    {
        if (string.IsNullOrWhiteSpace(json))
        {
            return null;
        }

        try
        {
            using var document = JsonDocument.Parse(json);
            var root = document.RootElement;
            if (root.ValueKind != JsonValueKind.Object
                || !root.TryGetProperty("schema", out var schema)
                || schema.ValueKind != JsonValueKind.Number
                || schema.GetDouble() > KnownSchema
                || string.IsNullOrEmpty(Text(root, "title")))
            {
                return null;
            }

            var actions = new JsonArray();
            if (root.TryGetProperty("actions", out var list) && list.ValueKind == JsonValueKind.Array)
            {
                foreach (var action in list.EnumerateArray())
                {
                    var label = action.ValueKind == JsonValueKind.Object ? Text(action, "label") : null;
                    var route = action.ValueKind == JsonValueKind.Object ? Text(action, "route") : null;
                    if (!string.IsNullOrEmpty(label) && !string.IsNullOrEmpty(route))
                    {
                        actions.Add(new JsonObject { ["label"] = label, ["route"] = route });
                    }
                }
            }

            double? progress = root.TryGetProperty("progress", out var figure)
                && figure.ValueKind == JsonValueKind.Number
                ? Math.Clamp(figure.GetDouble(), 0, 1)
                : null;

            return Card(
                Text(root, "title")!,
                Text(root, "subtitle"),
                Text(root, "value"),
                Text(root, "valueLabel"),
                progress,
                Text(root, "status") ?? "idle",
                Text(root, "route"),
                actions);
        }
        catch (JsonException)
        {
            return null;
        }
    }

    private static string? Text(JsonElement parent, string name) =>
        parent.TryGetProperty(name, out var value) && value.ValueKind == JsonValueKind.String
            ? value.GetString()
            : null;

    private static JsonObject Card(
        string title,
        string? subtitle,
        string? value,
        string? valueLabel,
        double? progress,
        string status,
        string? route,
        JsonArray actions)
    {
        var done = progress is { } fraction ? (int)Math.Round(fraction * 100) : 0;
        var firstActions = new JsonArray();
        foreach (var action in actions.Take(MediumActions))
        {
            firstActions.Add(action!.DeepClone());
        }

        return new JsonObject
        {
            ["title"] = title,
            ["subtitle"] = subtitle ?? string.Empty,
            ["hasSubtitle"] = !string.IsNullOrEmpty(subtitle),
            ["value"] = value ?? string.Empty,
            ["hasValue"] = !string.IsNullOrEmpty(value),
            ["valueLabel"] = valueLabel ?? string.Empty,
            ["hasValueLabel"] = !string.IsNullOrEmpty(valueLabel),
            ["hasProgress"] = progress != null,

            ["progressDone"] = done.ToString(),
            ["progressDark"] = ProgressBar.DataUri(done, DarkAccent, DarkLine),
            ["progressLight"] = ProgressBar.DataUri(done, LightAccent, LightLine),
            ["statusColor"] = status switch
            {
                "active" => "Accent",
                "success" => "Good",
                "warning" => "Warning",
                "failure" => "Attention",
                _ => "Default",
            },
            ["route"] = route ?? string.Empty,
            ["hasRoute"] = !string.IsNullOrEmpty(route),
            ["actions"] = actions,
            ["hasActions"] = actions.Count > 0,
            ["firstActions"] = firstActions,
        };
    }
}
