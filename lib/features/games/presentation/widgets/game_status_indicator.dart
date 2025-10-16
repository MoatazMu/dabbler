import 'package:flutter/material.dart';

enum GameStatus {
  open,
  fillingFast,
  almostFull,
  full,
  closed,
  cancelled,
  inProgress,
  completed
}

class GameStatusIndicator extends StatefulWidget {
  final GameStatus status;
  final int? currentPlayers;
  final int? maxPlayers;
  final String? customMessage;
  final bool showTooltip;
  final bool animate;

  const GameStatusIndicator({
    super.key,
    required this.status,
    this.currentPlayers,
    this.maxPlayers,
    this.customMessage,
    this.showTooltip = true,
    this.animate = true,
  });

  @override
  State<GameStatusIndicator> createState() => _GameStatusIndicatorState();
}

class _GameStatusIndicatorState extends State<GameStatusIndicator>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _pulseAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );

    _pulseAnimation = Tween<double>(
      begin: 0.8,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));

    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 1.1,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.elasticOut,
    ));

    // Start animation for filling fast status
    if (widget.status == GameStatus.fillingFast && widget.animate) {
      _animationController.repeat(reverse: true);
    }
  }

  @override
  void didUpdateWidget(GameStatusIndicator oldWidget) {
    super.didUpdateWidget(oldWidget);
    
    if (widget.status != oldWidget.status) {
      if (widget.status == GameStatus.fillingFast && widget.animate) {
        _animationController.repeat(reverse: true);
      } else {
        _animationController.stop();
        _animationController.reset();
      }
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final statusData = _getStatusData();
    
    Widget badge = Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: statusData.backgroundColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: statusData.borderColor,
          width: 1,
        ),
        boxShadow: statusData.hasShadow ? [
          BoxShadow(
            color: statusData.color.withOpacity(0.3),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ] : null,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            statusData.icon,
            size: 14,
            color: statusData.color,
          ),
          const SizedBox(width: 6),
          Text(
            statusData.text,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: statusData.color,
            ),
          ),
        ],
      ),
    );

    // Apply animations based on status
    if (widget.status == GameStatus.fillingFast && widget.animate) {
      badge = AnimatedBuilder(
        animation: _pulseAnimation,
        builder: (context, child) {
          return Transform.scale(
            scale: _pulseAnimation.value,
            child: badge,
          );
        },
      );
    } else if (widget.status == GameStatus.inProgress && widget.animate) {
      badge = AnimatedBuilder(
        animation: _scaleAnimation,
        builder: (context, child) {
          return Transform.scale(
            scale: _scaleAnimation.value,
            child: badge,
          );
        },
      );
    }

    // Add tooltip if enabled
    if (widget.showTooltip) {
      badge = Tooltip(
        message: _getTooltipMessage(),
        child: badge,
      );
    }

    return badge;
  }

  ({
    Color color,
    Color backgroundColor,
    Color borderColor,
    IconData icon,
    String text,
    bool hasShadow,
  }) _getStatusData() {
    switch (widget.status) {
      case GameStatus.open:
        return (
          color: Colors.green[700]!,
          backgroundColor: Colors.green[50]!,
          borderColor: Colors.green[200]!,
          icon: Icons.check_circle_outline,
          text: 'Open',
          hasShadow: false,
        );

      case GameStatus.fillingFast:
        return (
          color: Colors.orange[700]!,
          backgroundColor: Colors.orange[50]!,
          borderColor: Colors.orange[200]!,
          icon: Icons.trending_up,
          text: 'Filling Fast',
          hasShadow: true,
        );

      case GameStatus.almostFull:
        return (
          color: Colors.red[700]!,
          backgroundColor: Colors.red[50]!,
          borderColor: Colors.red[200]!,
          icon: Icons.warning_outlined,
          text: 'Almost Full',
          hasShadow: true,
        );

      case GameStatus.full:
        return (
          color: Colors.red[800]!,
          backgroundColor: Colors.red[100]!,
          borderColor: Colors.red[300]!,
          icon: Icons.block,
          text: 'Full',
          hasShadow: false,
        );

      case GameStatus.closed:
        return (
          color: Colors.grey[700]!,
          backgroundColor: Colors.grey[100]!,
          borderColor: Colors.grey[300]!,
          icon: Icons.lock_outline,
          text: 'Closed',
          hasShadow: false,
        );

      case GameStatus.cancelled:
        return (
          color: Colors.red[900]!,
          backgroundColor: Colors.red[50]!,
          borderColor: Colors.red[400]!,
          icon: Icons.cancel_outlined,
          text: 'Cancelled',
          hasShadow: false,
        );

      case GameStatus.inProgress:
        return (
          color: Colors.blue[700]!,
          backgroundColor: Colors.blue[50]!,
          borderColor: Colors.blue[200]!,
          icon: Icons.play_circle_outline,
          text: 'In Progress',
          hasShadow: true,
        );

      case GameStatus.completed:
        return (
          color: Colors.purple[700]!,
          backgroundColor: Colors.purple[50]!,
          borderColor: Colors.purple[200]!,
          icon: Icons.check_circle,
          text: 'Completed',
          hasShadow: false,
        );
    }
  }

  String _getTooltipMessage() {
    if (widget.customMessage != null) {
      return widget.customMessage!;
    }

    switch (widget.status) {
      case GameStatus.open:
        if (widget.currentPlayers != null && widget.maxPlayers != null) {
          final available = widget.maxPlayers! - widget.currentPlayers!;
          return 'Open for joining - $available spots available';
        }
        return 'This game is open for players to join';

      case GameStatus.fillingFast:
        if (widget.currentPlayers != null && widget.maxPlayers != null) {
          final percentage = (widget.currentPlayers! / widget.maxPlayers! * 100).round();
          return 'Filling fast - $percentage% full. Join quickly!';
        }
        return 'This game is filling up quickly. Join soon!';

      case GameStatus.almostFull:
        if (widget.currentPlayers != null && widget.maxPlayers != null) {
          final remaining = widget.maxPlayers! - widget.currentPlayers!;
          return 'Almost full - only $remaining spot${remaining == 1 ? '' : 's'} left';
        }
        return 'This game is almost full. Very few spots remaining!';

      case GameStatus.full:
        return 'This game is full. You can join the waitlist';

      case GameStatus.closed:
        return 'Registration for this game has closed';

      case GameStatus.cancelled:
        return 'This game has been cancelled';

      case GameStatus.inProgress:
        return 'This game is currently in progress';

      case GameStatus.completed:
        return 'This game has been completed';
    }
  }
}

// Helper function to determine status from player counts
GameStatus determineGameStatus({
  required int currentPlayers,
  required int maxPlayers,
  bool isClosed = false,
  bool isCancelled = false,
  bool isInProgress = false,
  bool isCompleted = false,
}) {
  if (isCompleted) return GameStatus.completed;
  if (isCancelled) return GameStatus.cancelled;
  if (isInProgress) return GameStatus.inProgress;
  if (isClosed) return GameStatus.closed;
  
  final fillPercentage = currentPlayers / maxPlayers;
  
  if (currentPlayers >= maxPlayers) {
    return GameStatus.full;
  } else if (fillPercentage >= 0.9) {
    return GameStatus.almostFull;
  } else if (fillPercentage >= 0.7) {
    return GameStatus.fillingFast;
  } else {
    return GameStatus.open;
  }
}
