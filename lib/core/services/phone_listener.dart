import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/services/auth_service.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/input_field.dart';
// import 'email_input_screen.dart'; // Routing is handled by GoRouter
import '../../core/utils/constants.dart';
// import 'language_selection_screen.dart'; // Routing is handled by GoRouter

class PhoneInputScreen extends StatefulWidget {
  const PhoneInputScreen({super.key});

  @override
  State<PhoneInputScreen> createState() => _PhoneInputScreenState();
}

class _PhoneInputScreenState extends State<PhoneInputScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _phoneController = TextEditingController();
  final String _countryCode = '+971'; // Default to UAE
  bool _isLoading = false;
  String? _errorMessage;
  String? _successMessage;
  bool _isPhoneNumberValid = false;

  @override
  void initState() {
    super.initState();
    _phoneController.addListener(_validatePhoneNumber);
  }

  @override
  void dispose() {
    _phoneController.removeListener(_validatePhoneNumber);
    _phoneController.dispose();
    super.dispose();
  }

  void _validatePhoneNumber() {
    // Basic validation for UAE: 9 digits, numeric.
    final phone = _phoneController.text.trim();
    final isValid = phone.length == 9 && int.tryParse(phone) != null;
    if (_isPhoneNumberValid != isValid) {
      setState(() {
        _isPhoneNumberValid = isValid;
      });
    }
  }

  Future<void> _handleSubmit() async {
    if (!_isPhoneNumberValid) return;
    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _successMessage = null;
    });
    final phone = '$_countryCode${_phoneController.text.trim()}';
    try {
      await AuthService().signInWithPhone(phone: phone);
      setState(() {
        _successMessage = 'OTP sent! Please check your phone.';
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to send OTP: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Sign In'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.language),
            onPressed: () => context.push('/language_selection'),
            tooltip: 'Select Language',
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppConstants.defaultPadding),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 32),
                // Header
                Text(
                  'Welcome to Dabbler Player',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  'Enter your phone to get started',
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: Colors.grey[600],
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 48),
                // Phone Input
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                      decoration: BoxDecoration(
                        color: Colors.grey[100],
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey[300]!),
                      ),
                      child: Row(
                        children: [
                          Text(_countryCode, style: Theme.of(context).textTheme.bodyLarge),
                          const Icon(Icons.arrow_drop_down, size: 24),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: CustomInputField(
                        controller: _phoneController,
                        label: 'Phone Number',
                        placeholder: '5X XXX XXXX',
                        keyboardType: TextInputType.phone,
                        // Optionally add validation here
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 32),
                // Error/Success
                if (_errorMessage != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.red.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.error, color: Colors.red, size: 18),
                          const SizedBox(width: 8),
                          Expanded(child: Text(_errorMessage!, style: TextStyle(color: Colors.red))),
                        ],
                      ),
                    ),
                  ),
                if (_successMessage != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.green.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.check_circle, color: Colors.green, size: 18),
                          const SizedBox(width: 8),
                          Expanded(child: Text(_successMessage!, style: TextStyle(color: Colors.green))),
                        ],
                      ),
                    ),
                  ),
                // Continue Button (Primary)
                CustomButton(
                  onPressed: _isLoading || !_isPhoneNumberValid ? null : _handleSubmit,
                  text: _isLoading ? 'Sending...' : 'Continue',
                ),
                const SizedBox(height: 16),
                // Continue as Guest Button (Secondary)
                CustomButton(
                  onPressed: () {
                    context.go('/home');
                  },
                  text: 'Continue as Guest',
                ),
                const SizedBox(height: 16),
                // Continue with Email Button (Secondary)
                CustomButton(
                  onPressed: () => context.push('/email_input'),
                  text: 'Continue using Email',
                ),
                const Spacer(),
                // Terms and Privacy
                Text(
                  'By continuing, you agree to our Terms of Service and Privacy Policy',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.grey[600],
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
