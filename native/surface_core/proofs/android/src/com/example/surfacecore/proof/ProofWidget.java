package com.example.surfacecore.proof;

import android.appwidget.AppWidgetManager;
import android.appwidget.AppWidgetProvider;
import android.content.BroadcastReceiver;
import android.content.Context;
import android.content.Intent;
import android.os.Debug;
import android.util.Log;
import com.example.surfacecore.SurfaceCore;
import java.io.BufferedReader;
import java.io.FileReader;
import java.io.IOException;
import java.net.HttpURLConnection;
import java.net.URL;
import java.util.Arrays;
import java.util.Locale;
import org.json.JSONException;
import org.json.JSONObject;

/**
 * Throwaway proof. A real AppWidgetProvider subclass, run the way the system runs one: through
 * a broadcast in a process with no activity and no Flutter engine.
 */
public final class ProofWidget extends AppWidgetProvider {
  private static final String TAG = "SurfaceCoreProof";
  private static final String RUN_ACTION = "com.example.surfacecore.proof.RUN";

  private Intent intent;

  @Override
  public void onReceive(Context context, Intent received) {
    intent = received;
    if (RUN_ACTION.equals(received.getAction())) {
      onUpdate(context, AppWidgetManager.getInstance(context),
          received.getIntArrayExtra(AppWidgetManager.EXTRA_APPWIDGET_IDS));
      return;
    }
    super.onReceive(context, received);
  }

  @Override
  public void onUpdate(Context context, AppWidgetManager manager, int[] appWidgetIds) {
    final BroadcastReceiver.PendingResult pending = goAsync();
    final Intent extras = intent;
    log("onUpdate ids=" + Arrays.toString(appWidgetIds) + " thread=" + Thread.currentThread().getName());
    new Thread(
            () -> {
              try {
                run(extras);
                log("RESULT ok");
              } catch (Throwable error) {
                log("RESULT FAILED " + error);
              } finally {
                pending.finish();
              }
            },
            "surface-core-proof")
        .start();
  }

  private static void run(Intent extras) throws Exception {
    String mode = extras.getStringExtra("mode");
    String base = extras.getStringExtra("base");
    String token = extras.getStringExtra("token");
    String https = extras.getStringExtra("https");
    String badCert = extras.getStringExtra("badcert");
    log("PLATFORM android abi=" + android.os.Build.SUPPORTED_ABIS[0]
        + " sdk=" + android.os.Build.VERSION.SDK_INT + " mode=" + mode);

    if ("baseline".equals(mode)) {
      log(memory("baseline"));
      return;
    }

    log(memory("before_load"));
    double loadMs = millis(() -> SurfaceCore.version());
    log(String.format(Locale.ROOT, "LATENCY load_library_first_call=%.2f ms", loadMs));
    log(memory("after_load"));

    if ("fetch".equals(mode)) {
      String[] output = new String[1];
      double elapsed = millis(() -> output[0] = SurfaceCore.fetchSnapshot(base, token));
      log(memory("after_fetch"));
      log(String.format(Locale.ROOT, "LATENCY cold_fetch=%.2f ms", elapsed));
      log("OUTPUT " + output[0]);
      return;
    }

    if ("https".equals(mode)) {
      String[] output = new String[1];
      double elapsed = millis(() -> output[0] = SurfaceCore.probeUrl(https));
      log(memory("after_https"));
      log(String.format(Locale.ROOT, "LATENCY cold_https=%.2f ms", elapsed));
      log("OUTPUT " + output[0]);
      return;
    }

    if ("soak".equals(mode)) {
      int count = 200;
      for (int index = 1; index <= count; index++) {
        SurfaceCore.fetchSnapshot(base, null);
        if (index % (count / 4) == 0) {
          log(memory("after_" + index));
        }
      }
      return;
    }

    check(!SurfaceCore.version().isEmpty(), "version " + SurfaceCore.version());
    check(SurfaceCore.formatPercent(0.72).equals("72%"), "format_percent 0.72 -> 72%");
    check(SurfaceCore.formatPercent(Double.NaN).equals("--"), "format_percent_nan");

    String signedOutText = SurfaceCore.fetchSnapshot(base, null);
    log("OUTPUT signed_out " + signedOutText);
    JSONObject signedOut = new JSONObject(signedOutText);
    check(signedOut.getInt("schema") == 1, "signed_out_schema");
    check(!signedOut.has("error"), "signed_out_no_error");
    check("Welcome to the starter.".equals(signedOut.getString("subtitle")), "signed_out_mapped");

    String signedInText = SurfaceCore.fetchSnapshot(base, token);
    log("OUTPUT signed_in " + signedInText);
    JSONObject signedIn = new JSONObject(signedInText);
    check(!signedIn.has("error"), "signed_in_no_error");
    check("Proof 🚀".equals(signedIn.getString("title")), "signed_in_utf8_round_trip");

    JSONObject rejected = new JSONObject(SurfaceCore.fetchSnapshot(base, "not-a-real-token"));
    check("warning".equals(rejected.getString("status")), "rejected_token_warning");

    JSONObject refused = new JSONObject(SurfaceCore.fetchSnapshot("http://127.0.0.1:1", null));
    check("network".equals(errorCode(refused)), "refused_is_network_error");

    JSONObject nullBase = new JSONObject(SurfaceCore.fetchSnapshot(null, null));
    check("invalid_argument".equals(errorCode(nullBase)), "null_base_url_no_crash");

    String httpsText = SurfaceCore.probeUrl(https);
    log("OUTPUT https " + httpsText);
    check(new JSONObject(httpsText).getBoolean("ok"), "https_public_host_ok");

    String overTls = SurfaceCore.fetchSnapshot(https, null);
    log("OUTPUT snapshot_over_tls " + overTls);
    check(new JSONObject(overTls).getJSONObject("error").has("httpStatus"),
        "snapshot_path_completes_tls status came over TLS");

    JSONObject bad = new JSONObject(SurfaceCore.probeUrl(badCert));
    for (int attempt = 0; attempt < 5 && "timeout".equals(errorCode(bad)); attempt++) {
      bad = new JSONObject(SurfaceCore.probeUrl(badCert));
    }
    log("OUTPUT bad_cert " + bad);
    check("tls".equals(errorCode(bad)), "bad_certificate_rejected");

    log("CLEARTEXT HttpURLConnection says: " + platformCleartext(base));

    double[] percent = new double[1000];
    for (int index = 0; index < percent.length; index++) {
      percent[index] = millis(() -> SurfaceCore.formatPercent(0.5));
    }
    log("LATENCY format_percent " + stats(percent));

    double[] local = new double[30];
    for (int index = 0; index < local.length; index++) {
      local[index] = millis(() -> SurfaceCore.fetchSnapshot(base, null));
    }
    log("LATENCY local_fetch " + stats(local));

    double[] tls = new double[5];
    for (int index = 0; index < tls.length; index++) {
      tls[index] = millis(() -> SurfaceCore.probeUrl(https));
    }
    log("LATENCY https_probe " + stats(tls));
    log(memory("end_of_full"));
  }

