import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/workspace_provider.dart';
import '../providers/page_provider.dart';
import '../providers/block_provider.dart';
import '../widgets/sidebar.dart';
import '../widgets/page_editor.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  void initState() {
    super.initState();
    // Load workspaces then pages once the frame is rendered.
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load() async {
    final workspaceProvider = context.read<WorkspaceProvider>();
    await workspaceProvider.loadWorkspaces();

    final workspace = workspaceProvider.current;
    if (workspace != null && mounted) {
      await context.read<PageProvider>().loadPages(workspace.id);
    }
  }

  @override
  Widget build(BuildContext context) {
    final workspaceProvider = context.watch<WorkspaceProvider>();
    final pageProvider = context.watch<PageProvider>();
    final blockProvider = context.watch<BlockProvider>();
    final workspace = workspaceProvider.current;

    if (workspaceProvider.isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (workspace == null) {
      return const Scaffold(
        body: Center(child: Text('No workspace found.')),
      );
    }

    final activePage = pageProvider.activePage;
    final isWide = MediaQuery.of(context).size.width >= 720;

    final sidebar = Sidebar(workspace: workspace);

    Widget editorArea;
    if (activePage == null) {
      editorArea = Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.article_outlined,
              size: 64,
              color: Theme.of(context).colorScheme.outlineVariant,
            ),
            const SizedBox(height: 16),
            Text(
              'Select a page or create a new one',
              style: TextStyle(
                  color: Theme.of(context).colorScheme.outline),
            ),
          ],
        ),
      );
    } else {
      editorArea = PageEditor(
        key: ValueKey(activePage.id),
        pageId: activePage.id,
        pageTitle: activePage.title,
        onTitleChanged: (title) {
          blockProvider; // keep alive
          pageProvider.updateTitle(activePage.id, title);
        },
      );
    }

    if (isWide) {
      // Wide screen: persistent sidebar + editor side by side.
      return Scaffold(
        body: Row(
          children: [
            sidebar,
            const VerticalDivider(width: 1),
            Expanded(child: editorArea),
          ],
        ),
      );
    } else {
      // Narrow screen (mobile): sidebar in a Drawer.
      return Scaffold(
        appBar: AppBar(
          title: Text(activePage?.title.isEmpty ?? true
              ? 'Notion'
              : activePage!.title),
        ),
        drawer: Drawer(child: sidebar),
        body: editorArea,
      );
    }
  }
}
