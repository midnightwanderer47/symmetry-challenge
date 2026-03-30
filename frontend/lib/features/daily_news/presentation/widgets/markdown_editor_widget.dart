import 'package:flutter/material.dart';

class MarkdownEditorWidget extends StatefulWidget {
  final String? initialValue;
  final ValueChanged<String> onChanged;
  final String? Function(String?)? validator;

  const MarkdownEditorWidget({
    Key? key,
    this.initialValue,
    required this.onChanged,
    this.validator,
  }) : super(key: key);

  @override
  State<MarkdownEditorWidget> createState() => _MarkdownEditorWidgetState();
}

class _MarkdownEditorWidgetState extends State<MarkdownEditorWidget> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialValue ?? '');
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _wrapSelection(String left, String right) {
    final text = _controller.text;
    final selection = _controller.selection;
    if (!selection.isValid) return;
    final selectedText = selection.textInside(text);
    final newText = text.replaceRange(
        selection.start, selection.end, '$left$selectedText$right');
    _controller.value = _controller.value.copyWith(
      text: newText,
      selection: TextSelection.collapsed(
        offset:
            selection.start + left.length + selectedText.length + right.length,
      ),
    );
    widget.onChanged(_controller.text);
  }

  void _insertAtLineStart(String prefix) {
    final text = _controller.text;
    final selection = _controller.selection;
    if (!selection.isValid) return;
    final lineStart = text.lastIndexOf('\n', selection.start - 1) + 1;
    final newText = text.replaceRange(lineStart, lineStart, prefix);
    _controller.value = _controller.value.copyWith(
      text: newText,
      selection: TextSelection.collapsed(
        offset: selection.start + prefix.length,
      ),
    );
    widget.onChanged(_controller.text);
  }

  @override
  Widget build(BuildContext context) {
    final onSurface = Theme.of(context).colorScheme.onSurface;
    final onSurfaceVariant = Theme.of(context).colorScheme.onSurfaceVariant;
    final charCount = _controller.text.length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          decoration: BoxDecoration(
            border: Border.all(
              color: onSurface.withValues(alpha: 0.38),
            ),
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(4),
              topRight: Radius.circular(4),
            ),
          ),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _ToolbarButton(
                  icon: Icons.format_bold,
                  tooltip: 'Bold',
                  onPressed: () => _wrapSelection('**', '**'),
                ),
                _ToolbarButton(
                  icon: Icons.format_italic,
                  tooltip: 'Italic',
                  onPressed: () => _wrapSelection('_', '_'),
                ),
                _ToolbarButton(
                  icon: Icons.title,
                  tooltip: 'Heading',
                  onPressed: () => _insertAtLineStart('## '),
                ),
                _ToolbarButton(
                  icon: Icons.format_list_bulleted,
                  tooltip: 'Bullet list',
                  onPressed: () => _insertAtLineStart('- '),
                ),
              ],
            ),
          ),
        ),
        TextFormField(
          controller: _controller,
          decoration: InputDecoration(
            border: OutlineInputBorder(
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(4),
                bottomRight: Radius.circular(4),
              ),
              borderSide: BorderSide(color: onSurface.withValues(alpha: 0.38)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(4),
                bottomRight: Radius.circular(4),
              ),
              borderSide: BorderSide(color: onSurface.withValues(alpha: 0.38)),
            ),
            contentPadding: const EdgeInsets.all(12),
          ),
          minLines: 6,
          maxLines: null,
          textAlignVertical: TextAlignVertical.top,
          keyboardType: TextInputType.multiline,
          stylusHandwritingEnabled: false,
          onChanged: (val) {
            setState(() {});
            widget.onChanged(val);
          },
          validator: widget.validator,
        ),
        const SizedBox(height: 4),
        Text(
          '$charCount / 50000',
          textAlign: TextAlign.end,
          style: TextStyle(
            fontSize: 12,
            color: onSurfaceVariant.withValues(alpha: 0.7),
          ),
        ),
      ],
    );
  }
}

class _ToolbarButton extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback onPressed;

  const _ToolbarButton({
    required this.icon,
    required this.tooltip,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: Icon(icon, size: 20),
      tooltip: tooltip,
      onPressed: onPressed,
      visualDensity: VisualDensity.compact,
    );
  }
}
