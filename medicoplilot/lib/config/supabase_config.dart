import 'package:flutter_dotenv/flutter_dotenv.dart';

class SupabaseConfig {
  // Load from .env file
  static String get supabaseUrl => dotenv.env['SUPABASE_URL'] ?? '';
  static String get supabaseAnonKey => dotenv.env['SUPABASE_PUBLISHABLE_KEY'] ?? '';
}

class ApiConfig {
  // Backend API configuration
  static const String baseUrl = 'http://localhost:8001';
  static const Duration timeout = Duration(seconds: 30);
}
