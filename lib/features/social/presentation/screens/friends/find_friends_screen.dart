import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../../core/widgets/loading_widget.dart';
import '../../../../../core/widgets/error_widget.dart' as core_error;
import '../../../../../core/widgets/custom_button.dart';

// Stub providers - these should be implemented in the actual social_providers.dart
final userSearchControllerProvider = StateNotifierProvider<UserSearchController, UserSearchState>((ref) => UserSearchController());
final nearbyUsersProvider = FutureProvider<List<dynamic>>((ref) async => []);
final contactSuggestionsProvider = FutureProvider<List<dynamic>>((ref) async => []);
final currentUserIdProvider = Provider<String>((ref) => 'stub-user-id');

// Stub state class
class UserSearchState {
  final List<dynamic> suggestedFriends;
  final bool isLoading;
  final Map<String, dynamic> filters;
  
  UserSearchState({
    this.suggestedFriends = const [],
    this.isLoading = false,
    this.filters = const {},
  });
  
  UserSearchState copyWith({
    List<dynamic>? suggestedFriends,
    bool? isLoading,
    Map<String, dynamic>? filters,
  }) {
    return UserSearchState(
      suggestedFriends: suggestedFriends ?? this.suggestedFriends,
      isLoading: isLoading ?? this.isLoading,
      filters: filters ?? this.filters,
    );
  }
}

// Stub controller
class UserSearchController extends StateNotifier<UserSearchState> {
  UserSearchController() : super(UserSearchState());
  
  void loadSuggestedFriends() {
    state = state.copyWith(isLoading: true);
    // Simulate loading
    Future.delayed(const Duration(seconds: 1), () {
      state = state.copyWith(
        isLoading: false,
        suggestedFriends: [],
      );
    });
  }
  
  void searchUsers(String query) {
    // Stub implementation
  }
  
  void clearSearch() {
    // Stub implementation
  }
  
  void refreshSuggestedFriends() {
    loadSuggestedFriends();
  }
  
  void sendFriendRequest(String userId) {
    // Stub implementation
  }
  
  void dismissSuggestion(String userId) {
    // Stub implementation
  }
  
  Future<bool> importContacts() async {
    // Stub implementation
    return true;
  }
  
  void updateFilters(Map<String, dynamic> filters) {
    state = state.copyWith(filters: filters);
  }
}

// Stub widgets
class SuggestedFriendsWidget extends StatelessWidget {
  final List<dynamic> suggestions;
  final bool isLoading;
  final Function(dynamic) onUserTap;
  final Function(String) onSendRequest;
  final Function(String) onDismiss;
  
  const SuggestedFriendsWidget({
    super.key,
    required this.suggestions,
    required this.isLoading,
    required this.onUserTap,
    required this.onSendRequest,
    required this.onDismiss,
  });
  
  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    
    if (suggestions.isEmpty) {
      return const Center(
        child: Text('No suggestions available'),
      );
    }
    
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: suggestions.length,
      itemBuilder: (context, index) {
        return const ListTile(
          title: Text('Suggested Friend'),
          subtitle: Text('Tap to view profile'),
        );
      },
    );
  }
}

class NearbyPlayersWidget extends StatelessWidget {
  final List<dynamic> nearbyUsers;
  final Function(dynamic) onUserTap;
  final Function(String) onSendRequest;
  final VoidCallback onViewMap;
  
  const NearbyPlayersWidget({
    super.key,
    required this.nearbyUsers,
    required this.onUserTap,
    required this.onSendRequest,
    required this.onViewMap,
  });
  
  @override
  Widget build(BuildContext context) {
    if (nearbyUsers.isEmpty) {
      return const Center(
        child: Text('No nearby players found'),
      );
    }
    
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: nearbyUsers.length,
      itemBuilder: (context, index) {
        return const ListTile(
          title: Text('Nearby Player'),
          subtitle: Text('Tap to view profile'),
        );
      },
    );
  }
}

class SearchResultsWidget extends StatelessWidget {
  final UserSearchState searchState;
  final Function(dynamic) onUserTap;
  final Function(String) onSendRequest;
  
  const SearchResultsWidget({
    super.key,
    required this.searchState,
    required this.onUserTap,
    required this.onSendRequest,
  });
  
  @override
  Widget build(BuildContext context) {
    if (searchState.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    
    return const Center(
      child: Text('Search results will appear here'),
    );
  }
}

class ImportContactsWidget extends StatelessWidget {
  final List<dynamic> contacts;
  final VoidCallback onImportContacts;
  final Function(String) onSendRequest;
  final Function(dynamic) onInvite;
  
  const ImportContactsWidget({
    super.key,
    required this.contacts,
    required this.onImportContacts,
    required this.onSendRequest,
    required this.onInvite,
  });
  
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          const Text('Import your contacts to find friends'),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: onImportContacts,
            child: const Text('Import Contacts'),
          ),
        ],
      ),
    );
  }
}

