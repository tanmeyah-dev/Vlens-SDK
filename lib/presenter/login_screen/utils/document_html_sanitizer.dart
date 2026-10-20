/// Prepares backend contract HTML for the in-app WebView.
library;

/// Word exports Arabic as presentation forms (U+FE70–U+FEFC).
/// Those glyphs do not re-join, so a narrow cell prints one letter per line.
/// NFKC maps them back to normal Arabic so the line can shape.
const Map<int, String> arabicPresentationForms = <int, String>{
  0xFE70: '\u0020\u064B',
  0xFE71: '\u0640\u064B',
  0xFE72: '\u0020\u064C',
  0xFE74: '\u0020\u064D',
  0xFE76: '\u0020\u064E',
  0xFE77: '\u0640\u064E',
  0xFE78: '\u0020\u064F',
  0xFE79: '\u0640\u064F',
  0xFE7A: '\u0020\u0650',
  0xFE7B: '\u0640\u0650',
  0xFE7C: '\u0020\u0651',
  0xFE7D: '\u0640\u0651',
  0xFE7E: '\u0020\u0652',
  0xFE7F: '\u0640\u0652',
  0xFE80: '\u0621',
  0xFE81: '\u0622',
  0xFE82: '\u0622',
  0xFE83: '\u0623',
  0xFE84: '\u0623',
  0xFE85: '\u0624',
  0xFE86: '\u0624',
  0xFE87: '\u0625',
  0xFE88: '\u0625',
  0xFE89: '\u0626',
  0xFE8A: '\u0626',
  0xFE8B: '\u0626',
  0xFE8C: '\u0626',
  0xFE8D: '\u0627',
  0xFE8E: '\u0627',
  0xFE8F: '\u0628',
  0xFE90: '\u0628',
  0xFE91: '\u0628',
  0xFE92: '\u0628',
  0xFE93: '\u0629',
  0xFE94: '\u0629',
  0xFE95: '\u062A',
  0xFE96: '\u062A',
  0xFE97: '\u062A',
  0xFE98: '\u062A',
  0xFE99: '\u062B',
  0xFE9A: '\u062B',
  0xFE9B: '\u062B',
  0xFE9C: '\u062B',
  0xFE9D: '\u062C',
  0xFE9E: '\u062C',
  0xFE9F: '\u062C',
  0xFEA0: '\u062C',
  0xFEA1: '\u062D',
  0xFEA2: '\u062D',
  0xFEA3: '\u062D',
  0xFEA4: '\u062D',
  0xFEA5: '\u062E',
  0xFEA6: '\u062E',
  0xFEA7: '\u062E',
  0xFEA8: '\u062E',
  0xFEA9: '\u062F',
  0xFEAA: '\u062F',
  0xFEAB: '\u0630',
  0xFEAC: '\u0630',
  0xFEAD: '\u0631',
  0xFEAE: '\u0631',
  0xFEAF: '\u0632',
  0xFEB0: '\u0632',
  0xFEB1: '\u0633',
  0xFEB2: '\u0633',
  0xFEB3: '\u0633',
  0xFEB4: '\u0633',
  0xFEB5: '\u0634',
  0xFEB6: '\u0634',
  0xFEB7: '\u0634',
  0xFEB8: '\u0634',
  0xFEB9: '\u0635',
  0xFEBA: '\u0635',
  0xFEBB: '\u0635',
  0xFEBC: '\u0635',
  0xFEBD: '\u0636',
  0xFEBE: '\u0636',
  0xFEBF: '\u0636',
  0xFEC0: '\u0636',
  0xFEC1: '\u0637',
  0xFEC2: '\u0637',
  0xFEC3: '\u0637',
  0xFEC4: '\u0637',
  0xFEC5: '\u0638',
  0xFEC6: '\u0638',
  0xFEC7: '\u0638',
  0xFEC8: '\u0638',
  0xFEC9: '\u0639',
  0xFECA: '\u0639',
  0xFECB: '\u0639',
  0xFECC: '\u0639',
  0xFECD: '\u063A',
  0xFECE: '\u063A',
  0xFECF: '\u063A',
  0xFED0: '\u063A',
  0xFED1: '\u0641',
  0xFED2: '\u0641',
  0xFED3: '\u0641',
  0xFED4: '\u0641',
  0xFED5: '\u0642',
  0xFED6: '\u0642',
  0xFED7: '\u0642',
  0xFED8: '\u0642',
  0xFED9: '\u0643',
  0xFEDA: '\u0643',
  0xFEDB: '\u0643',
  0xFEDC: '\u0643',
  0xFEDD: '\u0644',
  0xFEDE: '\u0644',
  0xFEDF: '\u0644',
  0xFEE0: '\u0644',
  0xFEE1: '\u0645',
  0xFEE2: '\u0645',
  0xFEE3: '\u0645',
  0xFEE4: '\u0645',
  0xFEE5: '\u0646',
  0xFEE6: '\u0646',
  0xFEE7: '\u0646',
  0xFEE8: '\u0646',
  0xFEE9: '\u0647',
  0xFEEA: '\u0647',
  0xFEEB: '\u0647',
  0xFEEC: '\u0647',
  0xFEED: '\u0648',
  0xFEEE: '\u0648',
  0xFEEF: '\u0649',
  0xFEF0: '\u0649',
  0xFEF1: '\u064A',
  0xFEF2: '\u064A',
  0xFEF3: '\u064A',
  0xFEF4: '\u064A',
  0xFEF5: '\u0644\u0622',
  0xFEF6: '\u0644\u0622',
  0xFEF7: '\u0644\u0623',
  0xFEF8: '\u0644\u0623',
  0xFEF9: '\u0644\u0625',
  0xFEFA: '\u0644\u0625',
  0xFEFB: '\u0644\u0627',
  0xFEFC: '\u0644\u0627',
};


