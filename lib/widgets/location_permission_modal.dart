import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../core/services/location_service.dart';
import '../widgets/custom_button.dart';

class LocationPermissionModal extends StatelessWidget {
  final VoidCallback? onLocationEnabled;
  final Function(String)? onManualLocationSet;
  final VoidCallback? onCancel;

  const LocationPermissionModal({
    super.key,
    this.onLocationEnabled,
    this.onManualLocationSet,
    this.onCancel,
  });

  static Future<void> show(
    BuildContext context, {
    VoidCallback? onLocationEnabled,
    Function(String)? onManualLocationSet,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => LocationPermissionModal(
        onLocationEnabled: onLocationEnabled,
        onManualLocationSet: onManualLocationSet,
        onCancel: () => Navigator.pop(context),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
        top: 20,
        left: 20,
        right: 20,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle bar
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.onSurfaceVariant.withOpacity(0.4),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 24),

          // Icon
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(
              LucideIcons.mapPin,
              size: 32,
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
          const SizedBox(height: 20),

          // Title
          Text(
            'Location Access Required',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w700,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),

          // Description
          Text(
            'To find nearby games and venues, we need access to your location. You can also set your area manually.',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
              height: 1.4,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),

          // Enable Location Button
          SizedBox(
            width: double.infinity,
            child: CustomButton(
              text: 'Enable Location',
              onPressed: () async {
                Navigator.pop(context);
                final locationService = LocationService();
                await locationService.fetchLocation();
                onLocationEnabled?.call();
              },
              variant: ButtonVariant.primary,
              size: ButtonSize.large,
              icon: LucideIcons.navigation,
            ),
          ),
          const SizedBox(height: 12),

          // Manual Location Button
          SizedBox(
            width: double.infinity,
            child: CustomButton(
              text: 'Set Area Manually',
              onPressed: () {
                Navigator.pop(context);
                _showManualLocationDialog(context);
              },
              variant: ButtonVariant.secondary,
              size: ButtonSize.large,
              icon: LucideIcons.edit,
            ),
          ),
          const SizedBox(height: 12),

          // Cancel Button
          TextButton(
            onPressed: onCancel,
            child: Text(
              'Cancel',
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  void _showManualLocationDialog(BuildContext context) {
    final controller = TextEditingController();
    final commonAreas = [
      'Dubai Marina',
      'JLT (Jumeirah Lake Towers)',
      'Downtown Dubai',
      'Business Bay',
      'DIFC',
      'Jumeirah',
      'Al Barsha',
      'Motor City',
      'Sports City',
      'Sharjah',
      'Abu Dhabi',
    ];

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Set Your Area'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: controller,
              decoration: const InputDecoration(
                labelText: 'Enter your area',
                hintText: 'e.g., Dubai Marina, JLT',
                border: OutlineInputBorder(),
              ),
              autofocus: true,
            ),
            const SizedBox(height: 16),
            Text(
              'Popular areas:',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: commonAreas.take(6).map((area) {
                return ActionChip(
                  label: Text(
                    area,
                    style: const TextStyle(fontSize: 12),
                  ),
                  onPressed: () {
                    controller.text = area;
                  },
                );
              }).toList(),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              final area = controller.text.trim();
              if (area.isNotEmpty) {
                Navigator.pop(context);
                onManualLocationSet?.call(area);
              }
            },
            child: const Text('Set Area'),
          ),
        ],
      ),
    );
  }
} 