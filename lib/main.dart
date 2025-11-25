import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';

// Supabase pakai alias biar tidak bentrok dengan Firebase User
import 'package:supabase_flutter/supabase_flutter.dart' as supa;

import 'firebase_options.dart';
import 'supabase_config.dart';
import 'screens/home_screen.dart';
import 'screens/login_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // INIT SUPABASE
  await supa.Supabase.initialize(
    url: supabaseUrl,
    anonKey: supabaseAnonKey,
  );

  // INIT FIREBASE
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Intip App',

      // Stream Firebase Auth → menentukan login atau home
      home: StreamBuilder<User?>(
        stream: FirebaseAuth.instance.authStateChanges(),
        builder: (context, snapshot) {
          // Loading awal
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            );
          }

          // Jika user sudah login → ke Home
          if (snapshot.hasData) {
            return const HomeScreen();
          }

          // Jika belum login → ke LoginScreen
          return const LoginScreen();
        },
      ),
    );
  }
}
