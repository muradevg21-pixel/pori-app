import 'package:material_ui/material_ui.dart';

/// Renders the small HTML subset used by the tafsir sources
/// (p, br, b/strong, em/i, u, h1-h6). Other tags are ignored, their text kept.
class SimpleHtml extends StatelessWidget {
  const SimpleHtml(this.html, {super.key, required this.style});
  final String html;
  final TextStyle style;

  @override
  Widget build(BuildContext context) {
    final paragraphs = parseSimpleHtml(html);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final p in paragraphs)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Text.rich(TextSpan(style: style, children: p)),
          ),
      ],
    );
  }
}

List<List<TextSpan>> parseSimpleHtml(String html) {
  final paragraphs = <List<TextSpan>>[];
  var current = <TextSpan>[];
  var bold = 0, italic = 0, underline = 0;

  void flush() {
    if (current.any((s) => (s.text ?? '').trim().isNotEmpty)) {
      paragraphs.add(current);
    }
    current = <TextSpan>[];
  }

  final tag = RegExp(r'<\s*(/?)\s*([a-zA-Z0-9]+)[^>]*?(/?)\s*>');
  var pos = 0;
  for (final m in tag.allMatches(html)) {
    if (m.start > pos) {
      final text = _decode(html.substring(pos, m.start));
      if (text.isNotEmpty) {
        current.add(TextSpan(
          text: text,
          style: TextStyle(
            fontWeight: bold > 0 ? FontWeight.w700 : null,
            fontStyle: italic > 0 ? FontStyle.italic : null,
            decoration: underline > 0 ? TextDecoration.underline : null,
          ),
        ));
      }
    }
    pos = m.end;
    final closing = m[1] == '/';
    final name = m[2]!.toLowerCase();
    final delta = closing ? -1 : 1;
    switch (name) {
      case 'p' || 'div':
        flush();
      case 'br':
        current.add(const TextSpan(text: '\n'));
      case 'b' || 'strong' || 'h1' || 'h2' || 'h3' || 'h4' || 'h5' || 'h6':
        bold = (bold + delta).clamp(0, 99);
        if (name.startsWith('h')) flush();
      case 'em' || 'i':
        italic = (italic + delta).clamp(0, 99);
      case 'u':
        underline = (underline + delta).clamp(0, 99);
    }
  }
  if (pos < html.length) {
    final text = _decode(html.substring(pos));
    if (text.isNotEmpty) current.add(TextSpan(text: text));
  }
  flush();
  return paragraphs;
}

String _decode(String s) => s
    .replaceAll(RegExp(r'\s+'), ' ')
    .replaceAll('&nbsp;', ' ')
    .replaceAll('&quot;', '"')
    .replaceAll('&#39;', "'")
    .replaceAll('&lt;', '<')
    .replaceAll('&gt;', '>')
    .replaceAllMapped(RegExp(r'&#(\d+);'),
        (m) => String.fromCharCode(int.parse(m[1]!)))
    .replaceAll('&amp;', '&');
