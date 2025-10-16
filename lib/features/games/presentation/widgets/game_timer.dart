import 'package:flutter/material.dart';
import 'dart:async';

enum TimerMode { countdown, countup, stopwatch }
enum TimerState { stopped, running, paused }
enum SportType { soccer, basketball, tennis, volleyball, other }

class GameTimer extends StatefulWidget {
  final TimerMode mode;
  final SportType sport;
  final Duration initialDuration;
  final Duration? maxDuration;
  final Function(Duration)? onTick;
  final Function(Duration)? onComplete;
  final Function(TimerState)? onStateChanged;
  final bool showControls;
  final bool showPeriods;
  final bool enableSoundAlerts;
  final Color? primaryColor;
  final double size;

  const GameTimer({
    super.key,
    this.mode = TimerMode.countup,
    this.sport = SportType.other,
    this.initialDuration = Duration.zero,
    this.maxDuration,
    this.onTick,
    this.onComplete,
    this.onStateChanged,
    this.showControls = true,
    this.showPeriods = false,
    this.enableSoundAlerts = true,
    this.primaryColor,
    this.size = 120,
  });

  @override
  State<GameTimer> createState() => _GameTimerState();
}

class _GameTimerState extends State<GameTimer>
    with TickerProviderStateMixin {
  late Timer _timer;
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;
  
  Duration _currentDuration = Duration.zero;
  TimerState _state = TimerState.stopped;
  int _currentPeriod = 1;
  int _totalPeriods = 2;
  bool _isOvertime = false;
  
  @override
  void initState() {
    super.initState();
    _currentDuration = widget.initialDuration;
    _setupSportSpecificSettings();
    
    _pulseController = AnimationController(
      duration: const Duration(seconds: 1),
      vsync: this,
    );
    
    _pulseAnimation = Tween<double>(
      begin: 1.0,
      end: 1.1,
    ).animate(CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void dispose() {
    if (_timer.isActive) _timer.cancel();
    _pulseController.dispose();
    super.dispose();
  }

  void _setupSportSpecificSettings() {
    switch (widget.sport) {
      case SportType.soccer:
        _totalPeriods = 2; // Two halves
        break;
      case SportType.basketball:
        _totalPeriods = 4; // Four quarters
        break;
      case SportType.tennis:
        _totalPeriods = 1; // Sets (handled differently)
        break;
      case SportType.volleyball:
        _totalPeriods = 1; // Sets to win (handled differently)
        break;
      case SportType.other:
        _totalPeriods = 1;
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: widget.size * 2,
      child: Column(
        children: [
          _buildTimerDisplay(),
          if (widget.showPeriods) ...[
            const SizedBox(height: 12),
            _buildPeriodIndicator(),
          ],
          if (widget.showControls) ...[
            const SizedBox(height: 16),
            _buildControlButtons(),
          ],
        ],
      ),
    );
  }

  Widget _buildTimerDisplay() {
    final color = widget.primaryColor ?? Theme.of(context).primaryColor;
    
    return AnimatedBuilder(
      animation: _pulseAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: _state == TimerState.running ? _pulseAnimation.value : 1.0,
          child: Container(
            width: widget.size,
            height: widget.size,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: _getTimerBackgroundColor(),
              border: Border.all(
                color: color,
                width: 4,
              ),
              boxShadow: [
                BoxShadow(
                  color: color.withOpacity(0.3),
                  blurRadius: 8,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: Stack(
              children: [
                // Progress indicator for countdown mode
                if (widget.mode == TimerMode.countdown && widget.maxDuration != null)
                  _buildProgressRing(color),
                
                // Timer text
                Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        _formatDuration(_currentDuration),
                        style: TextStyle(
                          fontSize: widget.size * 0.15,
                          fontWeight: FontWeight.bold,
                          color: _getTimerTextColor(),
                          fontFamily: 'monospace',
                        ),
                      ),
                      if (_isOvertime)
                        Text(
                          'OT',
                          style: TextStyle(
                            fontSize: widget.size * 0.08,
                            fontWeight: FontWeight.bold,
                            color: Colors.red,
                          ),
                        ),
                    ],
                  ),
                ),
                
                // State indicator
                Positioned(
                  top: 8,
                  right: 8,
                  child: _buildStateIndicator(),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildProgressRing(Color color) {
    final progress = widget.maxDuration != null
        ? (_currentDuration.inSeconds / widget.maxDuration!.inSeconds).clamp(0.0, 1.0)
        : 0.0;
    
    return Positioned.fill(
      child: CircularProgressIndicator(
        value: widget.mode == TimerMode.countdown ? 1.0 - progress : progress,
        strokeWidth: 6,
        backgroundColor: Colors.grey[300],
        valueColor: AlwaysStoppedAnimation<Color>(color),
      ),
    );
  }

  Widget _buildStateIndicator() {
    IconData icon;
    Color color;
    
    switch (_state) {
      case TimerState.running:
        icon = Icons.play_arrow;
        color = Colors.green;
        break;
      case TimerState.paused:
        icon = Icons.pause;
        color = Colors.orange;
        break;
      case TimerState.stopped:
        icon = Icons.stop;
        color = Colors.grey;
        break;
    }

    return Container(
      width: 24,
      height: 24,
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        shape: BoxShape.circle,
      ),
      child: Icon(
        icon,
        color: color,
        size: 16,
      ),
    );
  }

  Widget _buildPeriodIndicator() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            _getSportIcon(),
            size: 16,
            color: Colors.grey[600],
          ),
          const SizedBox(width: 8),
          Text(
            _getPeriodText(),
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
          if (_totalPeriods > 1) ...[
            const SizedBox(width: 12),
            ...List.generate(_totalPeriods, (index) {
              final isActive = index + 1 == _currentPeriod;
              final isCompleted = index + 1 < _currentPeriod;
              
              return Container(
                margin: const EdgeInsets.symmetric(horizontal: 2),
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: isCompleted 
                      ? Colors.green 
                      : isActive 
                          ? Theme.of(context).primaryColor 
                          : Colors.grey[300],
                  shape: BoxShape.circle,
                ),
              );
            }),
          ],
        ],
      ),
    );
  }

  Widget _buildControlButtons() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Start/Pause button
        _buildControlButton(
          icon: _state == TimerState.running ? Icons.pause : Icons.play_arrow,
          label: _state == TimerState.running ? 'Pause' : 'Start',
          color: _state == TimerState.running ? Colors.orange : Colors.green,
          onPressed: _toggleTimer,
        ),
        
        const SizedBox(width: 12),
        
        // Stop/Reset button
        _buildControlButton(
          icon: Icons.stop,
          label: 'Reset',
          color: Colors.red,
          onPressed: _resetTimer,
        ),
        
        if (widget.showPeriods && _totalPeriods > 1) ...[
          const SizedBox(width: 12),
          _buildControlButton(
            icon: Icons.skip_next,
            label: 'Next\nPeriod',
            color: Colors.blue,
            onPressed: _nextPeriod,
            isSmall: true,
          ),
        ],
      ],
    );
  }

  Widget _buildControlButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onPressed,
    bool isSmall = false,
  }) {
    return Column(
      children: [
        GestureDetector(
          onTap: onPressed,
          child: Container(
            width: isSmall ? 48 : 56,
            height: isSmall ? 48 : 56,
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              shape: BoxShape.circle,
              border: Border.all(color: color, width: 2),
            ),
            child: Icon(
              icon,
              color: color,
              size: isSmall ? 20 : 24,
            ),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 10,
            color: color,
            fontWeight: FontWeight.w600,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  void _toggleTimer() {
    setState(() {
      if (_state == TimerState.running) {
        _pauseTimer();
      } else {
        _startTimer();
      }
    });
  }

  void _startTimer() {
    _state = TimerState.running;
    widget.onStateChanged?.call(_state);
    
    if (_state == TimerState.running) {
      _pulseController.repeat(reverse: true);
    }
    
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        switch (widget.mode) {
          case TimerMode.countdown:
            if (_currentDuration.inSeconds > 0) {
              _currentDuration = Duration(seconds: _currentDuration.inSeconds - 1);
            } else {
              _onTimerComplete();
              return;
            }
            break;
          case TimerMode.countup:
          case TimerMode.stopwatch:
            _currentDuration = Duration(seconds: _currentDuration.inSeconds + 1);
            
            // Check if max duration reached
            if (widget.maxDuration != null && 
                _currentDuration >= widget.maxDuration!) {
              _onTimerComplete();
              return;
            }
            break;
        }
        
        widget.onTick?.call(_currentDuration);
        
        // Check for overtime
        if (widget.maxDuration != null && 
            _currentDuration > widget.maxDuration!) {
          _isOvertime = true;
        }
      });
    });
  }

  void _pauseTimer() {
    _state = TimerState.paused;
    _timer.cancel();
    _pulseController.stop();
    widget.onStateChanged?.call(_state);
  }

  void _resetTimer() {
    setState(() {
      _state = TimerState.stopped;
      _currentDuration = widget.initialDuration;
      _currentPeriod = 1;
      _isOvertime = false;
    });
    
    if (_timer.isActive) _timer.cancel();
    _pulseController.reset();
    widget.onStateChanged?.call(_state);
  }

  void _nextPeriod() {
    if (_currentPeriod < _totalPeriods) {
      setState(() {
        _currentPeriod++;
        _currentDuration = widget.initialDuration;
        _isOvertime = false;
      });
    }
  }

  void _onTimerComplete() {
    setState(() {
      _state = TimerState.stopped;
    });
    
    _timer.cancel();
    _pulseController.stop();
    
    widget.onComplete?.call(_currentDuration);
    widget.onStateChanged?.call(_state);
    
    // Play sound alert if enabled
    if (widget.enableSoundAlerts) {
      // Sound alert would be implemented here
    }
  }

  Color _getTimerBackgroundColor() {
    if (_isOvertime) return Colors.red[50]!;
    
    switch (_state) {
      case TimerState.running:
        return Colors.green[50]!;
      case TimerState.paused:
        return Colors.orange[50]!;
      case TimerState.stopped:
        return Colors.grey[50]!;
    }
  }

  Color _getTimerTextColor() {
    if (_isOvertime) return Colors.red[800]!;
    return Colors.black87;
  }

  IconData _getSportIcon() {
    switch (widget.sport) {
      case SportType.soccer:
        return Icons.sports_soccer;
      case SportType.basketball:
        return Icons.sports_basketball;
      case SportType.tennis:
        return Icons.sports_tennis;
      case SportType.volleyball:
        return Icons.sports_volleyball;
      case SportType.other:
        return Icons.sports;
    }
  }

  String _getPeriodText() {
    switch (widget.sport) {
      case SportType.soccer:
        if (_currentPeriod == 1) return '1st Half';
        if (_currentPeriod == 2) return '2nd Half';
        return 'Overtime';
      case SportType.basketball:
        switch (_currentPeriod) {
          case 1: return '1st Quarter';
          case 2: return '2nd Quarter';
          case 3: return '3rd Quarter';
          case 4: return '4th Quarter';
          default: return 'Overtime';
        }
      case SportType.tennis:
        return 'Set $_currentPeriod';
      case SportType.volleyball:
        return 'Set $_currentPeriod';
      case SportType.other:
        return 'Period $_currentPeriod';
    }
  }

  String _formatDuration(Duration duration) {
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    final seconds = duration.inSeconds.remainder(60);
    
    if (hours > 0) {
      return '${hours.toString().padLeft(2, '0')}:'
             '${minutes.toString().padLeft(2, '0')}:'
             '${seconds.toString().padLeft(2, '0')}';
    } else {
      return '${minutes.toString().padLeft(2, '0')}:'
             '${seconds.toString().padLeft(2, '0')}';
    }
  }

  // Public methods for external control
  void startTimer() => _startTimer();
  void pauseTimer() => _pauseTimer();
  void resetTimer() => _resetTimer();
  void nextPeriod() => _nextPeriod();
  
  Duration get currentDuration => _currentDuration;
  TimerState get timerState => _state;
  int get currentPeriod => _currentPeriod;
  bool get isOvertime => _isOvertime;
}
