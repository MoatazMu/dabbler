import 'package:flutter/material.dart';

mixin ErrorHandlingMixin<T extends StatefulWidget> on State<T> {
  void showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }
}
