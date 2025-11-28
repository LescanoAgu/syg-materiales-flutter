import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'firebase_options.dart'; // Configuración de PRODUCCIÓN
import 'app.dart';
import 'features/auth/presentation/pages/auth_gate.dart';
import 'core/services/notification_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  Widget initialScreen = const AuthGate();

  try {
    // 1. Opciones de Producción
    FirebaseOptions options = DefaultFirebaseOptions.currentPlatform;

    // 2. Inicializar
    if (Firebase.apps.isEmpty) {
      await Firebase.initializeApp(
        name: 'syg-prod', // Nombre opcional para distinguir instancias
        options: options,
      );
      print("🏭 [PROD] Sistema S&G Iniciado.");
    }

    // 3. Notificaciones
    try {
      await NotificationService().init();
    } catch (e) {
      print("⚠️ Error push notifications: $e");
    }

  } catch (e) {
    print("❌ Error fatal: $e");
    // En producción, aquí podrías mandar el error a Crashlytics
  }

  runApp(SyGMaterialesApp(home: initialScreen));
}