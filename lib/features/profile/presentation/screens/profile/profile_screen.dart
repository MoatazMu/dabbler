// import 'package:dabbler/features/authentication/presentation/providers/auth_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../controllers/profile_controller.dart';
import '../../../../../features/games/providers/games_providers.dart';
import '../../controllers/sports_profile_controller.dart';
import '../../providers/profile_providers.dart';
import 'package:dabbler/data/models/profile/user_profile.dart';
import 'package:dabbler/data/models/profile/sports_profile.dart';
import 'package:dabbler/features/profile/presentation/widgets/profile_rewards_widget.dart';
import '../../../../../utils/constants/route_constants.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late AnimationController _refreshController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  double _myAverageRating = 0.0;

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

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    _slideAnimation =
        Tween<Offset>(begin: const Offset(0, 0.1), end: Offset.zero).animate(
          CurvedAnimation(
            parent: _animationController,
            curve: Curves.easeOutCubic,
          ),
        );

    _animationController.forward();

    // Load initial data
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadProfileData();
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    _refreshController.dispose();
    super.dispose();
  }

  Future<void> _loadProfileData() async {
    final profileController = ref.read(profileControllerProvider.notifier);
    final sportsController = ref.read(sportsProfileControllerProvider.notifier);
    final user = ref.read(currentUserProvider);

    if (user != null) {
      await Future.wait<void>([
        profileController.loadProfile(user.id),
        sportsController.loadSportsProfiles(user.id),
      ]);
      await _loadAverageRating();
    }
  }

  Future<void> _loadAverageRating() async {
    final repository = ref.read(gamesRepositoryProvider);
    final avgRes = await repository.myAverageRating();
    if (mounted) {
      setState(() {
        _myAverageRating = avgRes.isSuccess ? avgRes.requireValue : 0.0;
      });
    }
  }

  Future<void> _onRefresh() async {
    _refreshController.reset();
    _refreshController.forward();
    await _loadProfileData();
  }

  @override
  Widget build(BuildContext context) {
    final profileState = ref.watch(profileControllerProvider);
    final sportsState = ref.watch(sportsProfileControllerProvider);

    return Scaffold(
      body: RefreshIndicator(
        onRefresh: _onRefresh,
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            _buildAppBar(context),
            SliverToBoxAdapter(
              child: FadeTransition(
                opacity: _fadeAnimation,
                child: SlideTransition(
                  position: _slideAnimation,
                  child: Column(
                    children: [
                      _buildProfileHeader(context, profileState),
                      _buildProfileCompletion(context, profileState),
                      _buildBasicInfo(context, profileState),
                      _buildRewardsSection(context),
                      _buildSportsProfiles(context, sportsState),
                      _buildStatisticsSummary(context, profileState),
                      const SizedBox(height: 100), // Bottom spacing
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAppBar(BuildContext context) {
    return SliverAppBar(
      expandedHeight: 120,
      floating: false,
      pinned: true,
      elevation: 0,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      leading: IconButton(
        onPressed: () => context.go('/home'),
        icon: const Icon(Icons.arrow_back),
        tooltip: 'Back to Home',
      ),
      flexibleSpace: FlexibleSpaceBar(
        title: Text(
          'My Profile',
          style: Theme.of(
            context,
          ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
        ),
        centerTitle: false,
        titlePadding: const EdgeInsets.only(left: 20, bottom: 16),
      ),
      actions: [
        IconButton(
          onPressed: () => context.push('/settings'),
          icon: const Icon(Icons.settings_outlined),
          tooltip: 'Settings',
        ),
        const SizedBox(width: 8),
      ],
    );
  }

  Widget _buildProfileHeader(BuildContext context, ProfileState profileState) {
    final profile = profileState.profile;

    return Container(
      margin: const EdgeInsets.all(20),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        children: [
          Stack(
            children: [
              Hero(
                tag: 'profile-avatar',
                child: CircleAvatar(
                  radius: 50,
                  backgroundColor: Theme.of(
                    context,
                  ).primaryColor.withValues(alpha: 0.1),
                  backgroundImage: profile?.avatarUrl != null
                      ? (profile!.avatarUrl!.startsWith('assets/')
                            ? AssetImage(profile.avatarUrl!) as ImageProvider
                            : NetworkImage(profile.avatarUrl!))
                      : null,
                  child: profile?.avatarUrl == null
                      ? Icon(
                          Icons.person,
                          size: 50,
                          color: Theme.of(context).primaryColor,
                        )
                      : null,
                ),
              ),
              Positioned(
                bottom: 0,
                right: 0,
                child: GestureDetector(
                  onTap: () => context.push('/profile/photo'),
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Theme.of(context).primaryColor,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: Theme.of(context).scaffoldBackgroundColor,
                        width: 3,
                      ),
                    ),
                    child: const Icon(
                      Icons.camera_alt,
                      color: Colors.white,
                      size: 16,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            profile?.getDisplayName() ?? 'Add Your Name',
            style: Theme.of(
              context,
            ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
          if (profile?.bio != null) ...[
            const SizedBox(height: 8),
            Text(
              profile!.bio!,
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: Colors.grey[600]),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildStatItem(context, 'Games', '12'),
              _buildStatItem(context, 'Wins', '8'),
              _buildStatItem(
                context,
                'My Rating',
                _myAverageRating > 0
                    ? _myAverageRating.toStringAsFixed(1)
                    : '—',
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(BuildContext context, String label, String value) {
    return Column(
      children: [
        Text(
          value,
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.bold,
            color: Theme.of(context).primaryColor,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: Theme.of(
            context,
          ).textTheme.bodySmall?.copyWith(color: Colors.grey[600]),
        ),
      ],
    );
  }

  Widget _buildProfileCompletion(
    BuildContext context,
    ProfileState profileState,
  ) {
    final completion = _calculateCompletion(profileState.profile);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Theme.of(context).primaryColor.withValues(alpha: 0.1),
            Theme.of(context).primaryColor.withValues(alpha: 0.05),
          ],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Theme.of(context).primaryColor.withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.trending_up,
                color: Theme.of(context).primaryColor,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                'Profile Completion',
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
              ),
              const Spacer(),
              Text(
                '${completion.toInt()}%',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).primaryColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          LinearProgressIndicator(
            value: completion / 100,
            backgroundColor: Colors.grey[300],
            valueColor: AlwaysStoppedAnimation<Color>(
              Theme.of(context).primaryColor,
            ),
            minHeight: 6,
          ),
          if (completion < 80) ...[
            const SizedBox(height: 12),
            GestureDetector(
              onTap: () => context.push('/profile/edit'),
              child: Text(
                'Complete your profile to get better matches',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).primaryColor,
                  decoration: TextDecoration.underline,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildBasicInfo(BuildContext context, ProfileState profileState) {
    final profile = profileState.profile;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'Basic Information',
                style: Theme.of(
                  context,
                ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
              ),
              const Spacer(),
              IconButton(
                onPressed: () => context.push('/profile/edit'),
                icon: const Icon(Icons.edit_outlined),
                iconSize: 20,
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (profile != null && profile.email.isNotEmpty)
            _buildInfoRow(context, Icons.email_outlined, profile.email),
          if (profile?.phoneNumber != null)
            _buildInfoRow(context, Icons.phone_outlined, profile!.phoneNumber!),
          if (profile?.location != null)
            _buildInfoRow(
              context,
              Icons.location_on_outlined,
              profile!.location!,
            ),
          if (profile?.dateOfBirth != null)
            _buildInfoRow(
              context,
              Icons.cake_outlined,
              '${_calculateAge(profile!.dateOfBirth!)} years old',
            ),
          if (profile == null ||
              (profile.email.isEmpty &&
                  profile.phoneNumber == null &&
                  profile.location == null &&
                  profile.dateOfBirth == null))
            _buildEmptyState(context, 'Add your basic information'),
        ],
      ),
    );
  }

  Widget _buildInfoRow(BuildContext context, IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Colors.grey[600]),
          const SizedBox(width: 12),
          Expanded(
            child: Text(text, style: Theme.of(context).textTheme.bodyMedium),
          ),
        ],
      ),
    );
  }

  Widget _buildSportsProfiles(
    BuildContext context,
    SportsProfileState sportsState,
  ) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'Sports Profiles',
                style: Theme.of(
                  context,
                ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
              ),
              const Spacer(),
              TextButton(
                onPressed: () => context.push('/profile/sports-preferences'),
                child: const Text('Manage'),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (sportsState.profiles.isNotEmpty)
            SizedBox(
              height: 200,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                itemCount: sportsState.profiles.length,
                itemBuilder: (context, index) {
                  final sport = sportsState.profiles[index];
                  return _buildSportCard(context, sport);
                },
              ),
            )
          else
            _buildEmptyState(context, 'Add your favorite sports'),
        ],
      ),
    );
  }

  Widget _buildSportCard(BuildContext context, SportProfile sport) {
    return Container(
      width: 160,
      margin: const EdgeInsets.only(right: 16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: Theme.of(
                      context,
                    ).primaryColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    _getSportIcon(sport.sportName),
                    color: Theme.of(context).primaryColor,
                    size: 24,
                  ),
                ),
                if (sport.isPrimarySport) ...[
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.orange,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.star,
                      color: Colors.white,
                      size: 12,
                    ),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 12),
            Text(
              sport.sportName,
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),
            Text(
              _getSkillLevelText(sport.skillLevel),
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: _getSkillLevelColor(sport.skillLevel),
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '${sport.yearsPlaying} years',
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: Colors.grey[600]),
            ),
            if (sport.achievements.isNotEmpty) ...[
              const SizedBox(height: 8),
              Wrap(
                spacing: 4,
                children: sport.achievements.take(2).map((achievement) {
                  return Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: Theme.of(
                        context,
                      ).primaryColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      achievement,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).primaryColor,
                        fontSize: 10,
                      ),
                    ),
                  );
                }).toList(),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildStatisticsSummary(
    BuildContext context,
    ProfileState profileState,
  ) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Activity Summary',
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildStatColumn(
                  context,
                  'Games Played',
                  '12',
                  Icons.sports_soccer,
                ),
              ),
              Expanded(
                child: _buildStatColumn(
                  context,
                  'Win Rate',
                  '67%',
                  Icons.emoji_events,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildStatColumn(
                  context,
                  'Average Rating',
                  '4.8',
                  Icons.star,
                ),
              ),
              Expanded(
                child: _buildStatColumn(
                  context,
                  'Friends Made',
                  '24',
                  Icons.people,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatColumn(
    BuildContext context,
    String label,
    String value,
    IconData icon,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Theme.of(context).primaryColor.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: Theme.of(context).primaryColor, size: 24),
        ),
        const SizedBox(height: 8),
        Text(
          value,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
            color: Theme.of(context).primaryColor,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: Theme.of(
            context,
          ).textTheme.bodySmall?.copyWith(color: Colors.grey[600]),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildEmptyState(BuildContext context, String message) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        children: [
          Icon(Icons.info_outline, color: Colors.grey[400], size: 32),
          const SizedBox(height: 8),
          Text(
            message,
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: Colors.grey[600]),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  double _calculateCompletion(UserProfile? profile) {
    if (profile == null) return 0.0;

    double completion = 0.0;
    const double maxScore = 100.0;

    // Basic info (40%)
    if (profile.firstName?.isNotEmpty == true) completion += 10.0;
    if (profile.lastName?.isNotEmpty == true) completion += 10.0;
    if (profile.email.isNotEmpty) completion += 10.0;
    if (profile.bio?.isNotEmpty == true) completion += 10.0;

    // Contact info (20%)
    if (profile.phoneNumber?.isNotEmpty == true) completion += 10.0;
    if (profile.location?.isNotEmpty == true) completion += 10.0;

    // Personal info (20%)
    if (profile.dateOfBirth != null) completion += 10.0;
    if (profile.avatarUrl?.isNotEmpty == true) completion += 10.0;

    // Additional info (20%)
    if (profile.gender?.isNotEmpty == true) completion += 10.0;
    // Note: interests field doesn't exist in entity, using bio instead
    if (profile.bio?.isNotEmpty == true) completion += 10.0;

    return completion.clamp(0.0, maxScore);
  }

  int _calculateAge(DateTime dateOfBirth) {
    final today = DateTime.now();
    int age = today.year - dateOfBirth.year;
    if (today.month < dateOfBirth.month ||
        (today.month == dateOfBirth.month && today.day < dateOfBirth.day)) {
      age--;
    }
    return age;
  }

  IconData _getSportIcon(String sportName) {
    switch (sportName.toLowerCase()) {
      case 'basketball':
        return Icons.sports_basketball;
      case 'football':
      case 'soccer':
        return Icons.sports_soccer;
      case 'tennis':
        return Icons.sports_tennis;
      case 'volleyball':
        return Icons.sports_volleyball;
      case 'baseball':
        return Icons.sports_baseball;
      case 'hockey':
        return Icons.sports_hockey;
      case 'golf':
        return Icons.sports_golf;
      default:
        return Icons.sports;
    }
  }

  String _getSkillLevelText(SkillLevel skillLevel) {
    switch (skillLevel) {
      case SkillLevel.beginner:
        return 'Beginner';
      case SkillLevel.intermediate:
        return 'Intermediate';
      case SkillLevel.advanced:
        return 'Advanced';
      case SkillLevel.expert:
        return 'Expert';
    }
  }

  Color _getSkillLevelColor(SkillLevel skillLevel) {
    switch (skillLevel) {
      case SkillLevel.beginner:
        return Colors.green;
      case SkillLevel.intermediate:
        return Colors.orange;
      case SkillLevel.advanced:
        return Colors.blue;
      case SkillLevel.expert:
        return Colors.purple;
    }
  }

  Widget _buildRewardsSection(BuildContext context) {
    // Get current user ID from profile state
    final profileState = ref.watch(profileControllerProvider);
    final userProfile = profileState.profile;

    if (userProfile == null) {
      return const SizedBox.shrink();
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ProfileRewardsWidget(userId: userProfile.id),
          const SizedBox(height: 12),
          Align(
            alignment: Alignment.centerRight,
            child: OutlinedButton.icon(
              onPressed: () => context.push(RoutePaths.leaderboard),
              icon: const Icon(Icons.leaderboard_outlined, size: 18),
              label: const Text('View Leaderboard'),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 10,
                ),
                textStyle: const TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
