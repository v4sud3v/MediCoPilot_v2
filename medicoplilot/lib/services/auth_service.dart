import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'token_service.dart';

class AuthService {
  final SupabaseClient _supabase = Supabase.instance.client;
  final TokenService _tokenService = TokenService();

  // Get current user
  User? get currentUser => _supabase.auth.currentUser;

  // Check if user is signed in
  bool get isSignedIn => currentUser != null;

  // Get current session
  Session? get currentSession => _supabase.auth.currentSession;

  // Sign in with email and password
  Future<AuthResponse> signIn({
    required String email,
    required String password,
  }) async {
    final response = await _supabase.auth.signInWithPassword(
      email: email,
      password: password,
    );

    // Save session data for persistence
    if (response.user != null && response.session != null) {
      await _tokenService.saveToken(response.session!.accessToken);
      await _tokenService.saveUserData({
        'id': response.user!.id,
        'email': response.user!.email,
      });
    }

    return response;
  }

  // Restore session from saved token
  Future<bool> restoreSession() async {
    try {
      final token = await _tokenService.getToken();
      if (token != null) {
        // Check if user is still valid
        if (currentUser != null) {
          return true;
        }
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  // Sign up new doctor
  Future<AuthResponse> signUp({
    required String email,
    required String password,
    required String name,
    String? specialization,
  }) async {
    // Create auth user
    final response = await _supabase.auth.signUp(
      email: email,
      password: password,
    );

    // If signup successful, insert into doctors table
    // Note: This works even without a session if RLS is disabled
    if (response.user != null) {
      try {
        final result = await _supabase.from('doctors').insert({
          'id': response.user!.id,
          'name': name,
          'email': email,
          'specialization': specialization,
        }).select();
        debugPrint('✅ Successfully inserted doctor: $result');
      } catch (e) {
        // Don't rethrow - allow signup to complete even if doctor insert fails
      }
    }

    return response;
  }

  // Sign out
  Future<void> signOut() async {
    await _supabase.auth.signOut();
    // Clear saved session data
    await _tokenService.clearAll();
  }

  // Get doctor details from doctors table
  Future<Map<String, dynamic>?> getDoctorDetails() async {
    if (currentUser == null) return null;

    final response = await _supabase
        .from('doctors')
        .select()
        .eq('id', currentUser!.id)
        .maybeSingle();

    return response;
  }

  // Update doctor profile
  Future<void> updateDoctorProfile({
    String? name,
    String? specialization,
  }) async {
    if (currentUser == null) {
      throw Exception('No user logged in');
    }

    final updates = <String, dynamic>{};
    if (name != null) updates['name'] = name;
    if (specialization != null) updates['specialization'] = specialization;

    if (updates.isNotEmpty) {
      await _supabase.from('doctors').update(updates).eq('id', currentUser!.id);
    }
  }

  // Reset password
  Future<void> resetPassword(String email) async {
    await _supabase.auth.resetPasswordForEmail(email);
  }

  // Listen to auth state changes
  Stream<AuthState> get authStateChanges => _supabase.auth.onAuthStateChange;
}
