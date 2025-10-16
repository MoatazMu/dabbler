import 'package:flutter/material.dart';

class PasswordStrengthIndicator extends StatelessWidget {
  final String password;
  const PasswordStrengthIndicator({super.key, required this.password});

  int get _score {
    int score = 0;
    if (password.length >= 8) score++;
    if (RegExp(r'[A-Z]').hasMatch(password)) score++;
    if (RegExp(r'[a-z]').hasMatch(password)) score++;
    if (RegExp(r'[0-9]').hasMatch(password)) score++;
    if (RegExp(r'[!@#\$&*~_\-]').hasMatch(password)) score++;
    return score;
  }

  @override
  Widget build(BuildContext context) {
    final score = _score;
    final color = [Colors.red, Colors.orange, Colors.yellow, Colors.lightGreen, Colors.green][score.clamp(0, 4)];
    final label = ['Very Weak', 'Weak', 'Fair', 'Good', 'Strong'][score.clamp(0, 4)];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        LinearProgressIndicator(
          value: score / 5,
          color: color,
          backgroundColor: Colors.grey[300],
          minHeight: 6,
        ),
        const SizedBox(height: 4),
        Text('Strength: $label', style: TextStyle(color: color, fontSize: 12)),
      ],
    );
  }
}
