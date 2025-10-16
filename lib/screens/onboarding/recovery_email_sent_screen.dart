import 'package:flutter/material.dart';
import '../../core/services/auth_service.dart';
import '../../core/utils/constants.dart';
import '../../widgets/custom_button.dart';

class RecoveryEmailSentScreen extends StatefulWidget {
  final String email;

  const RecoveryEmailSentScreen({super.key, required this.email});

  @override
  State<RecoveryEmailSentScreen> createState() => _RecoveryEmailSentScreenState();
}

class _RecoveryEmailSentScreenState extends State<RecoveryEmailSentScreen> {
  final bool _isResending = false;

  Future<void> _handleResendEmail() async {
    try {
      final authService = AuthService();
      await authService.sendPasswordResetEmail(widget.email);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Recovery email sent again!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to resend email: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Recovery Email Sent'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppConstants.defaultPadding),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 32),
              
              // Success Icon
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.green[50],
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.mark_email_read,
                  size: 48,
                  color: Colors.green[700],
                ),
              ),
              
              const SizedBox(height: 32),
              
              // Header
              Text(
                'Check Your Email',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              
              const SizedBox(height: 16),
              
              // Message
              Text(
                'We\'ve sent a password recovery link to',
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: Colors.grey[600],
                ),
                textAlign: TextAlign.center,
              ),
              
              const SizedBox(height: 8),
              
              Text(
                widget.email,
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
                textAlign: TextAlign.center,
              ),
              
              const SizedBox(height: 24),
              
              // Instructions
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.blue[50],
                  borderRadius: BorderRadius.circular(AppConstants.borderRadius),
                  border: Border.all(color: Colors.blue[200]!),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.info_outline,
                          color: Colors.blue[700],
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'What to do next:',
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                            color: Colors.blue[700],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    _buildInstruction('1. Check your email inbox'),
                    _buildInstruction('2. Click the recovery link in the email'),
                    _buildInstruction('3. Create a new password'),
                    _buildInstruction('4. Sign in with your new password'),
                  ],
                ),
              ),
              
              const SizedBox(height: 32),
              
              // Resend Email Button
              CustomButton(
                onPressed: _isResending ? null : _handleResendEmail,
                text: _isResending ? 'Sending...' : 'Resend Email',
              ),
              
              const SizedBox(height: 16),
              
              // Back to Sign In
              TextButton(
                onPressed: () {
                  Navigator.popUntil(context, (route) => route.isFirst);
                },
                child: Text(
                  'Back to Sign In',
                  style: TextStyle(
                    color: Colors.blue[700],
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              
              const Spacer(),
              
              // Help Text
              Text(
                'Didn\'t receive the email? Check your spam folder or try a different email address.',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Colors.grey[600],
                ),
                textAlign: TextAlign.center,
              ),
              
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInstruction(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Colors.blue[700],
              ),
            ),
          ),
        ],
      ),
    );
  }
} 