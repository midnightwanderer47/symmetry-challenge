import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:markdown/markdown.dart' as md;

class ArticleMarkdownBody extends StatelessWidget {
  final String content;

  const ArticleMarkdownBody({Key? key, required this.content})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    final onSurface = Theme.of(context).colorScheme.onSurface;
    final h1Style = TextStyle(fontFamily: 'Butler', fontSize: 24, fontWeight: FontWeight.bold, color: onSurface);
    final h2Style = TextStyle(fontFamily: 'Butler', fontSize: 20, fontWeight: FontWeight.bold, color: onSurface);
    final h3Style = TextStyle(fontFamily: 'Butler', fontSize: 18, fontWeight: FontWeight.bold, color: onSurface);
    final h4Style = TextStyle(fontFamily: 'Butler', fontSize: 16, fontWeight: FontWeight.bold, color: onSurface);
    final h5Style = TextStyle(fontFamily: 'Butler', fontSize: 14, fontWeight: FontWeight.bold, color: onSurface);
    final h6Style = TextStyle(fontFamily: 'Butler', fontSize: 13, fontWeight: FontWeight.bold, color: onSurface);

    return MarkdownBody(
      data: content,
      selectable: true,
      extensionSet: md.ExtensionSet.gitHubFlavored,
      styleSheet: MarkdownStyleSheet.fromTheme(Theme.of(context)).copyWith(
        p: TextStyle(fontSize: 16, height: 1.6, color: onSurface),
        h1: h1Style,
        h2: h2Style,
        h3: h3Style,
        h4: h4Style,
        h5: h5Style,
        h6: h6Style,
        strong: const TextStyle(fontWeight: FontWeight.bold),
      ),
      builders: {
        'h1': _HeadingBuilder(h1Style),
        'h2': _HeadingBuilder(h2Style),
        'h3': _HeadingBuilder(h3Style),
        'h4': _HeadingBuilder(h4Style),
        'h5': _HeadingBuilder(h5Style),
        'h6': _HeadingBuilder(h6Style),
      },
    );
  }
}

class _HeadingBuilder extends MarkdownElementBuilder {
  final TextStyle fallbackStyle;

  _HeadingBuilder(this.fallbackStyle);

  @override
  Widget? visitElementAfter(md.Element element, TextStyle? preferredStyle) {
    return Semantics(
      header: true,
      child: Text(element.textContent, style: preferredStyle ?? fallbackStyle),
    );
  }
}
