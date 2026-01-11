import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:dabbler/core/config/supabase_config.dart';
import 'package:dabbler/core/services/auth_service.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:dabbler/core/design_system/layouts/single_section_layout.dart';
import 'package:dabbler/themes/material3_extensions.dart';
import 'package:image_picker/image_picker.dart';
import 'package:dabbler/core/widgets/custom_avatar.dart';
import 'package:dabbler/features/profile/services/image_upload_service.dart';
import 'package:dabbler/core/utils/validators.dart';
import 'package:dabbler/core/utils/helpers.dart';
import 'package:dabbler/core/utils/constants.dart';
import 'package:dabbler/core/config/feature_flags.dart';

/// Screen for editing user profile information
class ProfileEditScreen extends StatefulWidget {
  const ProfileEditScreen({super.key});

  @override
  State<ProfileEditScreen> createState() => _ProfileEditScreenState();
}

class _ProfileEditScreenState extends State<ProfileEditScreen> {
  final _formKey = GlobalKey<FormState>();
  final _displayNameController = TextEditingController();
  final _phoneController = TextEditingController();

  String? _avatarPath;
  String? _avatarUrl;
  bool _isUploadingAvatar = false;

  String? _selectedGender;
  List<String> _selectedSports = [];

  String _normalizeSportKey(String value) {
    return value.trim().toLowerCase().replaceAll(RegExp(r'[\s-]+'), '_');
  }

  List<String> get _genderOptions {
    const base = ['male', 'female'];
    final current = _selectedGender;
    if (current != null && current.isNotEmpty && !base.contains(current)) {
      return [...base, current];
    }
    return base;
  }

  bool _isLoading = false;
  late AuthService _authService;

  @override
  void initState() {
    super.initState();
    _authService = AuthService();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    setState(() => _isLoading = true);

    try {
      final user = _authService.getCurrentUser();
      if (user?.id == null) return;

      final response = await Supabase.instance.client
          .from(SupabaseConfig.usersTable) // 'profiles' table
          .select()
          .eq('user_id', user!.id) // Match by user_id FK
          .maybeSingle();

      if (!mounted) return;

      if (response != null) {
        _displayNameController.text =
            (response['display_name'] as String?) ?? '';
        _phoneController.text = (response['phone'] as String?) ?? '';
        _selectedGender = (response['gender'] as String?)?.toLowerCase();
        _avatarPath = response['avatar_url'] as String?;
        _avatarUrl = _avatarPath == null
            ? null
            : Supabase.instance.client.storage
                  .from(SupabaseConfig.avatarsBucket)
                  .getPublicUrl(_avatarPath!);

        if (response['sports'] != null) {
          final sports = response['sports'];
          if (sports is List) {
            _selectedSports = sports
                .cast<String>()
                .map(_normalizeSportKey)
                .toSet()
                .toList();
          }
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error loading profile: $e')));
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _pickAndUploadAvatar() async {
    if (_isUploadingAvatar) return;

    final user = _authService.getCurrentUser();
    if (user == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please sign in to update your avatar')),
        );
      }
      return;
    }

    try {
      final picked = await ImagePicker().pickImage(source: ImageSource.gallery);
      if (picked == null) return;

      setState(() => _isUploadingAvatar = true);

      final uploadService = ImageUploadService();
      final bytes = await picked.readAsBytes();
      final uploadResult = await uploadService.uploadProfileImageBytes(
        userId: user.id,
        bytes: bytes,
        originalFileName: picked.name,
      );

      await _authService.updateUserProfile(avatarUrl: uploadResult.path);

      if (!mounted) return;
      setState(() {
        _avatarPath = uploadResult.path;
        _avatarUrl = uploadResult.url;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Avatar updated successfully')),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error updating avatar: $e')));
      }
    } finally {
      if (mounted) {
        setState(() => _isUploadingAvatar = false);
      }
    }
  }

