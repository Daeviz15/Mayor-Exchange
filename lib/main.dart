import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mayor_exchange/core/constants/supabase_constants.dart';
import 'package:mayor_exchange/core/theme/app_theme.dart';
import 'package:mayor_exchange/features/onboarding/screens/splash_screen.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

Future<void> main() async {
  // Ensure Flutter is initialized
  WidgetsFlutterBinding.ensureInitialized();

  // Load environment variables
  await dotenv.load(fileName: '.env');

  // Initialize Supabase
  await Supabase.initialize(
    url: SupabaseConstants.supabaseUrl,
    anonKey: SupabaseConstants.supabaseAnonKey,
  );

  runApp(const ProviderScope(child: MyApp()));
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Mayor Exchange',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      home: const SplashScreen(),
    );
  }
}
