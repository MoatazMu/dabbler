import 'package:flutter/material.dart';

class CreateGameScreen extends StatelessWidget {
  final Map<String, dynamic>? initialData;

  const CreateGameScreen({super.key, this.initialData});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Create Game')),
      body: const Center(
        child: Text('Create Game Screen - Under Construction'),
      ),
    );
  }
}
