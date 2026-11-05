import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/painting.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

/// Draws every launcher icon, splash logo and store banner from the brand's
/// Mark recipe (BRAND.md section 7), so a new app needs one command instead of
/// a designer: `just brand-assets St Starter`.
///
/// It runs under `flutter test` because that is the one place the repo already
/// has a font rasterizer with no extra dependency; it paints with `dart:ui`
/// and writes files, and tests nothing. Without the define it is skipped.
///
/// Sizes come from the files already in the platform folders where a platform
/// dictates them. Generated files are committed; `just splash` then bakes the
/// two logos into the native launch screens.
void main() {
  const write = bool.fromEnvironment('WRITE_BRAND_ASSETS');
  const symbol = String.fromEnvironment('BRAND_SYMBOL', defaultValue: 'St');
  const name = String.fromEnvironment('BRAND_NAME', defaultValue: 'Starter');

  testWidgets('generate brand assets', skip: !write, (tester) async {
    TestWidgetsFlutterBinding.ensureInitialized();
    await tester.runAsync(() async {
      await _loadFonts();
      await _generate(symbol: symbol, name: name);
    });
  });
}

// The brand's fixed logo colors: icon files sit on unknown backgrounds, so the
// default is the white tile (BRAND.md section 7).
const _tile = Color(0xFFFAFAFA);
const _ink = Color(0xFF0A0A0A);
const _square = Color(0xFFF38230);

// The Mark recipe, as fractions of the tile.
const _corner = 0.22;
const _letters = 0.42;
const _tracking = -0.02;
// Fractions of the letters' font size.
const _squareSize = 0.3;
const _squareGap = 0.07;
// Onest's cap height, used to center by ink rather than by line box.
const _capHeight = 0.7;

Future<void> _loadFonts() async {
  Future<void> family(String family, String asset) async {
    final loader = FontLoader(family)..addFont(rootBundle.load(asset));
    await loader.load();
  }

  await family('Onest', 'assets/fonts/Onest/onest-latin-600-normal.ttf');
  await family('Noto Sans Arabic', 'assets/fonts/Noto_Sans_Arabic/NotoSansArabic-SemiBold.ttf');
  await family('Noto Sans SC', 'assets/fonts/Noto_Sans_SC/NotoSansSC.ttf');
}

