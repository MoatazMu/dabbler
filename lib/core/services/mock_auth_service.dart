/// Mock authentication service for development and testing purposes
/// Provides mock implementations of auth methods without making actual API calls
class MockAuthService {
  /// Simulate sending OTP to a phone number
  /// This is a mock implementation that doesn't make real API calls
  Future<void> sendOtp(String phoneNumber) async {
    print('🔐 [MOCK] MockAuthService: Simulating OTP send to: $phoneNumber');
    
    // Simulate network delay
    await Future.delayed(const Duration(seconds: 2));
    
    // In a real implementation, this would send an actual OTP
    // For mock purposes, we just simulate success
    print('✅ [MOCK] MockAuthService: OTP sent successfully to: $phoneNumber');
    
    // Simulate potential errors for testing (uncomment to test error handling)
    // if (phoneNumber.contains('error')) {
    //   throw Exception('Failed to send OTP to $phoneNumber');
    // }
  }
  
  /// Simulate sending password reset email
  /// This is a mock implementation that doesn't make real API calls
  Future<void> sendPasswordResetEmail(String email) async {
    print('📧 [MOCK] MockAuthService: Simulating password reset email to: $email');
    
    // Simulate network delay
    await Future.delayed(const Duration(seconds: 1));
    
    // In a real implementation, this would send an actual password reset email
    // For mock purposes, we just simulate success
    print('✅ [MOCK] MockAuthService: Password reset email sent successfully to: $email');
    
    // Simulate potential errors for testing (uncomment to test error handling)
    // if (email.contains('invalid')) {
    //   throw Exception('Failed to send password reset email to $email');
    // }
  }
  
  /// Simulate OTP verification (in case it's needed later)
  Future<bool> verifyOtp(String phoneNumber, String otp) async {
    print('🔐 [MOCK] MockAuthService: Simulating OTP verification for: $phoneNumber with OTP: $otp');
    
    // Simulate network delay
    await Future.delayed(const Duration(seconds: 1));
    
    // For mock purposes, accept any 6-digit OTP
    final isValid = otp.length == 6 && RegExp(r'^\d{6}$').hasMatch(otp);
    
    if (isValid) {
      print('✅ [MOCK] MockAuthService: OTP verification successful for: $phoneNumber');
      return true;
    } else {
      print('❌ [MOCK] MockAuthService: OTP verification failed for: $phoneNumber');
      throw Exception('Invalid OTP: $otp');
    }
  }
}