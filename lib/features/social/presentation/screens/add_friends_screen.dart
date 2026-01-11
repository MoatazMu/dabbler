import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:share_plus/share_plus.dart';

import 'package:dabbler/core/design_system/layouts/single_section_layout.dart';
import 'package:dabbler/core/widgets/custom_avatar.dart';
import 'package:dabbler/themes/app_theme.dart';
import 'package:dabbler/utils/constants/route_constants.dart';
import '../../providers/social_providers.dart';

class AddFriendsScreen extends ConsumerStatefulWidget {
  const AddFriendsScreen({super.key});

  @override
  ConsumerState<AddFriendsScreen> createState() => _AddFriendsScreenState();
}

class _AddFriendsScreenState extends ConsumerState<AddFriendsScreen> {
  final TextEditingController _searchController = TextEditingController();

  void _openProfile(String userId) {
    if (userId.isEmpty) return;
    context.push('${RoutePaths.userProfile}/$userId');
  }

  Widget _buildListSkeleton({required int itemCount}) {
    final colorScheme = Theme.of(context).colorScheme;

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: itemCount,
      itemBuilder: (context, index) {
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
      },
    );
  }

  Widget _buildSectionHeader(
    BuildContext context,
    String title, {
    Widget? trailing,
  }) {
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

  Future<void> _inviteFromContacts() async {
    await Share.share(
      "Join me on Dabbler — let's connect and play together!",
      subject: 'Invite to Dabbler',
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
              ref
                  .read(simpleFriendsControllerProvider.notifier)
                  .loadSuggestions();
              ref.read(simpleFriendsControllerProvider.notifier).loadFriends();
            },
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  @override
  void initState() {
    super.initState();

    ref.read(simpleFriendsControllerProvider.notifier).clearError();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(simpleFriendsControllerProvider.notifier).loadSuggestions();
      ref.read(simpleFriendsControllerProvider.notifier).loadFriends();
    });
  }

  @override
  void dispose() {
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
        final themed = baseTheme.copyWith(colorScheme: socialScheme);

        return Theme(
          data: themed,
          child: Builder(
            builder: (context) {
              final theme = Theme.of(context);
              final colorScheme = theme.colorScheme;

              return SingleSectionLayout(
                category: 'social',
                scrollable: false,
                padding: EdgeInsets.zero,
                child: Column(
                  children: [
                    SafeArea(
                      bottom: false,
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(24, 12, 24, 18),
                        child: Row(
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
                                backgroundColor: colorScheme.secondaryContainer,
                                foregroundColor:
                                    colorScheme.onSecondaryContainer,
                              ),
                              icon: const Icon(Iconsax.arrow_left_copy),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                'Add Friends',
                                style: theme.textTheme.headlineSmall?.copyWith(
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                            if (state.isLoading)
                              const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                    Expanded(
                      child: state.error != null
                          ? _buildError(state.error!)
                          : _buildBody(context),
                    ),
                  ],
                ),
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildBody(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final state = ref.watch(simpleFriendsControllerProvider);
    final notifier = ref.read(simpleFriendsControllerProvider.notifier);

    final query = _searchController.text.trim();
    final isSearchingMode = query.length >= 2;

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

    Widget buildSearchField() {
      return Card.filled(
        margin: EdgeInsets.zero,
        shape: const StadiumBorder(),
        color: colorScheme.surfaceContainer,
        child: TextField(
          controller: _searchController,
          decoration: InputDecoration(
            hintText: 'Search',
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
            border: InputBorder.none,
            contentPadding: const EdgeInsets.symmetric(
              vertical: 14,
              horizontal: 16,
            ),
          ),
          onChanged: (value) {
            final trimmed = value.trim();
            if (trimmed.length >= 2) {
              notifier.searchUsers(trimmed);
            } else if (trimmed.isEmpty) {
              notifier.searchUsers('');
            }
            setState(() {});
          },
        ),
      );
    }

    Widget buildInviteRow() {
      return SizedBox(
        width: double.infinity,
        child: OutlinedButton(
          onPressed: _inviteFromContacts,
          style: OutlinedButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
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

    Widget buildAddedMeSection() {
      if (addedMeRows.isEmpty) return const SizedBox.shrink();

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader(context, 'Added Me'),
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
                        const SizedBox(width: 8),
                        IconButton(
                          onPressed: isProcessing
                              ? null
                              : () {
                                  ref
                                      .read(
                                        simpleFriendsControllerProvider
                                            .notifier,
                                      )
                                      .rejectRequest(userId);
                                },
                          icon: const Icon(Iconsax.close_circle_copy),
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
            context,
            'Find Friends',
            trailing: TextButton(
              onPressed: _inviteFromContacts,
              child: const Text('All Contacts'),
            ),
          ),
          if (state.isLoadingSuggestions && state.suggestions.isEmpty)
            SizedBox(height: 300, child: _buildListSkeleton(itemCount: 6))
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
                            onPressed: () {
                              ref
                                  .read(
                                    simpleFriendsControllerProvider.notifier,
                                  )
                                  .dismissSuggestion(userId);
                            },
                            icon: const Icon(Iconsax.close_circle_copy),
                          ),
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
                                : const Icon(Iconsax.user_add_copy, size: 18),
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

    Widget buildSearchResults() {
      if (state.isSearching && state.searchResults.isEmpty) {
        return SizedBox(height: 300, child: _buildListSkeleton(itemCount: 6));
      }

      if (state.searchResults.isEmpty) {
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 24),
          child: Text(
            'No users found',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
        );
      }

      final results = state.searchResults.where((row) {
        final id = _peerIdFromRow(row).trim();
        return id.isNotEmpty;
      }).toList();

      return Column(
        children: [
          for (final user in results)
            Builder(
              builder: (context) {
                final userId = _peerIdFromRow(user);
                final displayName = _displayNameFromRow(user);
                final username = _usernameFromRow(user);
                final avatarUrl = _avatarUrlFromRow(user);
                final isFriend = friendIds.contains(userId);
                final hasPendingRequest = outgoingIds.contains(userId);
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
                } else if (hasPendingRequest) {
                  trailing = Chip(
                    label: Text(
                      'Pending',
                      style: TextStyle(color: colorScheme.onTertiaryContainer),
                    ),
                    backgroundColor: colorScheme.tertiaryContainer,
                  );
                } else {
                  trailing = Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        onPressed: () {
                          ref
                              .read(simpleFriendsControllerProvider.notifier)
                              .dismissSuggestion(userId);
                        },
                        icon: const Icon(Iconsax.close_circle_copy),
                      ),
                      IconButton.filledTonal(
                        onPressed: isProcessing
                            ? null
                            : () {
                                ref
                                    .read(
                                      simpleFriendsControllerProvider.notifier,
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
                            : const Icon(Iconsax.user_add_copy, size: 18),
                      ),
                    ],
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

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      child: RefreshIndicator(
        onRefresh: () async {
          await ref
              .read(simpleFriendsControllerProvider.notifier)
              .loadSuggestions();
          await ref
              .read(simpleFriendsControllerProvider.notifier)
              .loadFriends();
        },
        child: ListView(
          padding: const EdgeInsets.only(bottom: 16),
          children: [
            buildSearchField(),
            if (isSearchingMode) ...[
              _buildSectionHeader(context, 'Search Results'),
              buildSearchResults(),
            ] else ...[
              const SizedBox(height: 12),
              buildInviteRow(),
              buildAddedMeSection(),
              buildFindFriendsSection(),
            ],
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}
