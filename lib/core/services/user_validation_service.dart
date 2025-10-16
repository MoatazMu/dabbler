import 'package:supabase_flutter/supabase_flutter.dart';
import 'auth_service.dart';

class UserValidationService {
  static final UserValidationService _instance = UserValidationService._internal();
  factory UserValidationService() => _instance;
  UserValidationService._internal();

  final AuthService _authService = AuthService();

  /// Check if a user exists by email using the comprehensive AuthService
  Future<bool> checkUserExists(String email) async {
    try {
      print('🔍 [DEBUG] UserValidationService: Checking if user exists: $email');
      
      // Use the comprehensive AuthService method
      final exists = await _authService.checkUserExistsByEmail(email);
      
      print('🔍 [DEBUG] UserValidationService: User exists: $exists');
      return exists;
    } catch (e) {
      print('❌ [DEBUG] UserValidationService: Error checking user existence: $e');
  // Never attempt to sign up here; just return false on error
  return false;
    }
  }

  /// Check if a user exists by phone using the comprehensive AuthService
  Future<bool> checkUserExistsByPhone(String phone) async {
    try {
      print('🔍 [DEBUG] UserValidationService: Checking if user exists by phone: $phone');
      
      // Use the comprehensive AuthService method
      final exists = await _authService.checkUserExistsByPhone(phone);
      
      print('🔍 [DEBUG] UserValidationService: User exists by phone: $exists');
      return exists;
    } catch (e) {
      print('❌ [DEBUG] UserValidationService: Error checking user existence by phone: $e');
      return false;
    }
  }

  /// Alternative method using admin API (requires admin key)
  /// Note: This method is deprecated and should not be used in production
  @Deprecated('Use checkUserExists() instead')
  Future<bool> checkUserExistsAdmin(String email) async {
    try {
      print('⚠️ [DEBUG] UserValidationService: Using deprecated admin method for: $email');
      // This would require admin privileges
      final response = await Supabase.instance.client
          .from('auth.users')
          .select('id')
          .eq('email', email)
          .maybeSingle();
      final exists = response != null;
      print('🔍 [DEBUG] UserValidationService: Admin check result: $exists');
      return exists;
    } catch (e) {
      print('❌ [DEBUG] UserValidationService: Admin check failed: $e');
      return false;
    }
  }

  /// Validate email format
  bool isValidEmail(String email) {
    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    final isValid = emailRegex.hasMatch(email);
    print('📧 [DEBUG] UserValidationService: Email validation for $email: $isValid');
    return isValid;
  }

  /// Validate phone format (UAE format)
  bool isValidPhone(String phone) {
    // Remove country code if present
    final cleanPhone = phone.replaceFirst(RegExp(r'^\+971'), '');
    final phoneRegex = RegExp(r'^5\d{8}$');
    final isValid = phoneRegex.hasMatch(cleanPhone);
    print('📱 [DEBUG] UserValidationService: Phone validation for $phone: $isValid');
    return isValid;
  }

  /// Validate password strength
  bool isValidPassword(String password) {
    // At least 8 characters, 1 uppercase, 1 lowercase, 1 number
    final passwordRegex = RegExp(r'^(?=.*[a-z])(?=.*[A-Z])(?=.*\d)[a-zA-Z\d@$!%*?&]{8,}$');
    final isValid = passwordRegex.hasMatch(password);
    print('🔐 [DEBUG] UserValidationService: Password validation: $isValid');
    return isValid;
  }

  /// Get password strength score (0-4)
  int getPasswordStrength(String password) {
    int score = 0;
    
    if (password.length >= 8) score++;
    if (password.contains(RegExp(r'[a-z]'))) score++;
    if (password.contains(RegExp(r'[A-Z]'))) score++;
    if (password.contains(RegExp(r'\d'))) score++;
    if (password.contains(RegExp(r'[@$!%*?&]'))) score++;
    
    print('🔐 [DEBUG] UserValidationService: Password strength score: $score');
    return score;
  }

  /// Get password strength description
  String getPasswordStrengthDescription(String password) {
    final score = getPasswordStrength(password);
    
    switch (score) {
      case 0:
      case 1:
        return 'Very Weak';
      case 2:
        return 'Weak';
      case 3:
        return 'Medium';
      case 4:
        return 'Strong';
      case 5:
        return 'Very Strong';
      default:
        return 'Unknown';
    }
  }
} 