import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../core/services/auth_service.dart';
import '../../core/utils/constants.dart';
import '../../core/utils/validators.dart';
import '../../core/utils/helpers.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/input_field.dart';
import '../../widgets/onboarding_progress.dart';
import '../../core/services/user_service.dart';
import '../../utils/constants/route_constants.dart';

class RegistrationData {
  String email;
  String? name;
  int? age;
  String? gender;
  List<String>? sports;
  String? intent;

  RegistrationData({
    required this.email,
    this.name,
    this.age,
    this.gender,
    this.sports,
    this.intent,
  });

  RegistrationData copyWith({
    String? name,
    int? age,
    String? gender,
    List<String>? sports,
    String? intent,
  }) {
    return RegistrationData(
      email: email,
      name: name ?? this.name,
      age: age ?? this.age,
      gender: gender ?? this.gender,
      sports: sports ?? this.sports,
      intent: intent ?? this.intent,
    );
  }

  // Convert to Map for GoRouter serialization
  Map<String, dynamic> toMap() {
    return {
      'email': email,
      'name': name,
      'age': age,
      'gender': gender,
      'sports': sports,
      'intent': intent,
    };
  }

  // Create from Map for GoRouter deserialization
  static RegistrationData fromMap(Map<String, dynamic> map) {
    return RegistrationData(
      email: map['email'] as String,
      name: map['name'] as String?, // Fixed: was 'display_name', should be 'name' to match toMap()
      age: map['age'] as int?,
      gender: map['gender'] as String?,
      sports: map['sports'] != null ? List<String>.from(map['sports']) : null,
      intent: map['intent'] as String?,
    );
  }
}

class CreateUserInformation extends StatefulWidget {
  final String email;
  final bool forceNew; // when true, ignore any existing authenticated session
  
  const CreateUserInformation({
    super.key,
    required this.email,
    this.forceNew = false,
  });

  @override
  State<CreateUserInformation> createState() => _CreateUserInformationState();
}

