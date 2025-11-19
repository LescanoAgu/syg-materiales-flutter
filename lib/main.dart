// lib/main.dart
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

// Importa las opciones generadas por FlutterFire
import 'firebase_options.dart';

// Si usás Provider:
import 'package:provider/provider.dart';

// IMPORTA AQUÍ TUS PROVIDERS REALES
// import 'features/stock/presentation/providers/stock_provider.dart';
// import 'features/stock/presentation/providers/movimiento_stock_provider.dart';
// import 'features/clientes/presentation/providers/cliente_provider.dart';
// import 'features/obras/presentation/providers/obra_provider.dart';
// etc...

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );

    runApp(const MyApp());
  } catch (e, st) {
    // Si Firebase falla al iniciar, te lo muestra en consola
    debugPrint('❌ Error al inicializar Firebase: $e');
    debugPrintStack(stackTrace: st);
    runApp(const FirebaseErrorApp());
  }
}

/// App principal cuando Firebase se inicializa correctamente
class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    // Si usás Provider, envolvemos acá
    return MultiProvider(
      providers: [
        // Ejemplos, descomenta y adapta:
        // ChangeNotifierProvider(create: (_) => StockProvider()),
        // ChangeNotifierProvider(create: (_) => MovimientoStockProvider()),
        // ChangeNotifierProvider(create: (_) => ClienteProvider()),
        // ChangeNotifierProvider(create: (_) => ObraProvider()),
      ],
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'SYG Materiales',
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF005E9C)),
          useMaterial3: true,
        ),
        home: const HomePage(),
      ),
    );
  }
}

/// App alternativa si Firebase no se pudo inicializar
class FirebaseErrorApp extends StatelessWidget {
  const FirebaseErrorApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        body: Center(
          child: Text(
            'Error al inicializar Firebase.\nRevisá la consola.',
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }
}

/// Pantalla inicial simple para probar conexión a Firestore
class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  String _status = 'Sin probar';

  Future<void> _testFirestorePing() async {
    setState(() {
      _status = 'Probando conexión a Firestore...';
    });

    try {
      final firestore = FirebaseFirestore.instance;

      // Escribimos un documentito de prueba
      await firestore.collection('debug').add({
        'mensaje': 'Ping desde la app',
        'timestamp': DateTime.now().toIso8601String(),
      });

      setState(() {
        _status = '✅ Firestore OK: se pudo escribir en /debug';
      });
    } catch (e, st) {
      debugPrint('❌ Error conectando a Firestore: $e');
      debugPrintStack(stackTrace: st);
      setState(() {
        _status = '❌ Error conectando a Firestore: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // Acá después podés poner tus botones:
    // "Ir a Stock", "Ir a Acopios", etc.
    return Scaffold(
      appBar: AppBar(
        title: const Text('SYG Materiales - Dev'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            const Text(
              'Prueba de conexión a Firebase / Firestore',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _testFirestorePing,
              child: const Text('Probar Firestore (escribir en /debug)'),
            ),
            const SizedBox(height: 24),
            Text(
              _status,
              style: const TextStyle(fontSize: 16),
            ),
          ],
        ),
      ),
    );
  }
}