/// Shared stylesheet for contract HTML. Short table cells share a row.
/// Long cells use the full width. Wrapping stays at word boundaries.
const String documentWebViewCss = '''
html, body {
  margin: 0 !important;
  padding: 12px 16px 32px !important;
  overflow-x: hidden !important;
  max-width: 100% !important;
  box-sizing: border-box;
  background: #fff;
  touch-action: pan-y !important;
  -webkit-text-size-adjust: 100%;
}
body {
  direction: rtl;
  text-align: right;
  font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Arial, sans-serif;
  font-size: 15px;
  line-height: 1.7;
  color: #1F2937;
  word-break: normal;
  overflow-wrap: normal;
  white-space: normal;
}
*, *::before, *::after { box-sizing: border-box; }
img, video, iframe, svg, canvas {
  max-width: 100%;
  height: auto;
}
p, li, h1, h2, h3, h4 {
  max-width: 100%;
  word-break: normal;
  overflow-wrap: normal;
  white-space: normal;
}
h1, h2, h3, h4 {
  font-size: 17px;
  font-weight: 700;
  line-height: 1.5;
  margin: 16px 0 8px;
}
p { margin: 0 0 8px; }
a { color: #1D4ED8; overflow-wrap: anywhere; }
table {
  display: block !important;
  width: 100% !important;
  max-width: 100% !important;
  height: auto !important;
  float: none !important;
  margin: 12px 0 !important;
  border: 1px solid #E5E7EB;
  border-radius: 8px;
  overflow: hidden !important;
  background: #fff;
}
thead, tbody, tfoot {
  display: block !important;
  width: 100% !important;
  height: auto !important;
}
tr {
  display: flex !important;
  flex-wrap: wrap !important;
  direction: ltr;
  width: 100% !important;
  height: auto !important;
  align-items: stretch;
  border-bottom: 1px solid #E5E7EB;
}
td, th {
  display: flex !important;
  flex-direction: column;
  justify-content: center;
  height: auto !important;
  min-height: 0 !important;
  min-width: 0 !important;
  float: none !important;
  white-space: normal !important;
  word-break: normal !important;
  overflow-wrap: normal !important;
  line-height: 1.45 !important;
  text-indent: 0 !important;
  border: none !important;
}
td.tan-short, th.tan-short, td.tan-dash, th.tan-dash {
  flex: 1 1 30% !important;
  width: auto !important;
  max-width: 100% !important;
  align-items: center;
  text-align: center !important;
  padding: 8px 6px !important;
  font-size: 13px;
  border-inline-start: 1px solid #E5E7EB !important;
}
td.tan-dash, th.tan-dash {
  color: #6B7280 !important;
  padding: 6px !important;
}
td.tan-long, th.tan-long {
  flex: 1 1 100% !important;
  width: 100% !important;
  max-width: 100% !important;
  align-items: stretch;
  text-align: right !important;
  direction: rtl;
  padding: 10px 12px !important;
  font-size: 14px;
}
td.tan-empty, th.tan-empty {
  display: none !important;
}
td p, th p {
  margin: 0 !important;
  max-width: 100%;
}
td.tan-short p, th.tan-short p, td.tan-dash p, th.tan-dash p {
  text-align: center !important;
  width: 100%;
}
td.tan-long p, th.tan-long p {
  text-align: right !important;
  direction: rtl;
}
''';

