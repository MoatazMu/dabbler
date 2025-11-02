import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:intl/intl.dart';
import '../../themes/app_theme.dart';
import '../../utils/constants/route_constants.dart';
import 'package:dabbler/core/services/auth_service.dart';
import '../../widgets/game_card.dart';
import '../../widgets/thoughts_input.dart';
import '../../widgets/category_buttons.dart';
import '../../widgets/action_cards.dart';
import '../../widgets/svg_avatar.dart';
import 'package:dabbler/features/games/providers/games_providers.dart';
import 'package:dabbler/features/games/presentation/features/join_game/game_detail_screen.dart';

/// Modern home screen for Dabbler
class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  final AuthService _authService = AuthService();
  Map<String, dynamic>? _userProfile;

  @override
  void initState() {
    super.initState();
    _loadUserProfile();
  }

  Future<void> _loadUserProfile() async {
    try {
      final profile = await _authService.getUserProfile();
      if (mounted) {
        setState(() {
          _userProfile = profile;
        });
      }
    } catch (e) {
      print('Error loading user profile: $e');
    }
  }

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) {
      return 'Good morning';
    } else if (hour < 17) {
      return 'Good afternoon';
    } else {
      return 'Good evening';
    }
  }

  @override
  Widget build(BuildContext context) {
    // Get display name from users table - NO FALLBACK to 'Player'
    final displayName =
        _userProfile?['display_name'] != null &&
            (_userProfile!['display_name'] as String).isNotEmpty
        ? (_userProfile!['display_name'] as String).split(' ').first
        : null;

    return Scaffold(
      // Transparent so the global AppBackground gradient is visible
      backgroundColor: Colors.transparent,
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Rank and Notification Row
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Rank/Leaderboard Button
                    GestureDetector(
                      onTap: () {
                        context.go(RoutePaths.rewards);
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 18,
                          vertical: 10,
                        ),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(
                            color: Colors.white.withOpacity(0.12),
                            width: 1,
                          ),
                          gradient: const LinearGradient(
                            begin: Alignment.centerLeft,
                            end: Alignment.centerRight,
                            colors: [Color(0xFF7B4397), Color(0xFFDC2430)],
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Iconsax.cup_copy,
                              size: 20,
                              color: Colors.white,
                            ),
                            const SizedBox(width: 8),
                            const Text(
                              'Silver',
                              style: TextStyle(
                                color: Colors.white,
                                fontFamily: 'Inter',
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                                height: 1.43,
                                letterSpacing: -0.15,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    // Notification Icon
                    GestureDetector(
                      onTap: () {
                        context.go(RoutePaths.notifications);
                      },
                      child: Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(
                            color: const Color(0xFFEBD7FA).withOpacity(0.24),
                            width: 1,
                          ),
                          color: const Color(0xFF301C4D),
                        ),
                        child: Icon(
                          Iconsax.notification_copy,
                          size: 24,
                          color: const Color(0xFFEBD7FA),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // Greeting and Avatar Row
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${_getGreeting()},',
                            style: context.textTheme.headlineLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: context.colors.onSurface,
                              height: 1.1,
                            ),
                          ),
                          const SizedBox(height: 4),
                          if (displayName != null)
                            Text(
                              displayName,
                              style: context.textTheme.headlineLarge?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: context.colors.primary,
                                height: 1.1,
                              ),
                            )
                          else
                            Text(
                              'Complete your profile',
                              style: context.textTheme.bodyMedium?.copyWith(
                                color: context.colors.error,
                                fontStyle: FontStyle.italic,
                              ),
                            ),
                        ],
                      ),
                    ),
                    // User Avatar
                    GestureDetector(
                      onTap: () => context.go(RoutePaths.profile),
                      child: SvgNetworkOrAssetAvatar(
                        imageUrlOrAsset: _userProfile?['avatar_url'],
                        radius: 32,
                        fallbackIcon: Icons.person,
                        backgroundColor: context.colors.primary.withValues(
                          alpha: 0.1,
                        ),
                        fallbackColor: context.colors.primary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 28),

                // Thoughts Input
                ThoughtsInput(
                  onTap: () {
                    // context.go('/create-post');
                  },
                ),
                const SizedBox(height: 20),

                // Category Buttons
                CategoryButtons(
                  onCommunityTap: () {
                    context.go(RoutePaths.social);
                  },
                  onSportsTap: () {
                    context.go(RoutePaths.explore);
                  },
                  onActivitiesTap: () {
                    context.go(RoutePaths.activities);
                  },
                ),
                const SizedBox(height: 20),

                // Upcoming Game Card (from Supabase)
                _buildUpcomingGameSection(),
                const SizedBox(height: 20),

                // Action Cards
                ActionCards(
                  onCreateGameTap: () {
                    context.go(RoutePaths.createGame);
                  },
                  onJoinGameTap: () {
                    context.go(RoutePaths.explore);
                  },
                ),

                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Builds the upcoming game section with real Supabase data
  Widget _buildUpcomingGameSection() {
    final nextGameAsync = ref.watch(nextUpcomingGameProvider);

    return nextGameAsync.when(
      data: (game) {
        if (game == null) {
          // No upcoming games - show empty state
          return _buildEmptyGameState();
        }

        // Calculate countdown
        final now = DateTime.now();
        final gameDateTime = DateTime(
          game.scheduledDate.year,
          game.scheduledDate.month,
          game.scheduledDate.day,
          _parseTime(game.startTime).hour,
          _parseTime(game.startTime).minute,
        );
        final difference = gameDateTime.difference(now);

        String countdownLabel;
        if (difference.inDays > 0) {
          countdownLabel = '${difference.inDays}d ${difference.inHours % 24}h';
        } else if (difference.inHours > 0) {
          countdownLabel =
              '${difference.inHours}h ${difference.inMinutes % 60}m';
        } else if (difference.inMinutes > 0) {
          countdownLabel = '${difference.inMinutes}m';
        } else {
          countdownLabel = 'Starting soon!';
        }

        // Format date
        final dateFormat = DateFormat('EEE, MMM dd');
        final formattedDate = dateFormat.format(game.scheduledDate);

        return GameCard(
          countdownLabel: countdownLabel,
          title: game.title,
          date: formattedDate,
          timeRange: '${game.startTime} - ${game.endTime}',
          location: 'Loading venue...',
          avatarUrls: const [],
          othersCount: game.currentPlayers,
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (context) => GameDetailScreen(gameId: game.id),
              ),
            );
          },
        );
      },
      loading: () => _buildLoadingGameCard(),
      error: (error, stack) {
        print('Error loading upcoming game: $error');
        return _buildErrorGameState();
      },
    );
  }

  /// Empty state when no games exist
  Widget _buildEmptyGameState() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.1), width: 1),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            const Color(0xFF301C4D).withOpacity(0.6),
            const Color(0xFF1E0E33).withOpacity(0.4),
          ],
        ),
      ),
      child: Column(
        children: [
          Icon(
            Iconsax.calendar_1_copy,
            size: 48,
            color: Colors.white.withOpacity(0.3),
          ),
          const SizedBox(height: 12),
          Text(
            'No upcoming games',
            style: TextStyle(
              color: Colors.white.withOpacity(0.7),
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Create or join a game to get started',
            style: TextStyle(
              color: Colors.white.withOpacity(0.5),
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  /// Loading placeholder
  Widget _buildLoadingGameCard() {
    return Container(
      height: 200,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        color: const Color(0xFF301C4D).withOpacity(0.3),
      ),
      child: Center(
        child: CircularProgressIndicator(color: Colors.white.withOpacity(0.5)),
      ),
    );
  }

  /// Error state
  Widget _buildErrorGameState() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.red.withOpacity(0.3), width: 1),
        color: const Color(0xFF301C4D).withOpacity(0.3),
      ),
      child: Column(
        children: [
          Icon(
            Icons.error_outline,
            size: 48,
            color: Colors.red.withOpacity(0.7),
          ),
          const SizedBox(height: 12),
          Text(
            'Failed to load games',
            style: TextStyle(
              color: Colors.white.withOpacity(0.7),
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Pull down to retry',
            style: TextStyle(
              color: Colors.white.withOpacity(0.5),
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  /// Parse time string "HH:mm" to TimeOfDay
  TimeOfDay _parseTime(String timeString) {
    try {
      final parts = timeString.split(':');
      return TimeOfDay(hour: int.parse(parts[0]), minute: int.parse(parts[1]));
    } catch (e) {
      return const TimeOfDay(hour: 0, minute: 0);
    }
  }
}
