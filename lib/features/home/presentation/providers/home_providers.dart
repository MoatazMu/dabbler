import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dabbler/data/models/social/post_model.dart';
import 'package:dabbler/features/social/services/social_service.dart';

/// Provides the most recent public posts for surfaces like the home screen.
final latestFeedPostsProvider = FutureProvider.autoDispose<List<PostModel>>((
  ref,
) async {
  final socialService = SocialService();
  final posts = await socialService.getFeedPosts(limit: 3);
  return posts;
});
