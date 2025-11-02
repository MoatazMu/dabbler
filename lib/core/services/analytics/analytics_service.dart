import 'dart:async';

typedef AnalyticsProps = Map<String, Object?>;

/// Central analytics façade. Wire your vendor(s) inside these methods.
class AnalyticsService {
  const AnalyticsService._();

  static Future<void> trackEvent(String name, [AnalyticsProps? props]) async {
    // TODO: forward to underlying provider(s)
  }

  static Future<void> trackScreen(
    String screenName, [
    AnalyticsProps? props,
  ]) async {
    // TODO: forward to underlying provider(s)
  }

  static Future<void> setUser(String userId, [AnalyticsProps? traits]) async {
    // TODO: implement identify
  }

  static Future<void> reset() async {
    // TODO: implement reset
  }
}
