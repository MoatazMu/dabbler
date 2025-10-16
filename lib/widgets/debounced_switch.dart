import 'dart:async';
import 'package:flutter/material.dart';

class DebouncedSwitch extends StatefulWidget {
  final bool value;
  final ValueChanged<bool> onChanged;
  final Duration delay;

  const DebouncedSwitch({super.key, required this.value, required this.onChanged, this.delay = const Duration(milliseconds: 400)});

  @override
  State<DebouncedSwitch> createState() => _DebouncedSwitchState();
}

class _DebouncedSwitchState extends State<DebouncedSwitch> {
  late bool _value;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _value = widget.value;
  }

  @override
  void didUpdateWidget(covariant DebouncedSwitch oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.value != widget.value) {
      _value = widget.value;
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Switch(
      value: _value,
      onChanged: (v) {
        setState(() => _value = v);
        _timer?.cancel();
        _timer = Timer(widget.delay, () => widget.onChanged(v));
      },
    );
  }
}


