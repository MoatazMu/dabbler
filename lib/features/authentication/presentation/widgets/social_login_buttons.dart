import 'package:flutter/material.dart';

class SocialLoginButtons extends StatelessWidget {
  final bool isLoading;
  final void Function(String provider) onLogin;
  const SocialLoginButtons({super.key, required this.isLoading, required this.onLogin});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            icon: Image.asset('assets/icons/google.png', height: 24),
            label: const Text('Continue with Google'),
            onPressed: isLoading ? null : () => onLogin('google'),
          ),
        ),
        const SizedBox(height: 8),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            icon: Image.asset('assets/icons/apple.png', height: 24),
            label: const Text('Continue with Apple'),
            onPressed: isLoading ? null : () => onLogin('apple'),
          ),
        ),
      ],
    );
  }
}
