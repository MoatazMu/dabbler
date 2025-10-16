import 'package:flutter/material.dart';

class PhoneVerificationScreen extends StatelessWidget {
  const PhoneVerificationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Verify Phone')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            const Text('Enter the code sent to your phone'),
            const SizedBox(height: 16),
            TextField(
              decoration: const InputDecoration(labelText: 'Verification Code'),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () {
                Navigator.pushReplacementNamed(context, '/complete-profile');
              },
              child: const Text('Verify'),
            ),
          ],
        ),
      ),
    );
  }
}
