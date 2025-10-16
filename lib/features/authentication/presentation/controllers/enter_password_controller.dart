
import '../providers/auth_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/services/auth_service.dart';

// State class for Enter Password screen
class EnterPasswordState {
  final bool isLoading;
  final bool obscurePassword;
  final String? errorMessage;
  final bool isSuccess;

  const EnterPasswordState({
    this.isLoading = false,
    this.obscurePassword = true,
    this.errorMessage,
    this.isSuccess = false,
  });

  EnterPasswordState copyWith({
    bool? isLoading,
    bool? obscurePassword,
    String? errorMessage,
    bool? isSuccess,
  }) {
    return EnterPasswordState(
      isLoading: isLoading ?? this.isLoading,
      obscurePassword: obscurePassword ?? this.obscurePassword,
      errorMessage: errorMessage,
      isSuccess: isSuccess ?? this.isSuccess,
    );
  }
}

// Controller for Enter Password screen business logic
class EnterPasswordController extends StateNotifier<EnterPasswordState> {
  final AuthService _authService;

  EnterPasswordController(this._authService) : super(const EnterPasswordState());

  // Toggle password visibility
  void togglePasswordVisibility() {
    state = state.copyWith(obscurePassword: !state.obscurePassword);
  }

  // Clear error message
  void clearError() {
    state = state.copyWith(errorMessage: null);
  }

  // Validate password input
  String? validatePassword(String? password) {
    if (password == null || password.isEmpty) {
      return 'Enter password';
    }
    return null;
  }

  // Sign in with email and password
  Future<void> signIn({
    required String email,
    required String password,
  }) async {
    // Clear any previous errors and set loading state
    state = state.copyWith(
      isLoading: true,
      errorMessage: null,
      isSuccess: false,
    );

    try {
      final result = await _authService.signInWithEmail(
        email: email,
        password: password,
      );

      if (result.user != null) {
        state = state.copyWith(
          isLoading: false,
          isSuccess: true,
        );
      } else {
        state = state.copyWith(
          isLoading: false,
          errorMessage: 'Invalid email or password',
        );
      }
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Sign in failed: ${e.toString()}',
      );
    }
  }

  // Reset state when screen is disposed or needs reset
  void reset() {
    state = const EnterPasswordState();
  }
}



// Provider for EnterPasswordController
final enterPasswordControllerProvider = StateNotifierProvider.family<
    EnterPasswordController, EnterPasswordState, String>((ref, email) {
  final authService = ref.read(authServiceProvider);
  return EnterPasswordController(authService);
});

// Convenience providers for specific state properties
final enterPasswordLoadingProvider = Provider.family<bool, String>((ref, email) {
  return ref.watch(enterPasswordControllerProvider(email)).isLoading;
});

final enterPasswordErrorProvider = Provider.family<String?, String>((ref, email) {
  return ref.watch(enterPasswordControllerProvider(email)).errorMessage;
});

final enterPasswordObscureProvider = Provider.family<bool, String>((ref, email) {
  return ref.watch(enterPasswordControllerProvider(email)).obscurePassword;
});

final enterPasswordSuccessProvider = Provider.family<bool, String>((ref, email) {
  return ref.watch(enterPasswordControllerProvider(email)).isSuccess;
});