import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'firebase_options.dart';

import 'core/constants/app_colors.dart';
import 'features/auth/presentation/pages/auth_gate.dart';
import 'features/auth/presentation/providers/auth_provider.dart';

// --- PROVIDERS ---
import 'features/stock/presentation/providers/producto_provider.dart';
import 'features/stock/presentation/providers/movimiento_stock_provider.dart';
import 'features/clientes/presentation/providers/cliente_provider.dart';
import 'features/obras/presentation/providers/obra_provider.dart';
import 'features/ordenes_internas/presentation/providers/orden_interna_provider.dart';
import 'features/usuarios/presentation/providers/usuarios_provider.dart';
import 'features/acopios/presentation/providers/acopio_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // ✅ SOLUCIÓN ROBUSTA (TRY-CATCH):
  // Intentamos inicializar. Si falla porque "ya existe", ignoramos el error y seguimos.
  try {
    if (Firebase.apps.isEmpty) {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
    }
  } catch (e) {
    debugPrint("⚠️ Firebase ya estaba inicializado (Hot Restart): $e");
  }

  runApp(const MyAppDev());
}

class MyAppDev extends StatelessWidget {
  const MyAppDev({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => ProductoProvider()),
        ChangeNotifierProvider(create: (_) => MovimientoStockProvider()),
        ChangeNotifierProvider(create: (_) => ClienteProvider()),
        ChangeNotifierProvider(create: (_) => ObraProvider()),
        ChangeNotifierProvider(create: (_) => OrdenInternaProvider()),
        ChangeNotifierProvider(create: (_) => UsuariosProvider()),
        ChangeNotifierProvider(create: (_) => AcopioProvider()),
      ],
      child: MaterialApp(
        title: 'S&G Dev',
        debugShowCheckedModeBanner: true,
        theme: ThemeData(
          primaryColor: AppColors.primary,
          colorScheme: ColorScheme.fromSwatch().copyWith(
            primary: AppColors.primary,
            secondary: AppColors.secondary,
          ),
          scaffoldBackgroundColor: AppColors.background,
          useMaterial3: false,
        ),
        home: const AuthGate(),
      ),
    );
  }
}