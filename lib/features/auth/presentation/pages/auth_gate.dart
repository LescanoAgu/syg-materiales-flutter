import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import 'login_page.dart';
import 'access_pending_page.dart';
import '../../../stock/presentation/pages/stock_page.dart'; // Tu Home actual

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, auth, _) {
        switch (auth.status) {
          case AuthStatus.checking:
            return const Scaffold(body: Center(child: CircularProgressIndicator()));

          case AuthStatus.unauthenticated:
            return const LoginPage();

          case AuthStatus.pending:
            return const AccessPendingPage();

          case AuthStatus.authenticated:
          // Aquí redirigimos a tu Home principal (StockPage)
            return const StockPage();
        }
      },
    );
  }
}