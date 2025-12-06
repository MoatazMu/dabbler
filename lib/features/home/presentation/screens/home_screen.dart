import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:dabbler/utils/constants/route_constants.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:dabbler/core/services/auth_service.dart';
import 'package:dabbler/core/config/feature_flags.dart';
import 'package:dabbler/features/profile/presentation/providers/profile_providers.dart';
import 'package:dabbler/features/games/providers/games_providers.dart';
import 'package:dabbler/features/games/presentation/screens/join_game/game_detail_screen.dart';
import 'package:dabbler/features/home/presentation/providers/home_providers.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:dabbler/core/design_system/design_system.dart';
import 'package:dabbler/widgets/thoughts_input.dart';
import 'package:dabbler/data/models/games/game.dart';
import 'package:dabbler/features/social/presentation/widgets/feed/post_card.dart';
import 'package:dabbler/features/social/services/social_service.dart';
import 'package:dabbler/core/widgets/custom_avatar.dart';
import 'package:dabbler/themes/material3_extensions.dart';

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

  bool _shouldShowCreateGame() {
    final profileState = ref.watch(profileControllerProvider);
    final profileType = profileState.profile?.profileType;

    print('🔍 [DEBUG] _shouldShowCreateGame - profileType: $profileType');
    print(
      '🔍 [DEBUG] enablePlayerGameCreation: ${FeatureFlags.enablePlayerGameCreation}',
    );
    print(
      '🔍 [DEBUG] enableOrganiserGameCreation: ${FeatureFlags.enableOrganiserGameCreation}',
    );

    if (profileType == 'player') {
      return FeatureFlags.enablePlayerGameCreation;
    } else if (profileType == 'organiser') {
      return FeatureFlags.enableOrganiserGameCreation;
    }
    return false;
  }

  bool _shouldShowJoinGame() {
    final profileState = ref.watch(profileControllerProvider);
    final profileType = profileState.profile?.profileType;

    if (profileType == 'player') {
      return FeatureFlags.enablePlayerGameJoining;
    } else if (profileType == 'organiser') {
      return FeatureFlags.enableOrganiserGameJoining;
    }
    return false;
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

  Future<void> _handleRefresh() async {
    // Reload user profile
    await _loadUserProfile();

    // Invalidate providers to refresh data
    ref.invalidate(profileControllerProvider);
    ref.invalidate(userUpcomingGamesProvider);
    ref.invalidate(latestFeedPostsProvider);

    // Small delay for smooth UX
    await Future.delayed(const Duration(milliseconds: 300));
  }

  Widget _buildHeader() {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    // Extract initials from display name
    String? getInitials(String? displayName) {
      if (displayName == null || displayName.isEmpty) return null;
      final parts = displayName.trim().split(' ');
      if (parts.isEmpty) return null;
      if (parts.length == 1) {
        return parts[0][0].toUpperCase();
      }
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }

    return Row(
      children: [
        GestureDetector(
          onTap: () => context.go('/home'),
          child: DSAvatar.size48(
            imageUrl:
                _userProfile?['avatar_url'] is String &&
                    (_userProfile!['avatar_url'] as String).isNotEmpty
                ? _userProfile!['avatar_url']
                : null,
            initials: getInitials(_userProfile?['display_name']),
            backgroundColor: colorScheme.categoryMain.withValues(alpha: 0.2),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            'Home',
            style: textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w700,
              color: colorScheme.onSurface,
            ),
          ),
        ),
        const SizedBox(width: 12),
        if (FeatureFlags.enableNotificationCenter)
          IconButton.filledTonal(
            onPressed: () => context.go(RoutePaths.notifications),
            icon: const Icon(Iconsax.notification_status_copy),
            style: IconButton.styleFrom(
              backgroundColor: colorScheme.categoryMain.withValues(alpha: 0.2),
              foregroundColor: colorScheme.onSurface,
              minimumSize: const Size(48, 48),
            ),
          ),
        if (FeatureFlags.enableNotificationCenter) const SizedBox(width: 8),
        IconButton.filledTonal(
          onPressed: () => context.go(RoutePaths.profile),
          icon: const Icon(Iconsax.user_copy),
          style: IconButton.styleFrom(
            backgroundColor: colorScheme.categoryMain.withValues(alpha: 0.2),
            foregroundColor: colorScheme.onSurface,
            minimumSize: const Size(48, 48),
          ),
        ),
      ],
    );
  }

  Widget _buildGreetingSection(String? displayName) {
    final tokens = context.colorTokens;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '${_getGreeting()},',
          style: AppTypography.titleMedium.copyWith(color: tokens.titleOnHead),
        ),
        if (displayName != null)
          Text(
            '$displayName!',
            style: AppTypography.displaySmall.copyWith(
              color: tokens.titleOnHead,
            ),
          )
        else
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Complete your profile',
                style: AppTypography.titleMedium.copyWith(
                  color: tokens.titleOnHead,
                  fontStyle: FontStyle.italic,
                ),
              ),
              const SizedBox(height: 8),
              AppButton.primary(
                label: 'Update now',
                onPressed: () => context.go(RoutePaths.profile),
                size: AppButtonSize.sm,
              ),
            ],
          ),
      ],
    );
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
      category: 'main',
      topSection: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(),
          const SizedBox(height: 24),
          _buildGreetingSection(displayName),
          Padding(
            padding: const EdgeInsets.only(top: 16),
            child: _buildUpcomingGameSection(),
          ),
          Padding(
            padding: const EdgeInsets.only(top: 16),
            child: ThoughtsInput(
              onTap: () {
                // TODO: Navigate to create post screen
              },
            ),
          ),
        ],
      ),
      bottomSection: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildQuickAccessSection(),
          Padding(
            padding: const EdgeInsets.only(top: 0),
            child: _buildNewlyJoinedSection(),
          ),
          Padding(
            padding: const EdgeInsets.only(top: 0),
            child: _buildActivitiesButton(),
          ),
          // Main Social Feed - Primary feature
          Padding(
            padding: const EdgeInsets.only(top: 28),
            child: _buildSocialFeedSection(),
          ),
          // Padding(
          //   padding: const EdgeInsets.only(top: 36),
          //   child: _buildRecentGamesSection(),
          // ),
        ],
      ),
      onRefresh: _handleRefresh,
    );
  }

  Widget _buildHeroSection(String? displayName) {
    final tokens = context.colorTokens;

    return Column(
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${_getGreeting()},',
                    style: AppTypography.titleMedium.copyWith(
                      color: tokens.titleOnHead,
                    ),
                  ),
                  if (displayName != null)
                    Text(
                      '$displayName!',
                      style: AppTypography.displaySmall.copyWith(
                        color: tokens.titleOnHead,
                      ),
                    )
                  else
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Complete your profile',
                          style: AppTypography.titleMedium.copyWith(
                            color: tokens.titleOnHead,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                        const SizedBox(height: 8),
                        AppButton.primary(
                          label: 'Update now',
                          onPressed: () => context.go(RoutePaths.profile),
                          size: AppButtonSize.sm,
                        ),
                      ],
                    ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Row(
              children: [
                if (FeatureFlags.enableNotificationCenter)
                  GestureDetector(
                    onTap: () => context.go(RoutePaths.notifications),
                    child: Container(
                      width: 30,
                      height: 30,
                      alignment: Alignment.center,
                      child: SvgPicture.asset(
                        'assets/icons/notification.svg',
                        width: 24,
                        height: 24,
                        colorFilter: ColorFilter.mode(
                          tokens.titleOnHead,
                          BlendMode.srcIn,
                        ),
                      ),
                    ),
                  ),
                if (FeatureFlags.enableNotificationCenter)
                  const SizedBox(width: 12),
                GestureDetector(
                  onTap: () => context.go(RoutePaths.profile),
                  child: DSAvatar.size54(
                    imageUrl: _userProfile?['avatar_url'],
                    initials: _userProfile?['display_name'],
                  ),
                ),
              ],
            ),
          ],
        ),
        Padding(
          padding: const EdgeInsets.only(top: 16),
          child: _buildUpcomingGameSection(),
        ),
        Padding(
          padding: const EdgeInsets.only(top: 16),
          child: ThoughtsInput(
            onTap: () {
              // TODO: Navigate to create post screen
              // For now, you can use PostService to create posts
            },
          ),
        ),
      ],
    );
  }

  Widget _buildQuickAccessSection() {
    return Column(
      children: [
        // Only show Create Game button for organisers with permission
        if (_shouldShowCreateGame())
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
    final tokens = context.colorTokens;

    return Row(
      children: [
        Expanded(
          child: FilledButton.tonalIcon(
            onPressed: () => context.go(RoutePaths.activities),
            style: FilledButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              backgroundColor: tokens.section,
              foregroundColor: tokens.titleOnSec,
            ),
            icon: const Text('⚡', style: TextStyle(fontSize: 18)),
            label: Text('Activities', style: AppTypography.labelMedium),
          ),
        ),
        if (FeatureFlags.enableNotificationCenter) ...[
          const SizedBox(width: 12),
          Expanded(
            child: FilledButton.tonalIcon(
              onPressed: () => context.go(RoutePaths.notifications),
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  vertical: 16,
                  horizontal: 20,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                backgroundColor: tokens.section,
                foregroundColor: tokens.titleOnSec,
              ),
              icon: const Text('🔔', style: TextStyle(fontSize: 18)),
              label: Text('Notifications', style: AppTypography.labelMedium),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildNewlyJoinedSection() {
    final tokens = context.colorTokens;

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
              style: AppTypography.titleLarge.copyWith(
                color: tokens.titleOnSec,
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
                          player['sport_key'] != null
                              ? AppAvatar.withSportBadge(
                                  imageUrl: player['avatar_url'],
                                  fallbackText: player['display_name'],
                                  size: 52,
                                  sportEmoji: _getSportEmoji(
                                    player['sport_key'],
                                  ),
                                )
                              : AppAvatar(
                                  imageUrl: player['avatar_url'],
                                  fallbackText: player['display_name'],
                                  size: 52,
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

  Widget _buildSocialFeedSection() {
    final tokens = context.colorTokens;
    final postsAsync = ref.watch(latestFeedPostsProvider);

    return postsAsync.when(
      data: (posts) {
        if (posts.isEmpty) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Feed',
                style: AppTypography.titleLarge.copyWith(
                  color: tokens.titleOnSec,
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(top: 12),
                child: Card(
                  elevation: 0,
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        SvgPicture.asset(
                          'assets/icons/document-text.svg',
                          width: 48,
                          height: 48,
                          colorFilter: ColorFilter.mode(
                            tokens.neutralOpacity,
                            BlendMode.srcIn,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No posts yet',
                          style: AppTypography.titleMedium.copyWith(
                            color: tokens.titleOnSec,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Be the first to share something with the community.',
                          textAlign: TextAlign.center,
                          style: AppTypography.bodyMedium.copyWith(
                            color: tokens.neutralOpacity,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          );
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(top: 0),
              child: Column(
                children: posts
                    .map(
                      (post) => PostCard(
                        post: post,
                        onLike: () => _handleLikePost(post.id),
                        onComment: () => _handleCommentPost(post.id),
                        onPostTap: () => context.pushNamed(
                          RouteNames.socialPostDetail,
                          pathParameters: {'postId': post.id},
                        ),
                        onProfileTap: () {
                          // TODO: Navigate to profile
                        },
                      ),
                    )
                    .toList(),
              ),
            ),
          ],
        );
      },
      loading: () => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Feed',
            style: AppTypography.titleLarge.copyWith(color: tokens.titleOnSec),
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
            'Feed',
            style: AppTypography.titleLarge.copyWith(color: tokens.titleOnSec),
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
                      style: AppTypography.titleMedium.copyWith(
                        color: tokens.titleOnSec,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Please check your connection and try again.',
                      style: AppTypography.bodyMedium.copyWith(
                        color: tokens.neutralOpacity,
                      ),
                    ),
                    const SizedBox(height: 12),
                    OutlinedButton(
                      onPressed: () => ref.refresh(latestFeedPostsProvider),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          SvgPicture.asset(
                            'assets/icons/refresh.svg',
                            width: 16,
                            height: 16,
                          ),
                          const SizedBox(width: 8),
                          const Text('Retry'),
                        ],
                      ),
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

  Future<void> _handleLikePost(String postId) async {
    try {
      final socialService = SocialService();
      await socialService.toggleLike(postId);
      // Refresh posts to show updated like count
      if (mounted) {
        ref.invalidate(latestFeedPostsProvider);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to like post: $e'),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    }
  }

  void _handleCommentPost(String postId) {
    context.pushNamed(
      RouteNames.socialPostDetail,
      pathParameters: {'postId': postId},
    );
  }

  Widget _buildRecentGamesSection() {
    final tokens = context.colorTokens;

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
              style: AppTypography.titleLarge.copyWith(
                color: tokens.titleOnSec,
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
    final tokens = context.colorTokens;

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
                      style: AppTypography.titleMedium.copyWith(
                        color: tokens.titleOnSec,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '$currentPlayers/$maxPlayers',
                    style: AppTypography.labelSmall.copyWith(
                      color: tokens.neutralOpacity,
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
                      style: AppTypography.bodySmall.copyWith(
                        color: tokens.neutralOpacity,
                      ),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Flexible(
                    child: Text(
                      location,
                      style: AppTypography.bodySmall.copyWith(
                        color: tokens.neutralOpacity,
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
          .eq('is_active', true)
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
          final showCreateGame = _shouldShowCreateGame();
          final showJoinGame = _shouldShowJoinGame();

          if (!showCreateGame && !showJoinGame) {
            return const SizedBox.shrink();
          }

          return Row(
            children: [
              if (showCreateGame)
                Expanded(
                  child: AppActionCard(
                    emoji: '➕',
                    title: 'Create Game',
                    subtitle: 'Start a new match',
                    onTap: () => context.go(RoutePaths.createGame),
                  ),
                ),
              if (showCreateGame && showJoinGame) const SizedBox(width: 12),
              if (showJoinGame)
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

  /// Builds upcoming game cards using design system component
  Widget _buildCollapsibleReminderCards(List<Game> games) {
    return Column(
      children: List.generate(games.length, (index) {
        final game = games[index];
        final isFirst = index == 0;
        final isLast = index == games.length - 1;

        return Padding(
          padding: EdgeInsets.only(bottom: isLast ? 0 : 8),
          child: _StatefulUpcomingGameCard(
            game: game,
            isFirst: isFirst,
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

/// Stateful wrapper for UpcomingGameCard to handle expand/collapse
class _StatefulUpcomingGameCard extends StatefulWidget {
  final Game game;
  final bool isFirst;
  final VoidCallback onTap;

  const _StatefulUpcomingGameCard({
    required this.game,
    required this.isFirst,
    required this.onTap,
  });

  @override
  State<_StatefulUpcomingGameCard> createState() =>
      _StatefulUpcomingGameCardState();
}

class _StatefulUpcomingGameCardState extends State<_StatefulUpcomingGameCard> {
  bool _isExpanded = false;
  Timer? _countdownTimer;

  @override
  void initState() {
    super.initState();
    // First card is expanded by default
    _isExpanded = widget.isFirst;
    _startCountdownTimer();
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    super.dispose();
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

  @override
  Widget build(BuildContext context) {
    final countdownLabel = _getCountdownLabel();
    final dateTime =
        '${DateFormat('EEE, MMM d').format(widget.game.scheduledDate)} - ${widget.game.startTime} - ${widget.game.endTime}';

    return GestureDetector(
      onTap: () {
        setState(() {
          _isExpanded = !_isExpanded;
        });
      },
      child: _isExpanded
          ? UpcomingGameCard.expanded(
              title: 'Upcoming Game',
              gameName: widget.game.title,
              timeRemaining: countdownLabel,
              sportIcon: AppSportIcon.size18(
                emoji: _getSportEmoji(widget.game.sport),
              ),
              dateTime: dateTime,
              location: widget.game.venueName ?? 'Location TBD',
              width: double.infinity,
            )
          : UpcomingGameCard.collapsed(
              title: 'Upcoming Game',
              gameName: widget.game.title,
              timeRemaining: countdownLabel,
              sportIcon: AppSportIcon.size18(
                emoji: _getSportEmoji(widget.game.sport),
              ),
              width: double.infinity,
            ),
    );
  }
}

class _FeedLoadingPlaceholder extends StatelessWidget {
  const _FeedLoadingPlaceholder();

  @override
  Widget build(BuildContext context) {
    final tokens = context.colorTokens;

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
                color: tokens.section,
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
                      color: tokens.section,
                      borderRadius: BorderRadius.circular(6),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    height: 12,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: tokens.section,
                      borderRadius: BorderRadius.circular(6),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Container(
                    height: 12,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: tokens.section,
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
