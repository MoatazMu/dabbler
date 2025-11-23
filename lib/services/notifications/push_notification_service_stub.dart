import 'package:flutter/foundation.dart';

/// Stub implementation for web platform (no-op).
class PushNotificationService {
  PushNotificationService._internal();
  static final PushNotificationService instance =
      PushNotificationService._internal();

  bool _initialized = false;

  Future<void> init() async {
    if (_initialized) return;
    // Push notifications are not supported on web in this app.
    debugPrint('🔔 [Push] Skipping push notification setup on web platform');
    _initialized = true;
  }
}

