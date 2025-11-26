import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'firebase_options_dev.dart'; // Importamos la config DEV
import 'app.dart'; // Importamos la UI compartida

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  Widget initialScreen = const HomePage();

  try {
    // 1. Definir opciones según plataforma
    FirebaseOptions options = kIsWeb
        ? DefaultFirebaseOptionsDev.web
        : DefaultFirebaseOptionsDev.currentPlatform;

    // 2. 🛑 FIX CRÍTICO: Verificar si ya existe una instancia antes de inicializar
    if (Firebase.apps.isEmpty) {
      await Firebase.initializeApp(
        name: 'materiales-syg-dev', // Nombre específico para evitar conflictos
        options: options,
      );
      print("✅ [DEV] Firebase inicializado correctamente.");
    } else {
      print("ℹ️ [DEV] Firebase ya estaba inicializado, reutilizando instancia.");
    }

  } catch (e) {
    print("❌ [DEV] Error inicializando Firebase: $e");

    // Si es error de duplicado, lo ignoramos para que la app no se detenga
    if (e.toString().contains("duplicate-app") || e.toString().contains("already exists")) {
      print("⚠️ Ignorando error de duplicado, continuamos.");
    } else {
      initialScreen = ErrorScreen(error: e.toString());
    }
  }

  runApp(SyGMaterialesApp(home: initialScreen));
}