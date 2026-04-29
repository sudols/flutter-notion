import 'package:flutter/material.dart';
import '../models/block.dart';

/// Shows a small overlay menu when the user types '/' in a block.
/// Calls [onSelected] with the chosen block type, then closes.
void showSlashMenu(
  BuildContext context, {
  required void Function(BlockType type) onSelected,
}) {
  final options = [
    _SlashOption(
      icon: Icons.text_fields,
      label: 'Text',
      type: BlockType.text,
    ),
    _SlashOption(
      icon: Icons.title,
      label: 'Heading',
      type: BlockType.heading,
    ),
    _SlashOption(
      icon: Icons.check_box_outlined,
      label: 'To-do',
      type: BlockType.todo,
    ),
    _SlashOption(
      icon: Icons.format_list_bulleted,
      label: 'Bullet List',
      type: BlockType.bullet,
    ),
  ];

  showModalBottomSheet<void>(
    context: context,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
    ),
    builder: (_) {
      return SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Padding(
              padding: EdgeInsets.all(12),
              child: Text(
                'Turn into…',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
            const Divider(height: 1),
            ...options.map(
              (opt) => ListTile(
                leading: Icon(opt.icon),
                title: Text(opt.label),
                onTap: () {
                  Navigator.of(context).pop();
                  onSelected(opt.type);
                },
              ),
            ),
          ],
        ),
      );
    },
  );
}

class _SlashOption {
  final IconData icon;
  final String label;
  final BlockType type;

  const _SlashOption({
    required this.icon,
    required this.label,
    required this.type,
  });
}
