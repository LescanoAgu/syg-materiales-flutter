import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
// Importamos las pantallas principales
import 'features/stock/presentation/pages/stock_page.dart';
import 'core/widgets/app_drawer.dart';
import 'core/constants/app_colors.dart';

// Importamos los Providers
import 'features/stock/presentation/providers/producto_provider.dart';
import 'features/stock/presentation/providers/movimiento_stock_provider.dart';
import 'features/clientes/presentation/providers/cliente_provider.dart';
import 'features/acopios/presentation/providers/acopio_provider.dart';
import 'features/obras/presentation/providers/obra_provider.dart';
import 'features/ordenes_internas/presentation/providers/orden_interna_provider.dart';

void main() async {
  // 1. Inicializar Binding de Flutter
  WidgetsFlutterBinding.ensureInitialized();

  // 2. Inicializar Firebase
  try {
    await Firebase.initializeApp();
    print("✅ Firebase inicializado correctamente");
  } catch (e) {
    print("❌ Error al inicializar Firebase: $e");
  }

  // 3. Correr la App
  runApp(const SyGMaterialesApp());
}

class SyGMaterialesApp extends StatelessWidget {
  const SyGMaterialesApp({super.key});

  @override
  Widget build(BuildContext context) {
    // MultiProvider inyecta la lógica en toda la app
    return MultiProvider(
      providers: [
        // Stock y Productos
        ChangeNotifierProvider(create: (_) => ProductoProvider()),
        ChangeNotifierProvider(create: (_) => MovimientoStockProvider()),

        // Clientes y Obras
        ChangeNotifierProvider(create: (_) => ClienteProvider()),
        ChangeNotifierProvider(create: (_) => ObraProvider()),

        // Acopios
        ChangeNotifierProvider(create: (_) => AcopioProvider()),

        // Órdenes
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
        // Definimos la página de inicio (puedes cambiarla si tienes un Login)
        home: const HomePage(),
      ),
    );
  }
}

// Página \"Home\" temporal para tener un punto de entrada con el Drawer
class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('S&G Materiales - Panel')),
      drawer: const AppDrawer(), // Aquí está el menú lateral que arreglamos
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.check_circle_outline, size: 100, color: AppColors.success),
            const SizedBox(height: 20),
            const Text(
              '¡Sistema Conectado a Firebase!',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            const Text('Usa el menú lateral para navegar'),
            const SizedBox(height: 30),
            ElevatedButton.icon(
              icon: const Icon(Icons.inventory),
              label: const Text('Ir al Stock'),
              onPressed: () {
                Navigator.push(context, MaterialPageRoute(builder: (_) => const StockPage()));
              },
            ),
          ],
        ),
      ),
    );
  }
}