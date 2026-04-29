import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/page.dart';
import '../providers/page_provider.dart';
import '../providers/block_provider.dart';

/// Renders a single page item in the sidebar tree.
/// Recursively renders child pages using [ExpansionTile].
class PageTreeItem extends StatelessWidget {
  final NotionPage page;
  final int workspaceId;
  final int depth;

  const PageTreeItem({
    super.key,
    required this.page,
    required this.workspaceId,
    this.depth = 0,
  });

  @override
  Widget build(BuildContext context) {
    final pageProvider = context.watch<PageProvider>();
    final children = pageProvider.childrenOf(page.id);
    final isActive = pageProvider.activePage?.id == page.id;
    final colorScheme = Theme.of(context).colorScheme;

    Future<void> openPage() async {
      final blockProvider = context.read<BlockProvider>();
      final scaffold = Scaffold.of(context);
      pageProvider.selectPage(page);
      await blockProvider.loadBlocks(page.id);
      // On mobile, close the drawer after selection.
      if (!context.mounted) return;
      if (scaffold.isDrawerOpen) {
        Navigator.of(context).pop();
      }
    }

    final tile = ListTile(
      dense: true,
      contentPadding:
          EdgeInsets.only(left: 16.0 + depth * 16, right: 8),
      selected: isActive,
      selectedTileColor: colorScheme.primaryContainer,
      leading: const Icon(Icons.article_outlined, size: 18),
      title: Text(
        page.title.isEmpty ? 'Untitled' : page.title,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      onTap: openPage,
      trailing: _AddChildButton(page: page, workspaceId: workspaceId),
    );

    if (children.isEmpty) {
      return tile;
    }

    return ExpansionTile(
      tilePadding: EdgeInsets.only(left: 16.0 + depth * 16, right: 8),
      childrenPadding: EdgeInsets.zero,
      leading: const Icon(Icons.article_outlined, size: 18),
      title: Text(
        page.title.isEmpty ? 'Untitled' : page.title,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: isActive
            ? TextStyle(color: colorScheme.primary, fontWeight: FontWeight.w600)
            : null,
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _AddChildButton(page: page, workspaceId: workspaceId),
          const Icon(Icons.expand_more, size: 18),
        ],
      ),
      onExpansionChanged: (_) => openPage(),
      children: children
          .map((child) => PageTreeItem(
                page: child,
                workspaceId: workspaceId,
                depth: depth + 1,
              ))
          .toList(),
    );
  }
}

class _AddChildButton extends StatelessWidget {
  final NotionPage page;
  final int workspaceId;

  const _AddChildButton({required this.page, required this.workspaceId});

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.add, size: 16),
      tooltip: 'Add sub-page',
      visualDensity: VisualDensity.compact,
      onPressed: () async {
        final pageProvider = context.read<PageProvider>();
        final blockProvider = context.read<BlockProvider>();
        final newPage = await pageProvider.createPage(
              workspaceId: workspaceId,
              title: 'Untitled',
              parentPageId: page.id,
            );
        if (!context.mounted) return;
        pageProvider.selectPage(newPage);
        await blockProvider.loadBlocks(newPage.id);
      },
    );
  }
}
