import 'package:flutter/material.dart';

/// Thoughts Input Widget - Clickable card that opens create post screen
class ThoughtsInput extends StatelessWidget {
  const ThoughtsInput({
    super.key,
    this.onTap,
    this.controller,
    this.minLines = 1,
    this.maxLines = 6,
    this.readOnly = false,
  });

  final VoidCallback? onTap;
  final TextEditingController? controller;
  final int minLines;
  final int? maxLines;
  final bool readOnly;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF301C4D),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: const Color(0xFFEBD7FA).withOpacity(0.12),
                width: 1,
              ),
            ),
            child: Text(
              "What's on your mind?",
              style: TextStyle(
                color: const Color(0xFFEBD7FA).withOpacity(0.70),
                fontFamily: 'Roboto',
                fontSize: 16,
                fontWeight: FontWeight.w400,
                letterSpacing: -0.312,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
