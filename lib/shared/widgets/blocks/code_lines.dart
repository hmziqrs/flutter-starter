import 'package:flutter/material.dart';
import 'package:forui/forui.dart';
import 'package:starter/shared/theme/brand_tokens.dart';

/// How a span of code is colored, following the brand's `--code-*` roles
/// (BRAND.md s4 "Code and charts").
enum CodeTokenKind {
  /// Keywords and modifiers — the primary, where the brand lives in code.
  keyword,

  /// Function and type names — info blue.
  function,

  /// String literals — success green.
  string,

  /// Numbers and constants (`true`, `false`, `null`) — purple.
  number,

  /// Comments — muted.
  comment,

  /// Punctuation and operators — muted.
  punctuation,

  /// Everything else — the normal foreground.
  plain,
}

/// One colored span of a code line.
@immutable
class CodeToken {
  const CodeToken(this.text, this.kind);

  final String text;

  final CodeTokenKind kind;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CodeToken &&
          runtimeType == other.runtimeType &&
          text == other.text &&
          kind == other.kind;

  @override
  int get hashCode => Object.hash(text, kind);

  @override
  String toString() => 'CodeToken($text, $kind)';
}

const Set<String> _keywords = <String>{
  'abstract',
  'as',
  'assert',
  'async',
  'await',
  'base',
  'break',
  'case',
  'catch',
  'class',
  'const',
  'continue',
  'covariant',
  'default',
  'deferred',
  'do',
  'else',
  'enum',
  'export',
  'extends',
  'extension',
  'external',
  'factory',
  'final',
  'finally',
  'for',
  'get',
  'hide',
  'if',
  'implements',
  'import',
  'in',
  'interface',
  'is',
  'late',
  'library',
  'mixin',
  'new',
  'on',
  'operator',
  'part',
  'required',
  'rethrow',
  'return',
  'sealed',
  'set',
  'show',
  'static',
  'super',
  'switch',
  'sync',
  'this',
  'throw',
  'try',
  'typedef',
  'var',
  'void',
  'when',
  'while',
  'with',
  'yield',
};

const Set<String> _constants = <String>{'false', 'true', 'null'};

bool _isIdentifierStart(int rune) =>
    (rune >= 0x61 && rune <= 0x7A) || // a-z
    (rune >= 0x41 && rune <= 0x5A) || // A-Z
    rune == 0x5F ||
    rune == 0x24; // _ or $

bool _isIdentifierPart(int rune) => _isIdentifierStart(rune) || (rune >= 0x30 && rune <= 0x39);

bool _isDigit(int rune) => rune >= 0x30 && rune <= 0x39;

bool _isHexDigit(int rune) => _isDigit(rune) || ((rune | 0x20) >= 0x61 && (rune | 0x20) <= 0x66);

