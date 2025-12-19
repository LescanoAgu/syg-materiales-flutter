import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
// Importamos firebase_options si usas la config generada
import 'firebase_options.dart';

import 'core/constants/app_colors.dart';
import 'features/auth/presentation/pages/auth_gate.dart';
import 'features/auth/presentation/providers/auth_provider.dart';

// --- PROVIDERS DE LA APP ---
import 'features/stock/presentation/providers/producto_provider.dart';
import 'features/stock/presentation/providers/movimiento_stock_provider.dart';
import 'features/clientes/presentation/providers/cliente_provider.dart';
import 'features/obras/presentation/providers/obra_provider.dart';
import 'features/ordenes_internas/presentation/providers/orden_interna_provider.dart';
import 'features/usuarios/presentation/providers/usuarios_provider.dart';
import 'features/acopios/presentation/providers/acopio_provider.dart';

// --- PÁGINA PRINCIPAL NUEVA ---
import 'features/home/presentation/pages/home_hub_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

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
        title: 'S&G Materiales',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          primaryColor: AppColors.primary,
          colorScheme: ColorScheme.fromSwatch().copyWith(
            primary: AppColors.primary,
            secondary: AppColors.secondary,
          ),
          scaffoldBackgroundColor: AppColors.background,
          useMaterial3: false, // O true si prefieres el estilo nuevo
        ),
        // Aquí definimos que AuthGate decida si muestra Login o el Hub
        home: const AuthGate(),
      ),
    );
  }
}