Future<void> _generate({required String symbol, required String name}) async {
  // Native splash logos: white tile on dark, black tile on light, kept inside
  // the two thirds Android 12 leaves visible.
  await _logo('assets/brand/logo_dark.png', 288, symbol, tile: _tile, ink: _ink);
  await _logo('assets/brand/logo_light.png', 288, symbol, tile: _ink, ink: _tile);

  // iOS: Apple adds the corners and rejects transparency, so full bleed.
  for (final file in _list('ios/Runner/Assets.xcassets/AppIcon.appiconset', '.png')) {
    final size = _pngSize(file).$1;
    await _write(file.path, size, size, (canvas) {
      canvas.drawColor(_tile, BlendMode.src);
      _mark(canvas, Offset.zero, size.toDouble(), symbol, 0.66 / _inkShare(symbol), _ink);
    });
  }

  // macOS: Apple's icon grid leaves a margin around the rounded tile.
  for (final file in _list('macos/Runner/Assets.xcassets/AppIcon.appiconset', '.png')) {
    final size = _pngSize(file).$1;
    await _roundedTile(file.path, size, symbol, inset: 0.0977);
  }

  // Android launchers, plus an adaptive icon for API 26 and up.
  for (final file in Directory('android/app/src/main/res').listSync(recursive: true)) {
    if (file is! File) continue;
    final base = file.uri.pathSegments.last;
    if (base == 'ic_launcher.png' || base == 'ic_launcher_tv.png') {
      await _roundedTile(file.path, _pngSize(file).$1, symbol, inset: 0.04);
    }
  }
  const foreground = 'android/app/src/main/res/drawable-nodpi/ic_launcher_foreground.png';
  File(foreground).parent.createSync(recursive: true);
  await _write(foreground, 432, 432, (canvas) {
    _mark(canvas, Offset.zero, 432, symbol, 0.54 / _inkShare(symbol), _ink);
  });
  File('android/app/src/main/res/mipmap-anydpi-v26/ic_launcher.xml')
    ..createSync(recursive: true)
    ..writeAsStringSync('''
<?xml version="1.0" encoding="utf-8"?>
<adaptive-icon xmlns:android="http://schemas.android.com/apk/res/android">
    <background android:drawable="@color/ic_launcher_background"/>
    <foreground android:drawable="@drawable/ic_launcher_foreground"/>
</adaptive-icon>
''');
  File('android/app/src/main/res/values/ic_launcher_background.xml').writeAsStringSync('''
<?xml version="1.0" encoding="utf-8"?>
<resources>
    <color name="ic_launcher_background">#FAFAFA</color>
</resources>
''');

  // Android TV banners, with the name in each language's own type.
  final banners = {
    'drawable-xhdpi': (name, 'Onest'),
    'drawable-en-xhdpi': (name, 'Onest'),
    'drawable-ar-xhdpi': ('نقطة البداية', 'Noto Sans Arabic'),
    'drawable-zh-rCN-xhdpi': ('起点', 'Noto Sans SC'),
  };
  for (final entry in banners.entries) {
    await _wordmarkPlate(
      'android/app/src/main/res/${entry.key}/tv_banner.png',
      320,
      180,
      entry.value.$1,
      entry.value.$2,
      fontShare: 0.2,
    );
  }

  // Web.
  await _roundedTile('web/favicon.png', 32, symbol, inset: 0);
  for (final size in [192, 512]) {
    await _roundedTile('web/icons/Icon-$size.png', size, symbol, inset: 0);
    await _write('web/icons/Icon-maskable-$size.png', size, size, (canvas) {
      canvas.drawColor(_tile, BlendMode.src);
      _mark(canvas, Offset.zero, size.toDouble(), symbol, 0.54 / _inkShare(symbol), _ink);
    });
  }

  // Linux tray, and the Windows 11 Widgets Board package.
  await _roundedTile('linux/runner/resources/tray_icon.png', 48, symbol, inset: 0);
  const widgetAssets = 'windows/widget_provider/Package/Assets';
  await _roundedTile('$widgetAssets/Square150x150Logo.png', 150, symbol, inset: 0);
  await _roundedTile('$widgetAssets/Square44x44Logo.png', 44, symbol, inset: 0);
  await _roundedTile('$widgetAssets/StoreLogo.png', 50, symbol, inset: 0);

  // Windows: an ICO is a small directory of PNGs.
  await _writeIco('windows/runner/resources/app_icon.ico', symbol, const [16, 32, 48, 256]);

  // tvOS: layers parallax, so the tile, then the letters on their own.
  for (final file in Directory(
    'tvos/Runner/Assets.xcassets/AppIcon.brandassets',
  ).listSync(recursive: true).whereType<File>().where((file) => file.path.endsWith('.png'))) {
    final (width, height) = _pngSize(file);
    final base = file.uri.pathSegments.last;
    if (base.contains('top_shelf')) {
      await _wordmarkPlate(file.path, width, height, name, 'Onest', fontShare: 0.1);
    } else if (base.contains('_back')) {
      await _write(file.path, width, height, (canvas) => canvas.drawColor(_tile, BlendMode.src));
    } else if (base.contains('_front')) {
      await _write(file.path, width, height, (canvas) {
        final extent = height.toDouble();
        _mark(canvas, Offset((width - extent) / 2, 0), extent, symbol, 1, _ink);
      });
    } else {
      await _write(file.path, width, height, (_) {});
    }
  }
}

/// How much of the tile's width the letters and square take at scale 1. Sizes
/// the mark on the surfaces where the platform owns the tile.
double _inkShare(String symbol) {
  final paragraph = _paragraph(symbol, 100 * _letters, 100 * _tracking, _ink);
  return (paragraph.maxIntrinsicWidth + 100 * _letters * (_squareGap + _squareSize)) / 100;
}

ui.Paragraph _paragraph(String text, double fontSize, double tracking, Color color) {
  final builder =
      ui.ParagraphBuilder(ui.ParagraphStyle(fontFamily: 'Onest', fontWeight: FontWeight.w600))
        ..pushStyle(
          ui.TextStyle(
            color: color,
            fontFamily: 'Onest',
            fontWeight: FontWeight.w600,
            fontSize: fontSize,
            letterSpacing: tracking,
          ),
        )
        ..addText(text);
  return builder.build()..layout(const ui.ParagraphConstraints(width: 100000));
}

/// The symbol and square, centered by ink inside a [extent]-wide tile at
/// [origin]. [scale] grows them for surfaces where the platform owns the tile.
void _mark(Canvas canvas, Offset origin, double extent, String symbol, double scale, Color ink) {
  final fontSize = extent * _letters * scale;
  final paragraph = _paragraph(symbol, fontSize, extent * _tracking * scale, ink);
  final square = fontSize * _squareSize;
  final gap = fontSize * _squareGap;
  final inkWidth = paragraph.maxIntrinsicWidth + gap + square;
  final left = origin.dx + (extent - inkWidth) / 2;
  final baseline = origin.dy + extent / 2 + fontSize * _capHeight / 2;
  canvas
    ..drawParagraph(paragraph, Offset(left, baseline - paragraph.alphabeticBaseline))
    ..drawRect(
      Rect.fromLTWH(left + paragraph.maxIntrinsicWidth + gap, baseline - square, square, square),
      Paint()..color = _square,
    );
}

