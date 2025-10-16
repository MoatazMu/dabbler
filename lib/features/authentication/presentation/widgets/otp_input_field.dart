import 'package:flutter/material.dart';

class OtpInputField extends StatelessWidget {
  final void Function(String) onChanged;
  final bool isLoading;
  final String? error;
  const OtpInputField({super.key, required this.onChanged, this.isLoading = false, this.error});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        TextField(
          keyboardType: TextInputType.number,
          maxLength: 6,
          decoration: InputDecoration(
            labelText: 'Verification Code',
            errorText: error,
            counterText: '',
          ),
          onChanged: onChanged,
        ),
        if (isLoading) const Padding(
          padding: EdgeInsets.only(top: 8.0),
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      ],
    );
  }
}
