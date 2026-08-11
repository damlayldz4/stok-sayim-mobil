import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'screens/assigned_counts_screen.dart';
import 'screens/login_screen.dart';
import 'services/api_client.dart';
import 'services/auth_service.dart';

void main() {
  runApp(const StokSayimApp());
}

class StokSayimApp extends StatelessWidget {
  const StokSayimApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => AuthService(ApiClient()),
      child: MaterialApp(
        title: 'Stok Sayım',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          colorSchemeSeed: const Color(0xFF0F172A),
          useMaterial3: true,
        ),
        home: const AuthGate(),
      ),
    );
  }
}

/// Uygulama açılışında token kontrolü bitene kadar yüklenme ekranı
/// gösterir, ardından oturum durumuna göre Login ya da Home'a yönlendirir.
class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthService>();

    if (auth.isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return auth.isLoggedIn ? const AssignedCountsScreen() : const LoginScreen();
  }
}