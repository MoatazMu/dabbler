import 'package:flutter/material.dart';

/// Thoughts Input Widget - Multiline text field for sharing thoughts
class ThoughtsInput extends StatefulWidget {
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
  State<ThoughtsInput> createState() => _ThoughtsInputState();
}

class _ThoughtsInputState extends State<ThoughtsInput> {
  late TextEditingController _controller;
  final FocusNode _focusNode = FocusNode();
  bool _isFocused = false;

  @override
  void initState() {
    super.initState();
    _controller = widget.controller ?? TextEditingController();
    _focusNode.addListener(_onFocusChange);
  }

  @override
  void dispose() {
    _focusNode.removeListener(_onFocusChange);
    _focusNode.dispose();
    if (widget.controller == null) {
      _controller.dispose();
    }
    super.dispose();
  }

  void _onFocusChange() {
    setState(() {
      _isFocused = _focusNode.hasFocus;
    });
  }

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: _controller,
      focusNode: _focusNode,
      readOnly: widget.readOnly,
      onTap: widget.onTap,
      maxLines: _isFocused ? widget.maxLines : widget.minLines,
      minLines: _isFocused ? 3 : widget.minLines,
      style: const TextStyle(
        color: Color(0xFFEBD7FA),
        fontFamily: 'Inter',
        fontSize: 16,
        fontWeight: FontWeight.w400,
        letterSpacing: -0.312,
      ),
      decoration: InputDecoration(
        hintText: "What's on your mind?",
        hintStyle: TextStyle(
          color: const Color(0xFFEBD7FA).withOpacity(0.70),
          fontFamily: 'Inter',
          fontSize: 16,
          fontWeight: FontWeight.w400,
          letterSpacing: -0.312,
        ),
        filled: true,
        fillColor: const Color(0xFF301C4D),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(22),
          borderSide: BorderSide(
            color: const Color(0xFFEBD7FA).withOpacity(0.24),
            width: 1,
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(22),
          borderSide: BorderSide(
            color: const Color(0xFFEBD7FA).withOpacity(0.24),
            width: 1,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(22),
          borderSide: BorderSide(
            color: const Color(0xFFEBD7FA).withOpacity(0.5),
            width: 1.5,
          ),
        ),
        contentPadding: EdgeInsets.symmetric(
          horizontal: 18,
          vertical: _isFocused ? 24 : 12,
        ),
      ),
    );
  }
}
