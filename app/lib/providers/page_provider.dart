import 'package:flutter/foundation.dart';

import '../api/page_api.dart';
import '../models/page.dart';

class PageProvider extends ChangeNotifier {
  // All non-archived pages for the current workspace, flat list.
  List<NotionPage> _pages = [];
  List<NotionPage> _archivedPages = [];
  NotionPage? _activePage;
  bool _isLoading = false;
  String? _error;

  List<NotionPage> get pages => _pages;
  List<NotionPage> get archivedPages => _archivedPages;
  NotionPage? get activePage => _activePage;
  bool get isLoading => _isLoading;
  String? get error => _error;

  // Returns top-level pages (no parent).
  List<NotionPage> get rootPages =>
      _pages.where((p) => p.parentPageId == null).toList();

  // Returns children of a given page.
  List<NotionPage> childrenOf(int parentId) =>
      _pages.where((p) => p.parentPageId == parentId).toList();

  Future<void> loadPages(int workspaceId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _pages = await pageApi.listPages(workspaceId: workspaceId);
      _archivedPages = await pageApi.listPages(
        workspaceId: workspaceId,
        includeArchived: true,
      ).then((all) => all.where((p) => p.isArchived).toList());
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<NotionPage> createPage({
    required int workspaceId,
    String title = 'Untitled',
    int? parentPageId,
  }) async {
    final page = await pageApi.createPage(
      workspaceId: workspaceId,
      title: title,
      parentPageId: parentPageId,
    );
    _pages.add(page);
    notifyListeners();
    return page;
  }

  Future<void> updateTitle(int pageId, String newTitle) async {
    final updated = await pageApi.updateTitle(pageId, newTitle);
    final index = _pages.indexWhere((p) => p.id == pageId);
    if (index != -1) {
      _pages[index] = updated;
      if (_activePage?.id == pageId) _activePage = updated;
      notifyListeners();
    }
  }

  Future<void> archivePage(int pageId) async {
    await pageApi.archivePage(pageId);
    final page = _pages.firstWhere((p) => p.id == pageId);
    _pages.removeWhere((p) => p.id == pageId);
    _archivedPages.add(page.copyWith(isArchived: true));
    if (_activePage?.id == pageId) _activePage = null;
    notifyListeners();
  }

  Future<void> restorePage(int pageId) async {
    await pageApi.restorePage(pageId);
    final page = _archivedPages.firstWhere((p) => p.id == pageId);
    _archivedPages.removeWhere((p) => p.id == pageId);
    _pages.add(page.copyWith(isArchived: false));
    notifyListeners();
  }

  void selectPage(NotionPage page) {
    _activePage = page;
    notifyListeners();
  }

  Future<List<NotionPage>> search(int workspaceId, String query) async {
    return pageApi.listPages(workspaceId: workspaceId, search: query);
  }

  void reset() {
    _pages = [];
    _archivedPages = [];
    _activePage = null;
    _error = null;
    notifyListeners();
  }
}
