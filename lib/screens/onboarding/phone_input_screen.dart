import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/services/auth_service.dart';
import '../../utils/constants/route_constants.dart';
import '../../features/authentication/presentation/providers/auth_providers.dart';

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
  // ...existing code...
    
    try {
  // ...existing code...
      
      // Check if user exists first
  // ...existing code...
      try {
        final authService = AuthService();
  // ...existing code...
        
        final userExists = await authService.checkUserExistsByPhone(phone);
  // ...existing code...
        
        if (userExists) {
          // ...existing code...
        } else {
          // ...existing code...
        }
        
        // Send OTP regardless of user existence
  // ...existing code...
        await authService.signInWithPhone(phone: phone);
  // ...existing code...
        
        if (mounted) {
          setState(() {
            _successMessage = 'OTP sent! Please check your phone.';
          });
        }
      } catch (dbError) {
  // ...existing code...
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
  // ...existing code...
    if (mounted) {
      try {
        context.push(RoutePaths.otpVerification, extra: {'phone': phone});
  // ...existing code...
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
              // Simple test header
              const Center(
                child: Text(
                  'Welcome to Dabbler Player',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: 12),
              const Center(
                child: Text(
                  'Enter your phone to get started',
                  style: TextStyle(fontSize: 16, color: Colors.grey),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: 48),
              
              // Simple phone input
              Form(
                key: _formKey,
                child: TextFormField(
                  controller: _phoneController,
                  decoration: const InputDecoration(
                    labelText: 'Phone Number',
                    hintText: '5X XXX XXXX',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.phone,
                  onChanged: _onPhoneChanged,
                  validator: _validatePhone,
                ),
              ),
              
              const SizedBox(height: 36),
              
              // Continue button
              ElevatedButton(
                onPressed: _isLoading ? null : () {
                  // ...existing code...
                  // ...existing code...
                  
                  _handleSubmit();
                },
                child: Text(_isLoading ? 'Sending...' : 'Continue'),
              ),
              
              const SizedBox(height: 16),
              
              OutlinedButton(
                onPressed: () async {
                  // ...existing code...
                  // ...existing code...
                  
                  // Sign in as guest first
                  try {
                    // ...existing code...
                    final guestSignIn = ref.read(guestSignInProvider);
                    await guestSignIn();
                    // ...existing code...
                    
                    // Then navigate to home
                    if (mounted) {
                      debugPrint('👤 [DEBUG] PhoneInputScreen: Navigating to home...');
                      context.go(RoutePaths.home);
                      debugPrint('👤 [DEBUG] PhoneInputScreen: Navigation successful');
                    }
                  } catch (e) {
                    debugPrint('❌ [DEBUG] PhoneInputScreen: Guest sign in or navigation error: $e');
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Guest sign in failed: $e')),
                      );
                    }
                  }
                },
                child: const Text('Continue as Guest'),
              ),
              
              const SizedBox(height: 16),
              
              OutlinedButton(
                onPressed: () {
                  debugPrint('📧 [DEBUG] PhoneInputScreen: Email button pressed');
                  debugPrint('📧 [DEBUG] PhoneInputScreen: Button state - mounted: $mounted');
                  
                  // Navigate to email input
                  try {
                    debugPrint('📧 [DEBUG] PhoneInputScreen: Navigating to email input...');
                    context.go(RoutePaths.emailInput);
                    debugPrint('📧 [DEBUG] PhoneInputScreen: Navigation successful');
                  } catch (e) {
                    debugPrint('❌ [DEBUG] PhoneInputScreen: Navigation error: $e');
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Navigation failed: $e')),
                    );
                  }
                },
                child: const Text('Continue using Email'),
              ),
              
              const SizedBox(height: 16),
              
              // Debug info
              if (_errorMessage != null)
                Container(
                  padding: const EdgeInsets.all(12),
                  color: Colors.red.withOpacity(0.1),
                  child: Text(_errorMessage!, style: const TextStyle(color: Colors.red)),
                ),
              
              if (_successMessage != null)
                Container(
                  padding: const EdgeInsets.all(12),
                  color: Colors.green.withOpacity(0.1),
                  child: Text(_successMessage!, style: const TextStyle(color: Colors.green)),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
