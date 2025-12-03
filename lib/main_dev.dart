import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart'; // Importante para settings
import 'package:flutter/foundation.dart' show kIsWeb;
import 'firebase_options_dev.dart'; // Tu archivo de config DEV
import 'app.dart';
import 'features/auth/presentation/pages/auth_gate.dart';
import 'core/services/notification_service.dart'; // Importar servicio de notificaciones

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  Widget initialScreen = const AuthGate();

  try {
    // 1. Configuración según plataforma
    FirebaseOptions options = kIsWeb
        ? DefaultFirebaseOptionsDev.web
        : DefaultFirebaseOptionsDev.currentPlatform;

    // 2. Inicializar Firebase (Singleton check)
    if (Firebase.apps.isEmpty) {
      await Firebase.initializeApp(
        options: options,
      );
      print("✅ [DEV] Firebase inicializado correctamente.");
    } else {
      print("ℹ️ [DEV] Firebase ya estaba activo.");
    }

    // 3. 🌐 FIX WEB: Desactivar persistencia para evitar error "offline" en localhost
    if (kIsWeb) {
      try {
        FirebaseFirestore.instance.settings = const Settings(
          persistenceEnabled: false,
        );
        print("🌐 [WEB] Persistencia Firestore desactivada (Modo Dev).");
      } catch (e) {
        print("⚠️ No se pudo configurar settings de Firestore: $e");
      }
    }

    // 4. 🔔 Inicializar Notificaciones
    try {
      await NotificationService().init();
      print("✅ Servicio de Notificaciones iniciado.");
    } catch (e) {
      print("⚠️ Error iniciando notificaciones (Puede ser normal en simulador): $e");
    }

  } catch (e) {
    print("❌ [DEV] Error CRÍTICO en main: $e");
    // Aquí podrías asignar initialScreen a una pantalla de error si quisieras
  }

  runApp(SyGMaterialesApp(home: initialScreen));
}