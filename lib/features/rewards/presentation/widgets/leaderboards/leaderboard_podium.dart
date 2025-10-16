import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';
import 'dart:math' as math;
import 'leaderboard_item.dart';

/// Podium placement data
class PodiumPlacement {
  final LeaderboardUser user;
  final int position;
  final String title;
  final Color color;
  final double podiumHeight;
  final List<String> stats;

  const PodiumPlacement({
    required this.user,
    required this.position,
    required this.title,
    required this.color,
    required this.podiumHeight,
    this.stats = const [],
  });
}

/// 3D podium visualization widget
class LeaderboardPodium extends StatefulWidget {
  final List<LeaderboardUser> topUsers;
  final VoidCallback? onShare;
  final Function(LeaderboardUser)? onUserTap;
  final bool showConfetti;
  final bool showVictoryAnimations;
  final bool show3DEffect;
  final bool showStats;
  final bool enableInteractions;
  final bool enableHaptics;
  final EdgeInsets? padding;
  final double? height;

  const LeaderboardPodium({
    super.key,
    required this.topUsers,
    this.onShare,
    this.onUserTap,
    this.showConfetti = true,
    this.showVictoryAnimations = true,
    this.show3DEffect = true,
    this.showStats = true,
    this.enableInteractions = true,
    this.enableHaptics = true,
    this.padding,
    this.height,
  });

  @override
  State<LeaderboardPodium> createState() => _LeaderboardPodiumState();
}

