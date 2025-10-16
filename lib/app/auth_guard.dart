import 'package:flutter/material.dart';
import '../features/authentication/presentation/providers/auth_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class AuthGuard {
  static String? redirectIfUnauthenticated(BuildContext context) {
    final container = ProviderScope.containerOf(context, listen: false);
    final isAuthenticated = container.read(isAuthenticatedProvider);
    if (!isAuthenticated) {
      return '/login';
    }
    return null;
  }
}
