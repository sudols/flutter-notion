import 'package:flutter/foundation.dart';

import '../api/workspace_api.dart';
import '../models/workspace.dart';

class WorkspaceProvider extends ChangeNotifier {
  List<Workspace> _workspaces = [];
  Workspace? _current;
  bool _isLoading = false;
  String? _error;

  List<Workspace> get workspaces => _workspaces;
  Workspace? get current => _current;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> loadWorkspaces() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _workspaces = await workspaceApi.listWorkspaces();
      if (_workspaces.isNotEmpty) {
        _current ??= _workspaces.first;
      }
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void selectWorkspace(Workspace workspace) {
    _current = workspace;
    notifyListeners();
  }

  void reset() {
    _workspaces = [];
    _current = null;
    _error = null;
    notifyListeners();
  }
}
