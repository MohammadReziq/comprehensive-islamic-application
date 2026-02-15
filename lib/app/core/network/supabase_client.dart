import 'package:supabase_flutter/supabase_flutter.dart';

/// ─── Supabase Configuration ───
class SupabaseConfig {
  static const String url = 'https://nyiejilwpwhmednjqcho.supabase.co';
  static const String anonKey =
      'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Im55aWVqaWx3cHdobWVkbmpxY2hvIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzExNTQ2MTMsImV4cCI6MjA4NjczMDYxM30.6f76zarwrPoWX_21AxMOl_iglsUsa4a35Zbfa7Vn24s';
}

/// Helper للوصول السريع لـ Supabase client
SupabaseClient get supabase => Supabase.instance.client;
