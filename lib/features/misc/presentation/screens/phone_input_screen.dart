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
  String _countryCode = '+971'; // Default to UAE
  String _countryFlag = '🇦🇪';
  String _countryName = 'UAE';
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
    if (phone.isEmpty) return 'Phone number is required';

    // Country-specific validation
    if (_countryCode == '+971') {
      // UAE: must be 9 digits starting with 5
      if (!RegExp(r'^5\d{8}').hasMatch(phone)) {
        return 'Enter a valid UAE number (5XXXXXXXX)';
      }
    } else {
      // Generic validation for other countries: 7-15 digits
      if (!RegExp(r'^\d{7,15}').hasMatch(phone)) {
        return 'Enter a valid phone number';
      }
    }
    return null;
  }

  void _showCountryPicker() {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        final colorScheme = Theme.of(context).colorScheme;
        final textTheme = Theme.of(context).textTheme;

        final countries = [
          {'code': '+971', 'flag': '🇦🇪', 'name': 'UAE'},
          {'code': '+966', 'flag': '🇸🇦', 'name': 'Saudi Arabia'},
          {'code': '+965', 'flag': '🇰🇼', 'name': 'Kuwait'},
          {'code': '+974', 'flag': '🇶🇦', 'name': 'Qatar'},
          {'code': '+973', 'flag': '🇧🇭', 'name': 'Bahrain'},
          {'code': '+968', 'flag': '🇴🇲', 'name': 'Oman'},
          {'code': '+962', 'flag': '🇯🇴', 'name': 'Jordan'},
          {'code': '+961', 'flag': '🇱🇧', 'name': 'Lebanon'},
          {'code': '+20', 'flag': '🇪🇬', 'name': 'Egypt'},
          {'code': '+1', 'flag': '🇺🇸', 'name': 'USA'},
          {'code': '+44', 'flag': '🇬🇧', 'name': 'UK'},
          {'code': '+91', 'flag': '🇮🇳', 'name': 'India'},
          {'code': '+92', 'flag': '🇵🇰', 'name': 'Pakistan'},
        ];

        return Container(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  'Select Country',
                  style: textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const Divider(height: 1),
              Flexible(
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: countries.length,
                  itemBuilder: (context, index) {
                    final country = countries[index];
                    return ListTile(
                      leading: Text(
                        country['flag']!,
                        style: const TextStyle(fontSize: 28),
                      ),
                      title: Text(country['name']!),
                      trailing: Text(
                        country['code']!,
                        style: textTheme.bodyLarge?.copyWith(
                          color: colorScheme.primary,
                        ),
                      ),
                      onTap: () {
                        setState(() {
                          _countryCode = country['code']!;
                          _countryFlag = country['flag']!;
                          _countryName = country['name']!;
                          _phoneController.clear();
                          _isPhoneValid = false;
                        });
                        Navigator.pop(context);
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
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
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
                child: _buildHeroSection(),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 28, 24, 40),
                child: _buildBottomSection(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeroSection() {
    final textTheme = Theme.of(context).textTheme;
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    final heroColor = isDarkMode
        ? const Color(0xFF4A148C)
        : const Color(0xFFE0C7FF);
    final textColor = isDarkMode ? Colors.white : Colors.black87;
    final subtextColor = isDarkMode
        ? Colors.white.withOpacity(0.85)
        : Colors.black.withOpacity(0.7);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: heroColor,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        children: [
          // Dabbler logo and text
          _buildLogo(textColor),
          const SizedBox(height: 24),
          // Welcome text - using Material 3 typography
          Text(
            'Welcome to dabbler!',
            style: textTheme.headlineSmall?.copyWith(
              color: textColor,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Enter your mobile number to get started',
            style: textTheme.bodyLarge?.copyWith(color: subtextColor),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildLogo(Color iconColor) {
    return Column(
      children: [
        // Dabbler geometric icon
        SvgPicture.asset(
          'assets/images/dabbler_logo.svg',
          width: 80,
          height: 88,
          colorFilter: ColorFilter.mode(iconColor, BlendMode.srcIn),
        ),
        SizedBox(height: AppSpacing.md),
        // Dabbler text logo
        SvgPicture.asset(
          'assets/images/dabbler_text_logo.svg',
          width: 110,
          height: 21,
          colorFilter: ColorFilter.mode(iconColor, BlendMode.srcIn),
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
              color:
                  Theme.of(
                    context,
                  ).extension<AppThemeExtension>()?.success.withOpacity(0.1) ??
                  Theme.of(context).colorScheme.primaryContainer,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.check_circle_outline,
                  color:
                      Theme.of(
                        context,
                      ).extension<AppThemeExtension>()?.success ??
                      Theme.of(context).colorScheme.primary,
                  size: 20,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    _successMessage!,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color:
                          Theme.of(
                            context,
                          ).extension<AppThemeExtension>()?.success ??
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
        style: textTheme.bodyLarge?.copyWith(color: colorScheme.onSurface),
        decoration: InputDecoration(
          hintText: _countryCode == '+971' ? '505050500' : 'Phone number',
          prefixIcon: InkWell(
            onTap: _showCountryPicker,
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.only(left: 16, right: 8),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(_countryFlag, style: const TextStyle(fontSize: 20)),
                  const SizedBox(width: 4),
                  Icon(
                    Icons.arrow_drop_down,
                    color: colorScheme.onSurfaceVariant,
                    size: 20,
                  ),
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
          child: Divider(color: colorScheme.outlineVariant, thickness: 1),
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
          child: Divider(color: colorScheme.outlineVariant, thickness: 1),
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
