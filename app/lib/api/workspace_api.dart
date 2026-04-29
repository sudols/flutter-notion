import '../models/workspace.dart';
import 'api_client.dart';

class WorkspaceApi {
  Future<List<Workspace>> listWorkspaces() async {
    final data = await apiClient.get('/workspaces/') as List<dynamic>;
    return data
        .map((w) => Workspace.fromJson(w as Map<String, dynamic>))
        .toList();
  }

  Future<Workspace> getWorkspace(int id) async {
    final data =
        await apiClient.get('/workspaces/$id/') as Map<String, dynamic>;
    return Workspace.fromJson(data);
  }
}

final workspaceApi = WorkspaceApi();
