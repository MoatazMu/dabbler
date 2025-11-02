import 'package:supabase_flutter/supabase_flutter.dart' as supabase;
import 'package:dabbler/data/models/authentication/user_model.dart';
import 'package:dabbler/data/models/authentication/auth_response_model.dart';
import 'package:dabbler/data/models/authentication/auth_session.dart';
// Removed unused direct user entity import; using UserModel conversion
import 'auth_remote_datasource.dart';
import '../../../../core/errors/exceptions.dart';

class SupabaseAuthDataSource implements AuthRemoteDataSource {
  final supabase.SupabaseClient client;
  SupabaseAuthDataSource(this.client);

  @override
  Future<AuthResponseModel> signInWithEmail({
    required String email,
    required String password,
  }) async {
    try {
      print(
        '🔐 [DEBUG] SupabaseAuthDataSource: Attempting sign in for: $email',
      );
      final response = await client.auth.signInWithPassword(
        email: email,
        password: password,
      );

      print(
        '🔐 [DEBUG] SupabaseAuthDataSource: Sign in response - user: ${response.user != null}, session: ${response.session != null}',
      );

      // Accept successful session even if user payload is not populated
      if (response.session != null) {
        print(
          '✅ [DEBUG] SupabaseAuthDataSource: Valid session found, converting to model',
        );
        return _convertSessionToModel(response.session!);
      }
      if (response.user == null) {
        print(
          '❌ [DEBUG] SupabaseAuthDataSource: No user in response, throwing InvalidCredentialsException',
        );
        throw InvalidCredentialsException();
      }
      print(
        '✅ [DEBUG] SupabaseAuthDataSource: Converting full auth response to model',
      );
      return _convertAuthResponseToModel(response);
    } on supabase.AuthException catch (e) {
      print(
        '❌ [DEBUG] SupabaseAuthDataSource: Supabase auth exception: ${e.message}',
      );
      if (e.message.contains('Invalid login credentials')) {
        throw InvalidCredentialsException();
      } else if (e.message.contains('Email not confirmed')) {
        throw UnverifiedEmailException();
      } else {
        throw AuthException(e.message);
      }
    } catch (e) {
      print(
        '❌ [DEBUG] SupabaseAuthDataSource: General exception during signInWithEmail: $e',
      );
      throw NetworkException(e.toString());
    }
  }

  @override
  Future<AuthResponseModel> signInWithPhone({required String phone}) async {
    try {
      await client.auth.signInWithOtp(phone: phone);
      // signInWithOtp returns void, so we create a response model without user/session
      return AuthResponseModel(
        user: null,
        session: null,
        error: null,
        metadata: {'phone': phone, 'otp_sent': true},
      );
    } on supabase.AuthException catch (e) {
      throw AuthException(e.message);
    } catch (e) {
      throw NetworkException(e.toString());
    }
  }

  @override
  Future<AuthResponseModel> signUp({
    required String email,
    required String password,
  }) async {
    try {
      final response = await client.auth.signUp(
        email: email,
        password: password,
      );
      if (response.user == null) throw EmailAlreadyExistsException();
      return _convertAuthResponseToModel(response);
    } on supabase.AuthException catch (e) {
      if (e.message.contains('already registered')) {
        throw EmailAlreadyExistsException();
      } else if (e.message.contains('Weak password')) {
        throw WeakPasswordException();
      } else {
        throw AuthException(e.message);
      }
    } catch (e) {
      throw NetworkException(e.toString());
    }
  }

  @override
  Future<void> signOut() async {
    try {
      await client.auth.signOut();
    } on supabase.AuthException catch (e) {
      throw AuthException(e.message);
    } catch (e) {
      throw NetworkException(e.toString());
    }
  }

  @override
  Future<UserModel> getCurrentUser() async {
    final user = client.auth.currentUser;
    if (user == null) throw AuthException('No user signed in');
    return UserModel.fromSupabaseUser(user);
  }

  @override
  Future<AuthResponseModel> getCurrentSession() async {
    final session = client.auth.currentSession;
    if (session == null) throw AuthException('No active session');
    return _convertSessionToModel(session);
  }

  @override
  Future<void> resetPassword({required String email}) async {
    try {
      await client.auth.resetPasswordForEmail(
        email,
        redirectTo: 'dabbler://app/reset-password',
      );
    } on supabase.AuthException catch (e) {
      throw AuthException(e.message);
    } catch (e) {
      throw NetworkException(e.toString());
    }
  }

  @override
  Future<void> updatePassword({required String newPassword}) async {
    try {
      await client.auth.updateUser(
        supabase.UserAttributes(password: newPassword),
      );
    } on supabase.AuthException catch (e) {
      if (e.message.contains('Weak password')) {
        throw WeakPasswordException();
      } else {
        throw AuthException(e.message);
      }
    } catch (e) {
      throw NetworkException(e.toString());
    }
  }

  @override
  Future<AuthResponseModel> verifyOTP({
    required String phone,
    required String token,
  }) async {
    try {
      final response = await client.auth.verifyOTP(
        phone: phone,
        token: token,
        type: supabase.OtpType.sms,
      );
      return _convertAuthResponseToModel(response);
    } on supabase.AuthException catch (e) {
      throw AuthException(e.message);
    } catch (e) {
      throw NetworkException(e.toString());
    }
  }

  /// Convert Supabase AuthResponse to AuthResponseModel
  AuthResponseModel _convertAuthResponseToModel(
    supabase.AuthResponse response,
  ) {
    return AuthResponseModel(
      user: response.user != null
          ? UserModel.fromSupabaseUser(response.user!)
          : null,
      session: response.session != null
          ? _convertSessionToAuthSession(response.session!)
          : null,
      error: null,
      metadata: null,
    );
  }

  /// Convert Supabase Session to AuthResponseModel
  AuthResponseModel _convertSessionToModel(supabase.Session session) {
    return AuthResponseModel(
      user: UserModel.fromSupabaseUser(session.user),
      session: _convertSessionToAuthSession(session),
      error: null,
      metadata: null,
    );
  }

  /// Convert Supabase Session to AuthSession
  AuthSession _convertSessionToAuthSession(supabase.Session session) {
    return AuthSession(
      accessToken: session.accessToken,
      refreshToken: session.refreshToken ?? '',
      expiresAt: DateTime.fromMillisecondsSinceEpoch(
        (session.expiresAt ?? 0) * 1000,
      ),
      user: UserModel.fromSupabaseUser(session.user),
    );
  }
}
