import 'package:flutter/material.dart';
import 'login_page.dart';
import 'business_login_page.dart';
import 'landing_page.dart';

void main() {
  runApp(const PricelyApp());
}

class PricelyApp extends StatelessWidget {
  const PricelyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Pricely',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorSchemeSeed: const Color(0xFF1A73E8),
        useMaterial3: true,
        fontFamily: 'Roboto',
      ),
      routes: {
        '/login': (_) => const LoginPage(),
        '/business-login': (_) => const BusinessLoginPage(),
      },
      home: const LandingPage(),
    );
  }
}
