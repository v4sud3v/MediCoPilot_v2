import 'package:supabase_flutter/supabase_flutter.dart';

class AuthService {
  final SupabaseClient _supabase = Supabase.instance.client;

  // Get current user
  User? get currentUser => _supabase.auth.currentUser;

  // Check if user is signed in
  bool get isSignedIn => currentUser != null;

  // Sign in with email and password
  Future<AuthResponse> signIn({
    required String email,
    required String password,
  }) async {
    return await _supabase.auth.signInWithPassword(
      email: email,
      password: password,
    );
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
        
        print('✅ Successfully inserted doctor: $result');
      } catch (e) {
        print('❌ Error inserting into doctors table: $e');
        print('User ID: ${response.user!.id}');
        print('Email: $email');
        // Don't rethrow - allow signup to complete even if doctor insert fails
      }
    }

    return response;
  }

  // Sign out
  Future<void> signOut() async {
    await _supabase.auth.signOut();
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
      await _supabase
          .from('doctors')
          .update(updates)
          .eq('id', currentUser!.id);
    }
  }

  // Reset password
  Future<void> resetPassword(String email) async {
    await _supabase.auth.resetPasswordForEmail(email);
  }

  // Listen to auth state changes
  Stream<AuthState> get authStateChanges => _supabase.auth.onAuthStateChange;
}
