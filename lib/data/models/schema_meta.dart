class SchemaMeta {
  const SchemaMeta({required this.schemaHash, this.notes});

  final String schemaHash;
  final String? notes;

  factory SchemaMeta.fromJson(Map<String, dynamic> json) {
    return SchemaMeta(
      schemaHash: json['schema_hash'] as String,
      notes: json['notes'] as String?,
    );
  }
}
