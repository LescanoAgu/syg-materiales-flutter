// lib/firebase_options_dev.dart
import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

/// Opciones de configuración para el entorno de DESARROLLO (materiales-syg-dev)
class DefaultFirebaseOptionsDev {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      return web;
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        return ios;
      case TargetPlatform.macOS:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for macos.',
        );
      case TargetPlatform.windows:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for windows.',
        );
      case TargetPlatform.linux:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for linux.',
        );
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not supported for this platform.',
        );
    }
  }

  // -------------------------------------------------------------------------
  // ⚠️ TAREA JR: Copia estos valores desde Firebase Console > Project Settings
  // para el proyecto "materiales-syg-dev"
  // -------------------------------------------------------------------------

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'LLENAR_API_KEY_WEB_DEV', // Ej: AIzaSyD...
    appId: 'LLENAR_APP_ID_WEB_DEV',   // Ej: 1:123456789:web:abc123...
    messagingSenderId: 'LLENAR_SENDER_ID_DEV',
    projectId: 'materiales-syg-dev', // El ID de tu proyecto dev
    authDomain: 'materiales-syg-dev.firebaseapp.com',
    storageBucket: 'materiales-syg-dev.firebasestorage.app',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'LLENAR_API_KEY_ANDROID_DEV',
    appId: 'LLENAR_APP_ID_ANDROID_DEV',
    messagingSenderId: 'LLENAR_SENDER_ID_DEV',
    projectId: 'materiales-syg-dev',
    storageBucket: 'materiales-syg-dev.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'LLENAR_API_KEY_IOS_DEV',
    appId: 'LLENAR_APP_ID_IOS_DEV',
    messagingSenderId: 'LLENAR_SENDER_ID_DEV',
    projectId: 'materiales-syg-dev',
    storageBucket: 'materiales-syg-dev.firebasestorage.app',
    iosBundleId: 'com.syg.sygMaterialesFlutter.dev', // Nota el .dev al final
  );
}