import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'dart:async';

// Función Top-Level para manejar mensajes en 2do plano (Background)
// Debe estar FUERA de la clase
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  print("🔔 Mensaje en 2do plano recibido: ${message.messageId}");
}

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications = FlutterLocalNotificationsPlugin();

  // Inicialización principal
  Future<void> init() async {
    // 1. Pedir permisos (Crítico para Android 13+ y iOS)
    NotificationSettings settings = await _firebaseMessaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      provisional: false,
    );

    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      print('✅ Permiso de notificaciones concedido');

      // 2. Configurar Handler de Background
      FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

      // 3. Configurar Notificaciones Locales (Para mostrar alerta cuando la app está abierta)
      await _setupLocalNotifications();

      // 4. Escuchar mensajes en primer plano
      FirebaseMessaging.onMessage.listen((RemoteMessage message) {
        print('🔔 Mensaje en primer plano: ${message.notification?.title}');
        _showForegroundNotification(message);
      });

    } else {
      print('❌ Permiso de notificaciones denegado');
    }
  }

  // Obtener el Token del dispositivo (La "dirección" para enviarle mensajes)
  Future<String?> getToken() async {
    try {
      // En web, getToken a veces requiere vapidKey, pero probemos sin ella primero
      String? token = await _firebaseMessaging.getToken();
      print("🏷️ FCM Token: $token");
      return token;
    } catch (e) {
      print("Error obteniendo token FCM: $e");
      return null;
    }
  }

  // Configuración de canales locales (Android necesita esto)
  Future<void> _setupLocalNotifications() async {
    const AndroidInitializationSettings initializationSettingsAndroid =
    AndroidInitializationSettings('@mipmap/ic_launcher'); // Usa tu ícono

    const InitializationSettings initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
      // iOS: const DarwinInitializationSettings(), // Descomentar si agregas iOS
    );

    await _localNotifications.initialize(initializationSettings);

    // Crear canal de alta importancia para Android
    const AndroidNotificationChannel channel = AndroidNotificationChannel(
      'high_importance_channel', // id
      'Notificaciones Importantes', // title
      description: 'Este canal se usa para alertas importantes de la obra.', // description
      importance: Importance.max,
    );

    await _localNotifications
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);
  }

  // Mostrar la notificación visualmente
  Future<void> _showForegroundNotification(RemoteMessage message) async {
    RemoteNotification? notification = message.notification;
    AndroidNotification? android = message.notification?.android;

    if (notification != null && android != null) {
      _localNotifications.show(
        notification.hashCode,
        notification.title,
        notification.body,
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'high_importance_channel',
            'Notificaciones Importantes',
            icon: '@mipmap/ic_launcher',
            importance: Importance.max,
            priority: Priority.high,
          ),
        ),
      );
    }
  }
}