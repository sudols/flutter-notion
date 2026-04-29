import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/block.dart';
import '../providers/block_provider.dart';
import 'slash_menu.dart';

/// Renders all blocks for the active page as a reorderable list.
class PageEditor extends StatelessWidget {
  final int pageId;
  final String pageTitle;
  final void Function(String) onTitleChanged;

  const PageEditor({
    super.key,
    required this.pageId,
    required this.pageTitle,
    required this.onTitleChanged,
  });

  @override
  Widget build(BuildContext context) {
    final blockProvider = context.watch<BlockProvider>();

    if (blockProvider.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    final blocks = blockProvider.blocks;

    return ReorderableListView.builder(
      padding: const EdgeInsets.fromLTRB(48, 24, 48, 120),
      onReorder: (oldIndex, newIndex) {
        // Skip header item (index 0).
        if (oldIndex == 0 || newIndex == 0) return;
        blockProvider.reorder(pageId, oldIndex - 1, newIndex - 1);
      },
      header: _TitleField(
        key: ValueKey('title_$pageId'),
        initialTitle: pageTitle,
        onChanged: onTitleChanged,
        onSubmitted: () {
          // When user presses Enter on the title, create the first block.
          if (blocks.isEmpty) {
            blockProvider.addBlock(pageId: pageId);
          }
        },
      ),
      itemCount: blocks.length,
      itemBuilder: (context, index) {
        final block = blocks[index];
        return BlockWidget(
          key: ValueKey(block.id),
          block: block,
          pageId: pageId,
          isLast: index == blocks.length - 1,
        );
      },
    );
  }
}

class _TitleField extends StatefulWidget {
  final String initialTitle;
  final void Function(String) onChanged;
  final VoidCallback onSubmitted;

  const _TitleField({
    super.key,
    required this.initialTitle,
    required this.onChanged,
    required this.onSubmitted,
  });

  @override
  State<_TitleField> createState() => _TitleFieldState();
}

class _TitleFieldState extends State<_TitleField> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialTitle);
  }

  @override
  void didUpdateWidget(_TitleField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.initialTitle != widget.initialTitle &&
        _controller.text != widget.initialTitle) {
      _controller.text = widget.initialTitle;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextField(
        controller: _controller,
        style: Theme.of(context)
            .textTheme
            .headlineMedium
            ?.copyWith(fontWeight: FontWeight.bold),
        decoration: const InputDecoration(
          hintText: 'Untitled',
          border: InputBorder.none,
        ),
        maxLines: null,
        textInputAction: TextInputAction.done,
        onChanged: widget.onChanged,
        onSubmitted: (_) => widget.onSubmitted(),
      ),
    );
  }
}

/// Renders a single block based on its type.
class BlockWidget extends StatefulWidget {
  final Block block;
  final int pageId;
  final bool isLast;

  const BlockWidget({
    super.key,
    required this.block,
    required this.pageId,
    required this.isLast,
  });

  @override
  State<BlockWidget> createState() => _BlockWidgetState();
}

class _BlockWidgetState extends State<BlockWidget> {
  late final TextEditingController _controller;
  late final FocusNode _focusNode;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.block.content);
    _focusNode = FocusNode();
  }

  @override
  void didUpdateWidget(BlockWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.block.content != widget.block.content &&
        _controller.text != widget.block.content) {
      _controller.text = widget.block.content;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _onChanged(String value) {
    if (value.startsWith('/') && value.length == 1) {
      _showSlashMenu();
      return;
    }
    context.read<BlockProvider>().updateContentLocally(widget.block.id, value);
  }

  void _onSubmitted(String _) {
    // Enter → create a new text block below.
    context.read<BlockProvider>().addBlock(
          pageId: widget.pageId,
          blockType: BlockType.text,
        );
  }

  void _onBackspace() {
    // Delete block when it's empty and Backspace is pressed.
    if (_controller.text.isEmpty) {
      context.read<BlockProvider>().deleteBlock(widget.block.id);
    }
  }

  void _showSlashMenu() {
    showSlashMenu(context, onSelected: (type) {
      _controller.clear();
      context.read<BlockProvider>().changeBlockType(widget.block.id, type);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Drag handle
          ReorderableDragStartListener(
            index: context
                    .findAncestorWidgetOfExactType<ReorderableListView>() !=
                null
                ? 0
                : 0,
            child: Padding(
              padding: const EdgeInsets.only(top: 10, right: 4),
              child: Icon(
                Icons.drag_indicator,
                size: 16,
                color: Theme.of(context).colorScheme.outlineVariant,
              ),
            ),
          ),
          Expanded(child: _buildBlockContent()),
        ],
      ),
    );
  }

  Widget _buildBlockContent() {
    switch (widget.block.blockType) {
      case BlockType.heading:
        return _buildTextField(
          style: Theme.of(context)
              .textTheme
              .titleLarge
              ?.copyWith(fontWeight: FontWeight.bold),
          hint: 'Heading',
        );
      case BlockType.bullet:
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Padding(
              padding: EdgeInsets.only(top: 12, right: 8),
              child: Text('•', style: TextStyle(fontSize: 18)),
            ),
            Expanded(
              child: _buildTextField(hint: 'Bullet point'),
            ),
          ],
        );
      case BlockType.todo:
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Checkbox(
              value: widget.block.isChecked,
              onChanged: (v) {
                context
                    .read<BlockProvider>()
                    .updateCheckedLocally(widget.block.id, v ?? false);
              },
            ),
            Expanded(
              child: _buildTextField(
                hint: 'To-do',
                style: widget.block.isChecked
                    ? TextStyle(
                        decoration: TextDecoration.lineThrough,
                        color: Theme.of(context).colorScheme.outline,
                      )
                    : null,
              ),
            ),
          ],
        );
      case BlockType.text:
        return _buildTextField(hint: "Type '/' for commands");
    }
  }

  Widget _buildTextField({TextStyle? style, String? hint}) {
    return KeyboardListener(
      focusNode: FocusNode(),
      onKeyEvent: (event) {
        if (event.character == null &&
            event.logicalKey.keyLabel == 'Backspace') {
          _onBackspace();
        }
      },
      child: TextField(
        controller: _controller,
        focusNode: _focusNode,
        style: style,
        decoration: InputDecoration(
          hintText: hint,
          border: InputBorder.none,
          isDense: true,
          contentPadding: const EdgeInsets.symmetric(vertical: 6),
        ),
        maxLines: null,
        textInputAction: TextInputAction.done,
        onChanged: _onChanged,
        onSubmitted: _onSubmitted,
      ),
    );
  }
}
