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
import 'package:dabbler/widgets/thoughts_input.dart';

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
    final colorScheme = Theme.of(context).colorScheme;

    // Get display name from users table - NO FALLBACK to 'Player'
    final displayName =
        _userProfile?['display_name'] != null &&
            (_userProfile!['display_name'] as String).isNotEmpty
        ? (_userProfile!['display_name'] as String).split(' ').first
        : null;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.only(top: 16),
                child: _buildHeroSection(displayName),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 28, 24, 40),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildQuickAccessSection(),
                    Padding(
                      padding: const EdgeInsets.only(top: 28),
                      child: _buildNewlyJoinedSection(),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(top: 28),
                      child: _buildActivitiesButton(),
                    ),
                    if (FeatureFlags.socialFeed)
                      Padding(
                        padding: const EdgeInsets.only(top: 28),
                        child: _buildLatestFeedsSection(),
                      ),
                    Padding(
                      padding: const EdgeInsets.only(top: 36),
                      child: _buildRecentGamesSection(),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeroSection(String? displayName) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    final heroColor = isDarkMode
        ? const Color(0xFF4A148C)
        : const Color(0xFFE0C7FF);
    final textColor = isDarkMode ? Colors.white : Colors.black87;
    final subtextColor = isDarkMode
        ? Colors.white.withOpacity(0.85)
        : Colors.black.withOpacity(0.7);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: heroColor,
              borderRadius: BorderRadius.circular(18),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${_getGreeting()},',
                        style: textTheme.titleMedium?.copyWith(
                          color: subtextColor,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: displayName != null
                            ? Text(
                                '$displayName!',
                                style: textTheme.headlineSmall?.copyWith(
                                  color: textColor,
                                  fontWeight: FontWeight.w800,
                                ),
                              )
                            : Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Complete your profile',
                                    style: textTheme.titleMedium?.copyWith(
                                      color: textColor,
                                      fontStyle: FontStyle.italic,
                                    ),
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.only(top: 8),
                                    child: FilledButton.tonal(
                                      onPressed: () =>
                                          context.go(RoutePaths.profile),
                                      style: FilledButton.styleFrom(
                                        backgroundColor: isDarkMode
                                            ? Colors.white.withOpacity(0.15)
                                            : Colors.black.withOpacity(0.1),
                                        foregroundColor: textColor,
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 16,
                                          vertical: 10,
                                        ),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            16,
                                          ),
                                        ),
                                      ),
                                      child: const Text('Update now'),
                                    ),
                                  ),
                                ],
                              ),
                      ),
                    ],
                  ),
                ),
                GestureDetector(
                  onTap: () => context.go(RoutePaths.profile),
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isDarkMode
                          ? Colors.white.withOpacity(0.18)
                          : Colors.black.withOpacity(0.1),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(4),
                      child: SvgNetworkOrAssetAvatar(
                        imageUrlOrAsset: _userProfile?['avatar_url'],
                        radius: 32,
                        fallbackIcon: Icons.person,
                        backgroundColor: isDarkMode
                            ? Colors.white
                            : Colors.black87,
                        fallbackColor: colorScheme.primary,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(top: 16),
            child: _buildUpcomingGameSection(),
          ),
          Padding(
            padding: const EdgeInsets.only(top: 16),
            child: const ThoughtsInput(
              onTap: null, // TODO: Navigate to create post screen
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickAccessSection() {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: AppButtonCard(
                emoji: '📚',
                label: 'Community',
                onTap: () => context.go(RoutePaths.social),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: AppButtonCard(
                emoji: '🏆',
                label: 'Sports',
                onTap: () => context.go(RoutePaths.sports),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          child: AppButtonCard(
            emoji: '⚽',
            label: 'Create Game',
            onTap: () => context.push(RoutePaths.createGame),
          ),
        ),
      ],
    );
  }

  Widget _buildActivitiesButton() {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;

    return FilledButton.tonalIcon(
      onPressed: () => context.go(RoutePaths.activities),
      style: FilledButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        backgroundColor: colorScheme.secondaryContainer,
        foregroundColor: colorScheme.onSecondaryContainer,
      ),
      icon: const Text('⚡', style: TextStyle(fontSize: 18)),
      label: Text(
        'Activities',
        style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
      ),
    );
  }

  Widget _buildNewlyJoinedSection() {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;

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
              style: textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w600,
                color: colorScheme.onSurface,
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxHeight: 75),
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
                                backgroundColor:
                                    colorScheme.surfaceContainerHigh,
                                child: player['avatar_url'] == null
                                    ? Icon(
                                        Icons.person,
                                        size: 26,
                                        color: colorScheme.onSurfaceVariant,
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
                                    color: colorScheme.surface,
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: colorScheme.surface,
                                      width: 2,
                                    ),
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
            ),
          ],
        );
      },
    );
  }

  Widget _buildLatestFeedsSection() {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Latest feeds',
          style: textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
            color: colorScheme.onSurface,
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(top: 12),
          child: Column(
            children: [
              // Placeholder for 3 recent posts
              ...List.generate(3, (index) => _buildFeedItem(index)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildFeedItem(int index) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;

    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CircleAvatar(
              radius: 20,
              backgroundColor: colorScheme.surfaceContainerHigh,
              child: Icon(
                Icons.person,
                size: 20,
                color: colorScheme.onSurfaceVariant,
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
                        style: textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: colorScheme.onSurface,
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.only(left: 8),
                        child: Text(
                          '2h',
                          style: textTheme.bodySmall?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ),
                    ],
                  ),
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      'Had an amazing time at the community cooking class today! 🍳 Learning new recip...',
                      style: textTheme.bodyMedium?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentGamesSection() {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;

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
              style: textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: colorScheme.onSurface,
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: Column(
                children: [...games.map((game) => _buildRecentGameItem(game))],
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildRecentGameItem(Map<String, dynamic> game) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;

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

    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () {
          if (game['id'] != null) {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (context) => GameDetailScreen(gameId: game['id']),
              ),
            );
          }
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
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
                                  style: textTheme.bodyMedium?.copyWith(
                                    fontWeight: FontWeight.w600,
                                    color: colorScheme.onSurface,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  format,
                                  style: textTheme.bodySmall?.copyWith(
                                    color: colorScheme.onSurfaceVariant,
                                  ),
                                ),
                              ],
                            ),
                            Row(
                              children: [
                                const Text(
                                  '👥',
                                  style: TextStyle(fontSize: 16),
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  '$currentPlayers/$maxPlayers',
                                  style: textTheme.bodySmall?.copyWith(
                                    color: colorScheme.onSurface,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                        Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Text(
                            title,
                            style: textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                              color: colorScheme.onSurface,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              Padding(
                padding: const EdgeInsets.only(top: 12),
                child: Row(
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
                            color: Theme.of(
                              context,
                            ).colorScheme.onSurfaceVariant,
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
                            color: Theme.of(
                              context,
                            ).colorScheme.onSurfaceVariant,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
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
          // Show action cards when no upcoming game
          return Row(
            children: [
              Expanded(
                child: AppActionCard(
                  emoji: '➕',
                  title: 'Create Game',
                  subtitle: 'Start a new match',
                  onTap: () => context.go(RoutePaths.createGame),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: AppActionCard(
                  emoji: '🔍',
                  title: 'Join Game',
                  subtitle: 'Find nearby games',
                  onTap: () => context.go(RoutePaths.sports),
                ),
              ),
            ],
          );
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

        final textTheme = Theme.of(context).textTheme;
        final colorScheme = Theme.of(context).colorScheme;

        return Card(
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          child: InkWell(
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => GameDetailScreen(gameId: game.id),
                ),
              );
            },
            borderRadius: BorderRadius.circular(20),
            child: Padding(
              padding: const EdgeInsets.all(20),
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
                            style: textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w500,
                              color: colorScheme.onSurface,
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
                          color: colorScheme.errorContainer,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: colorScheme.error.withOpacity(0.3),
                          ),
                        ),
                        child: Row(
                          children: [
                            const Text('⏰', style: TextStyle(fontSize: 14)),
                            const SizedBox(width: 4),
                            Text(
                              countdownLabel,
                              style: textTheme.bodyMedium?.copyWith(
                                fontWeight: FontWeight.w600,
                                color: colorScheme.onErrorContainer,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  Padding(
                    padding: const EdgeInsets.only(top: 16),
                    child: Text(
                      game.title,
                      style: textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: colorScheme.onSurface,
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(top: 12),
                    child: Row(
                      children: [
                        const Text('🕐', style: TextStyle(fontSize: 16)),
                        const SizedBox(width: 8),
                        Text(
                          timeFormat,
                          style: textTheme.bodyLarge?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Row(
                      children: [
                        const Text('📍', style: TextStyle(fontSize: 16)),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            game.venueName ?? 'Location TBD',
                            style: textTheme.bodyLarge?.copyWith(
                              color: colorScheme.onSurfaceVariant,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
      loading: () {
        return Card(
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 60),
            child: const Center(child: CircularProgressIndicator()),
          ),
        );
      },
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