  @override
  void dispose() {
    _displayNameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Widget _buildGenderSelect(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final selected = _selectedGender ?? '';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Gender',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.w500,
            color: colorScheme.onSurface,
            fontSize: 15,
          ),
        ),
        const SizedBox(height: 8),
        // Gender is not editable from this screen.
        AbsorbPointer(
          absorbing: true,
          child: Opacity(
            opacity: 0.65,
            child: Container(
              width: double.infinity,
              decoration: BoxDecoration(
                border: Border.all(
                  color: selected.isNotEmpty
                      ? colorScheme.categoryProfile.withValues(alpha: 0.55)
                      : colorScheme.outlineVariant,
                  width: 1.0,
                ),
                borderRadius: BorderRadius.circular(12),
                color: colorScheme.surface,
              ),
              child: Column(
                children: _genderOptions
                    .map((gender) => _buildGenderOption(context, gender))
                    .toList(),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildGenderOption(BuildContext context, String gender) {
    final colorScheme = Theme.of(context).colorScheme;
    final isSelected = _selectedGender == gender;

    return GestureDetector(
      onTap: null,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected
              ? colorScheme.categoryProfile.withValues(alpha: 0.15)
              : null,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                AppHelpers.capitalize(gender),
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: isSelected
                      ? colorScheme.categoryProfile
                      : colorScheme.onSurface,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                  fontSize: 15,
                ),
              ),
            ),
            if (isSelected)
              Icon(
                Iconsax.tick_circle_copy,
                color: colorScheme.categoryProfile,
                size: 20,
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildSelectableSportChip(String sportKey) {
    final colorScheme = Theme.of(context).colorScheme;
    final isSelected = _selectedSports.contains(sportKey);

    return FilterChip(
      label: Text(
        AppHelpers.getSportDisplayName(sportKey),
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
          color: isSelected
              ? colorScheme.categoryProfile
              : colorScheme.onSurface,
          fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
        ),
      ),
      avatar: Icon(
        AppHelpers.getSportIcon(sportKey),
        size: 20,
        color: isSelected ? colorScheme.categoryProfile : colorScheme.onSurface,
      ),
      selected: isSelected,
      showCheckmark: false,
      onSelected: (bool selected) {
        setState(() {
          if (selected) {
            _selectedSports.add(sportKey);
          } else {
            _selectedSports.remove(sportKey);
          }
        });
      },
      backgroundColor: Colors.transparent,
      selectedColor: colorScheme.categoryProfile.withValues(alpha: 0.2),
      side: BorderSide(
        color: isSelected ? colorScheme.categoryProfile : colorScheme.outline,
        width: isSelected ? 2 : 1.5,
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return SingleSectionLayout(
      category: 'profile',
      scrollable: true,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: _isLoading
            ? Center(
                child: CircularProgressIndicator(
                  color: colorScheme.categoryProfile,
                ),
              )
            : Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        IconButton.filledTonal(
                          onPressed: () => context.pop(),
                          icon: const Icon(Iconsax.arrow_left_copy),
                          style: IconButton.styleFrom(
                            backgroundColor: colorScheme.categoryProfile
                                .withValues(alpha: 0.0),
                            foregroundColor: colorScheme.onSurface,
                            minimumSize: const Size(48, 48),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'Edit Profile',
                            style: Theme.of(context).textTheme.titleMedium
                                ?.copyWith(
                                  fontWeight: FontWeight.w700,
                                  color: colorScheme.onSurface,
                                ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 20),

                    Center(
                      child: Stack(
                        children: [
                          AppAvatar(
                            imageUrl: _avatarUrl,
                            fallbackText:
                                _displayNameController.text.trim().isNotEmpty
                                ? _displayNameController.text
                                : 'User',
                            size: 100,
                            showBadge: false,
                            fallbackBackgroundColor: colorScheme.categoryProfile
                                .withValues(alpha: 0.14),
                            fallbackForegroundColor:
                                colorScheme.onPrimaryContainer,
                            borderColor: colorScheme.onPrimaryContainer
                                .withValues(alpha: 0.18),
                          ),
                          Positioned(
                            bottom: 0,
                            right: 0,
                            child: InkWell(
                              onTap: _isUploadingAvatar
                                  ? null
                                  : _pickAndUploadAvatar,
                              customBorder: const CircleBorder(),
                              child: Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: colorScheme.categoryProfile,
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: colorScheme.surfaceContainerLowest,
                                    width: 3,
                                  ),
                                ),
                                child: _isUploadingAvatar
                                    ? SizedBox(
                                        width: 16,
                                        height: 16,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          color: colorScheme.onPrimary,
                                        ),
                                      )
                                    : Icon(
                                        Icons.camera_alt,
                                        color: colorScheme.onPrimary,
                                        size: 16,
                                      ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 30),

                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Display Name',
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(
                                fontWeight: FontWeight.w600,
                                color: colorScheme.onSurface,
                              ),
                        ),
                        const SizedBox(height: 6),
                        TextFormField(
                          controller: _displayNameController,
                          decoration: const InputDecoration(
                            hintText: 'Choose a name',
                            border: OutlineInputBorder(),
                          ),
                          validator: AppValidators.validateName,
                        ),
                      ],
                    ),

                    const SizedBox(height: 12),

                    _buildGenderSelect(context),

                    const SizedBox(height: 12),

                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Phone number',
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(
                                fontWeight: FontWeight.w600,
                                color: colorScheme.onSurface,
                              ),
                        ),
                        const SizedBox(height: 6),
                        TextFormField(
                          controller: _phoneController,
                          decoration: const InputDecoration(
                            hintText: 'Optional',
                            border: OutlineInputBorder(),
                          ),
                          keyboardType: TextInputType.phone,
                        ),
                      ],
                    ),

                    const SizedBox(height: 16),

                    Text(
                      'Sports Preferences',
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: AppConstants.availableSports
                          .where(FeatureFlags.isSportEnabled)
                          .map(_buildSelectableSportChip)
                          .toList(),
                    ),

                    const SizedBox(height: 30),

                    SizedBox(
                      width: double.infinity,
                      child: FilledButton(
                        onPressed: _isLoading ? null : _saveProfile,
                        style: FilledButton.styleFrom(
                          minimumSize: const Size(double.infinity, 56),
                          backgroundColor: colorScheme.categoryProfile,
                          foregroundColor: colorScheme.onPrimary,
                          disabledBackgroundColor: colorScheme.categoryProfile
                              .withValues(alpha: 0.4),
                          disabledForegroundColor: colorScheme.onPrimary
                              .withValues(alpha: 0.75),
                        ),
                        child: const Text('Save changes'),
                      ),
                    ),
                  ],
                ),
              ),
      ),
    );
  }

  void _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      await _authService.updateUserProfile(
        displayName: _displayNameController.text.trim().isEmpty
            ? null
            : _displayNameController.text.trim(),
        phone: _phoneController.text.trim().isEmpty
            ? null
            : _phoneController.text.trim(),
        gender: _selectedGender,
        sports: _selectedSports.isNotEmpty ? _selectedSports : null,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Profile updated successfully!'),
            backgroundColor: Colors.green,
          ),
        );
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error updating profile: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }
}
