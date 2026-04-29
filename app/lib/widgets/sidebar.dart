import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/workspace.dart';
import '../providers/page_provider.dart';
import '../providers/block_provider.dart';
import '../providers/auth_provider.dart';
import '../screens/search_screen.dart';
import 'page_tree_item.dart';

class Sidebar extends StatelessWidget {
  final Workspace workspace;

  const Sidebar({super.key, required this.workspace});

  @override
  Widget build(BuildContext context) {
    final pageProvider = context.watch<PageProvider>();
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      width: 260,
      color: colorScheme.surfaceContainerLow,
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Workspace header
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      workspace.name,
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  // Logout
                  IconButton(
                    icon: const Icon(Icons.logout, size: 18),
                    tooltip: 'Log out',
                    onPressed: () async {
                      final pageProvider = context.read<PageProvider>();
                      final blockProvider = context.read<BlockProvider>();
                      final authProvider = context.read<AuthProvider>();
                      pageProvider.reset();
                      blockProvider.reset();
                      await authProvider.logout();
                    },
                  ),
                ],
              ),
            ),

            // Quick search
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              child: ListTile(
                dense: true,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8)),
                leading: const Icon(Icons.search, size: 18),
                title: const Text('Search'),
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) =>
                          SearchScreen(workspaceId: workspace.id),
                    ),
                  );
                },
              ),
            ),

            const Divider(height: 1),
            const SizedBox(height: 4),

            // New page button
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: ListTile(
                dense: true,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8)),
                leading: const Icon(Icons.add, size: 18),
                title: const Text('New Page'),
                onTap: () async {
                  final pageProvider = context.read<PageProvider>();
                  final blockProvider = context.read<BlockProvider>();
                  final newPage = await pageProvider.createPage(
                            workspaceId: workspace.id,
                          );
                  if (!context.mounted) return;
                  pageProvider.selectPage(newPage);
                  await blockProvider.loadBlocks(newPage.id);
                },
              ),
            ),

            const SizedBox(height: 4),
            const Divider(height: 1),

            // Page tree
            Expanded(
              child: pageProvider.isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : pageProvider.rootPages.isEmpty
                      ? Padding(
                          padding: const EdgeInsets.all(16),
                          child: Text(
                            'No pages yet.\nTap "New Page" to start.',
                            style: TextStyle(color: colorScheme.outline),
                            textAlign: TextAlign.center,
                          ),
                        )
                      : ListView(
                          padding: EdgeInsets.zero,
                          children: pageProvider.rootPages
                              .map((p) => PageTreeItem(
                                    page: p,
                                    workspaceId: workspace.id,
                                  ))
                              .toList(),
                        ),
            ),

            const Divider(height: 1),

            // Trash section
            _TrashSection(workspaceId: workspace.id),
          ],
        ),
      ),
    );
  }
}

class _TrashSection extends StatefulWidget {
  final int workspaceId;
  const _TrashSection({required this.workspaceId});

  @override
  State<_TrashSection> createState() => _TrashSectionState();
}

class _TrashSectionState extends State<_TrashSection> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final pageProvider = context.watch<PageProvider>();
    final archived = pageProvider.archivedPages;
    final colorScheme = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ListTile(
          dense: true,
          leading: const Icon(Icons.delete_outline, size: 18),
          title: Text('Trash (${archived.length})'),
          trailing: Icon(
            _expanded ? Icons.expand_less : Icons.expand_more,
            size: 18,
          ),
          onTap: () => setState(() => _expanded = !_expanded),
        ),
        if (_expanded)
          ...archived.map(
            (p) => ListTile(
              dense: true,
              contentPadding: const EdgeInsets.only(left: 32, right: 8),
              leading: const Icon(Icons.restore, size: 16),
              title: Text(
                p.title.isEmpty ? 'Untitled' : p.title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(color: colorScheme.outline),
              ),
              onTap: () async {
                await pageProvider.restorePage(p.id);
              },
            ),
          ),
      ],
    );
  }
}
