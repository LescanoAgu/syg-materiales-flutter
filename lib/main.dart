import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart'; // Asegúrate de que este archivo exista (generado por flutterfire)
import 'app.dart';
import 'features/auth/presentation/pages/auth_gate.dart';
import 'core/services/notification_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );

    // Inicializar Notificaciones (opcional, no bloquea la app si falla)
    try {
      await NotificationService().init();
    } catch (e) {
      debugPrint("⚠️ Error push notifications: $e");
    }

  } catch (e) {
    debugPrint("❌ Error fatal Firebase: $e");
  }

  // ✅ Aquí definimos la pantalla de inicio
  runApp(const SyGMaterialesApp(home: AuthGate()));
}