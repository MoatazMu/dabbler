import 'package:supabase_flutter/supabase_flutter.dart';
import '../config/supabase_config.dart';
import '../../utils/constants/route_constants.dart';

class AuthService {
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;
  AuthService._internal();

  final SupabaseClient _supabase = Supabase.instance.client;

  // =====================================================
  // AUTHENTICATION METHODS
  // =====================================================

  // Normalize email to avoid hidden/invisible chars and casing issues
  String _normalizeEmail(String email) {
    // Remove zero-width and BOM chars, collapse/strip whitespace, and lowercase
    final noInvisible = email.replaceAll(RegExp(r"[\u200B-\u200D\uFEFF]"), "");
    final noSpaces = noInvisible.replaceAll(RegExp(r"\s+"), "");
    return noSpaces.trim().toLowerCase();
  }

  /// Sign up with email and password
  Future<AuthResponse> signUpWithEmail({
    required String email,
    required String password,
  }) async {
    try {
      final normalizedEmail = _normalizeEmail(email);
      print(
        '🔐 [DEBUG] AuthService: Signing up user with email: $normalizedEmail',
      );

      final response = await _supabase.auth.signUp(
        email: normalizedEmail,
        password: password,
      );

      print('✅ [DEBUG] AuthService: Signup successful for: $normalizedEmail');
      return response;
    } catch (e) {
      print('❌ [DEBUG] AuthService: Signup failed for $email: $e');
      throw Exception('Sign up failed: $e');
    }
  }

  /// Sign up with email and password (NO metadata - we use profiles table)
  Future<AuthResponse> signUpWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    final normalizedEmail = _normalizeEmail(email);

