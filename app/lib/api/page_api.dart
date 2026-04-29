import '../models/page.dart';
import 'api_client.dart';

class PageApi {
  Future<List<NotionPage>> listPages({
    required int workspaceId,
    int? parentId,
    bool topLevelOnly = false,
    bool includeArchived = false,
    String? search,
  }) async {
    final query = <String, String>{
      'workspace': workspaceId.toString(),
    };
    if (topLevelOnly) query['parent'] = 'null';
    if (parentId != null) query['parent'] = parentId.toString();
    if (includeArchived) query['include_archived'] = 'true';
    if (search != null && search.isNotEmpty) query['search'] = search;

    final data = await apiClient.get('/pages/', query: query) as List<dynamic>;
    return data
        .map((p) => NotionPage.fromJson(p as Map<String, dynamic>))
        .toList();
  }

  Future<NotionPage> getPage(int id) async {
    final data = await apiClient.get('/pages/$id/') as Map<String, dynamic>;
    return NotionPage.fromJson(data);
  }

  Future<NotionPage> createPage({
    required int workspaceId,
    required String title,
    int? parentPageId,
  }) async {
    final body = <String, dynamic>{
      'title': title,
      'workspace': workspaceId,
    };
    if (parentPageId != null) body['parent_page'] = parentPageId;

    final data = await apiClient.post('/pages/', body) as Map<String, dynamic>;
    return NotionPage.fromJson(data);
  }

  Future<NotionPage> updateTitle(int id, String title) async {
    final data = await apiClient
        .patch('/pages/$id/', {'title': title}) as Map<String, dynamic>;
    return NotionPage.fromJson(data);
  }

  Future<void> archivePage(int id) async {
    await apiClient.post('/pages/$id/archive/', {});
  }

  Future<void> restorePage(int id) async {
    await apiClient.post('/pages/$id/restore/', {});
  }

  Future<void> deletePage(int id) async {
    await apiClient.delete('/pages/$id/');
  }
}

final pageApi = PageApi();
