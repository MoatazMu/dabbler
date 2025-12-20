import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import '../../controllers/profile_controller.dart';
import '../../controllers/sports_profile_controller.dart';
import '../../providers/profile_providers.dart';
import 'package:dabbler/data/models/profile/user_profile.dart';
import 'package:dabbler/data/models/profile/profile_statistics.dart';
import 'package:dabbler/themes/app_theme.dart';
import '../../../../../utils/constants/route_constants.dart';
import '../../widgets/profile/player_sport_profile_header.dart';
import 'package:dabbler/data/repositories/friends_repository_impl.dart';
import 'package:dabbler/features/misc/data/datasources/supabase_remote_data_source.dart';
import 'package:dabbler/features/misc/data/datasources/supabase_error_mapper.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:dabbler/core/fp/result.dart';
import 'package:dabbler/core/design_system/layouts/two_section_layout.dart';
import 'package:dabbler/core/design_system/tokens/token_based_theme.dart';
import 'package:dabbler/features/social/presentation/widgets/feed/post_card.dart';
import 'package:dabbler/data/models/social/post_model.dart';
import 'package:dabbler/features/social/services/social_service.dart';
import 'package:dabbler/features/social/providers.dart';
import 'package:dabbler/features/profile/presentation/widgets/friends_list_widget.dart';

/// Provider to fetch all posts by a user for the activities tab
final userPostsProvider = FutureProvider.family<List<PostModel>, String>((
  ref,
  userId,
) async {
  final supabase = Supabase.instance.client;

  try {
    // Query posts by author_user_id, similar to SocialService.getFeedPosts
    final postsResponse = await supabase
        .from('posts')
        .select(
          '*, vibe:vibes!primary_vibe_id(emoji, label_en, key, color_hex)',
        )
        .eq('author_user_id', userId)
        .eq('is_deleted', false)
        .eq('is_hidden_admin', false)
        .order('created_at', ascending: false)
        .limit(50);

    // Fetch author profile
    final profileResponse = await supabase
        .from('profiles')
        .select('user_id, display_name, avatar_url, verified')
        .eq('user_id', userId)
        .maybeSingle();

    // Fetch current user's liked post IDs
    final user = supabase.auth.currentUser;
    final Set<String> likedPostIds = {};
    if (user != null && postsResponse.isNotEmpty) {
      final postIds = postsResponse
          .map((post) => post['id'].toString())
          .toList();
      final likedPosts = await supabase
          .from('post_likes')
          .select('post_id')
          .eq('user_id', user.id)
          .inFilter('post_id', postIds);
      likedPostIds.addAll(likedPosts.map((like) => like['post_id'].toString()));
    }

    // Transform database posts to PostModel
    final posts = postsResponse.map((post) {
      final postId = post['id'].toString();

      // Extract media URL
      List<String> mediaUrls = [];
      final mediaData = post['media'];
      if (mediaData is Map<String, dynamic>) {
        final bucket = mediaData['bucket'] as String?;
        final path = mediaData['path'] as String?;
        if (bucket != null && path != null) {
          final publicUrl = supabase.storage.from(bucket).getPublicUrl(path);
          if (publicUrl.isNotEmpty) {
            mediaUrls.add(publicUrl);
          }
        }
      }

      return {
        ...post,
        'profiles': profileResponse ?? {},
        'is_liked': likedPostIds.contains(postId),
        'media_urls': mediaUrls,
      };
    }).toList();

    return posts.map((post) => PostModel.fromJson(post)).toList();
  } catch (e) {
    return [];
  }
});

