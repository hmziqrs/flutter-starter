# Canonical Flutter goldens

These baselines implement the intentional 13-case pairwise matrix in
`plans/completed/initial_ui.md` section 16.3.

The reviewed baseline environment is:

- the GitHub Actions `macos-26` runner image (macOS 26.x arm64). Pixel-exact
  comparison is sensitive to the macOS minor version, so the CI runner is the
  authoritative baseline environment; regenerate via the "Regenerate goldens"
  workflow (`.github/workflows/regen-goldens.yml`) after any image bump, then
  review the changed baselines before committing.
- Flutter 3.44.7 stable, framework `84fc5cbb22`;
- engine `7076f47b1d1a3a0edfd8837b17dc15be6abab661`;
- the `flutter test` Skia renderer and sRGB output;
- device-pixel ratio 1;
- source-controlled Noto Sans, Noto Sans Arabic, and Noto Sans SC fonts, plus
  the locked ForUI Lucide icon font from the package asset bundle.

The harness explicitly pins logical viewport, locale, brightness, application
font multiplier, nonlinear system text scaler, insets, focus, pointer policy,
and disabled animation state. It renders the real typed development-gallery
cases at a documented 500 ms settled timestamp. Baselines use Flutter's exact
golden comparator; there is no broad pixel tolerance.

Generate or intentionally review updates only on the `macos-26` CI runner
(authoritative baseline env) — easiest via the "Regenerate goldens" workflow,
which uploads the baselines for review before commit:

```sh
flutter test test/goldens/canonical_matrix_golden_test.dart --update-goldens
flutter test test/goldens/canonical_matrix_golden_test.dart
```

Other OS and renderer combinations should run widget/accessibility coverage,
not compare against these platform-specific pixels.
