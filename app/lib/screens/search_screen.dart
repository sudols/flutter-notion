import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/page.dart';
import '../providers/page_provider.dart';
import '../providers/block_provider.dart';

class SearchScreen extends StatefulWidget {
  final int workspaceId;

  const SearchScreen({super.key, required this.workspaceId});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final _controller = TextEditingController();
  List<NotionPage> _results = [];
  bool _isSearching = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _search(String query) async {
    if (query.trim().isEmpty) {
      setState(() => _results = []);
      return;
    }
    setState(() => _isSearching = true);
    try {
      final results = await context
          .read<PageProvider>()
          .search(widget.workspaceId, query.trim());
      setState(() => _results = results);
    } finally {
      setState(() => _isSearching = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: TextField(
          controller: _controller,
          autofocus: true,
          decoration: const InputDecoration(
            hintText: 'Search pages…',
            border: InputBorder.none,
          ),
          onChanged: _search,
        ),
      ),
      body: _isSearching
          ? const Center(child: CircularProgressIndicator())
          : _results.isEmpty
              ? Center(
                  child: Text(
                    _controller.text.isEmpty
                        ? 'Start typing to search'
                        : 'No results',
                    style: TextStyle(
                        color: Theme.of(context).colorScheme.outline),
                  ),
                )
              : ListView.builder(
                  itemCount: _results.length,
                  itemBuilder: (context, index) {
                    final page = _results[index];
                    return ListTile(
                      leading: const Icon(Icons.article_outlined),
                      title: Text(
                          page.title.isEmpty ? 'Untitled' : page.title),
                      onTap: () async {
                        context.read<PageProvider>().selectPage(page);
                        await context
                            .read<BlockProvider>()
                            .loadBlocks(page.id);
                        if (context.mounted) {
                          Navigator.of(context).pop(); // close search
                        }
                      },
                    );
                  },
                ),
    );
  }
}
