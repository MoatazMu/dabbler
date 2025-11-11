// import 'package:dabbler/features/authentication/presentation/providers/auth_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:dabbler/core/design_system/layouts/two_section_layout.dart';
import '../../controllers/profile_controller.dart';
import '../../controllers/sports_profile_controller.dart';
import '../../providers/profile_providers.dart';
import 'package:dabbler/data/models/profile/user_profile.dart';
import 'package:dabbler/data/models/profile/sports_profile.dart';
import 'package:dabbler/features/profile/presentation/widgets/profile_rewards_widget.dart';
import '../../../../../utils/constants/route_constants.dart';
import 'package:dabbler/themes/app_theme.dart';

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
    // Rating data loading (not displayed in top section)
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

    return TwoSectionLayout(
      category: 'profile',
      topSection: _buildTopSection(context, profileState),
      bottomSection: _buildBottomSection(context, profileState, sportsState),
    );
  }

  Widget _buildTopSection(BuildContext context, ProfileState profileState) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    
    return Padding(
      padding: const EdgeInsets.only(top: 48, left: 24, right: 24, bottom: 18),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Bar
          SizedBox(
            width: double.infinity,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Home icon button - Material 3 IconButton.filled
                IconButton.filled(
                  onPressed: () => context.go('/home'),
                  icon: const Text(
                    '🏠',
                    style: TextStyle(fontSize: 22),
                  ),
                  style: IconButton.styleFrom(
                    backgroundColor: colorScheme.onPrimary.withOpacity(0.2),
                    foregroundColor: colorScheme.onPrimary,
                    minimumSize: const Size(44, 44),
                  ),
                ),
                const Spacer(),
                // Settings button - Material 3 FilledButton
                FilledButton.icon(
                  onPressed: () => context.push('/settings'),
                  icon: const Text(
                    '⚙',
                    style: TextStyle(fontSize: 22),
                  ),
                  label: Text(
                    'Settings',
                    style: textTheme.bodyMedium?.copyWith(
                      color: colorScheme.onSurface,
                    ),
                  ),
                  style: FilledButton.styleFrom(
                    backgroundColor: colorScheme.onPrimary.withOpacity(0.2),
                    foregroundColor: colorScheme.onPrimary,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 10,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(22),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          // Profile Avatar and Stats
          _buildProfileHeaderContent(context, profileState),
        ],
      ),
    );
  }

  Widget _buildBottomSection(
    BuildContext context,
    ProfileState profileState,
    SportsProfileState sportsState,
  ) {
    return RefreshIndicator(
      onRefresh: _onRefresh,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: SlideTransition(
            position: _slideAnimation,
            child: Column(
              children: [
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
    );
  }

  Widget _buildProfileHeaderContent(
    BuildContext context,
    ProfileState profileState,
  ) {
    final profile = profileState.profile;

    return Column(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Avatar and Stats Row
        SizedBox(
          width: double.infinity,
          height: 96,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Avatar
              Container(
                width: 96,
                height: 96,
                clipBehavior: Clip.antiAlias,
                decoration: ShapeDecoration(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(25165800),
                  ),
                ),
                child: profile?.avatarUrl != null
                    ? Image.network(profile!.avatarUrl!, fit: BoxFit.cover)
                    : Builder(
                        builder: (context) {
                          final colorScheme = Theme.of(context).colorScheme;
                          return Container(
                            decoration: ShapeDecoration(
                              color: colorScheme.surfaceContainerHigh,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(25165800),
                              ),
                            ),
                            child: Icon(
                              Icons.person,
                              size: 48,
                              color: colorScheme.onSurfaceVariant,
                            ),
                          );
                        },
                      ),
              ),
              const SizedBox(width: 16),
              // Stats Container
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: ShapeDecoration(
                    color: Theme.of(context).colorScheme.onPrimary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(6),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.start,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Expanded(
                        child: SizedBox(
                          height: 48,
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Text(
                                '156',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: const Color(0xFF191919),
                                  fontSize: 15,
                                  fontFamily: 'Roboto',
                                  fontWeight: FontWeight.w500,
                                  height: 1.20,
                                ),
                              ),
                              Text(
                                'Games',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: const Color(0xFF191919),
                                  fontSize: 12,
                                  fontFamily: 'Roboto',
                                  fontWeight: FontWeight.w400,
                                  height: 1.67,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        width: 1,
                        height: 40,
                        decoration: BoxDecoration(
                          color: const Color(0xFF262626),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: SizedBox(
                          height: 48,
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Text(
                                '89',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: const Color(0xFF191919),
                                  fontSize: 15,
                                  fontFamily: 'Roboto',
                                  fontWeight: FontWeight.w500,
                                  height: 1.20,
                                ),
                              ),
                              Text(
                                'Wins',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: const Color(0xFF191919),
                                  fontSize: 12,
                                  fontFamily: 'Roboto',
                                  fontWeight: FontWeight.w400,
                                  height: 1.67,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        width: 1,
                        height: 40,
                        decoration: BoxDecoration(
                          color: const Color(0xFF262626),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: SizedBox(
                          height: 48,
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Text(
                                '4',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: const Color(0xFF191919),
                                  fontSize: 15,
                                  fontFamily: 'Roboto',
                                  fontWeight: FontWeight.w500,
                                  height: 1.20,
                                ),
                              ),
                              Text(
                                'Teams',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: const Color(0xFF191919),
                                  fontSize: 12,
                                  fontFamily: 'Roboto',
                                  fontWeight: FontWeight.w400,
                                  height: 1.67,
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
            ],
          ),
        ),
        const SizedBox(height: 18),
        // Name
        Text(
          profile?.getDisplayName() ?? 'Add Your Name',
          style: TextStyle(
            color: Color(0xFF191919),
            fontSize: 24,
            fontFamily: 'Roboto',
            height: 0.06,
            letterSpacing: -0.14,
          ),
        ),
        const SizedBox(height: 18),
        // Status
        Container(
          padding: const EdgeInsets.only(right: 49),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(
                'Active Now • Level 15 • Member 2y',
                style: TextStyle(
                  color: Color(0xFF179F4B),
                  fontSize: 16,
                  fontFamily: 'Inter',
                  height: 0.09,
                ),
              ),
            ],
          ),
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
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
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
          Builder(
            builder: (context) {
              final colorScheme = Theme.of(context).colorScheme;
              return LinearProgressIndicator(
                value: completion / 100,
                backgroundColor: colorScheme.surfaceContainerHighest,
                valueColor: AlwaysStoppedAnimation<Color>(
                  colorScheme.primary,
                ),
                minHeight: 6,
              );
            },
          ),
          if (completion < 80) ...[
            const SizedBox(height: 12),
            GestureDetector(
              onTap: () => context.push('/profile/edit'),
              child: Builder(
                builder: (context) {
                  final colorScheme = Theme.of(context).colorScheme;
                  final textTheme = Theme.of(context).textTheme;
                  return Text(
                    'Complete your profile to get better matches',
                    style: textTheme.bodySmall?.copyWith(
                      color: colorScheme.primary,
                      decoration: TextDecoration.underline,
                    ),
                  );
                },
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildBasicInfo(BuildContext context, ProfileState profileState) {
    final profile = profileState.profile;
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Card(
      elevation: 0,
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  'Basic Information',
                  style: textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: colorScheme.onSurface,
                  ),
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
      ),
    );
  }

  Widget _buildInfoRow(BuildContext context, IconData icon, String text) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Icon(icon, size: 20, color: colorScheme.onSurfaceVariant),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
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
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
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
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    
    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(right: 16),
      child: SizedBox(
        width: 160,
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
                      color: colorScheme.primaryContainer,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      _getSportIcon(sport.sportName),
                      color: colorScheme.onPrimaryContainer,
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
                        color: colorScheme.primaryContainer,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        Icons.star,
                        color: colorScheme.onPrimaryContainer,
                        size: 12,
                      ),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 12),
              Text(
                sport.sportName,
                style: textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: colorScheme.onSurface,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),
              Text(
                _getSkillLevelText(sport.skillLevel),
                style: textTheme.bodySmall?.copyWith(
                  color: _getSkillLevelColor(context, sport.skillLevel),
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '${sport.yearsPlaying} years',
                style: textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
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
                        color: colorScheme.primaryContainer,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        achievement,
                        style: textTheme.bodySmall?.copyWith(
                          color: colorScheme.onPrimaryContainer,
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
      ),
    );
  }

  Widget _buildStatisticsSummary(
    BuildContext context,
    ProfileState profileState,
  ) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    
    return Card(
      elevation: 0,
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Activity Summary',
              style: textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: colorScheme.onSurface,
              ),
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
      ),
    );
  }

  Widget _buildStatColumn(
    BuildContext context,
    String label,
    String value,
    IconData icon,
  ) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: colorScheme.primaryContainer,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            icon,
            color: colorScheme.onPrimaryContainer,
            size: 24,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          value,
          style: textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
            color: colorScheme.primary,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: textTheme.bodySmall?.copyWith(
            color: colorScheme.onSurfaceVariant,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildEmptyState(BuildContext context, String message) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    
    return Card(
      elevation: 0,
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Icon(
              Icons.info_outline,
              color: colorScheme.onSurfaceVariant,
              size: 32,
            ),
            const SizedBox(height: 8),
            Text(
              message,
              style: textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
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

  Color _getSkillLevelColor(BuildContext context, SkillLevel skillLevel) {
    final colorScheme = Theme.of(context).colorScheme;
    final appTheme = Theme.of(context).extension<AppThemeExtension>();
    
    switch (skillLevel) {
      case SkillLevel.beginner:
        return appTheme?.success ?? colorScheme.primaryContainer;
      case SkillLevel.intermediate:
        return appTheme?.warning ?? colorScheme.primaryContainer;
      case SkillLevel.advanced:
        return appTheme?.infoLink ?? colorScheme.primaryContainer;
      case SkillLevel.expert:
        return colorScheme.primary;
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
