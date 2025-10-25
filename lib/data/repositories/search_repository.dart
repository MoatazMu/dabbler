import '../../core/types/result.dart';
import '../models/post.dart';
import '../models/profile.dart';
import '../models/venue.dart';

abstract class SearchRepository {
  Future<Result<List<Post>>> searchPosts(
    String q, {
    int limit = 20,
    int offset = 0,
  });

  Future<Result<List<Venue>>> searchVenues(
    String q, {
    int limit = 20,
    int offset = 0,
  });

  Future<Result<List<Profile>>> searchProfiles(
    String q, {
    int limit = 20,
    int offset = 0,
  });
}
