using System.Runtime.InteropServices;
using Microsoft.Windows.Widgets.Providers;
using WinRT;

namespace Starter.Widgets;

[ComImport]
[ComVisible(false)]
[InterfaceType(ComInterfaceType.InterfaceIsIUnknown)]
[Guid("00000001-0000-0000-C000-000000000046")]
internal interface IClassFactory
{
    [PreserveSig]
    int CreateInstance(IntPtr outer, ref Guid interfaceId, out IntPtr instance);

    [PreserveSig]
    int LockServer(bool locked);
}

/// <summary>Hands COM a provider, as Microsoft's widget provider walkthrough does.</summary>
[ComVisible(true)]
internal sealed class WidgetProviderFactory<T> : IClassFactory
    where T : IWidgetProvider, new()
{
    private const int ClassENoAggregation = -2147221232;

    public int CreateInstance(IntPtr outer, ref Guid interfaceId, out IntPtr instance)
    {
        instance = IntPtr.Zero;
        if (outer != IntPtr.Zero)
        {
            return ClassENoAggregation;
        }

        var provider = IntPtr.Zero;
        try
        {
            provider = MarshalInspectable<IWidgetProvider>.FromManaged(new T());
            return Marshal.QueryInterface(provider, in interfaceId, out instance);
        }
        catch (Exception exception)
        {
            return Marshal.GetHRForException(exception);
        }
        finally
        {
            if (provider != IntPtr.Zero)
            {
                Marshal.Release(provider);
            }
        }
    }

    int IClassFactory.LockServer(bool locked) => 0;
}
