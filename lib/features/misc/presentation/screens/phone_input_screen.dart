import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:dabbler/core/services/auth_service.dart';
import 'package:dabbler/utils/constants/route_constants.dart';
import 'package:dabbler/core/design_system/design_system.dart';

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
    return Column(
      children: [
        SizedBox(height: AppSpacing.huge),
        // Dabbler logo and text
        _buildLogo(),
        SizedBox(height: AppSpacing.huge),
        // Welcome text
        Text(
          'Welcome to dabbler!',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: Theme.of(context).colorScheme.onSurface,
          ),
        ),
        SizedBox(height: AppSpacing.sm),
        Text(
          'Enter your mobile number to get started',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
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
        SizedBox(height: AppSpacing.lg),

        // Login with Email button
        _buildEmailButton(),

        SizedBox(height: AppSpacing.xl),

        // Divider with "or"
        _buildDivider(),

        SizedBox(height: AppSpacing.xl),

        // Continue with Google button
        _buildGoogleButton(),

        SizedBox(height: AppSpacing.md),

        // Continue with Email button
        _buildContinueEmailButton(),

        SizedBox(height: AppSpacing.xxl),

        // Terms and privacy
        _buildTermsText(),

        // Error/Success messages
        if (_errorMessage != null) ...[
          SizedBox(height: AppSpacing.lg),
          Container(
            padding: EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: AppColors.error.withOpacity(0.1),
              borderRadius: BorderRadius.circular(AppSpacing.sm),
              border: Border.all(color: AppColors.error.withOpacity(0.3)),
            ),
            child: Text(
              _errorMessage!,
              style: TextStyle(color: AppColors.error),
            ),
          ),
        ],

        if (_successMessage != null) ...[
          SizedBox(height: AppSpacing.lg),
          Container(
            padding: EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: AppColors.success.withOpacity(0.1),
              borderRadius: BorderRadius.circular(AppSpacing.sm),
              border: Border.all(color: AppColors.success.withOpacity(0.3)),
            ),
            child: Text(
              _successMessage!,
              style: TextStyle(color: AppColors.success),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildPhoneInput() {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: AppColors.cardColor(context),
        borderRadius: BorderRadius.circular(AppSpacing.cardBorderRadius),
        border: Border.all(color: AppColors.borderDark),
      ),
      child: Form(
        key: _formKey,
        child: Row(
          children: [
            Text('🇦🇪', style: TextStyle(fontSize: 22)),
            SizedBox(width: AppSpacing.sm),
            Text(
              _countryCode,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w400,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
            SizedBox(width: AppSpacing.md),
            Expanded(
              child: TextFormField(
                controller: _phoneController,
                decoration: InputDecoration(
                  hintText: '505050500',
                  hintStyle: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w400,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.zero,
                ),
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w400,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
                keyboardType: TextInputType.phone,
                onChanged: _onPhoneChanged,
                validator: _validatePhone,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmailButton() {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton(
        onPressed: _isLoading ? null : _handleSubmit,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primaryPurple,
          foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppSpacing.buttonBorderRadius),
          ),
        ),
        child: _isLoading
            ? SizedBox(
                height: 24,
                width: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('📱', style: TextStyle(fontSize: 18)),
                  SizedBox(width: AppSpacing.sm),
                  Text(
                    'Login with phone',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.w500),
                  ),
                ],
              ),
      ),
    );
  }

  Widget _buildDivider() {
    return Row(
      children: [
        Expanded(child: Container(height: 1, color: AppColors.borderDark)),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: AppSpacing.lg),
          child: Text(
            'or',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w400,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ),
        Expanded(child: Container(height: 1, color: AppColors.borderDark)),
      ],
    );
  }

  Widget _buildGoogleButton() {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton(
        onPressed: () {
          // TODO: Implement Google sign in
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('Google sign-in coming soon')));
        },
        style: ElevatedButton.styleFrom(
          elevation: 0,
          backgroundColor: AppColors.categoryBgMain(context),
          foregroundColor: Theme.of(context).colorScheme.onSurface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppSpacing.buttonBorderRadius),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'G',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
            ),
            SizedBox(width: AppSpacing.sm),
            Text(
              'Continue with Google',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w500),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContinueEmailButton() {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton(
        onPressed: () {
          debugPrint('📧 [DEBUG] PhoneInputScreen: Email button pressed');
          context.go(RoutePaths.emailInput);
        },
        style: ElevatedButton.styleFrom(
          elevation: 0,
          backgroundColor: AppColors.categoryBgMain(context),
          foregroundColor: Theme.of(context).colorScheme.onSurface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppSpacing.buttonBorderRadius),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('📨', style: TextStyle(fontSize: 18)),
            SizedBox(width: AppSpacing.sm),
            Text(
              'Continue with Email',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w500),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTermsText() {
    return Wrap(
      alignment: WrapAlignment.center,
      crossAxisAlignment: WrapCrossAlignment.center,
      spacing: 4,
      children: [
        Text(
          'By continuing, you agree to our',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w400,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
        GestureDetector(
          onTap: () {
            // TODO: Open Terms of Service
          },
          child: Text(
            'Terms of Service',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: Theme.of(context).colorScheme.onSurface,
              decoration: TextDecoration.underline,
            ),
          ),
        ),
        Text(
          'and',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w400,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
        GestureDetector(
          onTap: () {
            // TODO: Open Privacy Policy
          },
          child: Text(
            'Privacy Policy',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: Theme.of(context).colorScheme.onSurface,
              decoration: TextDecoration.underline,
            ),
          ),
        ),
      ],
    );
  }
}
