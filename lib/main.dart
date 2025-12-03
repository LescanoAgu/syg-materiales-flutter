import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'app.dart';
import 'features/auth/presentation/pages/auth_gate.dart';
import 'core/services/notification_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  Widget initialScreen = const AuthGate();

  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );

    // Inicializar Notificaciones
    try {
      await NotificationService().init();
    } catch (e) {
      print("⚠️ Error push notifications: $e");
    }

  } catch (e) {
    print("❌ Error fatal: $e");
  }

  runApp(SyGMaterialesApp(home: initialScreen));
}