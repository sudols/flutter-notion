enum BlockType { text, heading, todo, bullet }

extension BlockTypeExt on BlockType {
  String get apiValue {
    switch (this) {
      case BlockType.text:
        return 'text';
      case BlockType.heading:
        return 'heading';
      case BlockType.todo:
        return 'todo';
      case BlockType.bullet:
        return 'bullet';
    }
  }

  static BlockType fromApi(String value) {
    switch (value) {
      case 'heading':
        return BlockType.heading;
      case 'todo':
        return BlockType.todo;
      case 'bullet':
        return BlockType.bullet;
      default:
        return BlockType.text;
    }
  }
}

class Block {
  final int id;
  final int pageId;
  final BlockType blockType;
  final String content;
  final bool isChecked;
  final int position;

  const Block({
    required this.id,
    required this.pageId,
    required this.blockType,
    required this.content,
    required this.isChecked,
    required this.position,
  });

  factory Block.fromJson(Map<String, dynamic> json) {
    return Block(
      id: json['id'] as int,
      pageId: json['page'] as int,
      blockType: BlockTypeExt.fromApi(json['block_type'] as String),
      content: json['content'] as String? ?? '',
      isChecked: json['is_checked'] as bool? ?? false,
      position: json['position'] as int,
    );
  }

  Block copyWith({
    BlockType? blockType,
    String? content,
    bool? isChecked,
    int? position,
  }) {
    return Block(
      id: id,
      pageId: pageId,
      blockType: blockType ?? this.blockType,
      content: content ?? this.content,
      isChecked: isChecked ?? this.isChecked,
      position: position ?? this.position,
    );
  }
}
