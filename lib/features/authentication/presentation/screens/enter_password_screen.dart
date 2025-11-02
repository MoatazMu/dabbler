import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dabbler/core/services/auth_service.dart';
import '../providers/auth_providers.dart';
import '../../../../utils/constants/route_constants.dart';

class EnterPasswordScreen extends ConsumerStatefulWidget {
  final String email;
  const EnterPasswordScreen({super.key, required this.email});

  @override
  ConsumerState<EnterPasswordScreen> createState() =>
      _EnterPasswordScreenState();
}

class _EnterPasswordScreenState extends ConsumerState<EnterPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _signIn() async {
    if (!(_formKey.currentState?.validate() ?? false)) {
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final authService = AuthService();
      final result = await authService.signInWithEmail(
        email: widget.email,
        password: _passwordController.text,
      );

      if (result.user != null) {
        print(
          '🔐 [DEBUG] EnterPasswordScreen: Login successful, user: ${result.user?.email}',
        );

        // Handle successful login with the new method
        print('🔐 [DEBUG] EnterPasswordScreen: Handling successful login...');
        await ref.read(simpleAuthProvider.notifier).handleSuccessfulLogin();

        // Check if auth state was updated properly
        final authState = ref.read(simpleAuthProvider);
        print(
          '🔐 [DEBUG] EnterPasswordScreen: Auth state after refresh - authenticated: ${authState.isAuthenticated}, loading: ${authState.isLoading}',
        );

        // Let GoRouter redirect based on updated auth state; do not navigate manually
        return;
      } else {
        print('❌ [DEBUG] EnterPasswordScreen: Login failed - no user returned');
        setState(() {
          _errorMessage = 'Invalid email or password';
        });
      }
    } catch (e) {
      print('❌ [DEBUG] EnterPasswordScreen: Exception during login: $e');
      print('❌ [DEBUG] EnterPasswordScreen: Exception type: ${e.runtimeType}');

      final errText = e.toString().toLowerCase();
      final isInvalidCreds =
          errText.contains('invalid login credentials') ||
          errText.contains('invalid_credentials') ||
          errText.contains('invalid email or password') ||
          errText.contains('email not confirmed');

      setState(() {
        if (isInvalidCreds) {
          _errorMessage =
              'invalid_credentials'; // Special marker for showing create account button
        } else {
          _errorMessage = 'Sign in failed: ${e.toString()}';
        }
      });
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
    return Scaffold(
      appBar: AppBar(title: const Text('Enter Password')),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final bottomInset = MediaQuery.viewInsetsOf(context).bottom;
            return SingleChildScrollView(
              padding: EdgeInsets.fromLTRB(16, 16, 16, 16 + bottomInset),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight: constraints.maxHeight - 16,
                ),
                child: Form(
                  key: _formKey,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Email: ${widget.email}',
                        style: const TextStyle(fontSize: 16),
                      ),
                      const SizedBox(height: 8),
                      TextButton(
                        onPressed: () => context.go(RoutePaths.phoneInput),
                        child: const Text('Change Email'),
                      ),
                      const SizedBox(height: 24),
                      TextFormField(
                        controller: _passwordController,
                        decoration: InputDecoration(
                          labelText: 'Password',
                          suffixIcon: IconButton(
                            icon: Icon(
                              _obscurePassword
                                  ? Icons.visibility
                                  : Icons.visibility_off,
                            ),
                            onPressed: () => setState(
                              () => _obscurePassword = !_obscurePassword,
                            ),
                          ),
                        ),
                        obscureText: _obscurePassword,
                        validator: (v) =>
                            v == null || v.isEmpty ? 'Enter password' : null,
                        textInputAction: TextInputAction.done,
                        onFieldSubmitted: (_) => _signIn(),
                      ),
                      const SizedBox(height: 24),
                      SizedBox(
                        width: double.infinity,
                        height: 48,
                        child: ElevatedButton(
                          onPressed: _isLoading ? null : _signIn,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Theme.of(context).primaryColor,
                            foregroundColor: Colors.white,
                            elevation: 2,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: _isLoading
                              ? const SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                      Colors.white,
                                    ),
                                  ),
                                )
                              : const Text(
                                  'Login',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton(
                          onPressed: () => context.go(
                            RoutePaths.forgotPassword,
                            extra: {'email': widget.email},
                          ),
                          child: const Text('Forgot Password?'),
                        ),
                      ),
                      if (_errorMessage != null) ...[
                        const SizedBox(height: 16),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.red.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            _errorMessage == 'invalid_credentials'
                                ? 'Invalid email or password'
                                : _errorMessage!,
                            style: const TextStyle(color: Colors.red),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