class _UserActivitiesTab extends ConsumerWidget {
  final String userId;
  const _UserActivitiesTab({required this.userId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final postsAsync = ref.watch(userPostsProvider(userId));
    return postsAsync.when(
      data: (posts) {
        if (posts.isEmpty) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(24.0),
              child: Text('No activities yet.'),
            ),
          );
        }
        return ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: posts.length,
          itemBuilder: (context, index) {
            final post = posts[index];
            return PostCard(
              post: post,
              onLike: () => _handleLikePost(context, ref, post.id),
              onComment: () => _handleCommentPost(context, post.id),
              onDelete: () {
                // Refresh activities after deletion
                ref.invalidate(userPostsProvider(userId));
              },
              onPostTap: () => context.pushNamed(
                RouteNames.socialPostDetail,
                pathParameters: {'postId': post.id},
              ),
              onProfileTap: () {
                context.go('${RoutePaths.userProfile}/$userId');
              },
            );
          },
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, st) => const Center(
        child: Padding(
          padding: EdgeInsets.all(24.0),
          child: Text('Failed to load activities.'),
        ),
      ),
    );
  }

  Future<void> _handleLikePost(
    BuildContext context,
    WidgetRef ref,
    String postId,
  ) async {
    try {
      final socialService = SocialService();
      await socialService.toggleLike(postId);

      // Wait for database trigger to update like_count
      await Future.delayed(const Duration(milliseconds: 400));

      // Refresh posts to show updated like count
      if (context.mounted) {
        ref.invalidate(userPostsProvider(userId));
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to like post: $e'),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    }
  }

  void _handleCommentPost(BuildContext context, String postId) {
    context.pushNamed(
      RouteNames.socialPostDetail,
      pathParameters: {'postId': postId},
    );
  }
}

class UserProfileScreen extends ConsumerStatefulWidget {
  final String userId;

  const UserProfileScreen({super.key, required this.userId});

  @override
  ConsumerState<UserProfileScreen> createState() => _UserProfileScreenState();
}

class _UserProfileScreenState extends ConsumerState<UserProfileScreen>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late AnimationController _refreshController;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _refreshController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );

    _animationController.forward();

    // Check if viewing own profile and load data
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkOwnProfile();
      _loadProfileData();
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    _refreshController.dispose();
    super.dispose();
  }

  Future<void> _checkOwnProfile() async {
    final currentUser = ref.read(currentUserProvider);
    if (currentUser != null && currentUser.id == widget.userId) {
      // Redirect to own profile screen
      if (mounted) {
        context.go(RoutePaths.profile);
      }
    }
  }

  Future<void> _loadProfileData() async {
    final profileController = ref.read(profileControllerProvider.notifier);
    final sportsController = ref.read(sportsProfileControllerProvider.notifier);

    await Future.wait<void>([
      profileController.loadProfile(widget.userId),
      sportsController.loadSportsProfiles(widget.userId),
    ]);
  }

  Future<void> _onRefresh() async {
    _refreshController.reset();
    _refreshController.forward();
    await _loadProfileData();
  }

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    final theme = brightness == Brightness.dark
        ? TokenBasedTheme.build(AppThemeMode.socialDark)
        : TokenBasedTheme.build(AppThemeMode.socialLight);
    return Theme(
      data: theme,
      child: Builder(
        builder: (context) {
          final profileState = ref.watch(profileControllerProvider);
          final sportsState = ref.watch(sportsProfileControllerProvider);
          final colorScheme = Theme.of(context).colorScheme;
          final sportProfileHeaderAsync = ref.watch(
            sportProfileHeaderProvider(widget.userId),
          );

          // Show loading state
          if (profileState.isLoading) {
            return Scaffold(
              backgroundColor: colorScheme.surface,
              body: const Center(child: CircularProgressIndicator()),
            );
          }

          // Show error state
          if (profileState.errorMessage != null &&
              profileState.profile == null) {
            return Scaffold(
              backgroundColor: colorScheme.surface,
              body: SafeArea(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Iconsax.danger_copy,
                        size: 64,
                        color: colorScheme.error,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Profile not found',
                        style: Theme.of(context).textTheme.headlineSmall,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        profileState.errorMessage ?? 'Unable to load profile',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 24),
                      FilledButton.icon(
                        onPressed: () => context.pop(),
                        icon: const Icon(Iconsax.arrow_left_copy),
                        label: const Text('Go back'),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }

          return TwoSectionLayout(
            category: 'social',
            onRefresh: _onRefresh,
            topSection: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(context),
                const SizedBox(height: 24),
                _buildProfileHeroCard(context, profileState, sportsState),
                const SizedBox(height: 16),
                _buildActionButtons(context),
                const SizedBox(height: 16),
                _buildSportProfileHeaderSection(
                  context,
                  sportProfileHeaderAsync,
                ),
              ],
            ),
            bottomSection: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 16),
                _buildFriendsSection(context),
                const SizedBox(height: 24),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Text(
                    'Activities',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                _UserActivitiesTab(userId: widget.userId),
              ],
            ),
            bottomBackgroundColor: Theme.of(
              context,
            ).colorScheme.secondaryContainer,
          );
        },
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Row(
      children: [
        IconButton.filledTonal(
          onPressed: () =>
              context.canPop() ? context.pop() : context.go('/home'),
          icon: const Icon(Iconsax.arrow_left_copy),
          style: IconButton.styleFrom(
            backgroundColor: colorScheme.categorySocial.withValues(alpha: 0.0),
            foregroundColor: colorScheme.onSurface,
            minimumSize: const Size(48, 48),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Profile',
                style: textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: colorScheme.onSurface,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 12),
        IconButton.filledTonal(
          onPressed: () => _showMoreOptions(context),
          icon: const Icon(Iconsax.more_copy),
          style: IconButton.styleFrom(
            backgroundColor: colorScheme.categorySocial.withValues(alpha: 0.0),
            foregroundColor: colorScheme.onSurface,
            minimumSize: const Size(48, 48),
          ),
        ),
      ],
    );
  }

  Widget _buildProfileHeroCard(
    BuildContext context,
    ProfileState profileState,
    SportsProfileState sportsState,
  ) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final profile = profileState.profile;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(0),
      decoration: BoxDecoration(borderRadius: BorderRadius.circular(28)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _buildAvatar(context, profile),
              const SizedBox(width: 12),
              Expanded(
                child: _buildHeroDetails(
                  context,
                  profileState,
                  textTheme,
                  colorScheme,
                ),
              ),
            ],
          ),
          const SizedBox(height: 9),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 9),
            child: Text(
              profile?.bio?.isNotEmpty == true
                  ? profile!.bio!
                  : 'No bio available.',
              style: textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(height: 9),
          _buildHeroStats(context, profileState, sportsState),
        ],
      ),
    );
  }

  Widget _buildAvatar(BuildContext context, UserProfile? profile) {
    final colorScheme = Theme.of(context).colorScheme;

    return CircleAvatar(
      radius: 30,
      backgroundColor: colorScheme.categorySocial.withValues(alpha: 0.2),
      foregroundColor: colorScheme.categorySocial,
      backgroundImage:
          profile?.avatarUrl != null && profile!.avatarUrl!.isNotEmpty
          ? NetworkImage(profile.avatarUrl!)
          : null,
      child: profile?.avatarUrl == null || profile!.avatarUrl!.isEmpty
          ? const Icon(Iconsax.user_copy, size: 36)
          : null,
    );
  }

  Widget _buildHeroDetails(
    BuildContext context,
    ProfileState profileState,
    TextTheme textTheme,
    ColorScheme colorScheme,
  ) {
    final profile = profileState.profile;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          profile?.getDisplayName().isNotEmpty == true
              ? profile!.getDisplayName()
              : 'User',
          style: textTheme.labelLarge?.copyWith(
            fontWeight: FontWeight.w700,
            color: colorScheme.onSurface,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            if (profile?.username != null && profile!.username!.isNotEmpty) ...[
              Text(
                '@${profile.username}',
                style: textTheme.labelSmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
              if ((profile.city?.isNotEmpty == true ||
                      profile.country?.isNotEmpty == true) ||
                  profile.age != null) ...[
                const SizedBox(width: 9),
              ],
            ],
            if (profile?.city?.isNotEmpty == true ||
                profile?.country?.isNotEmpty == true) ...[
              Icon(
                Iconsax.location_copy,
                size: 16,
                color: colorScheme.onSurfaceVariant,
              ),
              const SizedBox(width: 4),
              Text(
                _formatLocation(profile!.city, profile.country),
                style: textTheme.labelSmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
              if (profile.age != null) ...[const SizedBox(width: 9)],
            ],
            if (profile?.age != null) ...[
              Icon(
                Iconsax.cake_copy,
                size: 16,
                color: colorScheme.onSurfaceVariant,
              ),
              const SizedBox(width: 4),
              Text(
                '${profile!.age!} Yo',
                style: textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ],
        ),
      ],
    );
  }

  Widget _buildHeroStats(
    BuildContext context,
    ProfileState profileState,
    SportsProfileState sportsState,
  ) {
    final profile = profileState.profile;
    final statistics = profile?.statistics ?? const ProfileStatistics();
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    final allStats = [
      _HeroStat(
        label: 'Games',
        value: statistics.totalGamesPlayed.toString(),
        icon: Iconsax.game_copy,
      ),
      _HeroStat(
        label: 'Win rate',
        value: statistics.winRateFormatted,
        icon: Iconsax.cup_copy,
      ),
      _HeroStat(
        label: 'Sports',
        value: sportsState.profiles.length.toString(),
        icon: Iconsax.medal_star_copy,
      ),
      _HeroStat(
        label: 'Reliability',
        value: '${statistics.getReliabilityScore().round()}%',
        icon: Iconsax.verify_copy,
      ),
      _HeroStat(
        label: 'Activity',
        value: statistics.getActivityLevel(),
        icon: Iconsax.flash_1_copy,
      ),
      _HeroStat(
        label: 'Last play',
        value: statistics.lastActiveFormatted,
        icon: Iconsax.clock_copy,
      ),
    ];

    return Column(
      children: [
        Row(
          children: allStats
              .sublist(0, 3)
              .map(
                (stat) => Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(right: 0),
                    child: _buildStatCard(stat, colorScheme, textTheme),
                  ),
                ),
              )
              .toList(),
        ),
        Row(
          children: allStats
              .sublist(3)
              .map(
                (stat) => Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(right: 0),
                    child: _buildStatCard(stat, colorScheme, textTheme),
                  ),
                ),
              )
              .toList(),
        ),
      ],
    );
  }

  Widget _buildStatCard(
    _HeroStat stat,
    ColorScheme colorScheme,
    TextTheme textTheme,
  ) {
    return Card(
      elevation: 0,
      color: colorScheme.categorySocial.withValues(alpha: 0.08),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide.none,
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              stat.value,
              style: textTheme.labelMedium?.copyWith(
                color: colorScheme.onSurface,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              stat.label,
              style: textTheme.labelSmall?.copyWith(
                color: colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.w400,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButtons(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final friendshipStatusAsync = ref.watch(
      friendshipStatusProvider(widget.userId),
    );

    return Row(
      children: [
        Expanded(
          child: FilledButton.icon(
            onPressed: () => _sendMessage(context),
            icon: const Icon(Iconsax.message_copy),
            label: const Text('Message'),
            style: FilledButton.styleFrom(
              backgroundColor: colorScheme.categorySocial,
              foregroundColor: colorScheme.onPrimary,
            ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: friendshipStatusAsync.when(
            data: (result) => switch (result) {
              Ok(:final value) => _buildFriendButton(context, value),
              Err() => _buildFriendButton(context, 'none'),
              _ => _buildFriendButton(context, 'none'),
            },
            loading: () => OutlinedButton.icon(
              onPressed: null,
              icon: const SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
              label: const Text('Loading'),
              style: OutlinedButton.styleFrom(
                foregroundColor: colorScheme.categorySocial,
                side: BorderSide(
                  color: colorScheme.categorySocial.withValues(alpha: 0.5),
                ),
              ),
            ),
            error: (_, __) => _buildFriendButton(context, 'none'),
          ),
        ),
      ],
    );
  }

  Widget _buildFriendButton(BuildContext context, String status) {
    final colorScheme = Theme.of(context).colorScheme;

    switch (status) {
      case 'friends':
        return OutlinedButton.icon(
          onPressed: () => _showUnfriendDialog(context),
          icon: const Icon(Iconsax.user_tick_copy),
          label: const Text('Friends'),
          style: OutlinedButton.styleFrom(
            foregroundColor: colorScheme.categorySocial,
            side: BorderSide(
              color: colorScheme.categorySocial.withValues(alpha: 0.5),
            ),
          ),
        );
      case 'pending_sent':
        return OutlinedButton.icon(
          onPressed: () => _cancelFriendRequest(context),
          icon: const Icon(Iconsax.user_remove_copy),
          label: const Text('Cancel Request'),
          style: OutlinedButton.styleFrom(
            foregroundColor: colorScheme.onSurfaceVariant,
            side: BorderSide(
              color: colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
            ),
          ),
        );
      case 'pending_received':
        return FilledButton.icon(
          onPressed: () => _acceptFriendRequest(context),
          icon: const Icon(Iconsax.user_tick_copy),
          label: const Text('Accept Request'),
          style: FilledButton.styleFrom(
            backgroundColor: colorScheme.categorySocial,
            foregroundColor: colorScheme.onPrimary,
          ),
        );
      case 'blocked':
        return OutlinedButton.icon(
          onPressed: null,
          icon: const Icon(Iconsax.slash_copy),
          label: const Text('Blocked'),
          style: OutlinedButton.styleFrom(
            foregroundColor: colorScheme.error,
            side: BorderSide(color: colorScheme.error.withValues(alpha: 0.5)),
          ),
        );
      case 'none':
      default:
        return OutlinedButton.icon(
          onPressed: () => _addFriend(context),
          icon: const Icon(Iconsax.user_add_copy),
          label: const Text('Add Friend'),
          style: OutlinedButton.styleFrom(
            foregroundColor: colorScheme.categorySocial,
            side: BorderSide(
              color: colorScheme.categorySocial.withValues(alpha: 0.5),
            ),
          ),
        );
    }
  }

  Widget _buildSportProfileHeaderSection(
    BuildContext context,
    AsyncValue<SportProfileHeaderData?> headerData,
  ) {
    return headerData.when(
      data: (data) {
        if (data == null) {
          return _buildSportProfileEmptyState(context);
        }
        return PlayerSportProfileHeader(
          profile: data.profile,
          tier: data.tier,
          badges: data.badges,
        );
      },
      loading: () => const SizedBox(
        height: 140,
        child: Center(child: CircularProgressIndicator()),
      ),
      error: (error, stackTrace) => _buildSportProfileEmptyState(context),
    );
  }

  Widget _buildSportProfileEmptyState(BuildContext context) {
    return const SizedBox.shrink();
  }

  Widget _buildFriendsSection(BuildContext context) {
    final friendsAsync = ref.watch(userFriendsListProvider(widget.userId));

    return friendsAsync.when(
      data: (friends) => FriendsListWidget(
        friends: friends,
        onViewAll: () {
          // TODO: Navigate to full friends list screen
        },
      ),
      loading: () => const FriendsListWidget(friends: [], isLoading: true),
      error: (_, __) => const SizedBox.shrink(),
    );
  }

  String _formatLocation(String? city, String? country) {
    final cityStr = city?.trim();
    final countryStr = country?.trim();

    if (cityStr != null &&
        cityStr.isNotEmpty &&
        countryStr != null &&
        countryStr.isNotEmpty) {
      return '$cityStr, $countryStr';
    } else if (cityStr != null && cityStr.isNotEmpty) {
      return cityStr;
    } else if (countryStr != null && countryStr.isNotEmpty) {
      return countryStr;
    }
    return '';
  }

  void _sendMessage(BuildContext context) {
    final userId = widget.userId;
    context.push('${RoutePaths.socialChat}/$userId');
  }

  void _addFriend(BuildContext context) async {
    try {
      final client = Supabase.instance.client;
      final errorMapper = SupabaseErrorMapper();
      final supabaseService = SupabaseService(client, errorMapper);
      final friendsRepo = FriendsRepositoryImpl(supabaseService);

      final result = await friendsRepo.sendFriendRequest(widget.userId);

      if (mounted) {
        switch (result) {
          case Ok():
            ref.invalidate(friendshipStatusProvider(widget.userId));
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Friend request sent')),
            );
          case Err(:final error):
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(SnackBar(content: Text('Failed: ${error.message}')));
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  void _acceptFriendRequest(BuildContext context) async {
    try {
      final client = Supabase.instance.client;
      final errorMapper = SupabaseErrorMapper();
      final supabaseService = SupabaseService(client, errorMapper);
      final friendsRepo = FriendsRepositoryImpl(supabaseService);

      final result = await friendsRepo.acceptFriendRequest(widget.userId);

      if (mounted) {
        switch (result) {
          case Ok():
            ref.invalidate(friendshipStatusProvider(widget.userId));
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Friend request accepted')),
            );
          case Err(:final error):
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(SnackBar(content: Text('Failed: ${error.message}')));
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  void _cancelFriendRequest(BuildContext context) async {
    try {
      final client = Supabase.instance.client;
      final errorMapper = SupabaseErrorMapper();
      final supabaseService = SupabaseService(client, errorMapper);
      final friendsRepo = FriendsRepositoryImpl(supabaseService);

      final result = await friendsRepo.rejectFriendRequest(widget.userId);

      if (mounted) {
        switch (result) {
          case Ok():
            ref.invalidate(friendshipStatusProvider(widget.userId));
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Friend request cancelled')),
            );
          case Err(:final error):
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(SnackBar(content: Text('Failed: ${error.message}')));
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  void _showUnfriendDialog(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Remove Friend'),
        content: const Text('Are you sure you want to remove this friend?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(dialogContext);
              _removeFriend(context);
            },
            style: FilledButton.styleFrom(backgroundColor: colorScheme.error),
            child: const Text('Remove'),
          ),
        ],
      ),
    );
  }

  void _removeFriend(BuildContext context) async {
    try {
      final client = Supabase.instance.client;
      final errorMapper = SupabaseErrorMapper();
      final supabaseService = SupabaseService(client, errorMapper);
      final friendsRepo = FriendsRepositoryImpl(supabaseService);

      final result = await friendsRepo.removeFriend(widget.userId);

      if (mounted) {
        switch (result) {
          case Ok():
            ref.invalidate(friendshipStatusProvider(widget.userId));
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(const SnackBar(content: Text('Friend removed')));
          case Err(:final error):
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(SnackBar(content: Text('Failed: ${error.message}')));
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  Future<void> _blockUser(BuildContext context) async {
    try {
      final client = Supabase.instance.client;
      final errorMapper = SupabaseErrorMapper();
      final supabaseService = SupabaseService(client, errorMapper);
      final friendsRepo = FriendsRepositoryImpl(supabaseService);

      final result = await friendsRepo.blockUser(widget.userId);

      if (mounted) {
        switch (result) {
          case Ok():
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(const SnackBar(content: Text('User blocked')));
          case Err(:final error):
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(SnackBar(content: Text('Failed: ${error.message}')));
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  void _reportUser(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Report User'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Why are you reporting this user?'),
            const SizedBox(height: 16),
            ...[
              'Harassment',
              'Spam',
              'Inappropriate content',
              'Hate speech',
              'Other',
            ].map(
              (reason) => ListTile(
                title: Text(reason),
                onTap: () {
                  Navigator.pop(context);
                  _submitUserReport(context, reason);
                },
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }

  Future<void> _submitUserReport(BuildContext context, String reason) async {
    try {
      final client = Supabase.instance.client;

      await client.from('reports').insert({
        'reporter_id': client.auth.currentUser?.id,
        'reported_user_id': widget.userId,
        'reason': reason,
        'target_type': 'user',
        'created_at': DateTime.now().toIso8601String(),
      });

      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Report submitted')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to submit report: $e')));
      }
    }
  }

  void _showMoreOptions(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    showModalBottomSheet(
      context: context,
      backgroundColor: colorScheme.surface,
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Iconsax.close_circle_copy),
              title: const Text('Block user'),
              onTap: () async {
                Navigator.pop(context);
                await _blockUser(context);
              },
            ),
            ListTile(
              leading: const Icon(Iconsax.warning_2_copy),
              title: const Text('Report user'),
              onTap: () {
                Navigator.pop(context);
                _reportUser(context);
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _HeroStat {
  final String label;
  final String value;
  final IconData icon;

  const _HeroStat({
    required this.label,
    required this.value,
    required this.icon,
  });
}
