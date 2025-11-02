import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/services/auth_service.dart';
import '../../widgets/custom_app_bar.dart';

class EditProfileScreen extends ConsumerStatefulWidget {
  const EditProfileScreen({super.key});

  @override
  ConsumerState<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends ConsumerState<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();

  // Controllers for database fields only
  final _displayNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();

  // State variables for database fields only
  String? _selectedGender;
  List<String> _selectedSports = [];

  // Available options
  final List<String> _sportsOptions = [
    'Football',
    'Basketball',
    'Tennis',
    'Swimming',
    'Running',
    'Cycling',
    'Golf',
    'Volleyball',
    'Baseball',
    'Soccer',
    'Cricket',
    'Badminton',
    'Table Tennis',
    'Boxing',
    'Martial Arts',
  ];

  bool _isLoading = false;
  late AuthService _authService;

  @override
  void initState() {
    super.initState();
    _authService = AuthService();
    _loadUserData();
  }

  @override
  void dispose() {
    _displayNameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _loadUserData() async {
    setState(() => _isLoading = true);

    try {
      final user = _authService.getCurrentUser();
      if (user?.id == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('User not found. Please log in again.'),
            ),
          );
        }
        return;
      }

      // Fetch from database
      final response = await Supabase.instance.client
          .from('users')
          .select()
          .eq('id', user!.id)
          .maybeSingle();

      if (!mounted) return;

      if (response != null) {
        // Get display name from database (only field that exists now)
        final displayName = (response['display_name'] as String?)?.trim() ?? '';

        // Only seed if user hasn't typed anything yet
        if (_displayNameController.text.isEmpty && displayName.isNotEmpty) {
          _displayNameController.text = displayName;
        }
        if (_emailController.text.isEmpty) {
          _emailController.text = (response['email'] as String?) ?? '';
        }
        if (_phoneController.text.isEmpty) {
          _phoneController.text = (response['phone'] as String?) ?? '';
        }

        // Set gender
        _selectedGender = (response['gender'] as String?)?.toLowerCase();

        // Set sports
        if (response['sports'] != null) {
          final sports = response['sports'];
          if (sports is List) {
            _selectedSports = sports.cast<String>();
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

  Future<void> _updateProfile() async {
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
          const SnackBar(content: Text('Profile updated successfully!')),
        );
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error updating profile: $e')));
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: CustomAppBar(actionIcon: Iconsax.user_edit_copy),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 116, 16, 16),
                children: [
                  _buildPersonalDetailsSection(),
                  _buildSportsPreferencesSection(),
                  _buildContactSection(),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: _updateProfile,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: const Text('Update Profile'),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildPersonalDetailsSection() {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Personal Details',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _displayNameController,
              decoration: const InputDecoration(
                labelText: 'Display Name',
                prefixIcon: Icon(Icons.person),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Display name is required and cannot be empty';
                }
                if (value.trim().length < 2) {
                  return 'Display name must be at least 2 characters';
                }
                if (value.trim().length > 50) {
                  return 'Display name must be 50 characters or less';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              initialValue: _selectedGender,
              decoration: const InputDecoration(
                labelText: 'Gender',
                prefixIcon: Icon(Icons.person),
              ),
              items: const [
                DropdownMenuItem(value: 'male', child: Text('Male')),
                DropdownMenuItem(value: 'female', child: Text('Female')),
              ],
              onChanged: (value) {
                setState(() {
                  _selectedGender = value;
                });
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSportsPreferencesSection() {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Sports Preferences',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            const Text(
              'Sports You Play',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _sportsOptions.map((sport) {
                final isSelected = _selectedSports.contains(sport);
                return FilterChip(
                  label: Text(sport),
                  selected: isSelected,
                  onSelected: (selected) {
                    setState(() {
                      if (selected) {
                        _selectedSports.add(sport);
                      } else {
                        _selectedSports.remove(sport);
                      }
                    });
                  },
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContactSection() {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Contact Information',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _emailController,
              decoration: const InputDecoration(
                labelText: 'Email',
                prefixIcon: Icon(Icons.email),
                suffixText: 'Read-only',
              ),
              enabled: false,
              style: TextStyle(color: Colors.grey[600]),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _phoneController,
              decoration: const InputDecoration(
                labelText: 'Phone Number',
                prefixIcon: Icon(Icons.phone),
              ),
              keyboardType: TextInputType.phone,
            ),
          ],
        ),
      ),
    );
  }
}
