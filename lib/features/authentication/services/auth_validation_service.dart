import '../domain/repositories/auth_repository.dart';
import '../../../../core/services/auth_service.dart';

class AuthValidationService {
  final AuthRepository repository;
  final AuthService _authService = AuthService();
  
  AuthValidationService(this.repository);

  Future<bool> isEmailAvailable(String email) async {
    try {
      // Check if user exists by email - if they exist, email is not available
      final userExists = await _authService.checkUserExistsByEmail(email);
      // Return true if email is available (user doesn't exist), false if unavailable
      return !userExists;
    } catch (e) {
      // If there's an error checking, assume email is available to be safe
      return true;
    }
  }

  Future<bool> isPhoneAvailable(String phone) async {
    try {
      // Check if user exists by phone - if they exist, phone is not available
      final userExists = await _authService.checkUserExistsByPhone(phone);
      // Return true if phone is available (user doesn't exist), false if unavailable
      return !userExists;
    } catch (e) {
      // If there's an error checking, assume phone is available to be safe
      return true;
    }
  }
}
