import 'dart:async';

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
import 'package:dabbler/data/models/social/post_model.dart';
import 'package:dabbler/features/home/presentation/providers/home_providers.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:dabbler/core/design_system/design_system.dart';
import 'package:dabbler/widgets/thoughts_input.dart';
import 'package:dabbler/data/models/games/game.dart';

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

  String _formatRelativeTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inMinutes < 1) {
      return 'just now';
    } else if (difference.inHours < 1) {
      return '${difference.inMinutes}m';
    } else if (difference.inDays < 1) {
      return '${difference.inHours}h';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d';
    } else {
      return DateFormat('MMM d').format(dateTime);
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

        // If no data, show 6 placeholder avatars
        final displayPlayers = players.isEmpty
            ? List.generate(
                6,
                (index) => {
                  'avatar_url': null,
                  'display_name': null,
                  'sport_key': null,
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
                              if (player['sport_key'] != null)
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
    final postsAsync = ref.watch(latestFeedPostsProvider);

    return postsAsync.when(
      data: (posts) {
        if (posts.isEmpty) {
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
                child: Card(
                  elevation: 0,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'No posts yet',
                          style: textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                            color: colorScheme.onSurface,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Be the first to share something with the community.',
                          style: textTheme.bodyMedium?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                        const SizedBox(height: 12),
                        OutlinedButton(
                          onPressed: () => context.go(RoutePaths.social),
                          child: const Text('Open social feed'),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          );
        }

        final visiblePosts = posts.take(3).toList();

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
                  ...visiblePosts.map((post) => _buildFeedItem(post)),
                  if (FeatureFlags.socialFeed)
                    Align(
                      alignment: Alignment.centerLeft,
                      child: TextButton(
                        onPressed: () => context.go(RoutePaths.social),
                        child: const Text('See all posts'),
                      ),
                    ),
                ],
              ),
            ),
          ],
        );
      },
      loading: () => Column(
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
              children: const [
                _FeedLoadingPlaceholder(),
                _FeedLoadingPlaceholder(),
                _FeedLoadingPlaceholder(),
              ],
            ),
          ),
        ],
      ),
      error: (error, stack) => Column(
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
            child: Card(
              elevation: 0,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Unable to load posts',
                      style: textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Please check your connection and try again.',
                      style: textTheme.bodyMedium?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 12),
                    OutlinedButton.icon(
                      onPressed: () => ref.refresh(latestFeedPostsProvider),
                      icon: const Icon(Icons.refresh),
                      label: const Text('Retry'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeedItem(PostModel post) {
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
              backgroundImage: post.authorAvatar.isNotEmpty
                  ? NetworkImage(post.authorAvatar)
                  : null,
              child: post.authorAvatar.isEmpty
                  ? Icon(
                      Icons.person,
                      size: 20,
                      color: colorScheme.onSurfaceVariant,
                    )
                  : null,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          post.authorName,
                          style: textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                            color: colorScheme.onSurface,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        _formatRelativeTime(post.createdAt),
                        style: textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                  if (post.content.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(
                        post.content,
                        style: textTheme.bodyMedium?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  if (post.mediaUrls.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: AspectRatio(
                          aspectRatio: 16 / 9,
                          child: Image.network(
                            post.mediaUrls.first,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => Container(
                              color: colorScheme.surfaceContainerHigh,
                              child: Icon(
                                Icons.broken_image,
                                color: colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ),
                        ),
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
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Text(
                    _getSportEmoji(sport),
                    style: const TextStyle(fontSize: 24),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      title,
                      style: textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: colorScheme.onSurface,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '$currentPlayers/$maxPlayers',
                    style: textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Text(
                      '$sport • $format • $date at $time',
                      style: textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Flexible(
                    child: Text(
                      location,
                      style: textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                      textAlign: TextAlign.right,
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                    ),
                  ),
                ],
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
          .from('profiles')
          .select(
            'user_id, display_name, avatar_url, preferred_sport, created_at',
          )
          .isFilter('deleted_at', null)
          .order('created_at', ascending: false, nullsFirst: false)
          .limit(6);

      return (response as List).map((item) {
        return {
          'user_id': item['user_id'],
          'display_name': item['display_name'],
          'avatar_url': item['avatar_url'],
          'sport_key': item['preferred_sport'],
          'created_at': item['created_at'],
        };
      }).toList();
    } catch (e) {
      print('Error fetching newly joined users: $e');
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
          // Exclude past games (server-side)
          .gte('start_at', DateTime.now().toUtc().toIso8601String())
          // Show the next upcoming games first
          .order('start_at', ascending: true)
          // Fetch a few extra in case some rows have stale timestamps
          .limit(10);

      final games = (response as List).cast<Map<String, dynamic>>();
      final upcomingGames = games.where(_isGameInFuture).take(2).toList();
      return upcomingGames;
    } catch (e) {
      print('Error fetching recent games: $e');
      return [];
    }
  }

  bool _isGameInFuture(Map<String, dynamic> game) {
    final now = DateTime.now();

    DateTime? parseDateTime(dynamic value) {
      if (value is DateTime) return value;
      if (value is String) {
        return DateTime.tryParse(value);
      }
      return null;
    }

    DateTime? upcomingDateTime;

    final serverStart = parseDateTime(game['start_at']);
    if (serverStart != null) {
      upcomingDateTime = serverStart;
    } else {
      final scheduledDate = parseDateTime(game['scheduled_date']);
      if (scheduledDate != null) {
        final startTime = game['start_time'];
        if (startTime is String) {
          final parts = startTime.split(':');
          final hour = parts.isNotEmpty ? int.tryParse(parts[0]) ?? 0 : 0;
          final minute = parts.length > 1 ? int.tryParse(parts[1]) ?? 0 : 0;
          upcomingDateTime = DateTime(
            scheduledDate.year,
            scheduledDate.month,
            scheduledDate.day,
            hour,
            minute,
          );
        } else {
          upcomingDateTime = scheduledDate;
        }
      }
    }

    if (upcomingDateTime == null) {
      // If we cannot determine the date, err on the side of showing it so data
      // issues can be spotted and fixed at the source.
      return true;
    }

    return upcomingDateTime.isAfter(now);
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
    final gamesAsync = ref.watch(userUpcomingGamesProvider);

    return gamesAsync.when(
      data: (games) {
        if (games.isEmpty) {
          // Show action cards when no upcoming games
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

        // Show collapsible reminder cards (Apple Wallet style)
        return _buildCollapsibleReminderCards(games);
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
        print('Error loading upcoming games: $error');
        return const SizedBox.shrink();
      },
    );
  }

  /// Builds collapsible reminder cards in Apple Wallet style
  Widget _buildCollapsibleReminderCards(List<Game> games) {
    return Column(
      children: List.generate(games.length, (index) {
        final game = games[index];
        final isFirst = index == 0;
        final isLast = index == games.length - 1;

        return Padding(
          padding: EdgeInsets.only(bottom: isLast ? 0 : 8),
          child: _CollapsibleReminderCard(
            game: game,
            isFirst: isFirst,
            isLast: isLast,
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => GameDetailScreen(gameId: game.id),
                ),
              );
            },
          ),
        );
      }),
    );
  }
}

/// Collapsible reminder card widget in Apple Wallet style
class _CollapsibleReminderCard extends StatefulWidget {
  final Game game;
  final bool isFirst;
  final bool isLast;
  final VoidCallback onTap;

  const _CollapsibleReminderCard({
    required this.game,
    required this.isFirst,
    required this.isLast,
    required this.onTap,
  });

  @override
  State<_CollapsibleReminderCard> createState() =>
      _CollapsibleReminderCardState();
}

class _CollapsibleReminderCardState extends State<_CollapsibleReminderCard>
    with SingleTickerProviderStateMixin {
  bool _isExpanded = false;
  late AnimationController _animationController;
  late Animation<double> _expandAnimation;
  Timer? _countdownTimer;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _expandAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    );
    // First card is expanded by default
    if (widget.isFirst) {
      _isExpanded = true;
      _animationController.value = 1.0;
    }
    _startCountdownTimer();
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    _animationController.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant _CollapsibleReminderCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.game.id != widget.game.id ||
        oldWidget.game.scheduledDate != widget.game.scheduledDate ||
        oldWidget.game.startTime != widget.game.startTime) {
      _startCountdownTimer();
    }
  }

  void _toggleExpanded() {
    setState(() {
      _isExpanded = !_isExpanded;
      if (_isExpanded) {
        _animationController.forward();
      } else {
        _animationController.reverse();
      }
    });
  }

  void _startCountdownTimer() {
    _countdownTimer?.cancel();
    _countdownTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      if (!mounted) return;
      setState(() {});
    });
  }

  String _getCountdownLabel() {
    final now = DateTime.now();
    final gameDateTime = DateTime(
      widget.game.scheduledDate.year,
      widget.game.scheduledDate.month,
      widget.game.scheduledDate.day,
      _parseTime(widget.game.startTime).hour,
      _parseTime(widget.game.startTime).minute,
    );
    final difference = gameDateTime.difference(now);

    if (difference.inDays > 0) {
      return '${difference.inDays}d ${difference.inHours % 24}h';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ${difference.inMinutes % 60}m';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m';
    } else {
      return 'Now';
    }
  }

  TimeOfDay _parseTime(String timeString) {
    try {
      final parts = timeString.split(':');
      return TimeOfDay(hour: int.parse(parts[0]), minute: int.parse(parts[1]));
    } catch (e) {
      return const TimeOfDay(hour: 0, minute: 0);
    }
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;
    final countdownLabel = _getCountdownLabel();
    final timeFormat = '${widget.game.startTime} - ${widget.game.endTime}';

    // Calculate border radius for Apple Wallet style (rounded corners only on first/last)
    final borderRadius = BorderRadius.only(
      topLeft: Radius.circular(widget.isFirst ? 20 : 0),
      topRight: Radius.circular(widget.isFirst ? 20 : 0),
      bottomLeft: Radius.circular(widget.isLast ? 20 : 0),
      bottomRight: Radius.circular(widget.isLast ? 20 : 0),
    );

    return GestureDetector(
      // Vertical swipe to expand/collapse like a notification stack
      onVerticalDragEnd: (details) {
        final velocity = details.primaryVelocity ?? 0;
        if (velocity > 0 && !_isExpanded) {
          // Swipe down to expand
          _toggleExpanded();
        } else if (velocity < 0 && _isExpanded) {
          // Swipe up to collapse
          _toggleExpanded();
        }
      },
      child: Card(
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(borderRadius: borderRadius),
        clipBehavior: Clip.antiAlias,
        child: Container(
          decoration: BoxDecoration(
            color: colorScheme.surfaceContainerHighest,
            borderRadius: borderRadius,
            border: Border(
              top: widget.isFirst
                  ? BorderSide.none
                  : BorderSide(
                      color: colorScheme.outlineVariant.withOpacity(0.3),
                      width: 0.5,
                    ),
            ),
          ),
          child: Column(
            children: [
              // Collapsed/Header view
              InkWell(
                onTap: widget.onTap,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      // Sport emoji
                      Text(
                        _getSportEmoji(widget.game.sport),
                        style: const TextStyle(fontSize: 24),
                      ),
                      const SizedBox(width: 12),
                      // Game title and time
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.game.title,
                              style: textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.w600,
                                color: colorScheme.onSurface,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              timeFormat,
                              style: textTheme.bodySmall?.copyWith(
                                color: colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      ),
                      // Countdown badge
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: colorScheme.errorContainer,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Text(
                          countdownLabel,
                          style: textTheme.bodySmall?.copyWith(
                            fontWeight: FontWeight.w600,
                            color: colorScheme.onErrorContainer,
                            fontSize: 12,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      // Expand/collapse icon (tap to toggle)
                      InkWell(
                        onTap: _toggleExpanded,
                        borderRadius: BorderRadius.circular(20),
                        child: RotationTransition(
                          turns: _expandAnimation,
                          child: Icon(
                            Icons.keyboard_arrow_down,
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              // Expanded details
              SizeTransition(
                sizeFactor: _expandAnimation,
                axisAlignment: -1.0,
                child: Container(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Divider(
                        height: 1,
                        thickness: 0.5,
                        color: colorScheme.outlineVariant.withOpacity(0.3),
                      ),
                      const SizedBox(height: 12),
                      // Date
                      Row(
                        children: [
                          Icon(
                            Icons.calendar_today,
                            size: 16,
                            color: colorScheme.onSurfaceVariant,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            DateFormat(
                              'EEE, MMM d',
                            ).format(widget.game.scheduledDate),
                            style: textTheme.bodyMedium?.copyWith(
                              color: colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      // Location
                      Row(
                        children: [
                          Icon(
                            Icons.location_on,
                            size: 16,
                            color: colorScheme.onSurfaceVariant,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              widget.game.venueName ?? 'Location TBD',
                              style: textTheme.bodyMedium?.copyWith(
                                color: colorScheme.onSurfaceVariant,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      // View details button
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton(
                          onPressed: widget.onTap,
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: Text(
                            'View Details',
                            style: textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
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
}

class _FeedLoadingPlaceholder extends StatelessWidget {
  const _FeedLoadingPlaceholder();

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: colorScheme.surfaceContainerHigh,
                borderRadius: BorderRadius.circular(20),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    height: 16,
                    width: 120,
                    decoration: BoxDecoration(
                      color: colorScheme.surfaceContainerHigh,
                      borderRadius: BorderRadius.circular(6),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    height: 12,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: colorScheme.surfaceContainerHigh,
                      borderRadius: BorderRadius.circular(6),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Container(
                    height: 12,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: colorScheme.surfaceContainerHigh,
                      borderRadius: BorderRadius.circular(6),
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
}