class _LeaderboardPodiumState extends State<LeaderboardPodium>
    with TickerProviderStateMixin {
  late AnimationController _entranceController;
  late AnimationController _confettiController;
  late AnimationController _crownController;
  late AnimationController _pointsController;
  late AnimationController _glowController;

  late Animation<double> _entranceAnimation;
  late Animation<double> _confettiAnimation;
  late Animation<double> _crownAnimation;
  late Animation<double> _pointsAnimation;
  late Animation<double> _glowAnimation;

  List<PodiumPlacement> _placements = [];

  @override
  void initState() {
    super.initState();
    _setupPlacements();
    _initializeAnimations();
  }

  void _setupPlacements() {
    _placements = [];
    final topThree = widget.topUsers.take(3).toList();
    
    for (int i = 0; i < topThree.length; i++) {
      final user = topThree[i];
      late Color color;
      late double height;
      late String title;

      switch (i) {
        case 0: // 1st place
          color = const Color(0xFFFFD700); // Gold
          height = 120.0;
          title = 'CHAMPION';
          break;
        case 1: // 2nd place
          color = const Color(0xFFC0C0C0); // Silver
          height = 90.0;
          title = 'RUNNER-UP';
          break;
        case 2: // 3rd place
          color = const Color(0xFFCD7F32); // Bronze
          height = 60.0;
          title = 'THIRD PLACE';
          break;
      }

      _placements.add(PodiumPlacement(
        user: user,
        position: i + 1,
        title: title,
        color: color,
        podiumHeight: height,
        stats: [
          '${user.points} pts',
          '${user.weeklyPoints} weekly',
          '${user.achievements.length} achievements',
        ],
      ));
    }
  }

  void _initializeAnimations() {
    _entranceController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );

    _confettiController = AnimationController(
      duration: const Duration(milliseconds: 3000),
      vsync: this,
    );

    _crownController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _pointsController = AnimationController(
      duration: const Duration(milliseconds: 2500),
      vsync: this,
    );

    _glowController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );

    _entranceAnimation = CurvedAnimation(
      parent: _entranceController,
      curve: Curves.elasticOut,
    );

    _confettiAnimation = CurvedAnimation(
      parent: _confettiController,
      curve: Curves.easeOut,
    );

    _crownAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _crownController,
      curve: Curves.bounceOut,
    ));

    _pointsAnimation = CurvedAnimation(
      parent: _pointsController,
      curve: Curves.easeOut,
    );

    _glowAnimation = Tween<double>(
      begin: 0.3,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _glowController,
      curve: Curves.easeInOut,
    ));

    // Start animations
    _entranceController.forward();
    
    if (widget.showVictoryAnimations) {
      Future.delayed(const Duration(milliseconds: 500), () {
        _crownController.forward();
      });
      
      Future.delayed(const Duration(milliseconds: 1000), () {
        _pointsController.forward();
      });

      if (widget.showConfetti) {
        Future.delayed(const Duration(milliseconds: 800), () {
          _confettiController.forward();
        });
      }
    }

    _glowController.repeat(reverse: true);
  }

  @override
  void dispose() {
    _entranceController.dispose();
    _confettiController.dispose();
    _crownController.dispose();
    _pointsController.dispose();
    _glowController.dispose();
    super.dispose();
  }

  void _handleUserTap(LeaderboardUser user) {
    if (!widget.enableInteractions) return;
    
    if (widget.enableHaptics) {
      HapticFeedback.lightImpact();
    }
    widget.onUserTap?.call(user);
  }

  void _handleShare() {
    if (widget.enableHaptics) {
      HapticFeedback.mediumImpact();
    }

    if (_placements.isEmpty) return;

    final champion = _placements[0].user;
    final message = 'Check out the leaderboard podium! 🏆\n'
        '🥇 ${champion.displayName} leads with ${champion.points} points!\n'
        'Can you make it to the top?';

    Share.share(message, subject: 'Leaderboard Champions');
    widget.onShare?.call();
  }

  @override
  Widget build(BuildContext context) {
    if (_placements.isEmpty) {
      return const Center(
        child: Text('No podium data available'),
      );
    }

    return Container(
      height: widget.height ?? 400,
      padding: widget.padding ?? const EdgeInsets.all(16),
      child: Stack(
        children: [
          if (widget.showConfetti) _buildConfetti(),
          Column(
            children: [
              _buildHeader(),
              const SizedBox(height: 20),
              Expanded(child: _buildPodium()),
              if (widget.showStats) _buildStatsSection(),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'LEADERBOARD PODIUM',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: const Color(0xFFFFD700),
              ),
            ),
            Text(
              'Top 3 Champions',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
        if (widget.onShare != null)
          IconButton(
            onPressed: _handleShare,
            icon: const Icon(Icons.share),
            tooltip: 'Share Podium',
          ),
      ],
    );
  }

  Widget _buildPodium() {
    return AnimatedBuilder(
      animation: _entranceAnimation,
      builder: (context, child) {
        return Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            // 2nd place (left)
            if (_placements.length > 1)
              Expanded(
                child: Transform.scale(
                  scale: _entranceAnimation.value,
                  child: _buildPodiumPosition(_placements[1], isSecond: true),
                ),
              ),
            // 1st place (center)
            Expanded(
              child: Transform.scale(
                scale: _entranceAnimation.value,
                child: _buildPodiumPosition(_placements[0], isFirst: true),
              ),
            ),
            // 3rd place (right)
            if (_placements.length > 2)
              Expanded(
                child: Transform.scale(
                  scale: _entranceAnimation.value,
                  child: _buildPodiumPosition(_placements[2], isThird: true),
                ),
              ),
          ],
        );
      },
    );
  }

  Widget _buildPodiumPosition(
    PodiumPlacement placement, {
    bool isFirst = false,
    bool isSecond = false,
    bool isThird = false,
  }) {
    return GestureDetector(
      onTap: () => _handleUserTap(placement.user),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildUserCard(placement, isFirst: isFirst),
          const SizedBox(height: 8),
          _buildPodiumBase(placement, isFirst: isFirst),
        ],
      ),
    );
  }

  Widget _buildUserCard(
    PodiumPlacement placement, {
    bool isFirst = false,
  }) {
    return AnimatedBuilder(
      animation: isFirst ? _glowAnimation : _entranceAnimation,
      builder: (context, child) {
        return Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            boxShadow: isFirst && widget.show3DEffect
                ? [
                    BoxShadow(
                      color: placement.color.withOpacity(0.4 * _glowAnimation.value),
                      blurRadius: 20,
                      spreadRadius: 5,
                    ),
                  ]
                : [],
          ),
          child: Card(
            elevation: isFirst ? 12 : 6,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: BorderSide(
                color: placement.color,
                width: isFirst ? 3 : 2,
              ),
            ),
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                gradient: LinearGradient(
                  colors: [
                    placement.color.withOpacity(0.1),
                    Colors.white,
                  ],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (isFirst) _buildCrown(),
                  _buildUserAvatar(placement),
                  const SizedBox(height: 8),
                  _buildUserInfo(placement),
                  const SizedBox(height: 8),
                  _buildPointsDisplay(placement),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildCrown() {
    return AnimatedBuilder(
      animation: _crownAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: _crownAnimation.value,
          child: Transform.rotate(
            angle: (1 - _crownAnimation.value) * 0.5,
            child: Container(
              margin: const EdgeInsets.only(bottom: 8),
              child: Text(
                '👑',
                style: TextStyle(
                  fontSize: 24,
                  shadows: [
                    Shadow(
                      color: const Color(0xFFFFD700).withOpacity(0.8),
                      blurRadius: 10,
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildUserAvatar(PodiumPlacement placement) {
    return Container(
      width: 60,
      height: 60,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: placement.color, width: 3),
        boxShadow: widget.show3DEffect
            ? [
                BoxShadow(
                  color: placement.color.withOpacity(0.3),
                  blurRadius: 8,
                  spreadRadius: 2,
                ),
              ]
            : [],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(30),
        child: placement.user.avatarUrl != null
            ? Image.network(
                placement.user.avatarUrl!,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) =>
                    _buildDefaultAvatar(placement),
              )
            : _buildDefaultAvatar(placement),
      ),
    );
  }

  Widget _buildDefaultAvatar(PodiumPlacement placement) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            placement.color.withOpacity(0.3),
            placement.color.withOpacity(0.1),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Center(
        child: Text(
          placement.user.displayName.isNotEmpty
              ? placement.user.displayName[0].toUpperCase()
              : placement.user.username[0].toUpperCase(),
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: placement.color,
          ),
        ),
      ),
    );
  }

  Widget _buildUserInfo(PodiumPlacement placement) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          placement.title,
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.bold,
            color: placement.color,
            letterSpacing: 1.2,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          placement.user.displayName.isNotEmpty
              ? placement.user.displayName
              : placement.user.username,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
          textAlign: TextAlign.center,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }

  Widget _buildPointsDisplay(PodiumPlacement placement) {
    return AnimatedBuilder(
      animation: _pointsAnimation,
      builder: (context, child) {
        final animatedPoints = (_pointsAnimation.value * placement.user.points).toInt();
        
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: placement.color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '$animatedPoints',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: placement.color,
                ),
              ),
              Text(
                'points',
                style: TextStyle(
                  fontSize: 10,
                  color: placement.color.withOpacity(0.8),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildPodiumBase(
    PodiumPlacement placement, {
    bool isFirst = false,
  }) {
    return AnimatedBuilder(
      animation: _entranceAnimation,
      builder: (context, child) {
        return Container(
          width: double.infinity,
          height: placement.podiumHeight * _entranceAnimation.value,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: widget.show3DEffect
                  ? [
                      placement.color,
                      placement.color.withOpacity(0.7),
                      placement.color.withOpacity(0.5),
                    ]
                  : [placement.color, placement.color],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(8),
              topRight: Radius.circular(8),
            ),
            boxShadow: widget.show3DEffect
                ? [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.2),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ]
                : [],
          ),
          child: Stack(
            children: [
              if (widget.show3DEffect) _build3DEffect(placement),
              Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      placement.user.rankMedal,
                      style: const TextStyle(fontSize: 32),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${placement.position}',
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _build3DEffect(PodiumPlacement placement) {
    return Positioned.fill(
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Colors.white.withOpacity(0.2),
              Colors.transparent,
              Colors.black.withOpacity(0.1),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(8),
            topRight: Radius.circular(8),
          ),
        ),
      ),
    );
  }

  Widget _buildConfetti() {
    return AnimatedBuilder(
      animation: _confettiAnimation,
      builder: (context, child) {
        return Stack(
          children: List.generate(20, (index) {
            final random = math.Random(index);
            final startX = random.nextDouble();
            final startY = -0.1;
            final endY = 1.1;
            final currentY = startY + (endY - startY) * _confettiAnimation.value;

            return Positioned(
              left: MediaQuery.of(context).size.width * startX,
              top: MediaQuery.of(context).size.height * currentY,
              child: Transform.rotate(
                angle: _confettiAnimation.value * 4 * math.pi + index,
                child: Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: [
                      Colors.red,
                      Colors.blue,
                      Colors.green,
                      Colors.yellow,
                      Colors.purple,
                      const Color(0xFFFFD700),
                    ][index % 6],
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
            );
          }),
        );
      },
    );
  }

  Widget _buildStatsSection() {
    return Container(
      margin: const EdgeInsets.only(top: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Podium Statistics',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: _placements.map((placement) {
              return Expanded(
                child: _buildUserStats(placement),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildUserStats(PodiumPlacement placement) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 4),
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: placement.color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: placement.color.withOpacity(0.3)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '#${placement.position}',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: placement.color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            placement.user.displayName.length > 8
                ? '${placement.user.displayName.substring(0, 8)}...'
                : placement.user.displayName,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 8),
          ...placement.stats.map((stat) => Padding(
            padding: const EdgeInsets.only(bottom: 2),
            child: Text(
              stat,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Colors.grey[600],
              ),
              textAlign: TextAlign.center,
            ),
          )),
        ],
      ),
    );
  }
}