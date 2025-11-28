import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'core/constants/app_colors.dart';
import 'core/widgets/app_drawer.dart';
import 'features/stock/presentation/pages/stock_page.dart';
import 'features/stock/presentation/providers/producto_provider.dart';
import 'features/stock/presentation/providers/movimiento_stock_provider.dart';
import 'features/clientes/presentation/providers/cliente_provider.dart';
import 'features/acopios/presentation/providers/acopio_provider.dart';
import 'features/obras/presentation/providers/obra_provider.dart';
import 'features/ordenes_internas/presentation/providers/orden_interna_provider.dart';
import 'services/firestore_service.dart';
import 'features/auth/presentation/providers/auth_provider.dart';
import 'features/usuarios/presentation/providers/usuarios_provider.dart';

class SyGMaterialesApp extends StatelessWidget {
  final Widget home;
  const SyGMaterialesApp({super.key, required this.home});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => ProductoProvider()),
        ChangeNotifierProvider(create: (_) => MovimientoStockProvider()),
        ChangeNotifierProvider(create: (_) => ClienteProvider()),
        ChangeNotifierProvider(create: (_) => ObraProvider()),
        ChangeNotifierProvider(create: (_) => AcopioProvider()),
        ChangeNotifierProvider(create: (_) => OrdenInternaProvider()),
        ChangeNotifierProvider(create: (_) => UsuariosProvider()),

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

// HomePage convertida a StatefulWidget para manejar la carga del Seed Data
class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  bool _cargando = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('S&G Materiales - Panel')),
      drawer: const AppDrawer(),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.business_center, size: 100, color: AppColors.primary),
            const SizedBox(height: 20),
            const Text('¡Sistema Conectado!', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            // Muestra en qué entorno estamos (según el título de la app o configuración visual)
            const Chip(label: Text("Entorno Activo")),

            const SizedBox(height: 40),

            // Botón Principal: Ir al Stock
            ElevatedButton.icon(
              icon: const Icon(Icons.inventory),
              label: const Text('Ir al Stock'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                textStyle: const TextStyle(fontSize: 18),
              ),
              onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const StockPage())),
            ),

            const SizedBox(height: 40),
            const Divider(indent: 50, endIndent: 50),
            const SizedBox(height: 20),
            const Text("HERRAMIENTAS DE DESARROLLO", style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold, fontSize: 12)),
            const SizedBox(height: 10),

            // 🔴 BOTÓN DE SEED DATA (Carga Inicial)
            _cargando
                ? const Column(
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 10),
                Text("Inicializando base de datos..."),
              ],
            )
                : FilledButton.icon(
              onPressed: _ejecutarSeedData,
              style: FilledButton.styleFrom(
                backgroundColor: Colors.orange,
                foregroundColor: Colors.white,
              ),
              icon: const Icon(Icons.cloud_upload),
              label: const Text('INICIALIZAR BASE DE DATOS (SEED)'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _ejecutarSeedData() async {
    setState(() => _cargando = true);
    try {
      // Llamamos al servicio que importamos arriba
      await FirestoreService().inicializarBaseDatos();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('✅ Datos cargados correctamente en Firebase'),
              backgroundColor: AppColors.success,
              duration: Duration(seconds: 3),
            )
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error al cargar datos: $e'),
              backgroundColor: AppColors.error,
              duration: const Duration(seconds: 5),
            )
        );
      }
    } finally {
      if (mounted) setState(() => _cargando = false);
    }
  }
}