class SocialConnectionsWidget extends StatelessWidget {
  final VoidCallback onConnectFacebook;
  final VoidCallback onConnectTwitter;
  final VoidCallback onConnectInstagram;
  
  const SocialConnectionsWidget({
    super.key,
    required this.onConnectFacebook,
    required this.onConnectTwitter,
    required this.onConnectInstagram,
  });
  
  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Connect Social Media',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                IconButton(
                  onPressed: onConnectFacebook,
                  icon: const Icon(Icons.facebook),
                ),
                IconButton(
                  onPressed: onConnectTwitter,
                  icon: const Icon(Icons.flutter_dash),
                ),
                IconButton(
                  onPressed: onConnectInstagram,
                  icon: const Icon(Icons.camera_alt),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class FindFriendsScreen extends ConsumerStatefulWidget {
  const FindFriendsScreen({super.key});

  @override
  ConsumerState<FindFriendsScreen> createState() => _FindFriendsScreenState();
}

class _FindFriendsScreenState extends ConsumerState<FindFriendsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _searchController.addListener(_onSearchChanged);
    
    // Load initial data
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(userSearchControllerProvider.notifier).loadSuggestedFriends();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    setState(() {
      _searchQuery = _searchController.text;
    });
    
    if (_searchQuery.isNotEmpty) {
      ref.read(userSearchControllerProvider.notifier).searchUsers(_searchQuery);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final searchState = ref.watch(userSearchControllerProvider);

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      appBar: _buildAppBar(context, theme),
      body: Column(
        children: [
          // Search bar
          _buildSearchBar(theme),
          
          // Show search results if searching
          if (_searchQuery.isNotEmpty)
            _buildSearchResults(context, theme, searchState)
          else ...[
            // Tab bar
            TabBar(
              controller: _tabController,
              isScrollable: true,
              tabs: const [
                Tab(text: 'Suggestions'),
                Tab(text: 'Nearby'),
                Tab(text: 'Contacts'),
                Tab(text: 'Connect'),
              ],
            ),
            
            // Tab content
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildSuggestionsTab(context, theme, searchState),
                  _buildNearbyTab(context, theme),
                  _buildContactsTab(context, theme),
                  _buildConnectTab(context, theme),
                ],
              ),
            ),
          ],
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showQRCodeDialog,
        icon: const Icon(Icons.qr_code),
        label: const Text('QR Code'),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(BuildContext context, ThemeData theme) {
    return AppBar(
      elevation: 0,
      backgroundColor: theme.colorScheme.surface,
      surfaceTintColor: Colors.transparent,
      leading: IconButton(
        onPressed: () => Navigator.pop(context),
        icon: const Icon(Icons.arrow_back),
      ),
      title: const Text('Find Friends'),
      actions: [
        IconButton(
          onPressed: _scanQRCode,
          icon: const Icon(Icons.qr_code_scanner),
          tooltip: 'Scan QR Code',
        ),
        PopupMenuButton(
          itemBuilder: (context) => [
            const PopupMenuItem(
              value: 'invite_friends',
              child: ListTile(
                leading: Icon(Icons.share),
                title: Text('Invite Friends'),
                contentPadding: EdgeInsets.zero,
              ),
            ),
            const PopupMenuItem(
              value: 'privacy_settings',
              child: ListTile(
                leading: Icon(Icons.privacy_tip),
                title: Text('Privacy Settings'),
                contentPadding: EdgeInsets.zero,
              ),
            ),
          ],
          onSelected: _handleMenuAction,
        ),
      ],
    );
  }

  Widget _buildSearchBar(ThemeData theme) {
    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
      ),
      child: TextField(
        controller: _searchController,
        decoration: InputDecoration(
          hintText: 'Search by name, username, or email',
          prefixIcon: const Icon(Icons.search),
          suffixIcon: _searchQuery.isNotEmpty
            ? IconButton(
                onPressed: () {
                  _searchController.clear();
                  ref.read(userSearchControllerProvider.notifier).clearSearch();
                },
                icon: const Icon(Icons.clear),
              )
            : IconButton(
                onPressed: _showSearchFilters,
                icon: const Icon(Icons.tune),
              ),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        ),
      ),
    );
  }

  Widget _buildSearchResults(
    BuildContext context,
    ThemeData theme,
    UserSearchState searchState,
  ) {
    return Expanded(
      child: SearchResultsWidget(
        searchState: searchState,
        onUserTap: (user) => _viewUserProfile(user.id),
        onSendRequest: (userId) => _sendFriendRequest(userId),
      ),
    );
  }

  Widget _buildSuggestionsTab(
    BuildContext context,
    ThemeData theme,
    UserSearchState searchState,
  ) {
    return SingleChildScrollView(
      controller: _scrollController,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Icon(
                Icons.recommend,
                color: theme.colorScheme.primary,
              ),
              const SizedBox(width: 8),
              Text(
                'People you may know',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              TextButton(
                onPressed: () => ref.read(userSearchControllerProvider.notifier)
                  .refreshSuggestedFriends(),
                child: const Text('Refresh'),
              ),
            ],
          ),
          
          const SizedBox(height: 16),
          
          // Suggested friends
          SuggestedFriendsWidget(
            suggestions: searchState.suggestedFriends,
            isLoading: searchState.isLoading,
            onUserTap: (user) => _viewUserProfile(user.id),
            onSendRequest: (userId) => _sendFriendRequest(userId),
            onDismiss: (userId) => _dismissSuggestion(userId),
          ),
        ],
      ),
    );
  }

  Widget _buildNearbyTab(BuildContext context, ThemeData theme) {
    return Consumer(
      builder: (context, ref, child) {
        final nearbyUsersAsync = ref.watch(nearbyUsersProvider);
        
        return nearbyUsersAsync.when(
          data: (users) => NearbyPlayersWidget(
            nearbyUsers: users,
            onUserTap: (user) => _viewUserProfile(user.id),
            onSendRequest: (userId) => _sendFriendRequest(userId),
            onViewMap: () => Navigator.pushNamed(context, '/social/nearby-players'),
          ),
          loading: () => const Center(child: LoadingWidget()),
          error: (error, stack) => Center(
            child: core_error.ErrorWidget(
              message: 'Failed to load nearby players: $error',
              onRetry: () => ref.refresh(nearbyUsersProvider),
            ),
          ),
        );
      },
    );
  }

  Widget _buildContactsTab(BuildContext context, ThemeData theme) {
    return Consumer(
      builder: (context, ref, child) {
        final contactsAsync = ref.watch(contactSuggestionsProvider);
        
        return contactsAsync.when(
          data: (contacts) => ImportContactsWidget(
            contacts: contacts,
            onImportContacts: () => _importContacts(),
            onSendRequest: (userId) => _sendFriendRequest(userId),
            onInvite: (contact) => _inviteContact(contact),
          ),
          loading: () => const Center(child: LoadingWidget()),
          error: (error, stack) => Center(
            child: core_error.ErrorWidget(
              message: 'Failed to load contacts: $error',
              onRetry: () => ref.refresh(contactSuggestionsProvider),
            ),
          ),
        );
      },
    );
  }

  Widget _buildConnectTab(BuildContext context, ThemeData theme) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Social media connections
          SocialConnectionsWidget(
            onConnectFacebook: () => _connectSocialMedia('facebook'),
            onConnectTwitter: () => _connectSocialMedia('twitter'),
            onConnectInstagram: () => _connectSocialMedia('instagram'),
          ),
          
          const SizedBox(height: 32),
          
          // QR Code section
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.qr_code,
                        color: theme.colorScheme.primary,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Share your QR Code',
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Let others scan your code to add you instantly',
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 20),
                  
                  Row(
                    children: [
                      Expanded(
                        child: CustomButton(
                          text: 'Show My Code',
                          onPressed: _showQRCodeDialog,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: CustomButton(
                          text: 'Scan Code',
                          onPressed: _scanQRCode,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          
          const SizedBox(height: 24),
          
          // Invite friends section
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.share,
                        color: theme.colorScheme.primary,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Invite friends to Dabbler',
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Share the app with your friends and family',
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 20),
                  
                  CustomButton(
                    text: 'Send Invites',
                    onPressed: _inviteFriends,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showSearchFilters() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => SearchFiltersSheet(
        currentFilters: ref.read(userSearchControllerProvider).filters,
        onFiltersChanged: (filters) {
          ref.read(userSearchControllerProvider.notifier).updateFilters(filters);
        },
      ),
    );
  }

  void _showQRCodeDialog() {
    final currentUserId = ref.read(currentUserIdProvider);
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('My QR Code'),
        content: SizedBox(
          width: 200,
          height: 200,
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.qr_code,
                  size: 100,
                  color: Colors.grey,
                ),
                const SizedBox(height: 16),
                Text('QR Code for user: $currentUserId'),
                const Text('(QR functionality not implemented)'),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              // Share QR code
            },
            child: const Text('Share'),
          ),
        ],
      ),
    );
  }

  void _scanQRCode() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('QR Scanner'),
        content: const Text('QR scanning functionality is not implemented yet.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }



  void _sendFriendRequest(String userId) {
    ref.read(userSearchControllerProvider.notifier).sendFriendRequest(userId);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Friend request sent!')),
    );
  }

  void _viewUserProfile(String userId) {
    Navigator.pushNamed(
      context,
      '/social/friend-profile',
      arguments: {'friendId': userId},
    );
  }

  void _dismissSuggestion(String userId) {
    ref.read(userSearchControllerProvider.notifier).dismissSuggestion(userId);
  }

  void _importContacts() async {
    final success = await ref.read(userSearchControllerProvider.notifier).importContacts();
    
    if (mounted) {
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Contacts imported successfully')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to import contacts')),
        );
      }
    }
  }

  void _inviteContact(dynamic contact) {
    // Implement contact invitation
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Invitation sent to ${contact.name}')),
    );
  }

  void _connectSocialMedia(String platform) {
    // Implement social media connection
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Connecting to ${platform.toUpperCase()}...')),
    );
  }

  void _inviteFriends() {
    // Implement friend invitation
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Sharing app invite...')),
    );
  }

  void _handleMenuAction(String action) {
    switch (action) {
      case 'invite_friends':
        _inviteFriends();
        break;
      case 'privacy_settings':
        Navigator.pushNamed(context, '/settings/privacy');
        break;
    }
  }
}

