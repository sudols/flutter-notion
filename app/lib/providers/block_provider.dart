import 'dart:async';
import 'package:flutter/foundation.dart';

import '../api/block_api.dart';
import '../models/block.dart';

class BlockProvider extends ChangeNotifier {
  List<Block> _blocks = [];
  bool _isLoading = false;
  String? _error;

  // Timer used to debounce auto-save.
  final Map<int, Timer> _saveTimers = {};

  List<Block> get blocks => _blocks;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> loadBlocks(int pageId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _blocks = await blockApi.listBlocks(pageId);
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<Block> addBlock({
    required int pageId,
    BlockType blockType = BlockType.text,
    String content = '',
  }) async {
    final block = await blockApi.createBlock(
      pageId: pageId,
      blockType: blockType,
      content: content,
    );
    _blocks.add(block);
    notifyListeners();
    return block;
  }

  /// Updates a block locally and schedules a debounced API save (500ms).
  void updateContentLocally(int blockId, String content) {
    final index = _blocks.indexWhere((b) => b.id == blockId);
    if (index == -1) return;
    _blocks[index] = _blocks[index].copyWith(content: content);
    notifyListeners();
    _scheduleSave(blockId, content: content);
  }

  void updateCheckedLocally(int blockId, bool isChecked) {
    final index = _blocks.indexWhere((b) => b.id == blockId);
    if (index == -1) return;
    _blocks[index] = _blocks[index].copyWith(isChecked: isChecked);
    notifyListeners();
    _scheduleSave(blockId, isChecked: isChecked);
  }

  Future<void> changeBlockType(int blockId, BlockType newType) async {
    final index = _blocks.indexWhere((b) => b.id == blockId);
    if (index == -1) return;
    final updated = await blockApi.updateBlock(
      blockId: blockId,
      blockType: newType,
    );
    _blocks[index] = updated;
    notifyListeners();
  }

  Future<void> deleteBlock(int blockId) async {
    _saveTimers[blockId]?.cancel();
    _saveTimers.remove(blockId);
    await blockApi.deleteBlock(blockId);
    _blocks.removeWhere((b) => b.id == blockId);
    notifyListeners();
  }

  /// Reorders blocks after drag-and-drop and syncs to API.
  Future<void> reorder(int pageId, int oldIndex, int newIndex) async {
    // ReorderableListView passes newIndex after removal, adjust it.
    if (newIndex > oldIndex) newIndex -= 1;
    final block = _blocks.removeAt(oldIndex);
    _blocks.insert(newIndex, block);
    notifyListeners();

    // Sync new order to backend.
    final orderedIds = _blocks.map((b) => b.id).toList();
    await blockApi.reorderBlocks(
      pageId: pageId,
      orderedBlockIds: orderedIds,
    );
  }

  void _scheduleSave(
    int blockId, {
    String? content,
    bool? isChecked,
  }) {
    _saveTimers[blockId]?.cancel();
    _saveTimers[blockId] = Timer(const Duration(milliseconds: 500), () async {
      try {
        await blockApi.updateBlock(
          blockId: blockId,
          content: content,
          isChecked: isChecked,
        );
      } catch (e) {
        // Log the error; the local state is still up-to-date.
        debugPrint('Auto-save failed for block $blockId: $e');
      }
      _saveTimers.remove(blockId);
    });
  }

  void reset() {
    for (final timer in _saveTimers.values) {
      timer.cancel();
    }
    _saveTimers.clear();
    _blocks = [];
    _error = null;
    notifyListeners();
  }
}
