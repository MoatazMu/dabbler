import 'package:dabbler/core/config/supabase_config.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

String? resolveAvatarUrl(String? avatarUrlOrPath) {
  final value = avatarUrlOrPath?.trim();
  if (value == null || value.isEmpty) return null;

  if (value.startsWith('http://') || value.startsWith('https://')) {
    return value;
  }

  return Supabase.instance.client.storage
      .from(SupabaseConfig.avatarsBucket)
      .getPublicUrl(value);
}
