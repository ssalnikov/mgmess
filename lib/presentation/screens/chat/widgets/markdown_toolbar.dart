import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';

class MarkdownToolbar extends StatelessWidget {
  final TextEditingController controller;
  final FocusNode focusNode;

  const MarkdownToolbar({
    super.key,
    required this.controller,
    required this.focusNode,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 40,
      color: AppColors.backgroundLight,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 4),
        child: Row(
          children: [
            _ToolbarButton(
              icon: Icons.format_bold,
              tooltip: 'Bold',
              onTap: () => _wrapSelection('**'),
            ),
            _ToolbarButton(
              icon: Icons.format_italic,
              tooltip: 'Italic',
              onTap: () => _wrapSelection('_'),
            ),
            _ToolbarButton(
              icon: Icons.format_strikethrough,
              tooltip: 'Strikethrough',
              onTap: () => _wrapSelection('~~'),
            ),
            _ToolbarButton(
              icon: Icons.code,
              tooltip: 'Code',
              onTap: () => _wrapSelection('`'),
            ),
            _ToolbarButton(
              icon: Icons.data_object,
              tooltip: 'Code block',
              onTap: () => _wrapSelection('```\n', '\n```'),
            ),
            _ToolbarButton(
              icon: Icons.title,
              tooltip: 'Heading',
              onTap: () => _insertAtLineStart('### '),
            ),
            _ToolbarButton(
              icon: Icons.format_list_bulleted,
              tooltip: 'Bullet list',
              onTap: () => _insertAtLineStart('- '),
            ),
            _ToolbarButton(
              icon: Icons.format_list_numbered,
              tooltip: 'Numbered list',
              onTap: () => _insertAtLineStart('1. '),
            ),
            _ToolbarButton(
              icon: Icons.link,
              tooltip: 'Link',
              onTap: _insertLink,
            ),
            _ToolbarButton(
              icon: Icons.format_quote,
              tooltip: 'Quote',
              onTap: () => _insertAtLineStart('> '),
            ),
          ],
        ),
      ),
    );
  }

  void _wrapSelection(String marker, [String? endMarker]) {
    final text = controller.text;
    final selection = controller.selection;
    final end = endMarker ?? marker;

    if (selection.isValid && !selection.isCollapsed) {
      final selected = text.substring(selection.start, selection.end);
      final newText = text.replaceRange(
        selection.start,
        selection.end,
        '$marker$selected$end',
      );
      controller.text = newText;
      controller.selection = TextSelection.collapsed(
        offset: selection.start + marker.length + selected.length,
      );
    } else {
      final cursorPos = selection.isValid
          ? selection.baseOffset
          : text.length;
      final newText =
          '${text.substring(0, cursorPos)}$marker$end${text.substring(cursorPos)}';
      controller.text = newText;
      controller.selection = TextSelection.collapsed(
        offset: cursorPos + marker.length,
      );
    }
    focusNode.requestFocus();
  }

  void _insertAtLineStart(String prefix) {
    final text = controller.text;
    final selection = controller.selection;
    final cursorPos = (selection.isValid && selection.isCollapsed)
        ? selection.baseOffset
        : text.length;

    // Find start of current line
    int lineStart = cursorPos;
    while (lineStart > 0 && text[lineStart - 1] != '\n') {
      lineStart--;
    }

    final newText =
        '${text.substring(0, lineStart)}$prefix${text.substring(lineStart)}';
    controller.text = newText;
    controller.selection = TextSelection.collapsed(
      offset: cursorPos + prefix.length,
    );
    focusNode.requestFocus();
  }

  void _insertLink() {
    final text = controller.text;
    final selection = controller.selection;

    if (selection.isValid && !selection.isCollapsed) {
      final selected = text.substring(selection.start, selection.end);
      final replacement = '[$selected](url)';
      final newText = text.replaceRange(
        selection.start,
        selection.end,
        replacement,
      );
      controller.text = newText;
      // Select "url" for easy replacement
      final urlStart = selection.start + selected.length + 2;
      controller.selection = TextSelection(
        baseOffset: urlStart,
        extentOffset: urlStart + 3,
      );
    } else {
      final cursorPos = (selection.isValid && selection.isCollapsed)
          ? selection.baseOffset
          : text.length;
      const link = '[text](url)';
      final newText =
          '${text.substring(0, cursorPos)}$link${text.substring(cursorPos)}';
      controller.text = newText;
      // Select "text" for easy replacement
      controller.selection = TextSelection(
        baseOffset: cursorPos + 1,
        extentOffset: cursorPos + 5,
      );
    }
    focusNode.requestFocus();
  }
}

class _ToolbarButton extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;

  const _ToolbarButton({
    required this.icon,
    required this.tooltip,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 36,
      height: 36,
      child: IconButton(
        icon: Icon(icon, size: 18, color: AppColors.textSecondary),
        tooltip: tooltip,
        onPressed: onTap,
        padding: EdgeInsets.zero,
        splashRadius: 16,
      ),
    );
  }
}
