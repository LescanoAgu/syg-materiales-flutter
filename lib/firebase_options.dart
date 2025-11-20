// lib/firebase_options.dart
import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

class DefaultFirebaseOptions {
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

  // CLAVE WEB NUEVA
  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyAhzNOhoj6V7yLS7043GlEvvDspl0n-p5k',
    appId: '1:703649607267:web:8c9fcb54399425146b1256',
    messagingSenderId: '703649607267',
    projectId: 'syg-materiales',
    authDomain: 'syg-materiales.firebaseapp.com',
    storageBucket: 'syg-materiales.firebasestorage.app',
  );

  // CLAVE ANDROID NUEVA
  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyAy4pZNbQK0FiqGR1TJ-4v9wYUhh6ppdYs',
    appId: '1:703649607267:android:c0c969e9388e74fe6b1256',
    messagingSenderId: '703649607267',
    projectId: 'syg-materiales',
    storageBucket: 'syg-materiales.firebasestorage.app',
  );

  // CLAVE IOS NUEVA
  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyAfTt_ZU1RCQRjy1kAqN1pRdtwJIk7AtM4',
    appId: '1:703649607267:ios:63350fc337bdf2b26b1256',
    messagingSenderId: '703649607267',
    projectId: 'syg-materiales',
    storageBucket: 'syg-materiales.firebasestorage.app',
    iosBundleId: 'com.syg.sygMaterialesFlutter',
  );
}