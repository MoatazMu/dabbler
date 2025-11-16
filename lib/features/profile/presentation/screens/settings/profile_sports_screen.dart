import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../../utils/constants/route_constants.dart';

/// Screen for managing user's sports and game preferences
class ProfileSportsScreen extends ConsumerStatefulWidget {
  const ProfileSportsScreen({super.key});

  @override
  ConsumerState<ProfileSportsScreen> createState() =>
      _ProfileSportsScreenState();
}

class _ProfileSportsScreenState extends ConsumerState<ProfileSportsScreen>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  bool _isLoading = true;

  // User's sport preferences - will be loaded from database
  Map<String, SportPreference> _sportPreferences = {};

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.0, 0.6, curve: Curves.easeOut),
      ),
    );

    _slideAnimation =
        Tween<Offset>(begin: const Offset(0, 0.3), end: Offset.zero).animate(
          CurvedAnimation(
            parent: _animationController,
            curve: const Interval(0.2, 1.0, curve: Curves.easeOutCubic),
          ),
        );

    _animationController.forward();
    _loadSportsPreferences();
  }

  Future<void> _loadSportsPreferences() async {
    try {
      setState(() {
        _isLoading = true;
      });

      final supabase = Supabase.instance.client;
      final userId = supabase.auth.currentUser?.id;

      if (userId == null) {
        throw Exception('User not authenticated');
      }

      // Fetch user's sports profiles from database
      // First get profile_id from user_id
      final profileResponse = await supabase
          .from('profiles')
          .select('id')
          .eq('user_id', userId)
          .maybeSingle();

      if (profileResponse == null) {
        throw Exception('Profile not found');
      }

      final profileId = profileResponse['id'] as String;

      final response = await supabase
          .from('sport_profiles')
          .select('*')
          .eq('profile_id', profileId);

      // Convert database records to SportPreference objects
      final Map<String, SportPreference> preferences = {};

      for (final sportData in response as List) {
        // sport_profiles table uses 'sport_key', not 'sport_type'
        final sportKey = (sportData['sport_key'] as String? ?? '').toLowerCase();
        if (sportKey.isEmpty) continue;
        
        preferences[sportKey] = SportPreference(
          name: _formatSportName(sportData['sport_key'] as String),
          icon: _getSportIcon(sportKey),
          isEnabled: true, // If it exists in sport_profiles, it's enabled
          skillLevel: _parseSkillLevel(sportData['skill_level']),
          preferredPosition: sportData['primary_position'] as String?,
        );
      }

      // Add common sports that user hasn't set up yet
      _addMissingSports(preferences);

      setState(() {
        _sportPreferences = preferences;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load sports preferences: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _addMissingSports(Map<String, SportPreference> preferences) {
    final commonSports = {
      'football': SportPreference(
        name: 'Football',
        icon: Icons.sports_soccer,
        isEnabled: false,
        skillLevel: SkillLevel.beginner,
        preferredPosition: null,
      ),
      'basketball': SportPreference(
        name: 'Basketball',
        icon: Icons.sports_basketball,
        isEnabled: false,
        skillLevel: SkillLevel.beginner,
        preferredPosition: null,
      ),
      'tennis': SportPreference(
        name: 'Tennis',
        icon: Icons.sports_tennis,
        isEnabled: false,
        skillLevel: SkillLevel.beginner,
        preferredPosition: null,
      ),
      'badminton': SportPreference(
        name: 'Badminton',
        icon: Icons.sports_tennis,
        isEnabled: false,
        skillLevel: SkillLevel.beginner,
        preferredPosition: null,
      ),
      'volleyball': SportPreference(
        name: 'Volleyball',
        icon: Icons.sports_volleyball,
        isEnabled: false,
        skillLevel: SkillLevel.beginner,
        preferredPosition: null,
      ),
    };

    for (final entry in commonSports.entries) {
      if (!preferences.containsKey(entry.key)) {
        preferences[entry.key] = entry.value;
      }
    }
  }

  String _formatSportName(String sportType) {
    return sportType
        .split('_')
        .map((word) => word[0].toUpperCase() + word.substring(1).toLowerCase())
        .join(' ');
  }

  IconData _getSportIcon(String sportKey) {
    switch (sportKey) {
      case 'football':
        return Icons.sports_soccer;
      case 'basketball':
        return Icons.sports_basketball;
      case 'tennis':
        return Icons.sports_tennis;
      case 'badminton':
        return Icons.sports_tennis;
      case 'volleyball':
        return Icons.sports_volleyball;
      default:
        return Icons.sports;
    }
  }

  SkillLevel _parseSkillLevel(dynamic level) {
    if (level is int) {
      switch (level) {
        case 1:
          return SkillLevel.beginner;
        case 2:
          return SkillLevel.intermediate;
        case 3:
          return SkillLevel.advanced;
        default:
          return SkillLevel.beginner;
      }
    }
    return SkillLevel.beginner;
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Sports Preferences'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
        actions: [
          if (_isLoading)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(16.0),
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
            )
          else
            TextButton(onPressed: _savePreferences, child: const Text('Save')),
        ],
      ),
      body: _isLoading && _sportPreferences.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : FadeTransition(
              opacity: _fadeAnimation,
              child: SlideTransition(
                position: _slideAnimation,
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildHeader(),
                      const SizedBox(height: 24),
                      _buildSportsPreferences(),
                      const SizedBox(height: 24),
                      _buildGeneralPreferences(),
                      const SizedBox(height: 96),
                    ],
                  ),
                ),
              ),
            ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push(RoutePaths.createGame),
        icon: const Icon(Icons.add_circle_outline),
        label: const Text('Create game'),
      ),
    );
  }

  Widget _buildHeader() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.sports_esports,
                  color: Theme.of(context).colorScheme.primary,
                  size: 24,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Sports & Games',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                FilledButton.icon(
                  onPressed: () => context.push(RoutePaths.createGame),
                  icon: const Icon(Icons.add_circle_outline),
                  label: const Text('Create game'),
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Customize your sports preferences and skill levels to get the best game recommendations.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSportsPreferences() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'My Sports',
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'Enable sports you want to play and set your skill level',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 16),
            ..._sportPreferences.entries.map(
              (entry) => _buildSportPreferenceItem(entry.key, entry.value),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSportPreferenceItem(
    String sportKey,
    SportPreference preference,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: ExpansionTile(
        leading: Icon(
          preference.icon,
          color: preference.isEnabled
              ? Theme.of(context).colorScheme.primary
              : Theme.of(context).colorScheme.outline,
        ),
        title: Text(
          preference.name,
          style: TextStyle(
            fontWeight: FontWeight.w500,
            color: preference.isEnabled
                ? Theme.of(context).colorScheme.onSurface
                : Theme.of(context).colorScheme.outline,
          ),
        ),
        subtitle: Text(
          preference.isEnabled ? preference.skillLevel.displayName : 'Disabled',
          style: TextStyle(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
        trailing: Switch(
          value: preference.isEnabled,
          onChanged: (value) {
            setState(() {
              _sportPreferences[sportKey] = preference.copyWith(
                isEnabled: value,
              );
            });
          },
        ),
        children: preference.isEnabled
            ? [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  child: Column(
                    children: [
                      _buildSkillLevelSelector(sportKey, preference),
                      if (preference.preferredPosition != null) ...[
                        const SizedBox(height: 16),
                        _buildPositionSelector(sportKey, preference),
                      ],
                      const SizedBox(height: 16),
                    ],
                  ),
                ),
              ]
            : [],
      ),
    );
  }

  Widget _buildSkillLevelSelector(String sportKey, SportPreference preference) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Skill Level',
          style: Theme.of(
            context,
          ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w500),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: SkillLevel.values.map((level) {
            final isSelected = preference.skillLevel == level;
            return FilterChip(
              label: Text(level.displayName),
              selected: isSelected,
              onSelected: (selected) {
                if (selected) {
                  setState(() {
                    _sportPreferences[sportKey] = preference.copyWith(
                      skillLevel: level,
                    );
                  });
                }
              },
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildPositionSelector(String sportKey, SportPreference preference) {
    final positions = _getPositionsForSport(sportKey);
    if (positions.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Preferred Position',
          style: Theme.of(
            context,
          ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w500),
        ),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          initialValue: preference.preferredPosition,
          decoration: const InputDecoration(
            border: OutlineInputBorder(),
            isDense: true,
          ),
          items: positions.map((position) {
            return DropdownMenuItem(value: position, child: Text(position));
          }).toList(),
          onChanged: (value) {
            setState(() {
              _sportPreferences[sportKey] = preference.copyWith(
                preferredPosition: value,
              );
            });
          },
        ),
      ],
    );
  }

  Widget _buildGeneralPreferences() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'General Preferences',
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            ListTile(
              leading: const Icon(Icons.group_outlined),
              title: const Text('Auto-join compatible games'),
              subtitle: const Text(
                'Automatically join games that match your preferences',
              ),
              trailing: Switch(value: true, onChanged: (value) {}),
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.location_city_outlined),
              title: const Text('Use location for recommendations'),
              subtitle: const Text('Find games near your current location'),
              trailing: Switch(value: true, onChanged: (value) {}),
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.schedule_outlined),
              title: const Text('Flexible timing'),
              subtitle: const Text('Show games with flexible start times'),
              trailing: Switch(value: false, onChanged: (value) {}),
            ),
          ],
        ),
      ),
    );
  }

  List<String> _getPositionsForSport(String sport) {
    switch (sport) {
      case 'football':
        return ['Goalkeeper', 'Defender', 'Midfielder', 'Forward'];
      case 'basketball':
        return [
          'Point Guard',
          'Shooting Guard',
          'Small Forward',
          'Power Forward',
          'Center',
        ];
      case 'volleyball':
        return [
          'Setter',
          'Outside Hitter',
          'Middle Blocker',
          'Opposite Hitter',
          'Libero',
        ];
      default:
        return [];
    }
  }

  Future<void> _savePreferences() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final supabase = Supabase.instance.client;
      final userId = supabase.auth.currentUser?.id;

      if (userId == null) {
        throw Exception('User not authenticated');
      }

      // Get profile_id from user_id
      final profileResponse = await supabase
          .from('profiles')
          .select('id')
          .eq('user_id', userId)
          .maybeSingle();

      if (profileResponse == null) {
        throw Exception('Profile not found');
      }

      final profileId = profileResponse['id'] as String;

      // Delete all existing sports profiles for this user
      await supabase.from('sport_profiles').delete().eq('profile_id', profileId);

      // Insert new/updated sports profiles for enabled sports
      final enabledSports = _sportPreferences.entries
          .where((entry) => entry.value.isEnabled)
          .toList();

      if (enabledSports.isNotEmpty) {
        final sportsData = enabledSports.map((entry) {
          return {
            'profile_id': profileId,
            'sport_key': entry.key.toLowerCase(),
            'skill_level': _skillLevelToInt(entry.value.skillLevel),
            // Note: sport_profiles table uses sport_key, not sport_type
            // Other fields like preferred_position, years_of_experience may need to be in attributes JSONB
          };
        }).toList();

        await supabase.from('sport_profiles').insert(sportsData);
      }

      // Also update the user's preferred sport in the profiles table
      final primarySport = enabledSports.isNotEmpty
          ? enabledSports.first.key
          : null;

      if (primarySport != null) {
        await supabase
            .from('profiles')
            .update({'preferred_sport': primarySport})
            .eq('user_id', userId);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Sports preferences saved successfully'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to save preferences: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  int _skillLevelToInt(SkillLevel level) {
    switch (level) {
      case SkillLevel.beginner:
        return 1;
      case SkillLevel.intermediate:
        return 2;
      case SkillLevel.advanced:
        return 3;
    }
  }
}

/// Model for sport preferences
class SportPreference {
  final String name;
  final IconData icon;
  final bool isEnabled;
  final SkillLevel skillLevel;
  final String? preferredPosition;

  const SportPreference({
    required this.name,
    required this.icon,
    required this.isEnabled,
    required this.skillLevel,
    this.preferredPosition,
  });

  SportPreference copyWith({
    String? name,
    IconData? icon,
    bool? isEnabled,
    SkillLevel? skillLevel,
    String? preferredPosition,
  }) {
    return SportPreference(
      name: name ?? this.name,
      icon: icon ?? this.icon,
      isEnabled: isEnabled ?? this.isEnabled,
      skillLevel: skillLevel ?? this.skillLevel,
      preferredPosition: preferredPosition ?? this.preferredPosition,
    );
  }
}

/// Enum for skill levels
enum SkillLevel {
  beginner,
  intermediate,
  advanced;

  String get displayName {
    switch (this) {
      case SkillLevel.beginner:
        return 'Beginner';
      case SkillLevel.intermediate:
        return 'Intermediate';
      case SkillLevel.advanced:
        return 'Advanced';
    }
  }
}
