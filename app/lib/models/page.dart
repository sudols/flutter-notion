class NotionPage {
  final int id;
  final String title;
  final int workspaceId;
  final int ownerId;
  final int? parentPageId;
  final bool isArchived;
  final DateTime updatedAt;

  const NotionPage({
    required this.id,
    required this.title,
    required this.workspaceId,
    required this.ownerId,
    this.parentPageId,
    required this.isArchived,
    required this.updatedAt,
  });

  factory NotionPage.fromJson(Map<String, dynamic> json) {
    return NotionPage(
      id: json['id'] as int,
      title: json['title'] as String,
      workspaceId: json['workspace'] as int,
      ownerId: (json['owner'] as Map<String, dynamic>)['id'] as int,
      parentPageId: json['parent_page'] as int?,
      isArchived: json['is_archived'] as bool? ?? false,
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  NotionPage copyWith({String? title, bool? isArchived, int? parentPageId}) {
    return NotionPage(
      id: id,
      title: title ?? this.title,
      workspaceId: workspaceId,
      ownerId: ownerId,
      parentPageId: parentPageId ?? this.parentPageId,
      isArchived: isArchived ?? this.isArchived,
      updatedAt: updatedAt,
    );
  }
}
