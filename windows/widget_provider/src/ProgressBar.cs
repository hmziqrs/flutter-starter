using System.IO.Compression;

namespace Starter.Widgets;

/// <summary>
/// Draws the progress bar as a PNG data URI. Adaptive Cards have no thin bar, and no
/// way to name a colour, so a card shows this image instead.
/// </summary>
internal static class ProgressBar
{
    // Twice the size of a medium widget's content, for high DPI screens.
    private const int Width = 536;
    private const int Height = 8;

    public static string DataUri(int percent, uint done, uint left)
    {
        var filled = Width * Math.Clamp(percent, 0, 100) / 100;
        using var pixels = new MemoryStream();
        using (var compressed = new ZLibStream(pixels, CompressionLevel.Optimal, leaveOpen: true))
        {
            for (var y = 0; y < Height; y++)
            {
                compressed.WriteByte(0); // No row filter.
                for (var x = 0; x < Width; x++)
                {
                    var colour = x < filled ? done : left;
                    compressed.WriteByte((byte)(colour >> 16));
                    compressed.WriteByte((byte)(colour >> 8));
                    compressed.WriteByte((byte)colour);
                }
            }
        }

        using var png = new MemoryStream();
        png.Write(new byte[] { 0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A });
        var header = new byte[13];
        WriteBigEndian(header, 0, Width);
        WriteBigEndian(header, 4, Height);
        header[8] = 8; // Bits per channel.
        header[9] = 2; // RGB.
        WriteChunk(png, "IHDR", header);
        WriteChunk(png, "IDAT", pixels.ToArray());
        WriteChunk(png, "IEND", Array.Empty<byte>());
        return "data:image/png;base64," + Convert.ToBase64String(png.ToArray());
    }

    private static void WriteChunk(Stream output, string type, byte[] data)
    {
        var chunk = new byte[4 + data.Length];
        for (var i = 0; i < 4; i++)
        {
            chunk[i] = (byte)type[i];
        }

        data.CopyTo(chunk, 4);
        var number = new byte[4];
        WriteBigEndian(number, 0, (uint)data.Length);
        output.Write(number);
        output.Write(chunk);
        WriteBigEndian(number, 0, Crc32(chunk));
        output.Write(number);
    }

    private static void WriteBigEndian(byte[] target, int offset, uint value)
    {
        target[offset] = (byte)(value >> 24);
        target[offset + 1] = (byte)(value >> 16);
        target[offset + 2] = (byte)(value >> 8);
        target[offset + 3] = (byte)value;
    }

    private static uint Crc32(byte[] data)
    {
        var crc = 0xFFFFFFFFu;
        foreach (var value in data)
        {
            crc ^= value;
            for (var bit = 0; bit < 8; bit++)
            {
                crc = (crc & 1) != 0 ? (crc >> 1) ^ 0xEDB88320u : crc >> 1;
            }
        }

        return ~crc;
    }
}