    try {
      print(
        '🔐 [DEBUG] AuthService: Signing up user with email: $normalizedEmail',
      );

      final response = await _supabase.auth.signUp(
        email: normalizedEmail,
        password: password,
        // NO metadata - we store everything in public.profiles
      );

      print('✅ [DEBUG] AuthService: User signed up successfully');
      return response;
    } catch (e) {
      print('❌ [DEBUG] AuthService: Sign up failed: $e');
      throw Exception(
        'Account creation failed. Please try again later or contact support.',
      );
    }
  }

  /// Create profile in public.profiles table (called after onboarding completes)
  Future<void> createProfile({
    required String userId,
    required String displayName,
    required String username,
    required int age,
    required String gender,
    required String intention,
    required String preferredSport,
    String? interests,
  }) async {
    try {
      print('👤 [DEBUG] AuthService: Creating profile for user: $userId');

      // Map intention to profile_type
      final profileType = intention == 'organise' ? 'organiser' : 'player';

      // Check if profile already exists
      final existingProfile = await _supabase
          .from(SupabaseConfig.usersTable)
          .select('id')
          .eq('user_id', userId)
          .maybeSingle();

      if (existingProfile != null) {
        print('✅ [DEBUG] AuthService: Profile already exists');
        return;
      }

      // Update display_name in auth.users metadata
      await _supabase.auth.updateUser(
        UserAttributes(data: {'display_name': displayName}),
      );
      print('✅ [DEBUG] AuthService: Updated display_name in auth.users');

      // Create profile with onboarding data
      final profileData = {
        'user_id': userId,
        'display_name': displayName,
        'username': username,
        'age': age,
        'gender': gender.toLowerCase(),
        'intention': intention.toLowerCase(),
        'profile_type': profileType,
        'preferred_sport': preferredSport.toLowerCase(),
        'interests': interests,
      };

      print('📤 [DEBUG] AuthService: Inserting profile into public.profiles');
      print('📋 [DEBUG] AuthService: Profile data:');
      print('   user_id: $userId');
      print('   display_name: "$displayName"');
      print(
        '   username: "$username" (isEmpty: ${username.isEmpty}, length: ${username.length})',
      );
      print('   age: $age');
      print('   gender: ${gender.toLowerCase()}');
      print('   intention: ${intention.toLowerCase()}');
      print('   profile_type: $profileType');
      print('   preferred_sport: ${preferredSport.toLowerCase()}');
      print('   interests: $interests');

      await _supabase.from(SupabaseConfig.usersTable).insert(profileData);

      print('✅ [DEBUG] AuthService: Profile created successfully');
    } catch (e) {
      print('❌ [DEBUG] AuthService: Profile creation failed: $e');
      throw Exception('Failed to create user profile: ${e.toString()}');
    }
  }

  /// Sign in with email and password
  Future<AuthResponse> signInWithEmail({
    required String email,
    required String password,
  }) async {
    try {
      final normalizedEmail = _normalizeEmail(email);
      print(
        '🔐 [DEBUG] AuthService: Signing in user with email: $normalizedEmail',
      );

      final response = await _supabase.auth.signInWithPassword(
        email: normalizedEmail,
        password: password,
      );

      print('✅ [DEBUG] AuthService: Signin successful for: $normalizedEmail');
      print(
        '🔐 [DEBUG] AuthService: User: ${response.user?.email}, Session: ${response.session != null ? 'Active' : 'None'}',
      );

      // Verify the auth state immediately after signin
      final isAuth = _supabase.auth.currentUser != null;
      print(
        '🔐 [DEBUG] AuthService: Immediate auth check after signin: $isAuth',
      );

      return response;
    } catch (e) {
      print('❌ [DEBUG] AuthService: Signin failed for $email: $e');
      print('❌ [DEBUG] AuthService: Error type: ${e.runtimeType}');
      throw Exception('Sign in failed: $e');
    }
  }

  /// Sign in with phone (OTP)
  Future<void> signInWithPhone({required String phone}) async {
    try {
      print('📱 [DEBUG] AuthService: Sending OTP to phone: $phone');

      await _supabase.auth.signInWithOtp(phone: phone);

      print('✅ [DEBUG] AuthService: OTP sent successfully to: $phone');
    } catch (e) {
      print('❌ [DEBUG] AuthService: OTP send failed for $phone: $e');
      throw Exception('Phone sign in failed: $e');
    }
  }

  /// Verify OTP
  Future<AuthResponse> verifyOtp({
    required String phone,
    required String token,
  }) async {
    try {
      print('🔐 [DEBUG] AuthService: Verifying OTP for phone: $phone');

      final response = await _supabase.auth.verifyOTP(
        phone: phone,
        token: token,
        type: OtpType.sms,
      );

      // After successful OTP verification, mark phone as confirmed in public.users
      if (response.user != null) {
        await _markPhoneAsConfirmed(response.user!.id, phone);
      }

      print('✅ [DEBUG] AuthService: OTP verification successful for: $phone');
      return response;
    } catch (e) {
      print('❌ [DEBUG] AuthService: OTP verification failed for $phone: $e');
      throw Exception('OTP verification failed: $e');
    }
  }

  /// Mark phone as confirmed in public.users table
  /// Note: Phone data is stored in auth.users, not the profiles table
  Future<void> _markPhoneAsConfirmed(String userId, String phone) async {
    try {
      print(
        '📱 [DEBUG] AuthService: Phone confirmation handled by Supabase auth',
      );
      // Phone confirmation is managed by Supabase auth system
      // The profiles table doesn't store phone/email data
    } catch (e) {
      print('⚠️ [DEBUG] AuthService: Failed to mark phone as confirmed: $e');
      // Don't throw error as this is not critical for auth flow
    }
  }

  /// Sign out user
  Future<void> signOut() async {
    try {
      print('🚪 [DEBUG] AuthService: Signing out user');

      await _supabase.auth.signOut();

      print('✅ [DEBUG] AuthService: Signout successful');
    } catch (e) {
      print('❌ [DEBUG] AuthService: Signout failed: $e');
      throw Exception('Sign out failed: $e');
    }
  }

  /// Update user password
  Future<void> updatePassword(String newPassword) async {
    try {
      print('🔐 [DEBUG] AuthService: Updating password');

      await _supabase.auth.updateUser(UserAttributes(password: newPassword));

      print('✅ [DEBUG] AuthService: Password updated successfully');
    } catch (e) {
      print('❌ [DEBUG] AuthService: Password update failed: $e');
      throw Exception('Password update failed: $e');
    }
  }

  /// Send password reset email
  Future<void> sendPasswordResetEmail(String email) async {
    try {
      print('📧 [DEBUG] AuthService: Sending password reset email to: $email');
      // Build deep link that opens the app to reset password screen
      final redirect =
          '${RoutePaths.deepLinkPrefix}${RoutePaths.resetPassword}';
      await _supabase.auth.resetPasswordForEmail(email, redirectTo: redirect);

      print('✅ [DEBUG] AuthService: Password reset email sent to: $email');
    } catch (e) {
      print(
        '❌ [DEBUG] AuthService: Password reset email failed for $email: $e',
      );
      throw Exception('Password reset email failed: $e');
    }
  }

  // =====================================================
  // USER STATUS METHODS
  // =====================================================

  /// Get current authenticated user
  User? getCurrentUser() {
    final user = _supabase.auth.currentUser;
    print('👤 [DEBUG] AuthService: Current user: ${user?.email ?? 'None'}');
    return user;
  }

  /// Check if user is authenticated
  bool isAuthenticated() {
    final authenticated = _supabase.auth.currentUser != null;
    print('🔐 [DEBUG] AuthService: User authenticated: $authenticated');
    return authenticated;
  }

  /// Get current user ID
  String? getCurrentUserId() {
    final userId = _supabase.auth.currentUser?.id;
    print('🆔 [DEBUG] AuthService: Current user ID: $userId');
    return userId;
  }

  /// Get current user email
  String? getCurrentUserEmail() {
    final email = _supabase.auth.currentUser?.email;
    print('📧 [DEBUG] AuthService: Current user email: $email');
    return email;
  }

  // =====================================================
  // USER VALIDATION METHODS
  // =====================================================

  /// Check if a user exists by email in auth.users
  /// Uses a unified database function to query auth.users table
  Future<bool> checkUserExistsByEmail(String email) async {
    final normalizedEmail = _normalizeEmail(email);
    print(
      '🔍 [DEBUG] AuthService: Email check requested for: $normalizedEmail',
    );
    return _checkUserExistsByIdentifier(normalizedEmail);
  }

  /// Check if a user exists by phone in auth.users
  /// Uses a unified database function to query auth.users table
  Future<bool> checkUserExistsByPhone(String phone) async {
    print('🔍 [DEBUG] AuthService: Phone check requested for: $phone');
    return _checkUserExistsByIdentifier(phone);
  }

  /// Internal method to check if a user exists by email or phone in auth.users
  /// Uses a database function that checks both email and phone columns
  Future<bool> _checkUserExistsByIdentifier(String identifier) async {
    try {
      // Call the unified database function to check auth.users
      final response = await _supabase.rpc(
        'check_user_exists_by_identifier',
        params: {'identifier': identifier},
      );

      final exists = response as bool;
      print(
        '✅ [DEBUG] AuthService: User ${exists ? "EXISTS" : "DOES NOT EXIST"} for identifier: $identifier',
      );

      return exists;
    } catch (e) {
      print('❌ [DEBUG] AuthService: Error checking user existence: $e');
      // On error, return false to allow flow to continue to onboarding
      return false;
    }
  }

  // =====================================================
  // USER PROFILE METHODS
  // =====================================================

  /// Get user profile from database
  Future<Map<String, dynamic>?> getUserProfile({List<String>? fields}) async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) {
        print('❌ [DEBUG] AuthService: No authenticated user for profile fetch');
        return null;
      }

      print('👤 [DEBUG] AuthService: Fetching profile for user: ${user.email}');
      final selectFields = (fields == null || fields.isEmpty)
          ? '*'
          : fields.join(',');

      // Use maybeSingle() instead of single() to handle missing profiles gracefully
      final response = await _supabase
          .from(SupabaseConfig.usersTable)
          .select(selectFields)
          .eq('user_id', user.id) // Query by user_id, not id
          .maybeSingle();

      if (response == null) {
        print(
          '⚠️ [DEBUG] AuthService: No profile found in users table for user: ${user.email}',
        );
        print(
          '❌ [DEBUG] AuthService: This should not happen - profile should be created during signup',
        );
        return null;
      }

      print(
        '✅ [DEBUG] AuthService: Profile fetched successfully with display_name: "${response['display_name']}"',
      );
      return response;
    } catch (e) {
      print('❌ [DEBUG] AuthService: Error fetching user profile: $e');
      return null;
    }
  }

  /// Check if username already exists in public.profiles
  Future<bool> checkUsernameExists(String username) async {
    try {
      print(
        '🔍 [DEBUG] AuthService: Checking username availability: $username',
      );

      final result = await _supabase
          .from(SupabaseConfig.usersTable)
          .select('id')
          .eq('username', username)
          .maybeSingle();

      final exists = result != null;
      print(
        exists
            ? '❌ [DEBUG] AuthService: Username ALREADY EXISTS: $username'
            : '✅ [DEBUG] AuthService: Username AVAILABLE: $username',
      );

      return exists;
    } catch (e) {
      print('❌ [DEBUG] AuthService: Error checking username: $e');
      return false; // On error, allow the username (validation will happen on insert)
    }
  }

  /// Batch fetch profiles by IDs with field selection
  Future<List<Map<String, dynamic>>> getProfilesByIds(
    List<String> userIds, {
    List<String>? fields,
  }) async {
    if (userIds.isEmpty) return [];
    final selectFields = (fields == null || fields.isEmpty)
        ? '*'
        : fields.join(',');
    try {
      final rows = await _supabase
          .from(SupabaseConfig.usersTable)
          .select(selectFields)
          .inFilter('user_id', userIds);
      return (rows as List).cast<Map<String, dynamic>>();
    } catch (e) {
      print('❌ [DEBUG] AuthService: Batch profile fetch failed: $e');
      return [];
    }
  }

  /// Update user profile
  Future<Map<String, dynamic>> updateUserProfile({
    String? displayName,
    String? username,
    String? bio,
    String? phone,
    DateTime? dateOfBirth,
    int? age,
    String? gender,
    String? nationality,
    String? skillLevel,
    List<String>? sports,
    List<String>? interests,
    String? intent,
    String? location,
    String? timezone,
    String? language,
  }) async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) throw Exception('User not authenticated');

      print('👤 [DEBUG] AuthService: Updating profile for user: ${user.email}');
      print('📝 [DEBUG] AuthService: Display name to update: "$displayName"');
      print(
        '📝 [DEBUG] AuthService: Age: $age, Gender: $gender, Bio: "${bio?.substring(0, bio.length > 50 ? 50 : bio.length) ?? ''}"',
      );

      // Prefer server-side RPC if available for consistent authorization/validation
      try {
        final response = await _supabase.rpc(
          'update_user_profile',
          params: {
            'user_display_name': displayName,
            'user_username': username,
            'user_bio': bio,
            'user_phone': phone,
            'user_date_of_birth': dateOfBirth?.toIso8601String(),
            'user_age': age,
            'user_gender': gender,
            'user_nationality': nationality,
            'user_skill_level': skillLevel,
            'user_sports': sports,
            'user_interests': interests,
            'user_intent': intent,
            'user_location': location,
            'user_timezone': timezone,
            'user_language': language,
          },
        );

        print('✅ [DEBUG] AuthService: Profile updated successfully via RPC');
        return response;
      } on PostgrestException catch (e) {
        // If RPC is missing (PGRST202) or not yet deployed, fallback to direct table update
        final isMissingRpc =
            e.code == 'PGRST202' ||
            (e.message.toLowerCase().contains('could not find the function') &&
                e.message.toLowerCase().contains('update_user_profile'));

        if (!isMissingRpc) {
          rethrow;
        }

        print(
          '⚠️ [DEBUG] AuthService: RPC update_user_profile not found. Falling back to direct update.',
        );

        // Build updates map with only non-null values to avoid wiping existing data
        final Map<String, dynamic> updates = {
          'updated_at': DateTime.now().toIso8601String(),
        };

        // CRITICAL: display_name is NOT NULL in database - validate before updating
        if (displayName != null) {
          final trimmedName = displayName.trim();
          if (trimmedName.isEmpty) {
            throw Exception(
              'Display name cannot be empty - database constraint will fail',
            );
          }
          if (trimmedName.length < 2) {
            throw Exception('Display name must be at least 2 characters long');
          }
          if (trimmedName.length > 50) {
            throw Exception('Display name must be 50 characters or less');
          }
          updates['display_name'] = trimmedName;
        }

        if (bio != null) {
          updates['bio'] = bio.trim().isEmpty ? null : bio.trim();
        }
        if (phone != null) {
          updates['phone'] = phone.trim().isEmpty ? null : phone.trim();
        }
        // Note: dateOfBirth not supported, we use age instead
        if (age != null) updates['age'] = age;
        if (gender != null && gender.trim().isNotEmpty) {
          updates['gender'] = gender.trim();
        }
        // Note: nationality not supported in current schema
        if (skillLevel != null) {
          updates['skill_level'] = skillLevel.trim().isEmpty
              ? null
              : skillLevel.trim();
        }
        if (sports != null) updates['sports'] = sports;
        // Note: interests not supported, we use sports instead
        if (intent != null && intent.trim().isNotEmpty) {
          updates['intent'] = intent.trim();
        }
        // Note: location not supported in current schema
        if (timezone != null) {
          updates['timezone'] = timezone.trim().isEmpty
              ? null
              : timezone.trim();
        }
        if (language != null) {
          updates['language'] = language.trim().isEmpty
              ? null
              : language.trim();
        }

        print('📋 [DEBUG] AuthService: Updates map: $updates');

        if (updates.length <= 1) {
          // Only updated_at
          print(
            'ℹ️ [DEBUG] AuthService: No profile fields to update. Returning current profile.',
          );
          final current = await _supabase
              .from(SupabaseConfig.usersTable)
              .select()
              .eq('id', user.id)
              .single();
          return current;
        }

        try {
          final updated = await _supabase
              .from(SupabaseConfig.usersTable)
              .update(updates)
              .eq('id', user.id)
              .select()
              .single();

          print(
            '✅ [DEBUG] AuthService: Profile updated successfully via direct table update',
          );
          return updated;
        } on PostgrestException catch (e2) {
          // Handle schema differences gracefully (e.g., full_name vs name, preferred_sports vs sports)
          final isMissingColumn =
              e2.code == '42703' ||
              e2.message.toLowerCase().contains('column') &&
                  e2.message.toLowerCase().contains('does not exist');
          if (!isMissingColumn) rethrow;

          print(
            '⚠️ [DEBUG] AuthService: Column mismatch on profiles table. Retrying with alternate column names.',
          );

          final Map<String, dynamic> altUpdates = {};
          // Map name -> full_name if present
          if (updates.containsKey('name')) {
            altUpdates['full_name'] = updates['name'];
          }
          // Map sports -> preferred_sports if present
          if (updates.containsKey('sports')) {
            altUpdates['preferred_sports'] = updates['sports'];
          }
          // Pass-through others
          if (updates.containsKey('age')) altUpdates['age'] = updates['age'];
          if (updates.containsKey('gender')) {
            altUpdates['gender'] = updates['gender'];
          }
          if (updates.containsKey('intent')) {
            altUpdates['intent'] = updates['intent'];
          }

          // If error reveals a specific missing column, drop it from the retry payload
          try {
            final lower = e2.message.toLowerCase();
            final startIdx = lower.indexOf('column ');
            final endIdx = lower.indexOf(' does not exist');
            if (startIdx != -1 && endIdx != -1 && endIdx > startIdx + 7) {
              final rawCol = e2.message.substring(startIdx + 7, endIdx).trim();
              final missingCol = rawCol
                  .replaceAll('u.', '')
                  .replaceAll('public.', '')
                  .replaceAll('profiles.', '')
                  .trim();
              altUpdates.remove(missingCol);
              // Also remove counterparts if applicable
              if (missingCol == 'name') altUpdates.remove('name');
              if (missingCol == 'sports') altUpdates.remove('sports');
            }
          } catch (_) {
            /* ignore parsing issues */
          }

          if (altUpdates.isEmpty) rethrow;

          final updatedAlt = await _supabase
              .from(SupabaseConfig.usersTable)
              .update(altUpdates)
              .eq('user_id', user.id)
              .select()
              .single();

          print(
            '✅ [DEBUG] AuthService: Profile updated successfully via alternate column names',
          );
          return updatedAlt;
        }
      }
    } catch (e) {
      print('❌ [DEBUG] AuthService: Profile update failed: $e');
      throw Exception('Profile update failed: $e');
    }
  }

  // =====================================================
  // SESSION MANAGEMENT
  // =====================================================

  /// Get current session
  Session? getCurrentSession() {
    final session = _supabase.auth.currentSession;
    print(
      '🔐 [DEBUG] AuthService: Current session: ${session != null ? 'Active' : 'None'}',
    );
    return session;
  }

  /// Check if session is expired
  bool isSessionExpired() {
    final session = _supabase.auth.currentSession;
    if (session == null) return true;

    final now = DateTime.now();
    final expiresAt = DateTime.fromMillisecondsSinceEpoch(
      (session.expiresAt ?? 0) * 1000,
    );
    final expired = now.isAfter(expiresAt);

    print('⏰ [DEBUG] AuthService: Session expired: $expired');
    return expired;
  }

  /// Refresh session
  Future<AuthResponse?> refreshSession() async {
    try {
      print('🔄 [DEBUG] AuthService: Refreshing session');

      final response = await _supabase.auth.refreshSession();

      print('✅ [DEBUG] AuthService: Session refreshed successfully');
      return response;
    } catch (e) {
      print('❌ [DEBUG] AuthService: Session refresh failed: $e');
      return null;
    }
  }
}
