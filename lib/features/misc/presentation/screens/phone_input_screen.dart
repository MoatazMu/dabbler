import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/services/auth_service.dart';
import '../../utils/constants/route_constants.dart';

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
    // ...existing code...

    return Scaffold(
      appBar: AppBar(
        title: const Text('Sign In'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.language),
            onPressed: () {
              // ...existing code...
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Language button pressed!')),
              );
            },
            tooltip: 'Select Language',
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 32),
              // Header
              const Center(
                child: Text(
                  'Welcome to Dabbler',
                  style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: 12),
              const Center(
                child: Text(
                  'Join the community of sports enthusiasts',
                  style: TextStyle(fontSize: 16, color: Colors.grey),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: 48),

              // Primary: Continue with Email button
              SizedBox(
                height: 56,
                child: ElevatedButton.icon(
                  onPressed: () {
                    debugPrint(
                      '📧 [DEBUG] PhoneInputScreen: Email button pressed',
                    );
                    context.go(RoutePaths.emailInput);
                  },
                  icon: const Icon(Icons.email_outlined, size: 24),
                  label: const Text(
                    'Continue with Email',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).primaryColor,
                    foregroundColor: Colors.white,
                    elevation: 2,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // Secondary: Continue with Google button (disabled for now)
              SizedBox(
                height: 56,
                child: OutlinedButton.icon(
                  onPressed: null, // Disabled for now
                  icon: Icon(
                    Icons.g_mobiledata_rounded,
                    size: 32,
                    color: Colors.grey.shade400,
                  ),
                  label: Text(
                    'Continue with Google',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey.shade400,
                    ),
                  ),
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(color: Colors.grey.shade300),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 32),

              // Divider
              Row(
                children: [
                  Expanded(child: Divider(color: Colors.grey.shade300)),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Text(
                      'or continue with phone',
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 14,
                      ),
                    ),
                  ),
                  Expanded(child: Divider(color: Colors.grey.shade300)),
                ],
              ),

              const SizedBox(height: 32),

              // Phone input
              Form(
                key: _formKey,
                child: TextFormField(
                  controller: _phoneController,
                  decoration: InputDecoration(
                    labelText: 'Phone Number',
                    hintText: '5X XXX XXXX',
                    prefixText: '$_countryCode ',
                    prefixStyle: const TextStyle(
                      color: Colors.black87,
                      fontWeight: FontWeight.w500,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  keyboardType: TextInputType.phone,
                  onChanged: _onPhoneChanged,
                  validator: _validatePhone,
                ),
              ),

              const SizedBox(height: 24),

              // Continue with phone button
              SizedBox(
                height: 56,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _handleSubmit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).primaryColor,
                    foregroundColor: Colors.white,
                    elevation: 2,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          height: 24,
                          width: 24,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              Colors.white,
                            ),
                          ),
                        )
                      : const Text(
                          'Continue',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                ),
              ),

              const Spacer(),

              // Error/Success messages
              if (_errorMessage != null)
                Container(
                  padding: const EdgeInsets.all(12),
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: Colors.red.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.red.withOpacity(0.3)),
                  ),
                  child: Text(
                    _errorMessage!,
                    style: const TextStyle(color: Colors.red),
                  ),
                ),

              if (_successMessage != null)
                Container(
                  padding: const EdgeInsets.all(12),
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: Colors.green.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.green.withOpacity(0.3)),
                  ),
                  child: Text(
                    _successMessage!,
                    style: const TextStyle(color: Colors.green),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
