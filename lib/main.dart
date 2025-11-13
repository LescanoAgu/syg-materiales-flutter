import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'services/firestore_service.dart'; // 👈 NUEVO: Importamos nuestro servicio

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
    return MaterialApp(
      title: 'S&G Materiales',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF00A859), // Verde S&G
        ),
        useMaterial3: true,
      ),
      home: const HomePage(),
    );
  }
}

// ========================================
// 🏠 PÁGINA PRINCIPAL (con botón de inicialización)
// ========================================
class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  // 1️⃣ Instancia del servicio de Firestore
  final FirestoreService _firestoreService = FirestoreService();

  // 2️⃣ Variables de estado
  bool _isLoading = false; // Para mostrar un loading mientras carga
  String _statusMessage = 'Presiona el botón para inicializar la base de datos';
  bool _isInitialized = false; // Para saber si ya se inicializó

  // 3️⃣ Función que inicializa la base de datos
  Future<void> _inicializarBaseDatos() async {
    // Activamos el loading
    setState(() {
      _isLoading = true;
      _statusMessage = 'Creando colecciones en Firestore...';
    });

    try {
      // Llamamos al servicio para crear las colecciones
      await _firestoreService.inicializarBaseDatos();

      // Si llegamos acá, todo salió bien
      setState(() {
        _isLoading = false;
        _isInitialized = true;
        _statusMessage = '✅ Base de datos inicializada correctamente\n\n'
            '📦 Se crearon:\n'
            '• 3 Clientes\n'
            '• 3 Obras\n'
            '• 5 Productos\n'
            '• 5 Registros de Stock\n'
            '• 3 Acopios\n'
            '• 4 Movimientos';
      });

      // Mostramos un mensaje de éxito
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('🎉 Base de datos creada exitosamente'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      // Si hubo un error
      setState(() {
        _isLoading = false;
        _statusMessage = '❌ Error al inicializar: $e';
      });

      // Mostramos el error
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    }
  }

  // 4️⃣ Función para ver los datos en Firebase Console
  void _abrirFirebaseConsole() {
    // Esto solo muestra el mensaje, el usuario debe abrir manualmente
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'Abrí Firebase Console en tu navegador para ver los datos:\n'
              'console.firebase.google.com',
        ),
        duration: Duration(seconds: 5),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Barra superior
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: const Text('S&G Materiales - Inicialización'),
      ),

      // Contenido principal
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // 5️⃣ Ícono que cambia según el estado
              Icon(
                _isInitialized
                    ? Icons.check_circle
                    : Icons.cloud_upload,
                size: 100,
                color: _isInitialized
                    ? Colors.green
                    : Theme.of(context).colorScheme.primary,
              ),

              const SizedBox(height: 30),

              // 6️⃣ Título
              Text(
                _isInitialized
                    ? '¡Base de datos lista!'
                    : 'Inicializar Base de Datos',
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 20),

              // 7️⃣ Mensaje de estado
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  _statusMessage,
                  style: const TextStyle(fontSize: 16),
                  textAlign: TextAlign.center,
                ),
              ),

              const SizedBox(height: 40),

              // 8️⃣ Botón de inicializar (solo si no está inicializado)
              if (!_isInitialized && !_isLoading)
                ElevatedButton.icon(
                  onPressed: _inicializarBaseDatos,
                  icon: const Icon(Icons.rocket_launch),
                  label: const Text(
                    'Inicializar Base de Datos',
                    style: TextStyle(fontSize: 18),
                  ),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 32,
                      vertical: 16,
                    ),
                    backgroundColor: Theme.of(context).colorScheme.primary,
                    foregroundColor: Colors.white,
                  ),
                ),

              // 9️⃣ Indicador de carga
              if (_isLoading)
                const Column(
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(height: 16),
                    Text(
                      'Esto puede tardar unos segundos...',
                      style: TextStyle(fontSize: 14, color: Colors.grey),
                    ),
                  ],
                ),

              // 🔟 Botón para abrir Firebase Console (solo si ya se inicializó)
              if (_isInitialized)
                Column(
                  children: [
                    ElevatedButton.icon(
                      onPressed: _abrirFirebaseConsole,
                      icon: const Icon(Icons.open_in_browser),
                      label: const Text('Ver en Firebase Console'),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 12,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Ve a: console.firebase.google.com',
                      style: TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }
}