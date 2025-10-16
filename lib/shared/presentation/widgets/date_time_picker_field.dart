import 'package:flutter/material.dart';

class DateTimePickerField extends StatefulWidget {
  final String? labelText;
  final String? hintText;
  final DateTime? initialDateTime;
  final DateTime? firstDate;
  final DateTime? lastDate;
  final Function(DateTime?) onChanged;
  final bool enabled;
  final bool showTime;
  final bool showDate;
  final List<TimeOfDay>? allowedTimes;
  final List<int>? blockedWeekdays; // 1=Monday, 7=Sunday
  final String? errorText;
  final InputDecoration? decoration;
  final TextStyle? textStyle;
  final bool is24HourFormat;

  const DateTimePickerField({
    super.key,
    this.labelText,
    this.hintText,
    this.initialDateTime,
    this.firstDate,
    this.lastDate,
    required this.onChanged,
    this.enabled = true,
    this.showTime = true,
    this.showDate = true,
    this.allowedTimes,
    this.blockedWeekdays,
    this.errorText,
    this.decoration,
    this.textStyle,
    this.is24HourFormat = false,
  });

  @override
  State<DateTimePickerField> createState() => _DateTimePickerFieldState();
}

class _DateTimePickerFieldState extends State<DateTimePickerField> {
  DateTime? _selectedDateTime;
  final TextEditingController _controller = TextEditingController();

  @override
  void initState() {
    super.initState();
    _selectedDateTime = widget.initialDateTime;
    _updateController();
  }

