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
    _slideAnimation =
        Tween<Offset>(begin: const Offset(0, 0.1), end: Offset.zero).animate(
          CurvedAnimation(
            parent: _animationController,
            curve: Curves.easeOutCubic,
          ),
        );

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
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.surface,
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
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return SliverAppBar(
      pinned: true,
      stretch: true,
      expandedHeight: 220,
      backgroundColor: colorScheme.surface,
      foregroundColor: colorScheme.onSurface,
      leading: IconButton(
        onPressed: () => context.pop(),
        icon: const Icon(Icons.arrow_back),
      ),
      actions: [
        IconButton(
          onPressed: () => context.push('/help/center'),
          icon: const Icon(Icons.help_outline),
          tooltip: 'Help center',
        ),
      ],
      flexibleSpace: FlexibleSpaceBar(
        collapseMode: CollapseMode.pin,
        stretchModes: const [
          StretchMode.zoomBackground,
          StretchMode.fadeTitle,
        ],
        titlePadding: const EdgeInsetsDirectional.only(start: 24, bottom: 16),
        title: Text(
          'Settings',
          style: textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
        ),
        background: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                colorScheme.primaryContainer.withOpacity(0.85),
                colorScheme.surface,
              ],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
          child: SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 72, 24, 32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Tune Dabbler to match how you play.',
                    style: textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Manage your account, preferences, and notifications all in one place.',
                    style: textTheme.bodyMedium?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSearchBar(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 12),
      child: TextField(
        controller: _searchController,
        onChanged: (value) {
          setState(() {
            _searchQuery = value.toLowerCase();
          });
        },
        decoration: InputDecoration(
          hintText: 'Search settings',
          prefixIcon: const Icon(Icons.search),
          suffixIcon: _searchQuery.isNotEmpty
              ? IconButton(
                  onPressed: () {
                    _searchController.clear();
                    setState(() {
                      _searchQuery = '';
                    });
                  },
                  icon: const Icon(Icons.close),
                )
              : null,
          filled: true,
          fillColor: colorScheme.surfaceContainerHighest,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(28),
            borderSide: BorderSide.none,
          ),
          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
        ),
      ),
    );
  }

  List<Widget> _buildFilteredSections(BuildContext context) {
    final filteredSections = _getFilteredSections();

    return filteredSections.map((section) {
      return SliverPadding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
        sliver: SliverToBoxAdapter(child: _buildSection(context, section)),
      );
    }).toList();
  }

  List<SettingsSection> _getFilteredSections() {
    if (_searchQuery.isEmpty) return _allSections;

    return _allSections
        .map((section) {
          final filteredItems = section.items.where((item) {
            return item.title.toLowerCase().contains(_searchQuery) ||
                item.subtitle.toLowerCase().contains(_searchQuery) ||
                item.searchTerms.any((term) => term.contains(_searchQuery));
          }).toList();

          return SettingsSection(title: section.title, items: filteredItems);
        })
        .where((section) => section.items.isNotEmpty)
        .toList();
  }

  Widget _buildSection(BuildContext context, SettingsSection section) {
    if (section.items.isEmpty) return const SizedBox.shrink();

    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 12),
          child: Text(
            section.title,
            style: textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w600,
              color: colorScheme.onSurfaceVariant,
              letterSpacing: 0.2,
            ),
          ),
        ),
        Card(
          elevation: 0,
          color: colorScheme.surfaceContainerHigh,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          child: Column(
            children: section.items.asMap().entries.map((entry) {
              final index = entry.key;
              final item = entry.value;
              final isLast = index == section.items.length - 1;

              return _buildSettingsItem(
                context,
                item,
                showDivider: !isLast,
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildSettingsItem(
    BuildContext context,
    SettingsItem item,
    {required bool showDivider},
  ) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Column(
      children: [
        ListTile(
          onTap: () => _navigateToSetting(item),
          leading: Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: colorScheme.primary.withOpacity(0.12),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(item.icon, color: colorScheme.primary),
          ),
          title: Text(
            item.title,
            style: textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
              color: colorScheme.onSurface,
            ),
          ),
          subtitle: Text(
            item.subtitle,
            style: textTheme.bodySmall?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
          trailing: Icon(Icons.chevron_right, color: colorScheme.onSurfaceVariant),
          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        ),
        if (showDivider)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Divider(
              height: 1,
              color: colorScheme.outlineVariant.withOpacity(0.4),
            ),
          ),
      ],
    );
  }

  Widget _buildSignOutSection(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 8),
      child: Card(
        elevation: 0,
        color: colorScheme.surfaceContainerHigh,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        child: ListTile(
          onTap: _showSignOutDialog,
          leading: Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: colorScheme.error.withOpacity(0.12),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(Icons.logout, color: colorScheme.error),
          ),
          title: Text(
            'Sign out',
            style: textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
              color: colorScheme.error,
            ),
          ),
          subtitle: Text(
            'Leave your account on this device',
            style: textTheme.bodySmall?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
          trailing: Icon(Icons.chevron_right, color: colorScheme.onSurfaceVariant),
          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        ),
      ),
    );
  }

  Widget _buildVersionInfo(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 32),
      child: Column(
        children: [
          Text(
            'Dabbler',
            style: textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
              color: colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Version $_appVersion',
            style: textTheme.bodySmall?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '© 2025 Dabbler. All rights reserved.',
            style: textTheme.labelSmall?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
          ),
        ],
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
        content: const Text(
          'Are you sure you want to sign out of your account?',
        ),
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
              foregroundColor: Theme.of(context).colorScheme.error,
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
        builder: (context) => const Center(child: CircularProgressIndicator()),
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
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }
  }
}

class SettingsSection {
  final String title;
  final List<SettingsItem> items;

  SettingsSection({required this.title, required this.items});
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
