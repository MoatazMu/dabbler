import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:share_plus/share_plus.dart';

import 'package:dabbler/core/design_system/layouts/two_section_layout.dart';
import 'package:dabbler/core/widgets/custom_avatar.dart';
import 'package:dabbler/features/social/presentation/controllers/simple_friends_controller.dart';
import 'package:dabbler/themes/app_theme.dart';
import 'package:dabbler/utils/constants/route_constants.dart';
import '../../providers/social_providers.dart';

/// Friends screen showing friend lists and management with real data
class RealFriendsScreen extends ConsumerStatefulWidget {
  const RealFriendsScreen({super.key});

  @override
  ConsumerState<RealFriendsScreen> createState() => _RealFriendsScreenState();
}

class _RealFriendsScreenState extends ConsumerState<RealFriendsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _mainTabController;
  bool _hasLoadedAddFriends = false;
  final TextEditingController _searchController = TextEditingController();

  String get _searchQuery => _searchController.text.trim();
  bool get _isSearchMode => _searchQuery.length >= 2;

  void _openProfile(String userId) {
    if (userId.isEmpty) return;
    context.push('${RoutePaths.userProfile}/$userId');
  }

  Future<void> _inviteFromContacts() async {
    await Share.share(
      "Join me on Dabbler — let's connect and play together!",
      subject: 'Invite to Dabbler',
    );
  }

  Widget _buildSearchBar() {
    final colorScheme = Theme.of(context).colorScheme;
    final notifier = ref.read(simpleFriendsControllerProvider.notifier);

    return SizedBox(
      height: 48,
      child: TextField(
        controller: _searchController,
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
          fontSize: 15,
          color: colorScheme.onSurface,
        ),
        decoration: InputDecoration(
          filled: true,
          fillColor: colorScheme.primary.withValues(alpha: 0.12),
          hintText: 'Display name or username',
          hintStyle: TextStyle(
            fontSize: 15,
            color: colorScheme.onSurfaceVariant,
          ),
          prefixIcon: const Icon(Iconsax.search_normal_copy),
          suffixIcon: _searchController.text.isEmpty
              ? null
              : IconButton(
                  icon: const Icon(Iconsax.close_circle_copy),
                  onPressed: () {
                    _searchController.clear();
                    notifier.searchUsers('');
                    setState(() {});
                  },
                ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: colorScheme.primary, width: 2),
          ),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 12,
          ),
        ),
        onChanged: (value) {
          final trimmed = value.trim();
          if (trimmed.length >= 2) {
            notifier.searchUsers(trimmed);
          } else {
            notifier.searchUsers('');
          }
          setState(() {});
        },
      ),
    );
  }

  Widget _buildSectionHeader(String title, {Widget? trailing}) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Padding(
      padding: const EdgeInsets.fromLTRB(0, 12, 0, 8),
      child: Row(
        children: [
          Expanded(
            child: Text(
              title,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
                color: colorScheme.onSurface,
              ),
            ),
          ),
          if (trailing != null) trailing,
        ],
      ),
    );
  }

  Widget _buildGlobalSearchResults(SimpleFriendsState state) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    if (state.isSearching && state.searchResults.isEmpty) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader('Search Results'),
          _buildListSkeleton(itemCount: 6, showActions: true),
        ],
      );
    }

    if (state.error != null && state.searchResults.isEmpty) {
      return _buildError(state.error!);
    }

    if (state.searchResults.isEmpty) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader('Search Results'),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 24),
            child: Text(
              'No users found',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ),
        ],
      );
    }

    final friendIds = state.friends.map(_peerIdFromRow).toSet();
    final incomingIds = state.incomingRequests.map(_peerIdFromRow).toSet();
    final outgoingIds = state.outgoingRequests.map(_peerIdFromRow).toSet();

    final results = state.searchResults.where((row) {
      final id = _peerIdFromRow(row).trim();
      return id.isNotEmpty;
    }).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader('Search Results'),
        for (final user in results)
          Builder(
            builder: (context) {
              final userId = _peerIdFromRow(user);
              final displayName = _displayNameFromRow(user);
              final username = _usernameFromRow(user);
              final avatarUrl = _avatarUrlFromRow(user);
              final isFriend = friendIds.contains(userId);
              final hasIncomingRequest = incomingIds.contains(userId);
              final hasOutgoingRequest = outgoingIds.contains(userId);
              final isProcessing = state.processingIds[userId] == true;

              Widget trailing;
              if (isFriend) {
                trailing = Chip(
                  label: Text(
                    'Friends',
                    style: TextStyle(color: colorScheme.onSecondaryContainer),
                  ),
                  backgroundColor: colorScheme.secondaryContainer,
                );
              } else if (hasIncomingRequest) {
                trailing = Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    FilledButton(
                      onPressed: isProcessing
                          ? null
                          : () {
                              ref
                                  .read(
                                    simpleFriendsControllerProvider.notifier,
                                  )
                                  .acceptRequest(userId);
                            },
                      child: isProcessing
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Text('Accept'),
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      onPressed: isProcessing
                          ? null
                          : () => _confirmRejectRequest(userId),
                      icon: const Icon(Iconsax.close_circle_copy),
                    ),
                  ],
                );
              } else if (hasOutgoingRequest) {
                trailing = Chip(
                  label: Text(
                    'Pending',
                    style: TextStyle(color: colorScheme.onTertiaryContainer),
                  ),
                  backgroundColor: colorScheme.tertiaryContainer,
                );
              } else {
                trailing = IconButton.filledTonal(
                  onPressed: isProcessing
                      ? null
                      : () {
                          ref
                              .read(simpleFriendsControllerProvider.notifier)
                              .sendRequest(userId);
                        },
                  icon: isProcessing
                      ? const SizedBox(
                          height: 16,
                          width: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Iconsax.user_add_copy, size: 18),
                );
              }

              return Card.filled(
                color: colorScheme.primary.withValues(alpha: 0.08),
                margin: const EdgeInsets.only(bottom: 8),
                child: ListTile(
                  onTap: () => _openProfile(userId),
                  leading: AppAvatar.small(
                    imageUrl: avatarUrl,
                    fallbackText: displayName,
                  ),
                  title: Text(displayName),
                  subtitle: Text('@$username'),
                  trailing: trailing,
                ),
              );
            },
          ),
      ],
    );
  }

  Widget _buildListSkeleton({
    required int itemCount,
    bool showActions = false,
  }) {
    final colorScheme = Theme.of(context).colorScheme;

    return Column(
      children: List.generate(itemCount, (index) {
        return Card.filled(
          color: colorScheme.primary.withValues(alpha: 0.08),
          margin: const EdgeInsets.only(bottom: 8),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: colorScheme.surfaceContainer,
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
                        width: 160,
                        decoration: BoxDecoration(
                          color: colorScheme.surfaceContainer,
                          borderRadius: BorderRadius.circular(6),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        height: 12,
                        width: 120,
                        decoration: BoxDecoration(
                          color: colorScheme.surfaceContainer,
                          borderRadius: BorderRadius.circular(6),
                        ),
                      ),
                      if (showActions) ...[
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: Container(
                                height: 36,
                                decoration: BoxDecoration(
                                  color: colorScheme.surfaceContainer,
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Container(
                                height: 36,
                                decoration: BoxDecoration(
                                  color: colorScheme.surfaceContainer,
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      }),
    );
  }

  String _peerIdFromRow(Map<String, dynamic> row) {
    final dynamic value =
        row['user_id'] ??
        row['peer_user_id'] ??
        row['friend_user_id'] ??
        row['id'];
    return (value is String) ? value : (value?.toString() ?? '');
  }

  String _displayNameFromRow(Map<String, dynamic> row) {
    final dynamic peerProfile = row['peer_profile'];
    if (peerProfile is Map) {
      final profile = Map<String, dynamic>.from(peerProfile);
      final dynamic nested = profile['display_name'] ?? profile['full_name'];
      if (nested is String && nested.trim().isNotEmpty) return nested;
    }

    final dynamic value = row['display_name'] ?? row['full_name'];
    return (value is String && value.trim().isNotEmpty)
        ? value
        : 'Unknown User';
  }

  String _usernameFromRow(Map<String, dynamic> row) {
    final dynamic peerProfile = row['peer_profile'];
    if (peerProfile is Map) {
      final profile = Map<String, dynamic>.from(peerProfile);
      final dynamic nested = profile['username'];
      final username = (nested is String) ? nested : (nested?.toString() ?? '');
      if (username.trim().isNotEmpty) return username;
    }

    final dynamic value = row['username'];
    final username = (value is String) ? value : (value?.toString() ?? '');
    return username.trim().isNotEmpty ? username : 'user';
  }

  String? _avatarUrlFromRow(Map<String, dynamic> row) {
    final dynamic peerProfile = row['peer_profile'];
    if (peerProfile is Map) {
      final profile = Map<String, dynamic>.from(peerProfile);
      final dynamic nested = profile['avatar_url'];
      final url = (nested is String) ? nested : (nested?.toString() ?? '');
      if (url.trim().isNotEmpty) return url;
    }

    final dynamic value = row['avatar_url'];
    final url = (value is String) ? value : (value?.toString() ?? '');
    return url.trim().isEmpty ? null : url;
  }

  @override
  void initState() {
    super.initState();
    _mainTabController = TabController(length: 2, vsync: this);
    _mainTabController.addListener(() {
      // Keep the segmented control + content in sync.
      setState(() {});
    });

    // Prevent stale error UI flashes (e.g. from a previous suggestions failure).
    ref.read(simpleFriendsControllerProvider.notifier).clearError();

    // Load friends data on init
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(simpleFriendsControllerProvider.notifier).loadFriends();
    });
  }

  @override
  void dispose() {
    _mainTabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(simpleFriendsControllerProvider);

    final brightness = Theme.of(context).brightness;

    return FutureBuilder<ColorScheme>(
      future: AppTheme.getColorScheme('social', brightness),
      builder: (context, snapshot) {
        final socialScheme =
            snapshot.data ?? context.getCategoryTheme('social');
        final baseTheme = Theme.of(context);
        final themed = baseTheme.copyWith(
          colorScheme: socialScheme,
          cardTheme: baseTheme.cardTheme.copyWith(
            color: socialScheme.surfaceContainerLow,
          ),
        );

        return Theme(
          data: themed,
          child: Builder(
            builder: (context) {
              final colorScheme = Theme.of(context).colorScheme;

              return TwoSectionLayout(
                category: 'social',
                topSection: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          IconButton.filledTonal(
                            onPressed: () {
                              context.canPop()
                                  ? context.pop()
                                  : context.go(RoutePaths.home);
                            },
                            iconSize: 24,
                            constraints: const BoxConstraints.tightFor(
                              width: 48,
                              height: 48,
                            ),
                            style: IconButton.styleFrom(
                              backgroundColor: Colors.transparent,
                              foregroundColor: colorScheme.onSecondaryContainer,
                            ),
                            icon: const Icon(Iconsax.arrow_left_copy),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'Community',
                              style: Theme.of(context).textTheme.titleMedium
                                  ?.copyWith(fontWeight: FontWeight.w700),
                            ),
                          ),
                          if (state.isLoading)
                            const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                        ],
                      ),
                      _buildTabSwitcher(),
                      const SizedBox(height: 12),
                      _buildSearchBar(),
                    ],
                  ),
                ),
                bottomPadding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
                onRefresh: () async {
                  if (_mainTabController.index == 0) {
                    await ref
                        .read(simpleFriendsControllerProvider.notifier)
                        .loadFriends();
                  } else {
                    await ref
                        .read(simpleFriendsControllerProvider.notifier)
                        .loadSuggestions();
                    await ref
                        .read(simpleFriendsControllerProvider.notifier)
                        .loadFriends();
                  }
                },
                bottomSection: _buildBottomSection(state),
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildTabSwitcher() {
    final textTheme = Theme.of(context).textTheme;
    final socialScheme = context.getCategoryTheme('social');

    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: SizedBox(
        width: double.infinity,
        child: SegmentedButton<int>(
          segments: const [
            ButtonSegment(
              value: 0,
              label: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Iconsax.people_copy, size: 18),
                  SizedBox(width: 8, height: 30),
                  Text('Friends'),
                ],
              ),
            ),
            ButtonSegment(
              value: 1,
              label: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Iconsax.user_add_copy, size: 18),
                  SizedBox(width: 8),
                  Text('People'),
                ],
              ),
            ),
          ],
          selected: <int>{_mainTabController.index},
          onSelectionChanged: (Set<int> newSelection) {
            final newIndex = newSelection.first;
            if (_mainTabController.index != newIndex) {
              setState(() {
                _mainTabController.index = newIndex;
              });

              // Lazily load Add Friends data the first time the tab is opened.
              if (newIndex == 1 && !_hasLoadedAddFriends) {
                _hasLoadedAddFriends = true;
                ref
                    .read(simpleFriendsControllerProvider.notifier)
                    .loadSuggestions();
                ref
                    .read(simpleFriendsControllerProvider.notifier)
                    .loadFriends();
              }
            }
          },
          style: ButtonStyle(
            side: WidgetStateProperty.all(
              const BorderSide(color: Colors.transparent),
            ),
            backgroundColor: WidgetStateProperty.resolveWith<Color?>((states) {
              if (states.contains(WidgetState.selected)) {
                return socialScheme.primary.withValues(alpha: 1);
              }
              return socialScheme.primary.withValues(alpha: 0.08);
            }),
            foregroundColor: WidgetStateProperty.resolveWith<Color?>((states) {
              if (states.contains(WidgetState.selected)) {
                return socialScheme.onPrimary;
              }
              return socialScheme.onSurfaceVariant;
            }),
            textStyle: WidgetStateProperty.all(
              textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
            ),
            padding: WidgetStateProperty.all(
              const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            ),
            shape: WidgetStateProperty.all(
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
          showSelectedIcon: false,
        ),
      ),
    );
  }

  Widget _buildBottomSection(SimpleFriendsState state) {
    final tabIndex = _mainTabController.index;

    if (_isSearchMode) {
      return _buildGlobalSearchResults(state);
    }

    if (tabIndex == 1) {
      if (state.error != null) return _buildError(state.error!);
      return _buildAddFriendsTab();
    }

    if (state.error != null && state.friends.isEmpty) {
      return _buildError(state.error!);
    }

    return _buildFriendsList(state.friends, isLoading: state.isLoading);
  }

  Widget _buildAddFriendsTab() {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final state = ref.watch(simpleFriendsControllerProvider);

    final friendIds = state.friends.map(_peerIdFromRow).toSet();
    final incomingIds = state.incomingRequests.map(_peerIdFromRow).toSet();
    final outgoingIds = state.outgoingRequests.map(_peerIdFromRow).toSet();

    final allSuggestionRows = state.suggestions.where((row) {
      final id = _peerIdFromRow(row).trim();
      if (id.isEmpty) return false;
      if (friendIds.contains(id)) return false;
      if (incomingIds.contains(id)) return false;
      if (outgoingIds.contains(id)) return false;
      if (state.dismissedSuggestionIds.contains(id)) return false;
      return true;
    }).toList();

    final addedMeRows = state.incomingRequests;

    final findFriendsPreviewCount = allSuggestionRows.length > 5
        ? 5
        : allSuggestionRows.length;
    final findFriendsPreview = allSuggestionRows.take(findFriendsPreviewCount);

    Widget buildInviteRow() {
      return SizedBox(
        width: double.infinity,
        child: OutlinedButton(
          onPressed: _inviteFromContacts,
          style: OutlinedButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 18),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: colorScheme.primary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Icon(
                  Iconsax.user_add_copy,
                  color: colorScheme.primary,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text('Invite your friends!'),
                    if (theme.textTheme.bodySmall != null)
                      Text(
                        'Invite from contacts',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                      )
                    else
                      const Text('Invite from contacts'),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Icon(
                Iconsax.arrow_right_3_copy,
                color: colorScheme.onSurfaceVariant,
                size: 18,
              ),
            ],
          ),
        ),
      );
    }

    Widget buildSkeletonList({required int itemCount}) {
      return Column(
        children: List.generate(itemCount, (index) {
          return Card.filled(
            color: colorScheme.primary.withValues(alpha: 0.08),
            margin: const EdgeInsets.only(bottom: 8),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: colorScheme.surfaceContainer,
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
                          width: 160,
                          decoration: BoxDecoration(
                            color: colorScheme.surfaceContainer,
                            borderRadius: BorderRadius.circular(6),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Container(
                          height: 12,
                          width: 120,
                          decoration: BoxDecoration(
                            color: colorScheme.surfaceContainer,
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
        }),
      );
    }

    Widget buildAddedMeSection() {
      if (addedMeRows.isEmpty) return const SizedBox.shrink();

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader('Added Me'),
          for (final row in addedMeRows)
            Builder(
              builder: (context) {
                final userId = _peerIdFromRow(row);
                final displayName = _displayNameFromRow(row);
                final username = _usernameFromRow(row);
                final avatarUrl = _avatarUrlFromRow(row);
                final isProcessing = state.processingIds[userId] == true;

                return Card.filled(
                  color: colorScheme.primary.withValues(alpha: 0.08),
                  margin: const EdgeInsets.only(bottom: 8),
                  child: ListTile(
                    onTap: () => _openProfile(userId),
                    leading: AppAvatar.small(
                      imageUrl: avatarUrl,
                      fallbackText: displayName,
                    ),
                    title: Text(displayName),
                    subtitle: Text('@$username'),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          onPressed: isProcessing
                              ? null
                              : () => _confirmRejectRequest(userId),
                          icon: const Icon(Iconsax.close_circle_copy),
                        ),
                        const SizedBox(width: 8),

                        FilledButton(
                          onPressed: isProcessing
                              ? null
                              : () {
                                  ref
                                      .read(
                                        simpleFriendsControllerProvider
                                            .notifier,
                                      )
                                      .acceptRequest(userId);
                                },
                          child: isProcessing
                              ? const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Text('Accept'),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
        ],
      );
    }

    Widget buildFindFriendsSection() {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader(
            'Find Friends',
            trailing: TextButton(
              onPressed: _inviteFromContacts,
              child: const Text('All Contacts'),
            ),
          ),
          if (state.isLoadingSuggestions && state.suggestions.isEmpty)
            buildSkeletonList(itemCount: 6)
          else if (allSuggestionRows.isEmpty)
            Card.filled(
              margin: EdgeInsets.zero,
              color: colorScheme.surfaceContainer,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  'No suggestions available right now.',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
            )
          else
            for (final suggestion in findFriendsPreview)
              Builder(
                builder: (context) {
                  final userId = _peerIdFromRow(suggestion);
                  final displayName = _displayNameFromRow(suggestion);
                  final username = _usernameFromRow(suggestion);
                  final avatarUrl = _avatarUrlFromRow(suggestion);
                  final mutualCount =
                      suggestion['mutual_friends_count'] as int? ?? 0;
                  final isProcessing = state.processingIds[userId] == true;

                  return Card.filled(
                    color: colorScheme.primary.withValues(alpha: 0.08),
                    margin: const EdgeInsets.only(bottom: 8),
                    child: ListTile(
                      onTap: () => _openProfile(userId),
                      leading: AppAvatar.small(
                        imageUrl: avatarUrl,
                        fallbackText: displayName,
                      ),
                      title: Text(displayName),
                      subtitle: Text(
                        mutualCount > 0
                            ? '@$username • $mutualCount mutual'
                            : '@$username',
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            onPressed: () => _confirmDismissSuggestion(userId),
                            icon: const Icon(Iconsax.close_circle_copy),
                          ),
                          const SizedBox(width: 6),
                          IconButton.filledTonal(
                            onPressed: isProcessing
                                ? null
                                : () {
                                    ref
                                        .read(
                                          simpleFriendsControllerProvider
                                              .notifier,
                                        )
                                        .sendRequest(userId);
                                  },
                            icon: isProcessing
                                ? const SizedBox(
                                    height: 16,
                                    width: 16,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  )
                                : const Icon(Iconsax.user_add_copy, size: 24),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        buildInviteRow(),
        buildAddedMeSection(),
        buildFindFriendsSection(),
        const SizedBox(height: 24),
      ],
    );
  }

  Widget _buildError(String error) {
    final colorScheme = Theme.of(context).colorScheme;

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Iconsax.danger_copy,
            size: 64,
            color: colorScheme.error.withValues(alpha: 0.8),
          ),
          const SizedBox(height: 16),
          Text(error, textAlign: TextAlign.center),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () {
              ref.read(simpleFriendsControllerProvider.notifier).loadFriends();
            },
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  Widget _buildFriendsList(
    List<Map<String, dynamic>> friends, {
    required bool isLoading,
  }) {
    if (isLoading && friends.isEmpty) {
      return _buildListSkeleton(itemCount: 8);
    }

    if (friends.isEmpty) {
      final theme = Theme.of(context);
      final colorScheme = theme.colorScheme;

      return Padding(
        padding: const EdgeInsets.only(top: 36),
        child: Center(
          child: Column(
            children: [
              Icon(
                Iconsax.people_copy,
                size: 64,
                color: colorScheme.onSurfaceVariant.withValues(alpha: 0.6),
              ),
              const SizedBox(height: 16),
              Text('No friends yet', style: theme.textTheme.titleLarge),
              const SizedBox(height: 8),
              Text(
                'Start connecting with other players!',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    return Column(
      children: [
        for (final friend in friends)
          Builder(
            builder: (context) {
              final colorScheme = Theme.of(context).colorScheme;
              final friendId = _peerIdFromRow(friend);
              final avatarUrl = _avatarUrlFromRow(friend);
              final displayName = _displayNameFromRow(friend);
              final username = _usernameFromRow(friend);

              return Card.filled(
                color: colorScheme.primary.withValues(alpha: 0.08),
                margin: const EdgeInsets.only(bottom: 8),
                child: ListTile(
                  leading: AppAvatar.small(
                    imageUrl: avatarUrl,
                    fallbackText: displayName,
                  ),
                  title: Text(displayName),
                  subtitle: Text('@$username'),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        tooltip: 'Unfriend',
                        icon: Icon(
                          Iconsax.user_remove_copy,
                          color: Theme.of(context).colorScheme.error,
                        ),
                        onPressed: () => _showUnfriendDialog(friendId),
                      ),
                      const SizedBox(width: 6),
                      IconButton(
                        tooltip: 'Block',
                        icon: Icon(
                          Iconsax.danger_copy,
                          color: Theme.of(context).colorScheme.error,
                        ),
                        onPressed: () => _showBlockDialog(friendId),
                      ),
                    ],
                  ),
                  onTap: () => _openProfile(friendId),
                ),
              );
            },
          ),
      ],
    );
  }

  void _showUnfriendDialog(String friendId) {
    final colorScheme = Theme.of(context).colorScheme;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Unfriend User?'),
        content: const Text(
          'Are you sure you want to remove this person from your friends?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              ref
                  .read(simpleFriendsControllerProvider.notifier)
                  .removeFriend(friendId);
            },
            style: TextButton.styleFrom(foregroundColor: colorScheme.error),
            child: const Text('Unfriend'),
          ),
        ],
      ),
    );
  }

  void _showBlockDialog(String userId) {
    final colorScheme = Theme.of(context).colorScheme;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Block User?'),
        content: const Text(
          'This user will no longer be able to see your profile or send you messages.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              ref
                  .read(simpleFriendsControllerProvider.notifier)
                  .blockUser(userId);
            },
            style: TextButton.styleFrom(foregroundColor: colorScheme.error),
            child: const Text('Block'),
          ),
        ],
      ),
    );
  }

  void _confirmRejectRequest(String userId) {
    final colorScheme = Theme.of(context).colorScheme;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reject Friend Request?'),
        content: const Text(
          'This will decline the friend request. You can still add them later.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              ref
                  .read(simpleFriendsControllerProvider.notifier)
                  .rejectRequest(userId);
            },
            style: TextButton.styleFrom(foregroundColor: colorScheme.error),
            child: const Text('Reject'),
          ),
        ],
      ),
    );
  }

  void _confirmDismissSuggestion(String userId) {
    final colorScheme = Theme.of(context).colorScheme;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Hide This Suggestion?'),
        content: const Text('We will hide this suggestion from your list.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              ref
                  .read(simpleFriendsControllerProvider.notifier)
                  .dismissSuggestion(userId);
            },
            style: TextButton.styleFrom(foregroundColor: colorScheme.error),
            child: const Text('Hide'),
          ),
        ],
      ),
    );
  }
}
