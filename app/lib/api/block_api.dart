import '../models/block.dart';
import 'api_client.dart';

class BlockApi {
  Future<List<Block>> listBlocks(int pageId) async {
    final data = await apiClient.get(
      '/blocks/',
      query: {'page': pageId.toString()},
    ) as List<dynamic>;
    return data
        .map((b) => Block.fromJson(b as Map<String, dynamic>))
        .toList();
  }

  Future<Block> createBlock({
    required int pageId,
    required BlockType blockType,
    String content = '',
    bool isChecked = false,
  }) async {
    final data = await apiClient.post('/blocks/', {
      'page': pageId,
      'block_type': blockType.apiValue,
      'content': content,
      'is_checked': isChecked,
    }) as Map<String, dynamic>;
    return Block.fromJson(data);
  }

  Future<Block> updateBlock({
    required int blockId,
    BlockType? blockType,
    String? content,
    bool? isChecked,
  }) async {
    final body = <String, dynamic>{};
    if (blockType != null) body['block_type'] = blockType.apiValue;
    if (content != null) body['content'] = content;
    if (isChecked != null) body['is_checked'] = isChecked;

    final data = await apiClient.patch('/blocks/$blockId/', body)
        as Map<String, dynamic>;
    return Block.fromJson(data);
  }

  Future<void> deleteBlock(int blockId) async {
    await apiClient.delete('/blocks/$blockId/');
  }

  Future<List<Block>> reorderBlocks({
    required int pageId,
    required List<int> orderedBlockIds,
  }) async {
    final data = await apiClient.post('/blocks/reorder/', {
      'page_id': pageId,
      'ordered_block_ids': orderedBlockIds,
    }) as List<dynamic>;
    return data
        .map((b) => Block.fromJson(b as Map<String, dynamic>))
        .toList();
  }
}

final blockApi = BlockApi();