/// Turns Word-exported contract HTML into markup a phone WebView can show.
String sanitizeDocumentHtml(String html) {
  if (html.isEmpty) return html;
  final buffer = StringBuffer();
  for (final rune in html.runes) {
    buffer.write(
      arabicPresentationForms[rune] ?? String.fromCharCodes(<int>[rune]),
    );
  }
  var out = buffer.toString();
  out = out.replaceAll(
    RegExp(r'<!--\s*\[if[\s\S]*?-->', caseSensitive: false),
    '',
  );
  out = out.replaceAll(
    RegExp(r'<!--\s*\[endif\]\s*-->', caseSensitive: false),
    '',
  );
  out = out.replaceAll(RegExp(r'</?o:p\b[^>]*>', caseSensitive: false), '');
  out = out.replaceAll(
    RegExp(
      '<a\\b[^>]*\\bname\\s*=\\s*["\'][^"\']*["\'][^>]*>\\s*</a>',
      caseSensitive: false,
    ),
    '',
  );
  out = out.replaceAllMapped(
    RegExp('style\\s*=\\s*"([^"]*)"', caseSensitive: false),
    (match) => _styleReplacement(match.group(1)!),
  );
  out = out.replaceAllMapped(
    RegExp("style\\s*=\\s*'([^']*)'", caseSensitive: false),
    (match) => _styleReplacement(match.group(1)!),
  );
  out = out.replaceAllMapped(
    RegExp(
      r'<(p|h1|h2|h3|h4|li|td|th|table|div|tr|col)\b([^>]*)>',
      caseSensitive: false,
    ),
    (match) {
      final tag = match.group(1)!;
      var attrs = match.group(2)!;
      final blob = ('$tag $attrs').toLowerCase();
      final name = tag.toLowerCase();
      final tablePart = name == 'table' ||
          name == 'td' ||
          name == 'th' ||
          name == 'tr' ||
          name == 'col';
      final word = blob.contains('mso') ||
          blob.contains('tableparagraph') ||
          blob.contains('direction: rtl') ||
          blob.contains('direction:rtl');
      if (tablePart) {
        attrs = attrs.replaceAll(
          RegExp(
            '\\salign\\s*=\\s*["\']left["\']',
            caseSensitive: false,
          ),
          '',
        );
        attrs = attrs.replaceAll(
          RegExp(
            '\\s(?:width|height)\\s*=\\s*["\'][^"\']*["\']',
            caseSensitive: false,
          ),
          '',
        );
      }
      if (word) {
        attrs = attrs.replaceAll(
          RegExp('\\bdir\\s*=\\s*["\']ltr["\']', caseSensitive: false),
          'dir="rtl"',
        );
      }
      return '<$tag$attrs>';
    },
  );
  out = out.replaceAll(
    RegExp('\\sclear\\s*=\\s*["\']all["\']', caseSensitive: false),
    '',
  );
  final emptyBidi = RegExp(
    '<span\\b[^>]*\\bdir\\s*=\\s*["\'](?:ltr|rtl)["\'][^>]*>\\s*</span>',
    caseSensitive: false,
  );
  var previous = '';
  while (previous != out) {
    previous = out;
    out = out.replaceAll(emptyBidi, '');
  }
  out = out.replaceAll(RegExp(r'(?:&nbsp;|\u00A0){3,}'), ' ');
  return _layoutTables(out);
}

/// Keeps brief cells (risk labels, dates, "--") beside each other.
/// A sentence or a merged cell takes the whole row.
String _layoutTables(String html) {
  return html.replaceAllMapped(
    RegExp(r'<table\b[^>]*>[\s\S]*?</table>', caseSensitive: false),
    (match) => _layoutTable(match.group(0)!),
  );
}