/// A small Dart tokenizer that stands in for Shiki, which has no Flutter
/// equivalent.
///
/// It maps whole lines onto the brand's `--code-*` roles: keywords in the
/// primary, function and type names in blue, strings in green, numbers and
/// constants in purple, comments and punctuation in muted. A line whose
/// first non-blank characters are `//` colors entirely as a comment; inline
/// `//` comments start where they begin. It is a faithful substitute for
/// the common cases — declarations, calls, literals — not a full parser,
/// so exotic syntax falls back to the plain foreground.
List<CodeToken> tokenizeDartLine(String line) {
  if (line.trimLeft().startsWith('//')) {
    return <CodeToken>[CodeToken(line, CodeTokenKind.comment)];
  }

  final tokens = <CodeToken>[];
  final buffer = StringBuffer();
  var index = 0;

  void flush(CodeTokenKind kind) {
    if (buffer.isNotEmpty) {
      tokens.add(CodeToken(buffer.toString(), kind));
      buffer.clear();
    }
  }

  while (index < line.length) {
    final rune = line.codeUnitAt(index);

    // Comments take the rest of the line.
    if (rune == 0x2F && index + 1 < line.length && line.codeUnitAt(index + 1) == 0x2F) {
      flush(CodeTokenKind.punctuation);
      tokens.add(CodeToken(line.substring(index), CodeTokenKind.comment));
      break;
    }

    // Strings, including their quotes; a leading `r` stays plain.
    if (rune == 0x27 || rune == 0x22) {
      flush(CodeTokenKind.punctuation);
      final quote = rune;
      final start = index;
      index++;
      while (index < line.length) {
        if (line.codeUnitAt(index) == 0x5C) {
          index += 2;
          continue;
        }
        if (line.codeUnitAt(index) == quote) {
          index++;
          break;
        }
        index++;
      }
      final end = index < line.length ? index : line.length;
      tokens.add(CodeToken(line.substring(start, end), CodeTokenKind.string));
      continue;
    }

    // Numbers: digits, or a dot starting a fraction.
    if (_isDigit(rune) ||
        (rune == 0x2E && index + 1 < line.length && _isDigit(line.codeUnitAt(index + 1)))) {
      flush(CodeTokenKind.punctuation);
      final start = index;
      final hex =
          rune == 0x30 && index + 1 < line.length && (line.codeUnitAt(index + 1) | 0x20) == 0x78;
      index += hex ? 2 : 1;
      while (index < line.length &&
          (hex
              ? _isHexDigit(line.codeUnitAt(index))
              : _isDigit(line.codeUnitAt(index)) ||
                    line.codeUnitAt(index) == 0x2E ||
                    line.codeUnitAt(index) == 0x5F ||
                    (line.codeUnitAt(index) | 0x20) == 0x65 ||
                    line.codeUnitAt(index) == 0x2B ||
                    line.codeUnitAt(index) == 0x2D)) {
        index++;
      }
      tokens.add(CodeToken(line.substring(start, index), CodeTokenKind.number));
      continue;
    }

    // Identifiers and keywords.
    if (_isIdentifierStart(rune)) {
      flush(CodeTokenKind.punctuation);
      final start = index;
      index++;
      while (index < line.length && _isIdentifierPart(line.codeUnitAt(index))) {
        index++;
      }
      final word = line.substring(start, index);
      if (_keywords.contains(word)) {
        tokens.add(CodeToken(word, CodeTokenKind.keyword));
      } else if (_constants.contains(word)) {
        tokens.add(CodeToken(word, CodeTokenKind.number));
      } else if (_startsWithPascalCase(word)) {
        tokens.add(CodeToken(word, CodeTokenKind.function));
      } else if (index < line.length && line.codeUnitAt(index) == 0x28) {
        tokens.add(CodeToken(word, CodeTokenKind.function));
      } else {
        tokens.add(CodeToken(word, CodeTokenKind.plain));
      }
      continue;
    }

    // Everything else is punctuation, operators, and the space between;
    // the buffer colors all of it muted.
    buffer.writeCharCode(rune);
    index++;
  }
  flush(CodeTokenKind.punctuation);
  return tokens;
}

bool _startsWithPascalCase(String word) {
  final first = word.codeUnitAt(0);
  // Type names read in the function color; the two share it in the brand's
  // code roles, so any capitalized identifier goes blue.
  return first >= 0x41 && first <= 0x5A;
}

/// Renders Dart source with the brand's code colors (BRAND.md s8 "Code
/// block"): JetBrains Mono at 13, `--code-foreground` text, tokenized by
/// [tokenizeDartLine].
class AppCodeLines extends StatelessWidget {
  const AppCodeLines({required this.source, this.fontSize = 13, super.key});

  /// The code to render; split on newlines, so empty lines are kept.
  final String source;

  final double fontSize;

  @override
  Widget build(BuildContext context) {
    final theme = context.theme;
    final colors = theme.colors;
    final base = TextStyle(
      fontFamily: 'JetBrains Mono',
      fontSize: fontSize,
      height: 1.7,
      color: colors.foreground,
    );
    final lines = source.split('\n');
    return Text.rich(
      TextSpan(
        children: <InlineSpan>[
          for (var lineIndex = 0; lineIndex < lines.length; lineIndex++) ...<InlineSpan>[
            if (lineIndex > 0) const TextSpan(text: '\n'),
            for (final token in tokenizeDartLine(lines[lineIndex]))
              TextSpan(
                text: token.text,
                style: TextStyle(color: _tokenColor(colors, theme.brand, token.kind)),
              ),
          ],
        ],
        style: base,
      ),
    );
  }

  Color _tokenColor(FColors colors, AppBrandColors brand, CodeTokenKind kind) => switch (kind) {
    CodeTokenKind.keyword => colors.primary,
    CodeTokenKind.function => brand.info,
    CodeTokenKind.string => brand.success,
    CodeTokenKind.number => brand.purple,
    CodeTokenKind.comment || CodeTokenKind.punctuation => colors.mutedForeground,
    CodeTokenKind.plain => colors.foreground,
  };
}
