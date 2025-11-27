// lib/main_dev.dart
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'firebase_options_dev.dart'; // Importamos la config DEV
import 'app.dart'; // Importamos la UI compartida
import 'features/auth/presentation/pages/auth_gate.dart';
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  Widget initialScreen = const AuthGate();

  try {
    // 1. Definir opciones según plataforma
    FirebaseOptions options = kIsWeb
        ? DefaultFirebaseOptionsDev.web
        : DefaultFirebaseOptionsDev.currentPlatform;

    // 2. 🛑 FIX: Verificar si ya existe una instancia antes de inicializar
    if (Firebase.apps.isEmpty) {
      await Firebase.initializeApp(
        name: 'materiales-syg-dev', // Opcional: Darle nombre específico en dev ayuda a evitar conflictos
        options: options,
      );
      print("✅ [DEV] Firebase inicializado correctamente: ${options.projectId}");
    } else {
      // Si ya existe, usamos la instancia [DEFAULT] o la que esté activa
      print("ℹ️ [DEV] Firebase ya estaba inicializado, reutilizando instancia.");
    }

  } catch (e) {
    print("❌ [DEV] Error inicializando Firebase: $e");

    // Si el error es "duplicate-app" (por si acaso falla el check), lo ignoramos y seguimos
    if (e.toString().contains("duplicate-app")) {
      print("⚠️ Ignorando error de duplicado, la app puede continuar.");
    } else {
      // Solo mostramos pantalla de error si es algo grave (ej: sin internet, json corrupto)
      initialScreen = ErrorScreen(error: e.toString());
    }
  }

  runApp(SyGMaterialesApp(home: initialScreen));
}