class _CreateUserInformationState extends State<CreateUserInformation> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  DateTime? _selectedBirthDate;
  String _selectedGender = '';

  bool _isLoading = false;
  bool _isLoadingData = true;


  final AuthService _authService = AuthService();
  final UserService _userService = UserService();

  // Avatar assets removed from this screen; avatar selection handled elsewhere.

  @override
  void initState() {
    super.initState();
    _initializeRegistrationForm();
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  /// Initializes the form by clearing any cached data, checking auth status,
  /// and loading existing data only if the user is already authenticated.
  Future<void> _initializeRegistrationForm() async {
    if (mounted) setState(() => _isLoadingData = true);

    // 1. Clear any cached user data to ensure a fresh start for registration.
    // This prevents stale data (like a name) from appearing.
    await _userService.clearUserForNewRegistration();

    try {
      // 2. Check for a valid email from the previous screen.
      if (widget.email.isEmpty && mounted) {
        debugPrint('❌ [DEBUG] CreateUserInformation: No email provided, redirecting to login.');
        context.go('/login');
        return;
      }
      debugPrint('📧 [DEBUG] CreateUserInformation: Initializing form for email: ${widget.email}');

      // 3. Check if user is already authenticated (e.g., editing their profile).
  if (!widget.forceNew && _authService.isAuthenticated()) {
        final currentEmail = _authService.getCurrentUserEmail();
        final normalizedCurrent = currentEmail?.trim().toLowerCase();
        final normalizedTarget = widget.email.trim().toLowerCase();

  if (normalizedCurrent == normalizedTarget) {
          // Same user -> treat as profile edit
          print('✅ [DEBUG] CreateUserInformation: Authenticated user matches entered email; loading existing data.');
          await _loadExistingUserData();
        } else {
          // Different authenticated account than the email we want to register.
          print('⚠️ [DEBUG] CreateUserInformation: Authenticated session (${currentEmail ?? 'unknown'}) differs from registration email ($normalizedTarget). Signing out to start fresh.');
          try {
            await _authService.signOut();
          } catch (e) {
            print('❌ [DEBUG] CreateUserInformation: Error signing out mismatched user: $e');
          }
          // Proceed as fresh registration
          print('🆕 [DEBUG] CreateUserInformation: Proceeding with empty form for new registration.');
          if (mounted) {
            setState(() {
              _nameController.text = '';
              _selectedGender = '';
              _selectedBirthDate = null;
              _isLoadingData = false;
            });
          }
        }
      } else {
        // 4. This is the standard new user registration path.
        print('🆕 [DEBUG] CreateUserInformation: New user, ensuring form is empty.');
        if (mounted) {
          setState(() {
            _nameController.text = '';
            _selectedGender = '';
            _selectedBirthDate = null;
            _isLoadingData = false;
          });
        }
      }
    } catch (e) {
      print('❌ [DEBUG] CreateUserInformation: Error during initialization: $e');
      if (mounted) {
        setState(() {
          _isLoadingData = false;
        });
      }
    }
  }

  /// Loads existing data for an authenticated user who is editing their profile.
  Future<void> _loadExistingUserData() async {
    try {
      final userProfile = await _authService.getUserProfile();
      
      if (userProfile != null && mounted) {
        // Populate the form for authenticated users (editing profiles)
        setState(() {
          _nameController.text = userProfile['display_name'] ?? '';
          // Note: We don't store age/gender in Supabase yet, so these will be empty
          _selectedGender = ''; // Keep empty
        });
      } else {
        // No existing profile, ensure fields are empty
        setState(() {
          _nameController.text = '';
          _selectedGender = '';
        });
      }
    } catch (e) {
      // Handle error silently - user will enter data manually
      print('Error loading user data: $e');
      // Ensure fields are empty even if there's an error
      setState(() {
        _nameController.text = '';
        _selectedGender = '';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingData = false;
        });
      }
    }
  }

  Future<void> _handleSubmit() async {
    // Validate all fields before proceeding
    if (!_formKey.currentState!.validate()) {
      // Show specific error message if validation fails
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please fill in all required fields correctly'),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 3),
        ),
      );
      return;
    }

    // Additional validation checks
    final name = _nameController.text.trim();
    
    if (name.length < AppConstants.minNameLength) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Name must be at least ${AppConstants.minNameLength} characters long'),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 3),
        ),
      );
      return;
    }
    
    if (_selectedBirthDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select your birth date'),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 3),
        ),
      );
      return;
    }
    
    final ageValue = _calculateAge(_selectedBirthDate!);
    if (ageValue < AppConstants.minAge || ageValue > AppConstants.maxAge) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('You must be between ${AppConstants.minAge} and ${AppConstants.maxAge} years old'),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 3),
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final email = widget.email;

      print('👤 [DEBUG] CreateUserInformation: Collecting user information for: $email');

      // Check if user already exists in database
      final userExists = await _authService.checkUserExistsByEmail(email);
      
      if (userExists) {
        print('✅ [DEBUG] CreateUserInformation: User exists, redirecting to password screen');
        if (mounted) {
          context.go('/enter-password', extra: email);
          return; // Exit early
        }
      }

      // Create registration data without creating any accounts
      final registrationData = RegistrationData(
        email: email,
        name: name,
        age: ageValue,
        gender: _selectedGender,
      );

      print('✅ [DEBUG] CreateUserInformation: User information collected successfully');
      print('📋 [DEBUG] CreateUserInformation: Name: $name, Age: $ageValue, Gender: $_selectedGender');

      // Navigate to sports selection with the collected data
      if (mounted) {
        // Convert to Map to avoid GoRouter serialization warning
        context.push(RoutePaths.sportsSelection, extra: registrationData.toMap());
      }
    } catch (e) {
      print('❌ [DEBUG] CreateUserInformation: Error in _handleSubmit: $e');
      if (mounted) {
        String errorMessage = 'An error occurred while creating your profile.';
        
        // Provide more specific error messages
        if (e.toString().contains('Database error saving new user')) {
          errorMessage = 'There was an issue with the database. Please try again.';
        } else if (e.toString().contains('User not authenticated')) {
          errorMessage = 'Authentication failed. Please try again.';
        } else if (e.toString().contains('Unable to authenticate user')) {
          errorMessage = 'Unable to verify your account. Please try again.';
        }
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 4),
            action: SnackBarAction(
              label: 'Retry',
              textColor: Colors.white,
              onPressed: () => _handleSubmit(),
            ),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  // Removed _handleSkip method - information is now required

  /// Calculate age from birth date
  int _calculateAge(DateTime birthDate) {
    final now = DateTime.now();
    int age = now.year - birthDate.year;
    if (now.month < birthDate.month || (now.month == birthDate.month && now.day < birthDate.day)) {
      age--;
    }
    return age;
  }

  /// Get a random avatar URL based on selected gender
  // (Removed unused _getRandomAvatarUrl helper after refactor; default avatar remains constant.)

  /// Check if all required fields are filled and valid
  bool _areAllFieldsValid() {
    final name = _nameController.text.trim();
    
    return name.length >= AppConstants.minNameLength &&
           _selectedBirthDate != null &&
           _selectedGender.isNotEmpty;
  }

  /// Build Ant Design style birth date picker
  Widget _buildBirthDatePicker(BuildContext context) {
    final ageText = _selectedBirthDate != null 
        ? '${_calculateAge(_selectedBirthDate!)} years old'
        : 'Select your birth date';
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Birth Date',
          style: Theme.of(context).textTheme.labelLarge?.copyWith(
            fontWeight: FontWeight.w600,
            color: Theme.of(context).colorScheme.onSurface,
          ),
        ),
        const SizedBox(height: 8),
        GestureDetector(
          onTap: () => _showDatePicker(context),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            decoration: BoxDecoration(
              border: Border.all(
                color: _selectedBirthDate != null 
                    ? Theme.of(context).colorScheme.primary
                    : Theme.of(context).colorScheme.outline.withValues(alpha: 0.3),
                width: 1.5,
              ),
              borderRadius: BorderRadius.circular(AppConstants.borderRadius),
              color: _selectedBirthDate != null 
                  ? Theme.of(context).colorScheme.primary.withValues(alpha: 0.05)
                  : Theme.of(context).colorScheme.surface,
            ),
            child: Row(
              children: [
                Icon(
                  LucideIcons.calendar,
                  color: _selectedBirthDate != null 
                      ? Theme.of(context).colorScheme.primary
                      : Theme.of(context).colorScheme.onSurfaceVariant,
                  size: 20,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    ageText,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: _selectedBirthDate != null 
                          ? Theme.of(context).colorScheme.onSurface
                          : Theme.of(context).colorScheme.onSurfaceVariant,
                      fontWeight: _selectedBirthDate != null ? FontWeight.w500 : FontWeight.normal,
                    ),
                  ),
                ),
                // Icon(
                //   LucideIcons.calendar,
                //   color: Theme.of(context).colorScheme.onSurfaceVariant,
                //   size: 21,
                // ),
              ],
            ),
          ),
        ),
        if (_selectedBirthDate != null) ...[
          const SizedBox(height: 8),
          // Text(
          //   'Born on ${_formatDate(_selectedBirthDate!)}',
          //   style: Theme.of(context).textTheme.bodySmall?.copyWith(
          //     color: Theme.of(context).colorScheme.primary,
          //     fontStyle: FontStyle.italic,
          //   ),
          // ),
        ],
      ],
    );
  }

  /// Show date picker dialog
  Future<void> _showDatePicker(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedBirthDate ?? DateTime.now().subtract(const Duration(days: 6570)), // 18 years ago
      firstDate: DateTime.now().subtract(const Duration(days: 36500)), // 100 years ago
      lastDate: DateTime.now().subtract(const Duration(days: 4745)), // 13 years ago
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: Theme.of(context).colorScheme.copyWith(
              primary: Theme.of(context).colorScheme.primary,
              onPrimary: Theme.of(context).colorScheme.onPrimary,
            ),
          ),
          child: child!,
        );
      },
    );
    
    if (picked != null && picked != _selectedBirthDate) {
      setState(() {
        _selectedBirthDate = picked;
      });
    }
  }



  /// Build Ant Design style gender select
  Widget _buildGenderSelect(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Gender',
          style: Theme.of(context).textTheme.labelLarge?.copyWith(
            fontWeight: FontWeight.w600,
            color: Theme.of(context).colorScheme.onSurface,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          width: double.infinity,
          decoration: BoxDecoration(
            border: Border.all(
              color: _selectedGender.isNotEmpty 
                  ? Theme.of(context).colorScheme.primary.withValues(alpha: 0.3)
                  : Theme.of(context).colorScheme.outline.withValues(alpha: 0.3),
              width: 1.0,
            ),
            borderRadius: BorderRadius.circular(AppConstants.borderRadius),
            color: _selectedGender.isNotEmpty 
                ? Theme.of(context).colorScheme.primary.withValues(alpha: 0.05)
                : Theme.of(context).colorScheme.surface.withValues(alpha: 0.5),
          ),
          child: Column(
            children: ['male', 'female'].map((gender) => _buildGenderOption(context, gender)).toList(),
          ),
        ),
      ],
    );
  }

  /// Build individual gender option
  Widget _buildGenderOption(BuildContext context, String gender) {
    final isSelected = _selectedGender == gender;
    
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedGender = gender;

        });
      },
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        decoration: BoxDecoration(
          color: isSelected 
              ? Theme.of(context).colorScheme.primary.withOpacity(0.1)
              : Colors.transparent,
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                AppHelpers.capitalize(gender),
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: isSelected 
                      ? Theme.of(context).colorScheme.primary
                      : Theme.of(context).colorScheme.onSurface,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                ),
              ),
            ),
            if (isSelected)
              Icon(
                LucideIcons.check,
                color: Theme.of(context).colorScheme.primary,
                size: 20,
              ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Create Profile'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Onboarding Progress
            OnboardingProgress(),
            
            // Main Content
            Expanded(
              child: _isLoadingData
                  ? const Center(child: CircularProgressIndicator())
                  : SingleChildScrollView(
                      padding: const EdgeInsets.all(AppConstants.defaultPadding),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            const SizedBox(height: 32),
                            
                            // Header
                            Text(
                              'Tell us about yourself',
                              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            
                            const SizedBox(height: 8),
                            
                            Text(
                              'Please provide your information to continue',
                              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                color: Colors.grey[600],
                              ),
                              textAlign: TextAlign.center,
                            ),
                            
                            const SizedBox(height: 48),
                            
                            // Name Input
                            CustomInputField(
                              controller: _nameController,
                              label: 'Display Name',
                              hintText: 'Choose a name',
                              validator: AppValidators.validateName,
                            ),
                            
                            const SizedBox(height: 16),
                            
                            // Birth Date Picker
                            _buildBirthDatePicker(context),
                            
                            const SizedBox(height: 16),
                            
                            // Gender Selection
                            _buildGenderSelect(context),
                            
                            const SizedBox(height: 32),
                            
                            // Continue Button
                            CustomButton(
                              onPressed: (_isLoading || !_areAllFieldsValid()) ? null : _handleSubmit,
                              text: _isLoading 
                                  ? 'Saving...' 
                                  : _areAllFieldsValid() 
                                      ? 'Continue' 
                                      : 'Fill all fields to continue',
                              variant: _areAllFieldsValid() 
                                  ? ButtonVariant.primary 
                                  : ButtonVariant.secondary,
                            ),
                            

                            
                            const SizedBox(height: 16),
                            
                            // Required fields note
                            // Text(
                            //   '* Required fields',
                            //   style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            //     color: Colors.grey[600],
                            //     fontStyle: FontStyle.italic,
                            //   ),
                            //   textAlign: TextAlign.center,
                            // ),
                            
                            const SizedBox(height: 32),
                          ],
                        ),
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
