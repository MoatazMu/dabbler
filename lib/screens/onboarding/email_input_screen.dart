import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/services/auth_service.dart';
import '../../utils/constants/route_constants.dart';
import 'package:go_router/go_router.dart';
import '../../features/authentication/presentation/providers/auth_providers.dart';

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
      debugPrint('📧 [DEBUG] EmailInputScreen: Processing email: $email');
      
      // Check if user exists in database
      debugPrint('🔍 [DEBUG] EmailInputScreen: Checking if user exists in database: $email');
      final authService = AuthService();
      final userExists = await authService.checkUserExistsByEmail(email);
      
      if (userExists) {
        debugPrint('✅ [DEBUG] EmailInputScreen: User exists in database: $email');
        // User exists - redirect to enter password screen
        if (mounted) {
          context.push(RoutePaths.enterPassword, extra: {'email': email});
        }
      } else {
        debugPrint('🆕 [DEBUG] EmailInputScreen: New user, redirecting to profile creation: $email');
        // User doesn't exist - redirect to profile creation (account will be created there)
        if (mounted) {
          context.push(RoutePaths.createUserInfo, extra: {'email': email, 'forceNew': true});
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
              debugPrint('🌐 [DEBUG] EmailInputScreen: Language button pressed');
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
                  'Enter your email to get started',
                  style: TextStyle(fontSize: 16, color: Colors.grey),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: 48),
              
              // Simple email input
              Form(
                key: _formKey,
                child: TextFormField(
                  controller: _emailController,
                  decoration: const InputDecoration(
                    labelText: 'Email Address',
                    hintText: 'Enter your email address',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.emailAddress,
                  onChanged: _onEmailChanged,
                  validator: _validateEmail,
                ),
              ),
              
              const SizedBox(height: 36),
              
              // Simple continue button
              ElevatedButton(
                onPressed: _isLoading ? null : () {
                  debugPrint('📧 [DEBUG] EmailInputScreen: Continue button pressed');
                  debugPrint('📧 [DEBUG] EmailInputScreen: Button state - mounted: $mounted, isLoading: $_isLoading');
                  
                  _handleSubmit();
                },
                child: Text(_isLoading ? 'Sending...' : 'Continue'),
              ),
              
              const SizedBox(height: 16),
              
              // Continue as Guest button
              OutlinedButton(
                onPressed: () async {
                  debugPrint('👤 [DEBUG] EmailInputScreen: Guest button pressed');
                  debugPrint('👤 [DEBUG] EmailInputScreen: Button state - mounted: $mounted');
                  
                  // Sign in as guest first
                  try {
                    debugPrint('👤 [DEBUG] EmailInputScreen: Signing in as guest...');
                    final guestSignIn = ref.read(guestSignInProvider);
                    await guestSignIn();
                    debugPrint('👤 [DEBUG] EmailInputScreen: Guest sign in successful');
                    
                    // Then navigate to home
                    if (mounted) {
                      debugPrint('👤 [DEBUG] EmailInputScreen: Navigating to home...');
                      context.go(RoutePaths.home);
                      debugPrint('📧 [DEBUG] EmailInputScreen: Navigation successful');
                    }
                  } catch (e) {
                    debugPrint('❌ [DEBUG] EmailInputScreen: Guest sign in or navigation error: $e');
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
              
              // Continue with Phone button
              OutlinedButton(
                onPressed: () {
                  debugPrint('📱 [DEBUG] EmailInputScreen: Phone button pressed');
                  debugPrint('📱 [DEBUG] EmailInputScreen: Button state - mounted: $mounted');
                  
                  // Navigate to phone input
                  try {
                    debugPrint('📱 [DEBUG] EmailInputScreen: Navigating to phone input...');
                    context.go(RoutePaths.phoneInput);
                    debugPrint('📱 [DEBUG] EmailInputScreen: Navigation successful');
                  } catch (e) {
                    debugPrint('❌ [DEBUG] EmailInputScreen: Navigation error: $e');
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Navigation failed: $e')),
                    );
                  }
                },
                child: const Text('Continue with Phone'),
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