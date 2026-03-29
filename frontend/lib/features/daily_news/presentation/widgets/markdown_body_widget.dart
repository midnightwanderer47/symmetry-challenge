import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:markdown/markdown.dart' as md;

class ArticleMarkdownBody extends StatelessWidget {
  final String content;

  const ArticleMarkdownBody({Key? key, required this.content})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MarkdownBody(
      data: content,
      selectable: true,
      extensionSet: md.ExtensionSet.gitHubFlavored,
      styleSheet: MarkdownStyleSheet.fromTheme(Theme.of(context)).copyWith(
        p: const TextStyle(fontSize: 16),
        h1: const TextStyle(fontFamily: 'Butler', fontSize: 24, fontWeight: FontWeight.bold),
        h2: const TextStyle(fontFamily: 'Butler', fontSize: 20, fontWeight: FontWeight.bold),
        h3: const TextStyle(fontFamily: 'Butler', fontSize: 18, fontWeight: FontWeight.bold),
        strong: const TextStyle(fontWeight: FontWeight.bold),
      ),
    );
  }
}
