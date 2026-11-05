package com.example.surfacecore;

import java.nio.charset.StandardCharsets;

/**
 * Java view of libsurface_core.so.
 *
 * <p>The native methods trade UTF-8 byte arrays, because JNI's string functions use Modified
 * UTF-8 and would corrupt an emoji. Do not rename this class or its package without renaming
 * the symbols in src/android.rs.
 */
public final class SurfaceCore {
  static {
    System.loadLibrary("surface_core");
  }

  private SurfaceCore() {}

  public static String version() {
    return text(nativeVersion());
  }

  /** Blocks for up to 5 seconds. Never call it on the main thread. */
  public static String fetchSnapshot(String baseUrl, String authTokenOrNull) {
    return text(nativeFetchSnapshot(bytes(baseUrl), bytes(authTokenOrNull)));
  }

  /** Blocks for up to 5 seconds. Never call it on the main thread. */
  public static String probeUrl(String url) {
    return text(nativeProbeUrl(bytes(url)));
  }

  public static String formatPercent(double progress) {
    return text(nativeFormatPercent(progress));
  }

  private static byte[] bytes(String value) {
    return value == null ? null : value.getBytes(StandardCharsets.UTF_8);
  }

  private static String text(byte[] value) {
    return new String(value, StandardCharsets.UTF_8);
  }

  private static native byte[] nativeVersion();

  private static native byte[] nativeFetchSnapshot(byte[] baseUrl, byte[] authTokenOrNull);

  private static native byte[] nativeProbeUrl(byte[] url);

  private static native byte[] nativeFormatPercent(double progress);
}