Future<void> _roundedTile(String path, int size, String symbol, {required double inset}) {
  return _write(path, size, size, (canvas) {
    final margin = size * inset;
    final extent = size - 2 * margin;
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(margin, margin, extent, extent),
        Radius.circular(extent * _corner),
      ),
      Paint()..color = _tile,
    );
    _mark(canvas, Offset(margin, margin), extent, symbol, 1, _ink);
  });
}

Future<void> _logo(
  String path,
  int size,
  String symbol, {
  required Color tile,
  required Color ink,
}) {
  return _write(path, size, size, (canvas) {
    final extent = size * 0.5;
    final margin = (size - extent) / 2;
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(margin, margin, extent, extent),
        Radius.circular(extent * _corner),
      ),
      Paint()..color = tile,
    );
    _mark(canvas, Offset(margin, margin), extent, symbol, 1, ink);
  });
}

/// The wordmark on the page color, for surfaces that show a wide picture.
Future<void> _wordmarkPlate(
  String path,
  int width,
  int height,
  String text,
  String family, {
  required double fontShare,
}) {
  return _write(path, width, height, (canvas) {
    canvas.drawColor(_ink, BlendMode.src);
    final fontSize = height * fontShare;
    final rtl = family == 'Noto Sans Arabic';
    final builder =
        ui.ParagraphBuilder(
            ui.ParagraphStyle(
              fontFamily: family,
              fontWeight: FontWeight.w600,
              textDirection: rtl ? TextDirection.rtl : TextDirection.ltr,
            ),
          )
          ..pushStyle(
            ui.TextStyle(
              color: _tile,
              fontFamily: family,
              fontWeight: FontWeight.w600,
              fontSize: fontSize,
              letterSpacing: fontSize * _tracking,
            ),
          )
          ..addText(text);
    final paragraph = builder.build()..layout(ui.ParagraphConstraints(width: width.toDouble()));
    final textWidth = paragraph.maxIntrinsicWidth;
    final square = fontSize * 0.36;
    final gap = fontSize * 0.07;
    final inkWidth = textWidth + gap + square;
    final left = (width - inkWidth) / 2;
    final baseline = height / 2 + fontSize * _capHeight / 2;
    // The line box fills the constraint; only its ink position matters, and
    // that depends on the paragraph's own direction.
    final textLeft = rtl ? left + gap + square - (width - textWidth) : left;
    canvas
      ..drawParagraph(paragraph, Offset(textLeft, baseline - paragraph.alphabeticBaseline))
      ..drawRect(
        Rect.fromLTWH(
          rtl ? left : left + textWidth + gap,
          baseline - square,
          square,
          square,
        ),
        Paint()..color = _square,
      );
  });
}

Future<Uint8List> _render(int width, int height, void Function(Canvas canvas) paint) async {
  final recorder = ui.PictureRecorder();
  paint(Canvas(recorder));
  final image = await recorder.endRecording().toImage(width, height);
  final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
  return bytes!.buffer.asUint8List();
}

Future<void> _write(String path, int width, int height, void Function(Canvas canvas) paint) async {
  File(path).writeAsBytesSync(await _render(width, height, paint));
}

Future<void> _writeIco(String path, String symbol, List<int> sizes) async {
  final pngs = <Uint8List>[];
  for (final size in sizes) {
    pngs.add(
      await _render(size, size, (canvas) {
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromLTWH(0, 0, size.toDouble(), size.toDouble()),
            Radius.circular(size * _corner),
          ),
          Paint()..color = _tile,
        );
        _mark(canvas, Offset.zero, size.toDouble(), symbol, 1, _ink);
      }),
    );
  }
  final out = BytesBuilder();
  final header = ByteData(6)
    ..setUint16(2, 1, Endian.little)
    ..setUint16(4, sizes.length, Endian.little);
  out.add(header.buffer.asUint8List());
  var offset = 6 + 16 * sizes.length;
  for (var i = 0; i < sizes.length; i++) {
    final entry = ByteData(16)
      ..setUint8(0, sizes[i] == 256 ? 0 : sizes[i])
      ..setUint8(1, sizes[i] == 256 ? 0 : sizes[i])
      ..setUint16(4, 1, Endian.little)
      ..setUint16(6, 32, Endian.little)
      ..setUint32(8, pngs[i].length, Endian.little)
      ..setUint32(12, offset, Endian.little);
    out.add(entry.buffer.asUint8List());
    offset += pngs[i].length;
  }
  pngs.forEach(out.add);
  File(path).writeAsBytesSync(out.takeBytes());
}

Iterable<File> _list(String directory, String extension) {
  return Directory(directory).listSync().whereType<File>().where((file) {
    return file.path.endsWith(extension);
  });
}

(int, int) _pngSize(File file) {
  final header = ByteData.sublistView(file.readAsBytesSync(), 16, 24);
  return (header.getUint32(0), header.getUint32(4));
}
