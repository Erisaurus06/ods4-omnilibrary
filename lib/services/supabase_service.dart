import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class SupabaseService {
  static Future<void> inicializar() async {
    // Es mejor cargar el dotenv AQUÍ si quieres separar responsabilidades
    final url = dotenv.env['SUPABASE_URL']!;
    final key = dotenv.env['SUPABASE_ANON_KEY']!;

    await Supabase.initialize(url: url, anonKey: key);
  }

  static SupabaseClient get client => Supabase.instance.client;
}
