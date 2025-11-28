import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'firebase_options_dev.dart';
import 'app.dart';
import 'features/auth/presentation/pages/auth_gate.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  Widget initialScreen = const AuthGate();

  try {
    FirebaseOptions options = kIsWeb
        ? DefaultFirebaseOptionsDev.web
        : DefaultFirebaseOptionsDev.currentPlatform;

    if (Firebase.apps.isEmpty) {
      await Firebase.initializeApp(
        // ❌ BORRAMOS ESTA LÍNEA: name: 'materiales-syg-dev',
        options: options,
      );
      print("✅ [DEV] Firebase DEFAULT inicializado.");
    } else {
      print("ℹ️ [DEV] Firebase ya estaba inicializado.");
    }

  } catch (e) {
    print("❌ [DEV] Error: $e");
    // Opcional: initialScreen = ErrorScreen(...)
  }

  runApp(SyGMaterialesApp(home: initialScreen));

  if (kIsWeb) {
    FirebaseFirestore.instance.settings = const Settings(
      persistenceEnabled: false, // 👈 ESTO ES OBLIGATORIO EN WEB DEV
    );
  }

}