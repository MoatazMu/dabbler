import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dabbler/utils/constants/route_constants.dart';
import 'package:go_router/go_router.dart';
import 'package:dabbler/features/authentication/presentation/providers/auth_providers.dart';
import 'package:dabbler/features/authentication/presentation/providers/onboarding_data_provider.dart';
import 'package:dabbler/core/design_system/design_system.dart';
import 'package:flutter_svg/flutter_svg.dart';

class EmailInputScreen extends ConsumerStatefulWidget {
  const EmailInputScreen({super.key});

  @override
  ConsumerState<EmailInputScreen> createState() => _EmailInputScreenState();
}

class _EmailInputScreenState extends ConsumerState<EmailInputScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  bool _isLoading = false;
  String? _errorMessage;
  String? _successMessage;
  bool _isEmailValid = false;

  @override
  void initState() {
    super.initState();
    debugPrint('📧 [DEBUG] EmailInputScreen: initState called');
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    debugPrint('📧 [DEBUG] EmailInputScreen: didChangeDependencies called');
  }

  @override
  void dispose() {
    debugPrint('📧 [DEBUG] EmailInputScreen: dispose called');
    _emailController.dispose();
    super.dispose();
  }

  String? _validateEmail(String? value) {
    final email = value?.trim() ?? '';
    if (email.isEmpty) return 'Email is required';
    if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email)) {
      return 'Enter a valid email address';
    }
    return null;
  }

  void _onEmailChanged(String value) {
    final isValid = _validateEmail(value) == null;
    if (isValid != _isEmailValid) {
      setState(() {
        _isEmailValid = isValid;
      });
    }
  }

  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) return;

    debugPrint('📧 [DEBUG] EmailInputScreen: _handleSubmit started');

    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _successMessage = null;
    });

    final email = _emailController.text.trim();
    debugPrint('📧 [DEBUG] EmailInputScreen: Email: $email');

    try {
      debugPrint('📧 [DEBUG] EmailInputScreen: Checking if user exists...');

      // Check if user exists in the system
      final authService = ref.read(authServiceProvider);
      final userExists = await authService.checkUserExistsByEmail(email);

      debugPrint('📧 [DEBUG] EmailInputScreen: User exists: $userExists');

      if (mounted) {
        if (userExists) {
          // User exists - go to password screen
          debugPrint(
            '✅ [DEBUG] EmailInputScreen: User exists, redirecting to password entry',
          );
          context.push(RoutePaths.enterPassword, extra: {'email': email});
        } else {
          // User doesn't exist - go directly to onboarding
          debugPrint(
            '🆕 [DEBUG] EmailInputScreen: New user, redirecting to onboarding',
          );

          // Initialize onboarding with email
          ref.read(onboardingDataProvider.notifier).initWithEmail(email);

          context.go(RoutePaths.createUserInfo, extra: {'email': email});
        }
      }
    } catch (e) {
      debugPrint('❌ [DEBUG] EmailInputScreen: Error in _handleSubmit: $e');
      if (mounted) {
        setState(() {
          _errorMessage = 'An error occurred. Please try again.';
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
  }

  @override
  Widget build(BuildContext context) {
    debugPrint('📧 [DEBUG] EmailInputScreen: build called');

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
          'Enter your email address to get started',
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
        // Email input field
        _buildEmailInput(),
        SizedBox(height: AppSpacing.lg),

        // Continue with Email button
        _buildContinueButton(),

        SizedBox(height: AppSpacing.xl),

        // Divider with "or"
        _buildDivider(),

        SizedBox(height: AppSpacing.xl),

        // Continue with Google button
        _buildGoogleButton(),

        SizedBox(height: AppSpacing.md),

        // Continue with Phone button
        _buildPhoneButton(),

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

  Widget _buildEmailInput() {
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
        child: TextFormField(
          controller: _emailController,
          decoration: InputDecoration(
            hintText: 'email@example.com',
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
          keyboardType: TextInputType.emailAddress,
          onChanged: _onEmailChanged,
          validator: _validateEmail,
        ),
      ),
    );
  }

  Widget _buildContinueButton() {
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
                  Text('📧', style: TextStyle(fontSize: 18)),
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

  Widget _buildPhoneButton() {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton(
        onPressed: () {
          debugPrint('📱 [DEBUG] EmailInputScreen: Phone button pressed');
          context.go(RoutePaths.phoneInput);
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
            Icon(Icons.phone, size: 18),
            SizedBox(width: AppSpacing.sm),
            Text(
              'Continue with Phone',
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
