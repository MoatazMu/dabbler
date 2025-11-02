import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:dabbler/themes/app_theme.dart';
import 'package:dabbler/features/social/services/social_service.dart';
import 'package:dabbler/utils/enums/social_enums.dart';
import 'package:dabbler/widgets/custom_app_bar.dart';

class AddPostScreen extends StatefulWidget {
  const AddPostScreen({super.key});

  @override
  State<AddPostScreen> createState() => _AddPostScreenState();
}

class _AddPostScreenState extends State<AddPostScreen> {
  final _textController = TextEditingController();
  final _imagePicker = ImagePicker();

  final List<XFile> _selectedImages = [];
  String _selectedLocation = '';

  final List<String> _quickLocations = [
    'Dubai Sports City',
    'JLT Tennis Court',
    'Al Wasl Sports Club',
    'Dubai Marina Beach',
    'Zabeel Park',
  ];

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: CustomAppBar(
        actionIcon: Iconsax.document_upload_copy,
        onActionPressed: _canPost() ? _handlePost : null,
      ),
      body: Column(
        children: [
          const SizedBox(height: 100), // Space for app bar
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Text Input
                  TextField(
                    controller: _textController,
                    maxLines: null,
                    minLines: 4,
                    style: const TextStyle(
                      color: Color(0xFFEBD7FA),
                      fontFamily: 'Inter',
                      fontSize: 16,
                      fontWeight: FontWeight.w400,
                      letterSpacing: -0.312,
                    ),
                    decoration: InputDecoration(
                      hintText: "What's on your mind?",
                      hintStyle: TextStyle(
                        color: const Color(0xFFEBD7FA).withOpacity(0.70),
                        fontFamily: 'Inter',
                        fontSize: 16,
                        fontWeight: FontWeight.w400,
                        letterSpacing: -0.312,
                      ),
                      filled: true,
                      fillColor: const Color(0xFF301C4D),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(22),
                        borderSide: BorderSide(
                          color: const Color(0xFFEBD7FA).withOpacity(0.24),
                          width: 1,
                        ),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(22),
                        borderSide: BorderSide(
                          color: const Color(0xFFEBD7FA).withOpacity(0.24),
                          width: 1,
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(22),
                        borderSide: BorderSide(
                          color: const Color(0xFFEBD7FA).withOpacity(0.5),
                          width: 1.5,
                        ),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 18,
                        vertical: 24,
                      ),
                    ),
                    onChanged: (_) => setState(() {}),
                  ),

                  const SizedBox(height: 20),

                  // Images Section
                  if (_selectedImages.isNotEmpty) ...[
                    Text(
                      'Photos (${_selectedImages.length})',
                      style: context.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: context.colors.onSurface,
                      ),
                    ),
                    const SizedBox(height: 12),
                    _buildImageGrid(),
                    const SizedBox(height: 20),
                  ],

                  // Location Section
                  if (_selectedLocation.isNotEmpty) ...[
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: context.colors.surfaceContainerHighest
                            .withOpacity(0.5),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            LucideIcons.mapPin,
                            size: 16,
                            color: context.colors.primary,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              _selectedLocation,
                              style: context.textTheme.bodyMedium?.copyWith(
                                color: context.colors.onSurface,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                          IconButton(
                            icon: Icon(
                              LucideIcons.x,
                              size: 16,
                              color: context.colors.onSurfaceVariant,
                            ),
                            onPressed: () =>
                                setState(() => _selectedLocation = ''),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],

                  // Quick Location Suggestions
                  if (_selectedLocation.isEmpty) ...[
                    Text(
                      'Add Location',
                      style: context.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: context.colors.onSurface,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: _quickLocations.map((location) {
                        return GestureDetector(
                          onTap: () =>
                              setState(() => _selectedLocation = location),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color: context.colors.surfaceContainerHighest
                                  .withOpacity(0.3),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: context.colors.outline.withOpacity(0.2),
                              ),
                            ),
                            child: Text(
                              location,
                              style: context.textTheme.bodySmall?.copyWith(
                                color: context.colors.onSurface,
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 20),
                  ],
                ],
              ),
            ),
          ),

          // Bottom Action Bar
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: context.colors.surface,
              border: Border(
                top: BorderSide(
                  color: context.colors.outline.withOpacity(0.1),
                  width: 1,
                ),
              ),
            ),
            child: Row(
              children: [
                _buildActionButton(
                  icon: LucideIcons.image,
                  label: 'Photo',
                  onTap: _pickImages,
                ),
                const SizedBox(width: 16),
                _buildActionButton(
                  icon: LucideIcons.mapPin,
                  label: 'Location',
                  onTap: _showLocationPicker,
                ),
                const SizedBox(width: 16),
                _buildActionButton(
                  icon: LucideIcons.tag,
                  label: 'Tag',
                  onTap: () => _showComingSoon('Tag Friends'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildImageGrid() {
    return SizedBox(
      height: 120,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: _selectedImages.length,
        itemBuilder: (context, index) {
          return Container(
            margin: const EdgeInsets.only(right: 8),
            child: Stack(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.file(
                    File(_selectedImages[index].path),
                    width: 120,
                    height: 120,
                    fit: BoxFit.cover,
                  ),
                ),
                Positioned(
                  top: 4,
                  right: 4,
                  child: GestureDetector(
                    onTap: () => _removeImage(index),
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.6),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        LucideIcons.x,
                        size: 16,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: context.colors.surfaceContainerHighest.withOpacity(0.3),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 18, color: context.colors.primary),
            const SizedBox(width: 6),
            Text(
              label,
              style: context.textTheme.bodyMedium?.copyWith(
                color: context.colors.onSurface,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  bool _canPost() {
    return _textController.text.trim().isNotEmpty || _selectedImages.isNotEmpty;
  }

  Future<void> _pickImages() async {
    try {
      final List<XFile> images = await _imagePicker.pickMultipleMedia();
      if (images.isNotEmpty) {
        setState(() {
          _selectedImages.addAll(images);
        });
      }
    } catch (e) {
      _showError('Failed to pick images');
    }
  }

  void _removeImage(int index) {
    setState(() {
      _selectedImages.removeAt(index);
    });
  }

  void _showLocationPicker() {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Select Location',
              style: context.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 16),
            ..._quickLocations.map((location) {
              return ListTile(
                leading: Icon(
                  LucideIcons.mapPin,
                  color: context.colors.primary,
                ),
                title: Text(location),
                onTap: () {
                  setState(() => _selectedLocation = location);
                  Navigator.pop(context);
                },
              );
            }),
          ],
        ),
      ),
    );
  }

  Future<void> _handlePost() async {
    if (!_canPost()) return;

    try {
      final socialService = SocialService();

      // Upload images if any
      List<String> mediaUrls = [];
      if (_selectedImages.isNotEmpty) {
        final imagePaths = _selectedImages.map((xFile) => xFile.path).toList();
        mediaUrls = await socialService.uploadImages(imagePaths);
      }

      // Create the post
      await socialService.createPost(
        content: _textController.text.trim(),
        mediaUrls: mediaUrls,
        locationName: _selectedLocation.isNotEmpty ? _selectedLocation : null,
        visibility: PostVisibility.public,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(LucideIcons.check, color: Colors.white, size: 16),
                const SizedBox(width: 8),
                const Text('Post shared successfully!'),
              ],
            ),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            margin: const EdgeInsets.all(16),
          ),
        );
        context.pop();
      }
    } catch (e) {
      _showError('Failed to share post: $e');
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(LucideIcons.alertCircle, color: Colors.white, size: 16),
            const SizedBox(width: 8),
            Text(message),
          ],
        ),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  void _showComingSoon(String feature) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(LucideIcons.clock, color: Colors.white, size: 16),
            const SizedBox(width: 8),
            Text('$feature coming soon!'),
          ],
        ),
        backgroundColor: context.colors.primary,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        margin: const EdgeInsets.all(16),
        duration: const Duration(seconds: 2),
      ),
    );
  }
}