  @override
  void didUpdateWidget(DateTimePickerField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.initialDateTime != oldWidget.initialDateTime) {
      _selectedDateTime = widget.initialDateTime;
      _updateController();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _updateController() {
    if (_selectedDateTime != null) {
      _controller.text = _formatDateTime(_selectedDateTime!);
    } else {
      _controller.clear();
    }
  }

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: _controller,
      enabled: widget.enabled,
      readOnly: true,
      style: widget.textStyle,
      decoration: widget.decoration ?? _buildDefaultDecoration(),
      onTap: widget.enabled ? _showDateTimePicker : null,
    );
  }

  InputDecoration _buildDefaultDecoration() {
    return InputDecoration(
      labelText: widget.labelText,
      hintText: widget.hintText ?? _getDefaultHintText(),
      errorText: widget.errorText,
      suffixIcon: _buildSuffixIcon(),
      border: const OutlineInputBorder(),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
    );
  }

  Widget _buildSuffixIcon() {
    if (!widget.showDate && widget.showTime) {
      return const Icon(Icons.access_time);
    } else if (widget.showDate && !widget.showTime) {
      return const Icon(Icons.calendar_today);
    } else {
      return const Icon(Icons.event);
    }
  }

  String _getDefaultHintText() {
    if (!widget.showDate && widget.showTime) {
      return 'Select time';
    } else if (widget.showDate && !widget.showTime) {
      return 'Select date';
    } else {
      return 'Select date and time';
    }
  }

  Future<void> _showDateTimePicker() async {
    DateTime? selectedDate = _selectedDateTime;
    TimeOfDay? selectedTime = _selectedDateTime != null
        ? TimeOfDay.fromDateTime(_selectedDateTime!)
        : null;

    // Show date picker if enabled
    if (widget.showDate) {
      final pickedDate = await _showCustomDatePicker();
      if (pickedDate == null) return;
      selectedDate = pickedDate;
    } else {
      selectedDate ??= DateTime.now();
    }

    // Show time picker if enabled
    if (widget.showTime) {
      final pickedTime = await _showCustomTimePicker(selectedDate);
      if (pickedTime == null) return;
      selectedTime = pickedTime;
    } else {
      selectedTime ??= const TimeOfDay(hour: 12, minute: 0);
    }

    // Combine date and time
    final newDateTime = DateTime(
      selectedDate.year,
      selectedDate.month,
      selectedDate.day,
      selectedTime.hour,
      selectedTime.minute,
    );

    setState(() {
      _selectedDateTime = newDateTime;
      _updateController();
    });

    widget.onChanged(_selectedDateTime);
    }

  Future<DateTime?> _showCustomDatePicker() async {
    final now = DateTime.now();
    final firstDate = widget.firstDate ?? now.subtract(const Duration(days: 365));
    final lastDate = widget.lastDate ?? now.add(const Duration(days: 365));

    return await showDatePicker(
      context: context,
      initialDate: _selectedDateTime ?? now,
      firstDate: firstDate,
      lastDate: lastDate,
      selectableDayPredicate: _isDateSelectable,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: Theme.of(context).colorScheme.copyWith(
              primary: Theme.of(context).primaryColor,
            ),
          ),
          child: child!,
        );
      },
    );
  }

  Future<TimeOfDay?> _showCustomTimePicker(DateTime selectedDate) async {
    if (widget.allowedTimes != null && widget.allowedTimes!.isNotEmpty) {
      return await _showTimeSlotPicker(selectedDate);
    }

    final initialTime = _selectedDateTime != null
        ? TimeOfDay.fromDateTime(_selectedDateTime!)
        : TimeOfDay.now();

    return await showTimePicker(
      context: context,
      initialTime: initialTime,
      builder: (context, child) {
        return MediaQuery(
          data: MediaQuery.of(context).copyWith(
            alwaysUse24HourFormat: widget.is24HourFormat,
          ),
          child: Theme(
            data: Theme.of(context).copyWith(
              timePickerTheme: TimePickerThemeData(
                backgroundColor: Colors.white,
                hourMinuteColor: WidgetStateColor.resolveWith(
                  (states) => states.contains(WidgetState.selected)
                      ? Theme.of(context).primaryColor.withOpacity(0.2)
                      : Colors.grey[100]!,
                ),
                dialHandColor: Theme.of(context).primaryColor,
                dialBackgroundColor: Colors.grey[50],
              ),
            ),
            child: child!,
          ),
        );
      },
    );
  }

  Future<TimeOfDay?> _showTimeSlotPicker(DateTime selectedDate) async {
    final availableSlots = _getAvailableTimeSlots(selectedDate);

    if (availableSlots.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No available time slots for this date'),
          backgroundColor: Colors.orange,
        ),
      );
      return null;
    }

    return await showDialog<TimeOfDay>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Select Time Slot'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: availableSlots.map((time) => ListTile(
              title: Text(_formatTimeOfDay(time)),
              onTap: () => Navigator.of(context).pop(time),
              selected: _selectedDateTime != null &&
                  TimeOfDay.fromDateTime(_selectedDateTime!) == time,
            )).toList(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }

  bool _isDateSelectable(DateTime date) {
    // Check if weekday is blocked
    if (widget.blockedWeekdays != null &&
        widget.blockedWeekdays!.contains(date.weekday)) {
      return false;
    }

    return true;
  }

  List<TimeOfDay> _getAvailableTimeSlots(DateTime date) {
    if (widget.allowedTimes == null) return [];

    // Filter out past time slots for today
    final now = DateTime.now();
    if (date.year == now.year &&
        date.month == now.month &&
        date.day == now.day) {
      return widget.allowedTimes!.where((time) {
        final slotDateTime = DateTime(
          date.year,
          date.month,
          date.day,
          time.hour,
          time.minute,
        );
        return slotDateTime.isAfter(now);
      }).toList();
    }

    return widget.allowedTimes!;
  }

  String _formatDateTime(DateTime dateTime) {
    final parts = <String>[];

    if (widget.showDate) {
      parts.add(_formatDate(dateTime));
    }

    if (widget.showTime) {
      parts.add(_formatTime(dateTime));
    }

    return parts.join(' at ');
  }

  String _formatDate(DateTime date) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];

    return '${months[date.month - 1]} ${date.day}, ${date.year}';
  }

  String _formatTime(DateTime dateTime) {
    final time = TimeOfDay.fromDateTime(dateTime);
    return _formatTimeOfDay(time);
  }

  String _formatTimeOfDay(TimeOfDay time) {
    if (widget.is24HourFormat) {
      return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
    } else {
      final hour = time.hourOfPeriod == 0 ? 12 : time.hourOfPeriod;
      final period = time.period == DayPeriod.am ? 'AM' : 'PM';
      return '$hour:${time.minute.toString().padLeft(2, '0')} $period';
    }
  }

  // Public methods for external control
  void setDateTime(DateTime? dateTime) {
    setState(() {
      _selectedDateTime = dateTime;
      _updateController();
    });
  }

  void clearDateTime() {
    setState(() {
      _selectedDateTime = null;
      _controller.clear();
    });
    widget.onChanged(null);
  }

  DateTime? get selectedDateTime => _selectedDateTime;
}

// Utility function to create common time slots
List<TimeOfDay> createTimeSlots({
  TimeOfDay start = const TimeOfDay(hour: 9, minute: 0),
  TimeOfDay end = const TimeOfDay(hour: 21, minute: 0),
  int intervalMinutes = 30,
}) {
  final slots = <TimeOfDay>[];
  
  int currentMinutes = start.hour * 60 + start.minute;
  final endMinutes = end.hour * 60 + end.minute;
  
  while (currentMinutes <= endMinutes) {
    final hour = currentMinutes ~/ 60;
    final minute = currentMinutes % 60;
    
    if (hour < 24) {
      slots.add(TimeOfDay(hour: hour, minute: minute));
    }
    
    currentMinutes += intervalMinutes;
  }
  
  return slots;
}

// Utility function to create blocked weekdays list
List<int> createBlockedWeekdays({
  bool blockSunday = false,
  bool blockMonday = false,
  bool blockTuesday = false,
  bool blockWednesday = false,
  bool blockThursday = false,
  bool blockFriday = false,
  bool blockSaturday = false,
}) {
  final blocked = <int>[];
  
  if (blockMonday) blocked.add(1);
  if (blockTuesday) blocked.add(2);
  if (blockWednesday) blocked.add(3);
  if (blockThursday) blocked.add(4);
  if (blockFriday) blocked.add(5);
  if (blockSaturday) blocked.add(6);
  if (blockSunday) blocked.add(7);
  
  return blocked;
}
