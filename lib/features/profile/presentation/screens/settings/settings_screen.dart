import 'package:dabbler/features/authentication/presentation/providers/auth_providers.dart';
import 'package:dabbler/core/services/auth_service.dart';
import 'package:flutter/material.dart';
import 'package:dabbler/utils/constants/route_constants.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  final String _appVersion = '1.0.0';

  final List<SettingsSection> _allSections = [
    SettingsSection(
      title: 'Account',
      items: [
        SettingsItem(
          title: 'Account Management',
          subtitle: 'Email, password, security',
          icon: Icons.person_outline,
          route: '/settings/account',
          searchTerms: ['account', 'email', 'password', 'security', 'login'],
        ),
        SettingsItem(
          title: 'Privacy Settings',
          subtitle: 'Control your data and visibility',
          icon: Icons.privacy_tip_outlined,
          route: '/settings/privacy',
          searchTerms: ['privacy', 'visibility', 'data', 'sharing', 'profile'],
        ),
      ],
    ),
    SettingsSection(
      title: 'Preferences',
      items: [
        SettingsItem(
          title: 'Game Preferences',
          subtitle: 'Game types, duration, competition',
          icon: Icons.sports_esports_outlined,
          route: '/preferences/games',
          searchTerms: ['games', 'types', 'duration', 'competition', 'team'],
        ),
        SettingsItem(
          title: 'Availability',
          subtitle: 'Schedule and time preferences',
          icon: Icons.schedule_outlined,
          route: '/preferences/availability',
          searchTerms: ['availability', 'schedule', 'time', 'calendar'],
        ),
      ],
    ),
    SettingsSection(
      title: 'Display',
      items: [
        SettingsItem(
          title: 'Theme',
          subtitle: 'Light, dark, or system default',
          icon: Icons.palette_outlined,
          route: '/settings/theme',
          searchTerms: ['theme', 'dark', 'light', 'appearance'],
        ),
        SettingsItem(
          title: 'Language',
          subtitle: 'Choose your preferred language',
          icon: Icons.language_outlined,
          route: '/settings/language',
          searchTerms: ['language', 'locale', 'translate'],
        ),
      ],
    ),
    SettingsSection(
      title: 'Help & Support',
      items: [
        SettingsItem(
          title: 'Help Center',
          subtitle: 'FAQs and tutorials',
          icon: Icons.help_outline,
          route: '/help/center',
          searchTerms: ['help', 'faq', 'support', 'tutorials'],
        ),
        SettingsItem(
          title: 'Contact Support',
          subtitle: 'Get help from our team',
          icon: Icons.support_agent_outlined,
          route: '/help/contact',
          searchTerms: ['contact', 'support', 'help', 'team'],
        ),
        SettingsItem(
          title: 'Report a Bug',
          subtitle: 'Help us improve the app',
          icon: Icons.bug_report_outlined,
          route: '/help/bug-report',
          searchTerms: ['bug', 'report', 'issue', 'problem'],
        ),
      ],
    ),
    SettingsSection(
      title: 'About',
      items: [
        SettingsItem(
          title: 'Terms of Service',
          subtitle: 'Read our terms and conditions',
          icon: Icons.description_outlined,
          route: '/about/terms',
          searchTerms: ['terms', 'service', 'conditions', 'legal'],
        ),
        SettingsItem(
          title: 'Privacy Policy',
          subtitle: 'How we handle your data',
          icon: Icons.policy_outlined,
          route: '/about/privacy',
          searchTerms: ['privacy', 'policy', 'data', 'legal'],
        ),
        SettingsItem(
          title: 'Licenses',
          subtitle: 'Open source licenses',
          icon: Icons.code_outlined,
          route: '/about/licenses',
          searchTerms: ['licenses', 'open', 'source', 'legal'],
        ),
      ],
    ),
  ];

  @override
  void initState() {
    super.initState();
    
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.1),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutCubic,
    ));

    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: SlideTransition(
          position: _slideAnimation,
          child: CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              _buildAppBar(context),
              SliverToBoxAdapter(child: _buildSearchBar(context)),
              ..._buildFilteredSections(context),
              SliverToBoxAdapter(child: _buildSignOutSection(context)),
              SliverToBoxAdapter(child: _buildVersionInfo(context)),
              const SliverToBoxAdapter(child: SizedBox(height: 20)),
            ],
          ),
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
        onPressed: () => context.pop(),
        icon: const Icon(Icons.arrow_back),
      ),
      flexibleSpace: FlexibleSpaceBar(
        title: Text(
          'Settings',
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: false,
        titlePadding: const EdgeInsets.only(left: 56, bottom: 16),
      ),
    );
  }

  Widget _buildSearchBar(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(20),
      child: TextField(
        controller: _searchController,
        onChanged: (value) {
          setState(() {
            _searchQuery = value.toLowerCase();
          });
        },
        decoration: InputDecoration(
          hintText: 'Search settings...',
          prefixIcon: const Icon(Icons.search),
          suffixIcon: _searchQuery.isNotEmpty
              ? IconButton(
                  onPressed: () {
                    _searchController.clear();
                    setState(() {
                      _searchQuery = '';
                    });
                  },
                  icon: const Icon(Icons.clear),
                )
              : null,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide.none,
          ),
          filled: true,
          fillColor: Theme.of(context).cardColor,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 12,
          ),
        ),
      ),
    );
  }

  List<Widget> _buildFilteredSections(BuildContext context) {
    final filteredSections = _getFilteredSections();
    
    return filteredSections.map((section) {
      return SliverToBoxAdapter(
        child: _buildSection(context, section),
      );
    }).toList();
  }

  List<SettingsSection> _getFilteredSections() {
    if (_searchQuery.isEmpty) return _allSections;
    
    return _allSections.map((section) {
      final filteredItems = section.items.where((item) {
        return item.title.toLowerCase().contains(_searchQuery) ||
               item.subtitle.toLowerCase().contains(_searchQuery) ||
               item.searchTerms.any((term) => term.contains(_searchQuery));
      }).toList();
      
      return SettingsSection(
        title: section.title,
        items: filteredItems,
      );
    }).where((section) => section.items.isNotEmpty).toList();
  }

  Widget _buildSection(BuildContext context, SettingsSection section) {
    if (section.items.isEmpty) return const SizedBox.shrink();
    
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 12),
            child: Text(
              section.title,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: Theme.of(context).primaryColor,
              ),
            ),
          ),
          Card(
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              children: section.items.asMap().entries.map((entry) {
                final index = entry.key;
                final item = entry.value;
                final isLast = index == section.items.length - 1;
                
                return _buildSettingsItem(context, item, isLast);
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsItem(BuildContext context, SettingsItem item, bool isLast) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => _navigateToSetting(item),
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(isLast ? 0 : 16),
          bottom: Radius.circular(isLast ? 16 : 0),
        ),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            border: !isLast
                ? Border(
                    bottom: BorderSide(
                      color: Colors.grey[200]!,
                      width: 0.5,
                    ),
                  )
                : null,
          ),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: Theme.of(context).primaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  item.icon,
                  color: Theme.of(context).primaryColor,
                  size: 20,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.title,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      item.subtitle,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.arrow_forward_ios,
                size: 16,
                color: Colors.grey,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSignOutSection(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Card(
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: _showSignOutDialog,
            borderRadius: BorderRadius.circular(16),
            child: Container(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: Colors.red.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.logout,
                      color: Colors.red,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Sign Out',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                            color: Colors.red,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Sign out of your account',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Icon(
                    Icons.arrow_forward_ios,
                    size: 16,
                    color: Colors.grey,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildVersionInfo(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: Center(
        child: Column(
          children: [
            Text(
              'Dabbler',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: Theme.of(context).primaryColor,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Version $_appVersion',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '© 2025 Dabbler. All rights reserved.',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Colors.grey[500],
                fontSize: 12,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  void _navigateToSetting(SettingsItem item) {
    context.push(item.route);
  }

  void _showSignOutDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Sign Out'),
        content: const Text('Are you sure you want to sign out of your account?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.of(context).pop();
              await _signOut();
            },
            style: TextButton.styleFrom(
              foregroundColor: Colors.red,
            ),
            child: const Text('Sign Out'),
          ),
        ],
      ),
    );
  }

  Future<void> _signOut() async {
    try {
      // Show loading indicator
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(
          child: CircularProgressIndicator(),
        ),
      );

      // Prefer SimpleAuthNotifier (independent of unimplemented AuthRepository).
      try {
        await ref.read(simpleAuthProvider.notifier).signOut();
      } on UnimplementedError catch (_) {
        // Fallback: direct AuthService sign out if provider path not ready
        await AuthService().signOut();
        routerRefreshNotifier.notifyAuthStateChanged();
      }

      if (mounted) {
        Navigator.of(context).pop(); // Remove loading dialog
        // Navigate to phone input (primary auth entry) instead of legacy /login
        context.go(RoutePaths.phoneInput);
      }
    } catch (e) {
      if (mounted) {
        Navigator.of(context).pop(); // Remove loading dialog
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error signing out: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}

class SettingsSection {
  final String title;
  final List<SettingsItem> items;

  SettingsSection({
    required this.title,
    required this.items,
  });
}

class SettingsItem {
  final String title;
  final String subtitle;
  final IconData icon;
  final String route;
  final List<String> searchTerms;

  SettingsItem({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.route,
    required this.searchTerms,
  });
}
