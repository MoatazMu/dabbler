import 'package:flutter/material.dart';
import 'package:dabbler/core/services/auth_service.dart';
import 'package:dabbler/core/utils/constants.dart';
import 'package:dabbler/core/utils/validators.dart';
import '../../widgets/app_button.dart';
import '../../widgets/input_field.dart';

class ChangePhoneScreen extends StatefulWidget {
  const ChangePhoneScreen({super.key});

  @override
  State<ChangePhoneScreen> createState() => _ChangePhoneScreenState();
}

class _ChangePhoneScreenState extends State<ChangePhoneScreen> {
  final _formKey = GlobalKey<FormState>();
  final _phoneController = TextEditingController();
  String _selectedCountryCode = '+971';
  bool _isLoading = false;

  final List<Map<String, String>> _countryCodes = [
    {'code': '+971', 'country': 'UAE', 'flag': '🇦🇪'},
    {'code': '+20', 'country': 'Egypt', 'flag': '🇪🇬'},
    {'code': '+1', 'country': 'US', 'flag': '🇺🇸'},
  ];

  @override
  void dispose() {
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final fullPhoneNumber =
          '$_selectedCountryCode${_phoneController.text.replaceAll(RegExp(r'[^\d]'), '')}';

      final authService = AuthService();
      await authService.signInWithPhone(phone: fullPhoneNumber);

      if (mounted) {
        Navigator.pushNamed(
          context,
          '/otp-verification',
          arguments: {'phoneNumber': fullPhoneNumber},
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Change Phone Number'),
        backgroundColor: Colors.transparent,
        elevation: 0,
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
                  'Update Phone Number',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),

                const SizedBox(height: 8),

                Text(
                  'Enter your new phone number to receive verification code',
                  style: Theme.of(
                    context,
                  ).textTheme.bodyLarge?.copyWith(color: Colors.grey[600]),
                  textAlign: TextAlign.center,
                ),

                const SizedBox(height: 48),

                // Phone Input
                Row(
                  children: [
                    // Country Code Dropdown
                    Container(
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey[300]!),
                        borderRadius: BorderRadius.circular(
                          AppConstants.borderRadius,
                        ),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: _selectedCountryCode,
                          items: _countryCodes.map((country) {
                            return DropdownMenuItem(
                              value: country['code'],
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(country['flag']!),
                                    const SizedBox(width: 4),
                                    Text(country['code']!),
                                  ],
                                ),
                              ),
                            );
                          }).toList(),
                          onChanged: (value) {
                            if (value != null) {
                              setState(() => _selectedCountryCode = value);
                            }
                          },
                        ),
                      ),
                    ),

                    const SizedBox(width: 12),

                    // Phone Number Input
                    Expanded(
                      child: CustomInputField(
                        controller: _phoneController,
                        label: 'Phone Number',
                        hintText: 'Enter your new phone number',
                        keyboardType: TextInputType.phone,
                        validator: AppValidators.validatePhoneNumber,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 32),

                // Update Button
                AppButton(
                  onPressed: _isLoading ? null : _handleSubmit,
                  label: _isLoading ? 'Saving...' : 'Continue',
                ),

                const Spacer(),

                // Info Text
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.blue[50],
                    borderRadius: BorderRadius.circular(
                      AppConstants.borderRadius,
                    ),
                    border: Border.all(color: Colors.blue[200]!),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.info_outline,
                        color: Colors.blue[700],
                        size: 20,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'A verification code will be sent to your new phone number to confirm the change.',
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(color: Colors.blue[700]),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 16),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
