import 'package:flutter_dotenv/flutter_dotenv.dart';

class SupabaseConfig {
  // Load from .env file
  static String get supabaseUrl => dotenv.env['SUPABASE_URL'] ?? '';
  static String get supabaseAnonKey => dotenv.env['SUPABASE_PUBLISHABLE_KEY'] ?? '';
}

class ApiConfig {
  static String get baseUrl => dotenv.env['BACKEND_URL'] ?? 'http://localhost:8000';
}
