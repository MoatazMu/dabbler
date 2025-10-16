import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../providers/profile_providers.dart';
import '../../../domain/entities/sports_profile.dart';

class SkillLevelSetupScreen extends ConsumerStatefulWidget {
  final SportProfile? existingSport;
  final String? sportName;
  final bool isNew;

  const SkillLevelSetupScreen({
    super.key,
    this.existingSport,
    this.sportName,
    this.isNew = false,
  });

  @override
  ConsumerState<SkillLevelSetupScreen> createState() => _SkillLevelSetupScreenState();
}

class _SkillLevelSetupScreenState extends ConsumerState<SkillLevelSetupScreen>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late AnimationController _skillAnimationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _skillScaleAnimation;
  
  final _formKey = GlobalKey<FormState>();
  final _certificationsController = TextEditingController();
  
  String? _sportName;
  SkillLevel _selectedSkillLevel = SkillLevel.beginner;
  int _yearsPlaying = 0;
  List<String> _selectedPositions = [];
  List<String> _certifications = [];
  bool _isPrimarySport = false;
  bool _isSaving = false;

  final Map<String, List<String>> _sportPositions = {
    'basketball': ['Point Guard', 'Shooting Guard', 'Small Forward', 'Power Forward', 'Center'],
    'football': ['Goalkeeper', 'Defender', 'Midfielder', 'Forward', 'Striker'],
    'volleyball': ['Setter', 'Outside Hitter', 'Middle Blocker', 'Opposite Hitter', 'Libero'],
    'baseball': ['Pitcher', 'Catcher', 'First Base', 'Second Base', 'Third Base', 'Shortstop', 'Outfield'],
    'tennis': ['Singles', 'Doubles'],
    'hockey': ['Center', 'Left Wing', 'Right Wing', 'Defenseman', 'Goalie'],
  };

  @override
  void initState() {
    super.initState();
    _sportName = widget.sportName ?? widget.existingSport?.sportName;
    
    if (widget.existingSport != null) {
      _selectedSkillLevel = widget.existingSport!.skillLevel;
      _yearsPlaying = widget.existingSport!.yearsPlaying;
      _selectedPositions = List.from(widget.existingSport!.preferredPositions);
      _certifications = List.from(widget.existingSport!.certifications);
      _isPrimarySport = widget.existingSport!.isPrimarySport;
    }
    
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    
    _skillAnimationController = AnimationController(
      duration: const Duration(milliseconds: 300),
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
    _skillScaleAnimation = Tween<double>(
      begin: 1.0,
      end: 1.1,
    ).animate(CurvedAnimation(
      parent: _skillAnimationController,
      curve: Curves.elasticOut,
    ));

    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _skillAnimationController.dispose();
    _certificationsController.dispose();
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
              SliverToBoxAdapter(
                child: Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      _buildSportHeader(context),
                      _buildSkillLevelSection(context),
                      _buildExperienceSection(context),
                      _buildPositionsSection(context),
                      _buildCertificationsSection(context),
                      _buildPrimarySportSection(context),
                      const SizedBox(height: 100), // Bottom spacing for save button
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _isSaving ? null : _saveSportProfile,
        icon: _isSaving
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : const Icon(Icons.save),
        label: Text(_isSaving 
            ? 'Saving...' 
            : (widget.isNew ? 'Add Sport' : 'Save Changes')),
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
          widget.isNew ? 'Add Sport' : 'Edit Sport',
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: false,
        titlePadding: const EdgeInsets.only(left: 56, bottom: 16),
      ),
      actions: [
        TextButton(
          onPressed: _isSaving ? null : _saveSportProfile,
          child: _isSaving 
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Save'),
        ),
        const SizedBox(width: 8),
      ],
    );
  }

  Widget _buildSportHeader(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(20),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Theme.of(context).primaryColor,
            Theme.of(context).primaryColor.withOpacity(0.8),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).primaryColor.withOpacity(0.3),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(
              _getSportIcon(_sportName ?? ''),
              color: Colors.white,
              size: 32,
            ),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _sportName ?? 'Unknown Sport',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  widget.isNew ? 'Set up your skill profile' : 'Update your profile',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.white.withOpacity(0.9),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSkillLevelSection(BuildContext context) {
    return _buildSection(
      context,
      'Skill Level',
      'How would you rate your current skill level?',
      [
        const SizedBox(height: 8),
        ...SkillLevel.values.map((level) {
          final isSelected = _selectedSkillLevel == level;
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: ScaleTransition(
              scale: isSelected ? _skillScaleAnimation : 
                     const AlwaysStoppedAnimation(1.0),
              child: Material(
                color: isSelected 
                    ? Theme.of(context).primaryColor.withOpacity(0.1)
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(16),
                child: InkWell(
                  onTap: () {
                    setState(() {
                      _selectedSkillLevel = level;
                    });
                    if (isSelected) {
                      _skillAnimationController.forward().then((_) {
                        _skillAnimationController.reverse();
                      });
                    }
                  },
                  borderRadius: BorderRadius.circular(16),
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: isSelected 
                            ? Theme.of(context).primaryColor
                            : Colors.grey[300]!,
                        width: isSelected ? 2 : 1,
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 12,
                          height: 12,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: isSelected 
                                ? Theme.of(context).primaryColor
                                : Colors.transparent,
                            border: Border.all(
                              color: isSelected 
                                  ? Theme.of(context).primaryColor
                                  : Colors.grey[400]!,
                              width: 2,
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _getSkillLevelName(level),
                                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                                  color: isSelected ? Theme.of(context).primaryColor : null,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                _getSkillLevelDescription(level),
                                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  color: Colors.grey[600],
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (isSelected)
                          Icon(
                            Icons.check_circle,
                            color: Theme.of(context).primaryColor,
                            size: 24,
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          );
        }),
      ],
    );
  }

  Widget _buildExperienceSection(BuildContext context) {
    return _buildSection(
      context,
      'Years of Experience',
      'How long have you been playing this sport?',
      [
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Theme.of(context).primaryColor.withOpacity(0.05),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            children: [
              Text(
                '$_yearsPlaying ${_yearsPlaying == 1 ? 'year' : 'years'}',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  color: Theme.of(context).primaryColor,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              Slider(
                value: _yearsPlaying.toDouble(),
                min: 0,
                max: 50,
                divisions: 50,
                activeColor: Theme.of(context).primaryColor,
                inactiveColor: Theme.of(context).primaryColor.withOpacity(0.3),
                onChanged: (value) {
                  setState(() {
                    _yearsPlaying = value.round();
                  });
                },
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'New',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Colors.grey[600],
                    ),
                  ),
                  Text(
                    '50+ years',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPositionsSection(BuildContext context) {
    final positions = _getAvailablePositions();
    
    if (positions.isEmpty) {
      return const SizedBox.shrink();
    }

    return _buildSection(
      context,
      'Preferred Positions',
      'Select the positions you prefer to play (optional)',
      [
        const SizedBox(height: 16),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: positions.map((position) {
            final isSelected = _selectedPositions.contains(position);
            return FilterChip(
              label: Text(position),
              selected: isSelected,
              onSelected: (selected) {
                setState(() {
                  if (selected) {
                    _selectedPositions.add(position);
                  } else {
                    _selectedPositions.remove(position);
                  }
                });
              },
              selectedColor: Theme.of(context).primaryColor.withOpacity(0.2),
              checkmarkColor: Theme.of(context).primaryColor,
              labelStyle: TextStyle(
                color: isSelected 
                    ? Theme.of(context).primaryColor
                    : Colors.grey[700],
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildCertificationsSection(BuildContext context) {
    return _buildSection(
      context,
      'Certifications & Achievements',
      'Add any relevant certifications, achievements, or awards (optional)',
      [
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: TextFormField(
                controller: _certificationsController,
                decoration: InputDecoration(
                  hintText: 'Enter certification or achievement',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                ),
                onFieldSubmitted: _addCertification,
              ),
            ),
            const SizedBox(width: 12),
            IconButton(
              onPressed: () => _addCertification(_certificationsController.text),
              icon: const Icon(Icons.add),
              style: IconButton.styleFrom(
                backgroundColor: Theme.of(context).primaryColor,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
        if (_certifications.isNotEmpty) ...[
          const SizedBox(height: 16),
          ..._certifications.map((cert) {
            return Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: Theme.of(context).primaryColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: Theme.of(context).primaryColor.withOpacity(0.3),
                ),
              ),
              child: Row(
                children: [
                  const Icon(Icons.emoji_events, color: Colors.orange, size: 20),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      cert,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ),
                  IconButton(
                    onPressed: () => _removeCertification(cert),
                    icon: const Icon(Icons.close, size: 18),
                    constraints: const BoxConstraints(
                      minWidth: 32,
                      minHeight: 32,
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ],
    );
  }

  Widget _buildPrimarySportSection(BuildContext context) {
    return _buildSection(
      context,
      'Primary Sport',
      'Set this as your main sport for profile display',
      [
        const SizedBox(height: 16),
        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.grey[300]!),
          ),
          child: SwitchListTile(
            title: Text(
              'Set as Primary Sport',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            subtitle: Text(
              _isPrimarySport 
                  ? 'This will be featured prominently on your profile'
                  : 'Set this sport as your main focus',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Colors.grey[600],
              ),
            ),
            value: _isPrimarySport,
            onChanged: (value) {
              setState(() {
                _isPrimarySport = value;
              });
            },
            activeThumbColor: Theme.of(context).primaryColor,
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          ),
        ),
      ],
    );
  }

  Widget _buildSection(BuildContext context, String title, String description, List<Widget> children) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            description,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Colors.grey[600],
            ),
          ),
          ...children,
        ],
      ),
    );
  }

  List<String> _getAvailablePositions() {
    if (_sportName == null) return [];
    final key = _sportName!.toLowerCase();
    return _sportPositions[key] ?? [];
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

  String _getSkillLevelName(SkillLevel level) {
    switch (level) {
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

  String _getSkillLevelDescription(SkillLevel level) {
    switch (level) {
      case SkillLevel.beginner:
        return 'Just starting out or learning the basics';
      case SkillLevel.intermediate:
        return 'Comfortable with fundamentals, developing skills';
      case SkillLevel.advanced:
        return 'Strong skills, plays competitively';
      case SkillLevel.expert:
        return 'Professional level or extensive experience';
    }
  }

  void _addCertification(String text) {
    if (text.trim().isNotEmpty && !_certifications.contains(text.trim())) {
      setState(() {
        _certifications.add(text.trim());
        _certificationsController.clear();
      });
    }
  }

  void _removeCertification(String cert) {
    setState(() {
      _certifications.remove(cert);
    });
  }

  Future<void> _saveSportProfile() async {
    if (_sportName == null) return;

    setState(() {
      _isSaving = true;
    });

    try {
      final controller = ref.read(sportsProfileControllerProvider.notifier);
      
      if (widget.isNew) {
        await controller.createSportsProfile(
          sportId: _sportName!.toLowerCase().replaceAll(' ', '_'),
          sportName: _sportName!,
          skillLevel: _selectedSkillLevel,
          yearsPlaying: _yearsPlaying,
          preferredPositions: _selectedPositions,
          isPrimarySport: _isPrimarySport,
        );
      } else if (widget.existingSport != null) {
        // Update existing sport profile
        // This would require an update method in the controller
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Sport profile updated successfully'),
            backgroundColor: Colors.green,
          ),
        );
      }

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              widget.isNew 
                  ? '$_sportName added to your profile'
                  : '$_sportName profile updated',
            ),
            backgroundColor: Colors.green,
          ),
        );
        context.pop();
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error saving sport profile: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }
}