  /** The platform client obeys the network security config. The library's raw sockets do not. */
  private static String platformCleartext(String base) {
    HttpURLConnection connection = null;
    try {
      connection = (HttpURLConnection) new URL(base + "/healthz").openConnection();
      connection.setConnectTimeout(3000);
      return "allowed, status " + connection.getResponseCode();
    } catch (IOException error) {
      return "blocked: " + error.getMessage();
    } finally {
      if (connection != null) {
        connection.disconnect();
      }
    }
  }

  private static String errorCode(JSONObject snapshot) throws JSONException {
    return snapshot.has("error") && !snapshot.isNull("error")
        ? snapshot.getJSONObject("error").getString("code")
        : "";
  }

  private static void check(boolean condition, String label) {
    log((condition ? "PASS " : "FAIL ") + label);
    if (!condition) {
      throw new IllegalStateException(label);
    }
  }

  private static double millis(Runnable body) {
    long start = System.nanoTime();
    body.run();
    return (System.nanoTime() - start) / 1_000_000.0;
  }

  private static String stats(double[] samples) {
    double[] sorted = samples.clone();
    Arrays.sort(sorted);
    return String.format(Locale.ROOT, "n=%d min=%.2f median=%.2f p95=%.2f max=%.2f ms",
        sorted.length, sorted[0], sorted[sorted.length / 2],
        sorted[Math.min(sorted.length - 1, sorted.length * 95 / 100)],
        sorted[sorted.length - 1]);
  }

  /** VmHWM is peak resident. Native PSS is the part of the process the library can change. */
  private static String memory(String label) throws IOException {
    long rss = 0;
    long peak = 0;
    try (BufferedReader reader = new BufferedReader(new FileReader("/proc/self/status"))) {
      for (String line = reader.readLine(); line != null; line = reader.readLine()) {
        if (line.startsWith("VmRSS:")) {
          rss = kilobytes(line);
        } else if (line.startsWith("VmHWM:")) {
          peak = kilobytes(line);
        }
      }
    }
    Debug.MemoryInfo info = new Debug.MemoryInfo();
    Debug.getMemoryInfo(info);
    return String.format(Locale.ROOT,
        "MEM %s rss_mb=%.2f rss_peak_mb=%.2f pss_total_mb=%.2f pss_native_mb=%.2f", label,
        rss / 1024.0, peak / 1024.0, info.getTotalPss() / 1024.0, info.nativePss / 1024.0);
  }

  private static long kilobytes(String line) {
    return Long.parseLong(line.replaceAll("[^0-9]", ""));
  }

  private static void log(String message) {
    Log.i(TAG, message);
  }
}
