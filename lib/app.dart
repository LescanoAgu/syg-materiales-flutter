// lib/app.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'core/constants/app_colors.dart';
import 'core/widgets/app_drawer.dart';
import 'features/stock/presentation/pages/stock_page.dart';

// Providers
import 'features/stock/presentation/providers/producto_provider.dart';
import 'features/stock/presentation/providers/movimiento_stock_provider.dart';
import 'features/clientes/presentation/providers/cliente_provider.dart';
import 'features/acopios/presentation/providers/acopio_provider.dart';
import 'features/obras/presentation/providers/obra_provider.dart';
import 'features/ordenes_internas/presentation/providers/orden_interna_provider.dart';

class SyGMaterialesApp extends StatelessWidget {
  final Widget home;
  const SyGMaterialesApp({super.key, required this.home});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ProductoProvider()),
        ChangeNotifierProvider(create: (_) => MovimientoStockProvider()),
        ChangeNotifierProvider(create: (_) => ClienteProvider()),
        ChangeNotifierProvider(create: (_) => ObraProvider()),
        ChangeNotifierProvider(create: (_) => AcopioProvider()),
        ChangeNotifierProvider(create: (_) => OrdenInternaProvider()),
      ],
      child: MaterialApp(
        title: 'S&G Materiales',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          primaryColor: AppColors.primary,
          colorScheme: ColorScheme.fromSeed(
            seedColor: AppColors.primary,
            primary: AppColors.primary,
            secondary: AppColors.secondary,
          ),
          useMaterial3: true,
          appBarTheme: const AppBarTheme(
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
            centerTitle: true,
          ),
        ),
        home: home,
      ),
    );
  }
}

class ErrorScreen extends StatelessWidget {
  final String error;
  const ErrorScreen({super.key, required this.error});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error, color: AppColors.error, size: 80),
              const SizedBox(height: 20),
              const Text(
                '¡ERROR CRÍTICO AL INICIAR!',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.error),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 10),
              Text(
                'Detalle: $error',
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 14, color: AppColors.textDark),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class HomePage extends StatelessWidget {
  const HomePage({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('S&G Materiales - Panel')),
      drawer: const AppDrawer(),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.check_circle_outline, size: 100, color: AppColors.success),
            const SizedBox(height: 20),
            const Text('¡Sistema Conectado!', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 30),
            ElevatedButton.icon(
              icon: const Icon(Icons.inventory),
              label: const Text('Ir al Stock'),
              onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const StockPage())),
            ),
          ],
        ),
      ),
    );
  }
}