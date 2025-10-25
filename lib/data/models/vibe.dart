class Vibe {
  final String id;
  final String postId;
  final String? key;
  final String? label;
  final String? emoji;
  final int sortOrder;
  final DateTime? createdAt;

  const Vibe({
    required this.id,
    required this.postId,
    this.key,
    this.label,
    this.emoji,
    this.sortOrder = 0,
    this.createdAt,
  });

  factory Vibe.fromJson(Map<String, dynamic> json) {
    return Vibe(
      id: json['id'] as String,
      postId: json['post_id'] as String,
      key: json['key'] as String?,
      label: json['label'] as String?,
      emoji: json['emoji'] as String?,
      sortOrder: (json['sort_order'] as num?)?.toInt() ?? 0,
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'post_id': postId,
        if (key != null) 'key': key,
        if (label != null) 'label': label,
        if (emoji != null) 'emoji': emoji,
        'sort_order': sortOrder,
        if (createdAt != null) 'created_at': createdAt!.toIso8601String(),
      };

  Vibe copyWith({
    String? id,
    String? postId,
    String? key,
    String? label,
    String? emoji,
    int? sortOrder,
    DateTime? createdAt,
  }) {
    return Vibe(
      id: id ?? this.id,
      postId: postId ?? this.postId,
      key: key ?? this.key,
      label: label ?? this.label,
      emoji: emoji ?? this.emoji,
      sortOrder: sortOrder ?? this.sortOrder,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
