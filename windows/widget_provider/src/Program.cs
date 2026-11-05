using System.Runtime.InteropServices;
using Starter.Widgets;

// Prints the card data for a snapshot file, or for the stored snapshot, without
// touching COM or the Windows App SDK. Lets a machine with no Widgets Board check
// what a widget would be sent.
if (args.Length > 0 && args[0] == "--print-card-data")
{
    var path = args.Length > 1 ? args[1] : SurfaceCard.SnapshotPath;
    File.WriteAllText(
        args.Length > 2 ? args[2] : "card-data.json",
        SurfaceCard.DataFor(File.Exists(path) ? File.ReadAllText(path) : null));
    return;
}

WinRT.ComWrappersSupport.InitializeComWrappers();
var classId = Guid.Parse(WidgetProvider.ClassId);
var factory = new WidgetProviderFactory<WidgetProvider>();
const uint ClsctxLocalServer = 0x4;
const uint RegclsMultipleUse = 0x1;
Marshal.ThrowExceptionForHR(
    NativeMethods.CoRegisterClassObject(classId, factory, ClsctxLocalServer, RegclsMultipleUse, out var cookie));

try
{
    // The host starts this process when a widget needs it. It ends once the last
    // pinned widget is gone.
    WidgetProvider.NoWidgetsLeft.WaitOne();
}
finally
{
    _ = NativeMethods.CoRevokeClassObject(cookie);
    GC.KeepAlive(factory);
}

internal static partial class NativeMethods
{
    [DllImport("ole32.dll")]
    public static extern int CoRegisterClassObject(
        [MarshalAs(UnmanagedType.LPStruct)] Guid classId,
        [MarshalAs(UnmanagedType.IUnknown)] object factory,
        uint context,
        uint flags,
        out uint cookie);

    [DllImport("ole32.dll")]
    public static extern int CoRevokeClassObject(uint cookie);
}
