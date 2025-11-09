import 'package:flutter/material.dart';
import 'package:dabbler/utils/constants/route_constants.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:dabbler/core/services/auth_service.dart';
import 'package:dabbler/core/config/feature_flags.dart';
import 'package:dabbler/widgets/svg_avatar.dart';
import 'package:dabbler/features/games/providers/games_providers.dart';
import 'package:dabbler/features/games/presentation/screens/join_game/game_detail_screen.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:dabbler/core/design_system/design_system.dart';

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

    return TwoSectionLayout(
      topSection: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Greeting and Avatar Row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('${_getGreeting()},', style: AppTypography.greeting),
                    if (displayName != null)
                      Text('$displayName!', style: AppTypography.displayLarge)
                    else
                      Text(
                        'Complete your profile',
                        style: AppTypography.bodyMedium.copyWith(
                          color: AppColors.error,
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
                  radius: 30,
                  fallbackIcon: Icons.person,
                  backgroundColor: AppColors.primaryPurpleLight,
                  fallbackColor: AppColors.primaryPurple,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sectionSpacing),

          // Upcoming Game Card
          _buildUpcomingGameSection(),
          const SizedBox(height: AppSpacing.xl),

          // Thoughts Input
          _buildThoughtsInput(),
        ],
      ),
      bottomSection: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Category Buttons
          Row(
            children: [
              Expanded(
                child: AppButtonCard(
                  emoji: '📚',
                  label: 'Community',
                  onTap: () => context.go(RoutePaths.social),
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: AppButtonCard(
                  emoji: '🏆',
                  label: 'Sports',
                  onTap: () => context.go(RoutePaths.sports),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sectionSpacing),

          // Newly joined section
          _buildNewlyJoinedSection(),
          const SizedBox(height: AppSpacing.sectionSpacing),

          // Action Cards
          Row(
            children: [
              Expanded(
                child: AppActionCard(
                  emoji: '➕',
                  title: 'Create Game',
                  subtitle: 'Start a new match',
                  onTap: () => context.go(RoutePaths.createGame),
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: AppActionCard(
                  emoji: '🔍',
                  title: 'Join Game',
                  subtitle: 'Find nearby games',
                  onTap: () => context.go(RoutePaths.sports),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sectionSpacing),

          // Activities button
          _buildActivitiesButton(),
          const SizedBox(height: AppSpacing.sectionSpacing),

          // Latest feeds (if social enabled)
          if (FeatureFlags.socialFeed) _buildLatestFeedsSection(),
          if (FeatureFlags.socialFeed)
            const SizedBox(height: AppSpacing.sectionSpacing),

          // Recent Games
          _buildRecentGamesSection(),
          const SizedBox(height: AppSpacing.sectionSpacing),
        ],
      ),
    );
  }

  Widget _buildThoughtsInput() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: AppColors.cardColor(context),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.stroke(context)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              'What\'s on your mind?',
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
                fontSize: 15,
              ),
            ),
          ),
          const Text('📝', style: TextStyle(fontSize: 20)),
        ],
      ),
    );
  }

  Widget _buildActivitiesButton() {
    return GestureDetector(
      onTap: () => context.go(RoutePaths.activities),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: AppColors.cardColor(context),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.stroke(context)),
        ),
        child: Center(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text('⚡', style: TextStyle(fontSize: 18)),
              const SizedBox(width: 8),
              Text(
                'Activities',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNewlyJoinedSection() {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: _fetchRecentPlayers(),
      builder: (context, snapshot) {
        // Show placeholder avatars even while loading
        final players = snapshot.hasData ? snapshot.data! : [];

        // If no data, show 6 placeholder avatars with different sports
        final displayPlayers = players.isEmpty
            ? List.generate(
                6,
                (index) => {
                  'avatar_url': null,
                  'display_name': null,
                  'sport_key': [
                    'football',
                    'basketball',
                    'tennis',
                    'volleyball',
                    'cricket',
                    'football',
                  ][index],
                },
              )
            : players;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Newly joined',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 75,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: displayPlayers.length > 6
                    ? 6
                    : displayPlayers.length,
                itemBuilder: (context, index) {
                  final player = displayPlayers[index];
                  return Padding(
                    padding: const EdgeInsets.only(right: 16),
                    child: Column(
                      children: [
                        Stack(
                          clipBehavior: Clip.none,
                          children: [
                            CircleAvatar(
                              radius: 26,
                              backgroundImage: player['avatar_url'] != null
                                  ? NetworkImage(player['avatar_url'])
                                  : null,
                              backgroundColor: Colors.grey.shade300,
                              child: player['avatar_url'] == null
                                  ? Icon(
                                      Icons.person,
                                      size: 26,
                                      color: Colors.grey.shade600,
                                    )
                                  : null,
                            ),
                            Positioned(
                              bottom: -2,
                              right: -2,
                              child: Container(
                                width: 24,
                                height: 24,
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: Colors.white,
                                    width: 2,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.1),
                                      blurRadius: 4,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: Center(
                                  child: Text(
                                    _getSportEmoji(player['sport_key']),
                                    style: const TextStyle(fontSize: 12),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildLatestFeedsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Latest feeds',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Theme.of(context).colorScheme.onSurface,
          ),
        ),
        const SizedBox(height: 12),
        // Placeholder for 3 recent posts
        ...List.generate(3, (index) => _buildFeedItem(index)),
      ],
    );
  }

  Widget _buildFeedItem(int index) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.cardColor(context),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.stroke(context)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 20,
            backgroundColor: AppColors.sectionBg(context),
            child: Icon(
              Icons.person,
              size: 20,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      'Sarah',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '2h',
                      style: TextStyle(
                        fontSize: 13,
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  'Had an amazing time at the community cooking class today! 🍳 Learning new recip...',
                  style: TextStyle(
                    fontSize: 14,
                    color: AppColors.bodyTxt(context),
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecentGamesSection() {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: _fetchRecentGames(),
      builder: (context, snapshot) {
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const SizedBox.shrink();
        }

        final games = snapshot.data!;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Recent Games',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 12),
            ...games.map((game) => _buildRecentGameItem(game)),
          ],
        );
      },
    );
  }

  Widget _buildRecentGameItem(Map<String, dynamic> game) {
    final sport = game['sport'] ?? 'Football';
    final format = game['format'] ?? 'Futsal';
    final title = game['title'] ?? 'Game';
    final date = game['scheduled_date'] != null
        ? DateFormat('dd MMM').format(DateTime.parse(game['scheduled_date']))
        : '25 OCT';
    final time = game['start_time'] ?? '6:00 PM';
    final location = game['location_name'] ?? 'Downtown, Dubai';
    final currentPlayers = game['current_players'] ?? 5;
    final maxPlayers = game['max_players'] ?? 10;

    return GestureDetector(
      onTap: () {
        if (game['id'] != null) {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => GameDetailScreen(gameId: game['id']),
            ),
          );
        }
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.cardColor(context),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.stroke(context)),
        ),
        child: Column(
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _getSportEmoji(sport),
                  style: const TextStyle(fontSize: 32),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Text(
                                sport,
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: Theme.of(context).colorScheme.onSurface,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                format,
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w400,
                                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                                ),
                              ),
                            ],
                          ),
                          Row(
                            children: [
                              const Text('👥', style: TextStyle(fontSize: 16)),
                              const SizedBox(width: 4),
                              Text(
                                '$currentPlayers/$maxPlayers',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w400,
                                  color: Theme.of(context).colorScheme.onSurface,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        title,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Row(
                  children: [
                    const Text('�', style: TextStyle(fontSize: 14)),
                    const SizedBox(width: 6),
                    Text(
                      '$date • $time',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w400,
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
                const SizedBox(width: 16),
                Row(
                  children: [
                    const Text('�', style: TextStyle(fontSize: 14)),
                    const SizedBox(width: 6),
                    Text(
                      location,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w400,
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<List<Map<String, dynamic>>> _fetchRecentPlayers() async {
    try {
      final supabase = Supabase.instance.client;
      final response = await supabase
          .from('sport_profiles')
          .select(
            'profile_id, sport_key, skill_level, profiles!inner(display_name, avatar_url)',
          )
          .limit(6);

      return (response as List).map((item) {
        return {
          'profile_id': item['profile_id'],
          'sport_key': item['sport_key'],
          'skill_level': item['skill_level'],
          'display_name': item['profiles']['display_name'],
          'avatar_url': item['profiles']['avatar_url'],
        };
      }).toList();
    } catch (e) {
      print('Error fetching recent players: $e');
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> _fetchRecentGames() async {
    try {
      final supabase = Supabase.instance.client;
      final response = await supabase
          .from('games')
          .select()
          .eq('is_cancelled', false)
          .order('created_at', ascending: false)
          .limit(2);

      return (response as List).cast<Map<String, dynamic>>();
    } catch (e) {
      print('Error fetching recent games: $e');
      return [];
    }
  }

  String _getSportEmoji(String? sport) {
    if (sport == null) return '⚽';
    switch (sport.toLowerCase()) {
      case 'football':
      case 'soccer':
        return '⚽';
      case 'basketball':
        return '🏀';
      case 'tennis':
        return '🎾';
      case 'cricket':
        return '🏏';
      case 'padel':
        return '🎾';
      case 'volleyball':
        return '🏐';
      default:
        return '⚽';
    }
  }

  /// Builds the upcoming game section with real Supabase data
  Widget _buildUpcomingGameSection() {
    final nextGameAsync = ref.watch(nextUpcomingGameProvider);

    return nextGameAsync.when(
      data: (game) {
        if (game == null) {
          return const SizedBox.shrink();
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
          countdownLabel =
              '${difference.inHours}h ${difference.inMinutes % 60}m';
        } else if (difference.inHours > 0) {
          countdownLabel =
              '${difference.inHours}h ${difference.inMinutes % 60}m';
        } else if (difference.inMinutes > 0) {
          countdownLabel = '${difference.inMinutes}m';
        } else {
          countdownLabel = '0h 45m';
        }

        // Format date
        final timeFormat = '${game.startTime} - ${game.endTime}';

        return GestureDetector(
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (context) => GameDetailScreen(gameId: game.id),
              ),
            );
          },
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.cardColor(context),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppColors.stroke(context)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        const Text('🕐', style: TextStyle(fontSize: 20)),
                        const SizedBox(width: 8),
                        Text(
                          'Upcoming Game',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                            color: Theme.of(context).colorScheme.onSurface,
                          ),
                        ),
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.danger.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: AppColors.danger.withOpacity(0.3),
                        ),
                      ),
                      child: Row(
                        children: [
                          const Text('⏰', style: TextStyle(fontSize: 14)),
                          const SizedBox(width: 4),
                          Text(
                            countdownLabel,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: AppColors.danger,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Text(
                  game.title,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    const Text('🕐', style: TextStyle(fontSize: 16)),
                    const SizedBox(width: 8),
                    Text(
                      timeFormat,
                      style: TextStyle(
                        fontSize: 15,
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Text('📍', style: TextStyle(fontSize: 16)),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        game.venueName ?? 'Location TBD',
                        style: TextStyle(
                          fontSize: 15,
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
      loading: () => Container(
        height: 160,
        decoration: BoxDecoration(
          color: AppColors.cardColor(context),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.stroke(context)),
        ),
        child: const Center(
          child: CircularProgressIndicator(color: AppColors.primaryPurple),
        ),
      ),
      error: (error, stack) {
        print('Error loading upcoming game: $error');
        return const SizedBox.shrink();
      },
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
