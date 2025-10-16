import '../models/profile_model.dart';

abstract class ProfileLocalDataSource {
  Future<ProfileModel?> getCachedProfile(String userId);
  Future<void> cacheProfile(ProfileModel profile);
  Future<bool> isCacheValid(String userId);
  Future<void> removeCachedProfile(String userId);
}

class ProfileLocalDataSourceImpl implements ProfileLocalDataSource {
  // This is a mock implementation. In a real app, you would use a database like Hive or shared_preferences.
  final Map<String, ProfileModel> _cache = {};
  final Map<String, DateTime> _cacheTime = {};

  @override
  Future<void> cacheProfile(ProfileModel profile) async {
    _cache[profile.id] = profile;
    _cacheTime[profile.id] = DateTime.now();
  }

  @override
  Future<ProfileModel?> getCachedProfile(String userId) async {
    return _cache[userId];
  }

  @override
  Future<bool> isCacheValid(String userId) async {
    final cachedTime = _cacheTime[userId];
    if (cachedTime == null) {
      return false;
    }
    // Cache is valid for 5 minutes
    return DateTime.now().difference(cachedTime).inMinutes < 5;
  }

  @override
  Future<void> removeCachedProfile(String userId) async {
    _cache.remove(userId);
    _cacheTime.remove(userId);
  }
}
