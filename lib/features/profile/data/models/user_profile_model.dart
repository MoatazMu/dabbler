// Minimal UserProfile stub
class UserProfile {
  final String id;
  final String? username;
  final String? displayName;
  final String? email;
  final String? avatarUrl;
  final DateTime? createdAt;

  UserProfile({
    required this.id,
    this.username,
    this.displayName,
    this.email,
    this.avatarUrl,
    this.createdAt,
  });
}
