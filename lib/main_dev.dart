// lib/main_dev.dart
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'firebase_options_dev.dart'; // Importamos la config DEV
import 'app.dart'; // Importamos la UI compartida

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  Widget initialScreen = const HomePage();

  try {
    // ⚠️ LÓGICA CLAVE: Si es Web, usamos .web, si es móvil usamos .currentPlatform
    // Pero siempre de la clase DefaultFirebaseOptionsDev
    FirebaseOptions options = kIsWeb
        ? DefaultFirebaseOptionsDev.web
        : DefaultFirebaseOptionsDev.currentPlatform;

    await Firebase.initializeApp(options: options);
    print("✅ [DEV] Firebase inicializado correctamente: ${options.projectId}");

  } catch (e) {
    print("❌ [DEV] Error inicializando Firebase: $e");
    initialScreen = ErrorScreen(error: e.toString());
  }

  runApp(SyGMaterialesApp(home: initialScreen));
}