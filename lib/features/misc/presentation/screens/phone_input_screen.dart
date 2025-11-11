import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:dabbler/core/services/auth_service.dart';
import 'package:dabbler/utils/constants/route_constants.dart';
import 'package:dabbler/core/design_system/design_system.dart';
import 'package:dabbler/themes/app_theme.dart';

class PhoneInputScreen extends ConsumerStatefulWidget {
  const PhoneInputScreen({super.key});

  @override
  ConsumerState<PhoneInputScreen> createState() => _PhoneInputScreenState();
}

class _PhoneInputScreenState extends ConsumerState<PhoneInputScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _phoneController = TextEditingController();
  final String _countryCode = '+971'; // Default to UAE
  bool _isLoading = false;
  String? _errorMessage;
  String? _successMessage;
  bool _isPhoneValid = false;

  @override
  void initState() {
    super.initState();
    // ...existing code...
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // ...existing code...
  }

  @override
  void dispose() {
    // ...existing code...
    _phoneController.dispose();
    super.dispose();
  }

  String? _validatePhone(String? value) {
    final phone = value?.trim() ?? '';
    // Simple validation: must be 9 digits (UAE format: 5XXXXXXXX)
    if (phone.isEmpty) return 'Phone number is required';
    if (!RegExp(r'^5\d{8}').hasMatch(phone)) {
      return 'Enter a valid UAE phone number';
    }
    return null;
  }

  void _onPhoneChanged(String value) {
    final isValid = _validatePhone(value) == null;
    if (isValid != _isPhoneValid) {
      setState(() {
        _isPhoneValid = isValid;
      });
    }
  }

  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) return;

    // ...existing code...

    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _successMessage = null;
    });

    final phone = '$_countryCode${_phoneController.text.trim()}';
    bool userExistsBeforeOtp = false;

    try {
      // Check if user exists BEFORE sending OTP
      // This is important because Supabase's signInWithOtp creates the user if they don't exist
      try {
        final authService = AuthService();

        print('🔍 [DEBUG] PhoneInputScreen: Checking if user exists: $phone');
        userExistsBeforeOtp = await authService.checkUserExistsByPhone(phone);
        print('🔍 [DEBUG] PhoneInputScreen: User exists: $userExistsBeforeOtp');

        // Send OTP regardless of user existence
        await authService.signInWithPhone(phone: phone);
        // ...existing code...

        if (mounted) {
          setState(() {
            _successMessage = 'OTP sent! Please check your phone.';
          });
        }
      } catch (dbError) {
        // ...existing code...
        final errorMsg = dbError.toString();

        // Check for phone provider not configured error
        if (errorMsg.contains('phone_provider_disabled') ||
            errorMsg.contains('Unsupported phone provider')) {
          if (mounted) {
            setState(() {
              _errorMessage =
                  'Phone authentication is not available yet. Please use email to continue.';
            });
          }
          return;
        }

        if (mounted) {
          setState(() {
            _errorMessage = 'Service error: ${dbError.toString()}';
          });
        }
        return; // Don't navigate if there's an error
      }
    } catch (e) {
      // ...existing code...
      if (mounted) {
        setState(() {
          _errorMessage = 'Failed to send OTP. Please try again.';
        });
      }
      return; // Don't navigate if there's an error
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }

    // Navigate to OTP verification screen only if everything succeeded
    if (mounted) {
      try {
        context.push(
          RoutePaths.otpVerification,
          extra: {'phone': phone, 'userExistsBeforeOtp': userExistsBeforeOtp},
        );
      } catch (navError) {
        // ...existing code...
        if (mounted) {
          setState(() {
            _errorMessage = 'Navigation failed: ${navError.toString()}';
          });
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return TwoSectionLayout(
      topSection: _buildTopSection(),
      bottomSection: _buildBottomSection(),
    );
  }

  Widget _buildTopSection() {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;
    
    return Column(
      children: [
        const SizedBox(height: 32),
        // Dabbler logo and text
        _buildLogo(),
        const SizedBox(height: 32),
        // Welcome text - using Material 3 typography
        Text(
          'Welcome to dabbler!',
          style: textTheme.headlineSmall?.copyWith(
            color: colorScheme.onSurface,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Enter your mobile number to get started',
          style: textTheme.bodyLarge?.copyWith(
            color: colorScheme.onSurfaceVariant,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildLogo() {
    return Column(
      children: [
        // Dabbler geometric icon
        SvgPicture.asset(
          'assets/images/dabbler_logo.svg',
          width: 80,
          height: 88,
        ),
        SizedBox(height: AppSpacing.md),
        // Dabbler text logo
        SvgPicture.asset(
          'assets/images/dabbler_text_logo.svg',
          width: 110,
          height: 21,
        ),
      ],
    );
  }

  Widget _buildBottomSection() {
    return Column(
      children: [
        // Phone input field
        _buildPhoneInput(),
        const SizedBox(height: 16), // Material 3 spacing: 16dp

        // Login with Email button
        _buildEmailButton(),

        const SizedBox(height: 24), // Material 3 spacing: 24dp

        // Divider with "or"
        _buildDivider(),

        const SizedBox(height: 24), // Material 3 spacing: 24dp

        // Continue with Google button
        _buildGoogleButton(),

        const SizedBox(height: 12), // Material 3 spacing: 12dp

        // Continue with Email button
        _buildContinueEmailButton(),

        const SizedBox(height: 24), // Material 3 spacing: 24dp

        // Terms and privacy
        _buildTermsText(),

        // Error/Success messages - using Material 3 colors
        if (_errorMessage != null) ...[
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.errorContainer,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.error_outline,
                  color: Theme.of(context).colorScheme.onErrorContainer,
                  size: 20,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    _errorMessage!,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onErrorContainer,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],

        if (_successMessage != null) ...[
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Theme.of(context).extension<AppThemeExtension>()?.success.withOpacity(0.1) ??
                  Theme.of(context).colorScheme.primaryContainer,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.check_circle_outline,
                  color: Theme.of(context).extension<AppThemeExtension>()?.success ??
                      Theme.of(context).colorScheme.primary,
                  size: 20,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    _successMessage!,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).extension<AppThemeExtension>()?.success ??
                          Theme.of(context).colorScheme.onPrimaryContainer,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildPhoneInput() {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    
    // Use Material 3 TextFormField with proper styling and validation
    return Form(
      key: _formKey,
      child: TextFormField(
        controller: _phoneController,
        keyboardType: TextInputType.phone,
        onChanged: _onPhoneChanged,
        validator: _validatePhone,
        style: textTheme.bodyLarge?.copyWith(
          color: colorScheme.onSurface,
        ),
        decoration: InputDecoration(
          hintText: '505050500',
          prefixIcon: Padding(
            padding: const EdgeInsets.only(left: 16, right: 8),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('🇦🇪', style: TextStyle(fontSize: 20)),
                const SizedBox(width: 8),
                Text(
                  _countryCode,
                  style: textTheme.bodyLarge?.copyWith(
                    color: colorScheme.onSurface,
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  width: 1,
                  height: 20,
                  color: colorScheme.outlineVariant,
                ),
              ],
            ),
          ),
          // Material 3 uses InputDecorationTheme from theme
        ).applyDefaults(Theme.of(context).inputDecorationTheme),
      ),
    );
  }

  Widget _buildEmailButton() {
    // Use Material 3 FilledButton for primary action
    return FilledButton.icon(
      onPressed: _isLoading ? null : _handleSubmit,
      icon: _isLoading
          ? SizedBox(
              height: 20,
              width: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(
                  Theme.of(context).colorScheme.onPrimary,
                ),
              ),
            )
          : const Icon(Icons.phone, size: 20),
      label: Text(_isLoading ? 'Sending...' : 'Login with phone'),
      style: FilledButton.styleFrom(
        minimumSize: const Size(double.infinity, 56),
      ),
    );
  }

  Widget _buildDivider() {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    
    // Use Material 3 Divider
    return Row(
      children: [
        Expanded(
          child: Divider(
            color: colorScheme.outlineVariant,
            thickness: 1,
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            'or',
            style: textTheme.bodyMedium?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
        ),
        Expanded(
          child: Divider(
            color: colorScheme.outlineVariant,
            thickness: 1,
          ),
        ),
      ],
    );
  }

  Widget _buildGoogleButton() {
    // Use Material 3 OutlinedButton for secondary actions
    return OutlinedButton.icon(
      onPressed: () {
        // TODO: Implement Google sign in
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Google sign-in coming soon')),
        );
      },
      icon: const Text(
        'G',
        style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
      ),
      label: const Text('Continue with Google'),
      style: OutlinedButton.styleFrom(
        minimumSize: const Size(double.infinity, 56),
      ),
    );
  }

  Widget _buildContinueEmailButton() {
    // Use Material 3 FilledButton.tonal for secondary actions
    return FilledButton.tonalIcon(
      onPressed: () {
        debugPrint('📧 [DEBUG] PhoneInputScreen: Email button pressed');
        context.go(RoutePaths.emailInput);
      },
      icon: const Text('📨', style: TextStyle(fontSize: 18)),
      label: const Text('Continue with Email'),
      style: FilledButton.styleFrom(
        minimumSize: const Size(double.infinity, 56),
      ),
    );
  }

  Widget _buildTermsText() {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    
    return Wrap(
      alignment: WrapAlignment.center,
      crossAxisAlignment: WrapCrossAlignment.center,
      spacing: 4,
      children: [
        Text(
          'By continuing, you agree to our',
          style: textTheme.bodySmall?.copyWith(
            color: colorScheme.onSurfaceVariant,
          ),
        ),
        TextButton(
          onPressed: () {
            // TODO: Open Terms of Service
          },
          style: TextButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            minimumSize: Size.zero,
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
          child: Text(
            'Terms of Service',
            style: textTheme.bodySmall?.copyWith(
              color: colorScheme.primary,
              decoration: TextDecoration.underline,
            ),
          ),
        ),
        Text(
          'and',
          style: textTheme.bodySmall?.copyWith(
            color: colorScheme.onSurfaceVariant,
          ),
        ),
        TextButton(
          onPressed: () {
            // TODO: Open Privacy Policy
          },
          style: TextButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            minimumSize: Size.zero,
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
          child: Text(
            'Privacy Policy',
            style: textTheme.bodySmall?.copyWith(
              color: colorScheme.primary,
              decoration: TextDecoration.underline,
            ),
          ),
        ),
      ],
    );
  }
}

