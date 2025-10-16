import 'dart:async';
import 'package:flutter/material.dart';
import '../../helpers/profile_helpers/profile_completion_helper.dart';

/// Mixin for managing profile completion tracking and UI components
mixin ProfileCompletionMixin<T extends StatefulWidget> on State<T> {
  double _completionPercentage = 0.0;
  List<String> _missingFields = [];
  Timer? _updateTimer;
  UserProfile? _currentProfile;
  bool _isLoading = false;
  
  /// Initialize profile completion tracking with periodic updates
  void initProfileCompletion(UserProfile profile) {
    _currentProfile = profile;
    _updateCompletion(profile);
    
    // Update periodically while on screen to catch external changes
    _updateTimer = Timer.periodic(
      const Duration(seconds: 30),
      (_) => _updateCompletion(profile),
    );
  }
  
  /// Update completion percentage and missing fields
  void _updateCompletion(UserProfile profile) {
    if (!mounted) return;
    
    setState(() {
      _completionPercentage = ProfileCompletionHelper
          .calculateCompletion(profile).toDouble();
      _missingFields = ProfileCompletionHelper.getMissingFields(profile);
      _isLoading = false;
    });
  }
  
  /// Manually trigger completion recalculation
  void refreshCompletion() {
    if (_currentProfile != null) {
      setState(() {
        _isLoading = true;
      });
      _updateCompletion(_currentProfile!);
    }
  }
  
  /// Build circular progress indicator for completion percentage
  Widget buildCompletionIndicator({
    double size = 60,
    double strokeWidth = 4,
    bool showPercentage = true,
    TextStyle? textStyle,
  }) {
    final textSize = textStyle?.fontSize ?? size * 0.25;
    
    return Stack(
      alignment: Alignment.center,
      children: [
        SizedBox(
          width: size,
          height: size,
          child: _isLoading
              ? CircularProgressIndicator(
                  strokeWidth: strokeWidth,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.grey[400]!),
                )
              : CircularProgressIndicator(
                  value: _completionPercentage / 100,
                  strokeWidth: strokeWidth,
                  backgroundColor: Colors.grey[300],
                  valueColor: AlwaysStoppedAnimation<Color>(
                    _getCompletionColor(),
                  ),
                ),
        ),
        if (showPercentage && !_isLoading)
          Text(
            '${_completionPercentage.round()}%',
            style: textStyle ?? TextStyle(
              fontSize: textSize,
              fontWeight: FontWeight.bold,
              color: _getCompletionColor(),
            ),
          ),
        if (_isLoading)
          Icon(
            Icons.refresh,
            size: size * 0.3,
            color: Colors.grey[600],
          ),
      ],
    );
  }
  
  /// Build linear progress indicator
  Widget buildLinearCompletionIndicator({
    double height = 8,
    bool showPercentage = false,
    EdgeInsetsGeometry? padding,
  }) {
    return Container(
      padding: padding ?? const EdgeInsets.symmetric(vertical: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (showPercentage)
            Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Text(
                'Profile ${_completionPercentage.round()}% Complete',
                style: TextStyle(
                  fontSize: 12,
                  color: _getCompletionColor(),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          Container(
            height: height,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(height / 2),
              color: Colors.grey[300],
            ),
            child: FractionallySizedBox(
              alignment: Alignment.centerLeft,
              widthFactor: _completionPercentage / 100,
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(height / 2),
                  color: _getCompletionColor(),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  /// Get color based on completion percentage
  Color _getCompletionColor() {
    if (_completionPercentage >= 85) return const Color(0xFF4CAF50); // Green
    if (_completionPercentage >= 70) return const Color(0xFF2196F3); // Blue
    if (_completionPercentage >= 50) return const Color(0xFFFF9800); // Orange
    if (_completionPercentage >= 25) return const Color(0xFFFF5722); // Deep Orange
    return const Color(0xFFF44336); // Red
  }
  
  /// Get completion status text
  String get completionStatusText {
    if (_completionPercentage >= 95) return 'Profile Complete!';
    if (_completionPercentage >= 85) return 'Almost Done!';
    if (_completionPercentage >= 70) return 'Good Progress';
    if (_completionPercentage >= 50) return 'Getting There';
    if (_completionPercentage >= 25) return 'Getting Started';
    return 'Just Started';
  }
  
  /// Get completion status icon
  IconData get completionStatusIcon {
    if (_completionPercentage >= 95) return Icons.check_circle;
    if (_completionPercentage >= 85) return Icons.trending_up;
    if (_completionPercentage >= 70) return Icons.thumb_up;
    if (_completionPercentage >= 50) return Icons.more_horiz;
    if (_completionPercentage >= 25) return Icons.play_arrow;
    return Icons.info_outline;
  }
  
  /// Show completion tips modal bottom sheet
  void showCompletionTips({
    bool showImmediateActions = true,
    VoidCallback? onFieldTapped,
  }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => Container(
        padding: EdgeInsets.only(
          left: 16,
          right: 16,
          top: 16,
          bottom: MediaQuery.of(context).viewInsets.bottom + 16,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Handle bar
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            
            // Header
            Row(
              children: [
                Icon(
                  completionStatusIcon,
                  color: _getCompletionColor(),
                  size: 28,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Complete Your Profile',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        completionStatusText,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: _getCompletionColor(),
                        ),
                      ),
                    ],
                  ),
                ),
                buildCompletionIndicator(size: 50, showPercentage: true),
              ],
            ),
            const SizedBox(height: 20),
            
            // Progress indicator
            buildLinearCompletionIndicator(showPercentage: true),
            const SizedBox(height: 20),
            
            // Missing fields or completion message
            if (_missingFields.isEmpty)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.green[50],
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.green[200]!),
                ),
                child: Row(
                  children: [
                    Icon(Icons.celebration, color: Colors.green[600]),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Your profile is complete! You\'re ready to connect with other players.',
                        style: TextStyle(color: Colors.green[700]),
                      ),
                    ),
                  ],
                ),
              )
            else
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Complete these fields to improve your profile:',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 12),
                  ..._missingFields.take(5).map((field) => _buildMissingFieldTile(
                    field,
                    onTap: () {
                      Navigator.pop(context);
                      onFieldTapped?.call();
                      _navigateToField(field);
                    },
                  )),
                  
                  if (_missingFields.length > 5)
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Text(
                        'Plus ${_missingFields.length - 5} more fields...',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ),
                ],
              ),
            
            const SizedBox(height: 20),
            
            // Action buttons
            if (showImmediateActions && _missingFields.isNotEmpty)
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Later'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.pop(context);
                        _navigateToField(_missingFields.first);
                      },
                      child: const Text('Complete Now'),
                    ),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }
  
  /// Build tile for missing field
  Widget _buildMissingFieldTile(String field, {VoidCallback? onTap}) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: Colors.orange[50],
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(
          _getFieldIcon(field),
          color: Colors.orange[600],
          size: 20,
        ),
      ),
      title: Text(_getFieldDisplayName(field)),
      subtitle: Text(_getFieldDescription(field)),
      trailing: const Icon(Icons.arrow_forward_ios, size: 16),
      onTap: onTap,
    );
  }
  
  /// Get icon for field type
  IconData _getFieldIcon(String field) {
    switch (field.toLowerCase()) {
      case 'profile_picture':
      case 'avatar':
        return Icons.photo_camera;
      case 'bio':
      case 'description':
        return Icons.description;
      case 'location':
        return Icons.location_on;
      case 'phone':
      case 'phone_number':
        return Icons.phone;
      case 'date_of_birth':
      case 'birthday':
        return Icons.cake;
      case 'sports':
        return Icons.sports;
      case 'height':
      case 'weight':
        return Icons.fitness_center;
      default:
        return Icons.edit;
    }
  }
  
  /// Get display name for field
  String _getFieldDisplayName(String field) {
    switch (field.toLowerCase()) {
      case 'profile_picture':
        return 'Profile Picture';
      case 'date_of_birth':
        return 'Date of Birth';
      case 'phone_number':
        return 'Phone Number';
      default:
        return field.replaceAll('_', ' ').split(' ')
            .map((word) => word.isEmpty ? '' : '${word[0].toUpperCase()}${word.substring(1)}')
            .join(' ');
    }
  }
  
  /// Get description for field
  String _getFieldDescription(String field) {
    switch (field.toLowerCase()) {
      case 'profile_picture':
        return 'Add a profile picture to help others recognize you';
      case 'bio':
        return 'Tell others about yourself and your interests';
      case 'location':
        return 'Help players find you for local games';
      case 'sports':
        return 'Add the sports you play and your skill levels';
      case 'phone_number':
        return 'Optional contact information';
      case 'date_of_birth':
        return 'Help find age-appropriate matches';
      default:
        return 'Complete this field to improve your profile';
    }
  }
  
  /// Navigate to appropriate field editing screen
  void _navigateToField(String field) {
    // This should be overridden by the implementing widget or use a router
    // TODO: Implement navigation logic
    
    // Example navigation (would be customized per app)
    switch (field.toLowerCase()) {
      case 'profile_picture':
        // Navigator.pushNamed(context, '/profile/edit/photo');
        break;
      case 'bio':
        // Navigator.pushNamed(context, '/profile/edit/bio');
        break;
      case 'sports':
        // Navigator.pushNamed(context, '/profile/edit/sports');
        break;
      default:
        // Navigator.pushNamed(context, '/profile/edit');
        break;
    }
  }
  
  /// Show completion celebration when profile reaches 100%
  void showCompletionCelebration() {
    if (_completionPercentage >= 95) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.celebration, color: Colors.orange),
              SizedBox(width: 8),
              Text('Congratulations!'),
            ],
          ),
          content: const Text(
            'Your profile is now complete! You can now fully enjoy all features and connect with other players.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Awesome!'),
            ),
          ],
        ),
      );
    }
  }
  
  /// Get completion rewards/benefits text
  List<String> get completionBenefits {
    if (_completionPercentage >= 95) {
      return [
        '✓ Full access to all features',
        '✓ Better match recommendations',
        '✓ Increased profile visibility',
        '✓ Priority in game invitations',
      ];
    } else if (_completionPercentage >= 70) {
      return [
        '✓ Good match recommendations',
        '✓ Most features available',
        '• Complete profile for full benefits',
      ];
    } else {
      return [
        '• Complete profile for better matches',
        '• Add sports to find teammates',
        '• Upload photo to stand out',
      ];
    }
  }
  
  /// Check if specific field is missing
  bool isFieldMissing(String field) {
    return _missingFields.contains(field);
  }
  
  /// Get completion percentage
  double get completionPercentage => _completionPercentage;
  
  /// Get missing fields list
  List<String> get missingFields => List.from(_missingFields);
  
  /// Check if profile is substantially complete (>= 70%)
  bool get isProfileSubstantiallyComplete => _completionPercentage >= 70;
  
  /// Check if profile is fully complete (>= 95%)
  bool get isProfileFullyComplete => _completionPercentage >= 95;
  
  @override
  void dispose() {
    _updateTimer?.cancel();
    super.dispose();
  }
}
