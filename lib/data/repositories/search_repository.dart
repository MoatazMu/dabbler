
import 'package:dabbler/core/fp/result.dart';
import '../models/profile.dart';
import '../models/venue.dart';
import '../models/post.dart';

abstract class SearchRepository {
  Future<Result<List<Profile>>> searchProfiles({
    required String query,
    int limit = 20,
    int offset = 0,
  });

  Future<Result<List<Venue>>> searchVenues({
    required String query,
    int limit = 20,
    int offset = 0,
  });

  Future<Result<List<Post>>> searchPosts({
    required String query,
    int limit = 20,
    int offset = 0,
  });
}

