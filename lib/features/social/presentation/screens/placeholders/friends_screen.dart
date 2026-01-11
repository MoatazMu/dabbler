import 'package:flutter/material.dart';

import '../real_friends_screen.dart';

/// Friends screen kept for backward compatibility.
///
/// This file previously contained hardcoded placeholder data.
/// It now delegates to the real friends screen implementation.
class FriendsScreen extends StatelessWidget {
  const FriendsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const RealFriendsScreen();
  }
}