String _layoutTable(String table) {
  return table.replaceAllMapped(
    RegExp(
      r'<(td|th)\b([^>]*)>([\s\S]*?)</\1>',
      caseSensitive: false,
    ),
    (match) {
      final tag = match.group(1)!;
      final attrs = _appendClass(
        match.group(2)!,
        _cellClass(match.group(3)!, match.group(2)!),
      );
      return '<$tag$attrs>${match.group(3)}</$tag>';
    },
  );
}

String _cellClass(String inner, String attrs) {
  final text = inner
      .replaceAll(RegExp(r'<[^>]+>'), ' ')
      .replaceAll('&nbsp;', ' ')
      .replaceAll('\u00A0', ' ')
      .replaceAll(RegExp(r'&\w+;'), ' ')
      .replaceAll(RegExp(r'\s+'), ' ')
      .trim();
  if (text.isEmpty) return 'tan-empty';
  if (RegExp(r'^[-–—.\s]+$').hasMatch(text)) return 'tan-dash';
  final colspan = RegExp(
    'colspan\\s*=\\s*["\']?(\\d+)',
    caseSensitive: false,
  ).firstMatch(attrs);
  final span = int.tryParse(colspan?.group(1) ?? '') ?? 1;
  if (span > 1 || text.length > 28) return 'tan-long';
  return 'tan-short';
}

String _appendClass(String attrs, String cls) {
  final quoted = RegExp(
    'class\\s*=\\s*"([^"]*)"',
    caseSensitive: false,
  ).firstMatch(attrs);
  if (quoted != null) {
    return attrs.replaceRange(
      quoted.start,
      quoted.end,
      'class="${quoted.group(1)} $cls"',
    );
  }
  final single = RegExp(
    "class\\s*=\\s*'([^']*)'",
    caseSensitive: false,
  ).firstMatch(attrs);
  if (single != null) {
    return attrs.replaceRange(
      single.start,
      single.end,
      'class="${single.group(1)} $cls"',
    );
  }
  return '$attrs class="$cls"';
}

String _styleReplacement(String style) {
  final cleaned = _cleanWordStyle(style);
  if (identical(cleaned, style)) {
    return 'style="$style"';
  }
  if (cleaned.isEmpty) return '';
  return 'style="$cleaned"';
}

/// Word paragraphs carry `mso-*`, centimetre margins, and hanging indents.
/// KYC cards do not, so their flex styles are left as the backend sent them.
String _cleanWordStyle(String style) {
  final lower = style.toLowerCase();
  final isWord = lower.contains('mso-') ||
      lower.contains('unicode-bidi') ||
      lower.contains('text-indent') ||
      lower.contains('cm');
  if (!isWord) return style;

  final kept = <String>[];
  for (final part in style.split(';')) {
    final decl = part.trim();
    if (decl.isEmpty) continue;
    final colon = decl.indexOf(':');
    if (colon <= 0) continue;
    final prop = decl.substring(0, colon).trim().toLowerCase();
    final value = decl.substring(colon + 1).trim();
    final v = value.toLowerCase();
    if (prop.startsWith('mso')) continue;
    if (_droppedWordProperties.contains(prop)) continue;
    if (prop.startsWith('margin') || prop.startsWith('padding')) continue;
    if (prop.startsWith('border')) continue;
    if (prop == 'direction') {
      if (v.contains('rtl')) kept.add('direction: rtl');
      continue;
    }
    if (prop == 'text-align') {
      if (v.contains('center')) {
        kept.add('text-align: center');
      } else if (v.contains('justify')) {
        kept.add('text-align: justify');
      } else {
        kept.add('text-align: right');
      }
      continue;
    }
    if (prop == 'color' ||
        prop == 'background' ||
        prop == 'background-color') {
      if (v.contains('windowtext') ||
          v.contains('transparent') ||
          v == 'currentcolor') {
        continue;
      }
      kept.add('$prop: $value');
      continue;
    }
    if (prop == 'font-weight' ||
        prop == 'font-style' ||
        prop == 'text-decoration') {
      kept.add('$prop: $value');
    }
  }
  return kept.join('; ');
}

const Set<String> _droppedWordProperties = <String>{
  'unicode-bidi',
  'text-indent',
  'letter-spacing',
  'float',
  'position',
  'top',
  'left',
  'right',
  'bottom',
  'width',
  'height',
  'min-width',
  'max-width',
  'min-height',
  'max-height',
  'line-height',
  'font-size',
  'font-family',
  'tab-stops',
};
