import 'dart:convert';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

class OfflineSupportService {
  static const _cachedGamesKey = 'cached_games';
  static const _queuedActionsKey = 'queued_actions';

  static Stream<bool> connectivityStream() async* {
    final connectivity = Connectivity();
    yield* connectivity.onConnectivityChanged.map((r) => r != ConnectivityResult.none);
  }

  static Future<void> cacheGames(List<Map<String, dynamic>> games) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_cachedGamesKey, jsonEncode(games));
  }

  static Future<List<Map<String, dynamic>>> getCachedGames() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_cachedGamesKey);
    if (raw == null) return [];
    final list = (jsonDecode(raw) as List).cast<Map<String, dynamic>>();
    return list;
  }

  static Future<void> queueAction(Map<String, dynamic> action) async {
    final prefs = await SharedPreferences.getInstance();
    final existing = await getQueuedActions();
    existing.add(action);
    await prefs.setString(_queuedActionsKey, jsonEncode(existing));
  }

  static Future<List<Map<String, dynamic>>> getQueuedActions() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_queuedActionsKey);
    if (raw == null) return [];
    return (jsonDecode(raw) as List).cast<Map<String, dynamic>>();
  }

  static Future<void> clearQueuedActions() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_queuedActionsKey);
  }
}