/// Search filters bottom sheet
class SearchFiltersSheet extends StatefulWidget {
  final Map<String, dynamic> currentFilters;
  final Function(Map<String, dynamic>) onFiltersChanged;

  const SearchFiltersSheet({
    super.key,
    required this.currentFilters,
    required this.onFiltersChanged,
  });

  @override
  State<SearchFiltersSheet> createState() => _SearchFiltersSheetState();
}

class _SearchFiltersSheetState extends State<SearchFiltersSheet> {
  late Map<String, dynamic> _filters;

  @override
  void initState() {
    super.initState();
    _filters = Map.from(widget.currentFilters);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Container(
      height: MediaQuery.of(context).size.height * 0.7,
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'Search Filters',
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              IconButton(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.close),
              ),
            ],
          ),
          
          const SizedBox(height: 20),
          
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Location filter
                  _buildFilterSection(
                    'Location',
                    Icons.location_on,
                    [
                      CheckboxListTile(
                        title: const Text('Near me'),
                        value: _filters['nearMe'] ?? false,
                        onChanged: (value) => setState(() => _filters['nearMe'] = value),
                      ),
                      // Add distance slider if "Near me" is selected
                      if (_filters['nearMe'] == true) ...[
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Distance: ${_filters['distance'] ?? 10} km'),
                              Slider(
                                value: (_filters['distance'] ?? 10).toDouble(),
                                min: 1,
                                max: 100,
                                divisions: 99,
                                onChanged: (value) => setState(() => 
                                  _filters['distance'] = value.round()),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                  
                  // Sports filter
                  _buildFilterSection(
                    'Sports',
                    Icons.sports,
                    [
                      CheckboxListTile(
                        title: const Text('Basketball'),
                        value: _filters['sports']?.contains('basketball') ?? false,
                        onChanged: (value) => _toggleSportFilter('basketball', value),
                      ),
                      CheckboxListTile(
                        title: const Text('Football'),
                        value: _filters['sports']?.contains('football') ?? false,
                        onChanged: (value) => _toggleSportFilter('football', value),
                      ),
                      CheckboxListTile(
                        title: const Text('Soccer'),
                        value: _filters['sports']?.contains('soccer') ?? false,
                        onChanged: (value) => _toggleSportFilter('soccer', value),
                      ),
                      // Add more sports...
                    ],
                  ),
                  
                  // Age range filter
                  _buildFilterSection(
                    'Age Range',
                    Icons.cake,
                    [
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Age: ${_filters['minAge'] ?? 18} - ${_filters['maxAge'] ?? 65}'),
                            RangeSlider(
                              values: RangeValues(
                                (_filters['minAge'] ?? 18).toDouble(),
                                (_filters['maxAge'] ?? 65).toDouble(),
                              ),
                              min: 18,
                              max: 65,
                              divisions: 47,
                              onChanged: (values) => setState(() {
                                _filters['minAge'] = values.start.round();
                                _filters['maxAge'] = values.end.round();
                              }),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          
          const SizedBox(height: 20),
          
          // Action buttons
          Row(
            children: [
              Expanded(
                child: CustomButton(
                  text: 'Clear All',
                  onPressed: () {
                    setState(() => _filters.clear());
                  },
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: CustomButton(
                  text: 'Apply Filters',
                  onPressed: () {
                    widget.onFiltersChanged(_filters);
                    Navigator.pop(context);
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFilterSection(
    String title,
    IconData icon,
    List<Widget> children,
  ) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  Icon(icon, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    title,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            ),
            ...children,
          ],
        ),
      ),
    );
  }

  void _toggleSportFilter(String sport, bool? value) {
    setState(() {
      _filters['sports'] ??= <String>[];
      if (value == true) {
        (_filters['sports'] as List<String>).add(sport);
      } else {
        (_filters['sports'] as List<String>).remove(sport);
      }
    });
  }
}
