import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz;
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin = 
      FlutterLocalNotificationsPlugin();
  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;

  // Флаг, были ли уже запрошены разрешения
  bool _permissionsRequested = false;
  
  // Колбэки для обработки нажатий
  Function(String? payload)? onNotificationTap;

  // Для обработки фоновых уведомлений
  static Future<void> _backgroundHandler(RemoteMessage message) async {
    print("Handling a background message: ${message.messageId}");
    print("Message data: ${message.data}");
  }

  Future<void> init() async {
    tz.initializeTimeZones();
    
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    
    final DarwinInitializationSettings initializationSettingsIOS =
        DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );
    
    final InitializationSettings initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: initializationSettingsIOS,
    );

    await flutterLocalNotificationsPlugin.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: (NotificationResponse response) async {
        print('Notification clicked: ${response.payload}');
        if (onNotificationTap != null) {
          onNotificationTap!(response.payload);
        }
      },
    );

    // Инициализируем Firebase Messaging, но не ждем разрешений
    _initializeFirebaseMessaging();
  }

  void _initializeFirebaseMessaging() {
    if (kIsWeb) {
      // Для веба просто логируем
      print('Web platform detected, FCM will be initialized on demand');
      return;
    }

    // Получаем токен без ожидания разрешений
    _firebaseMessaging.getToken().then((token) {
      print('FCM Token: $token');
    }).catchError((e) {
      print('Error getting FCM token: $e');
    });

    // Обработка сообщений, когда приложение открыто
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      print('Got a message whilst in the foreground!');
      if (message.notification != null) {
        _showLocalNotification(
          id: message.hashCode,
          title: message.notification!.title ?? 'Уведомление',
          body: message.notification!.body ?? '',
          payload: message.data['route'],
        );
      }
    });

    FirebaseMessaging.onBackgroundMessage(_backgroundHandler);

    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      print('A new onMessageOpenedApp event was published!');
      if (message.data['route'] != null && onNotificationTap != null) {
        onNotificationTap!(message.data['route']);
      }
    });
  }

  // Отдельный метод для запроса разрешений (не блокирует инициализацию)
  Future<void> requestPermissionsIfNeeded() async {
    if (_permissionsRequested) return;
    
    _permissionsRequested = true;
    
    try {
      if (kIsWeb) {
        print('Web platform - notifications handled by browser');
        return;
      }

      NotificationSettings settings = await _firebaseMessaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );
      
      print('User granted permission: ${settings.authorizationStatus}');
      
      await flutterLocalNotificationsPlugin
          .resolvePlatformSpecificImplementation<
              IOSFlutterLocalNotificationsPlugin>()
          ?.requestPermissions(
            alert: true,
            badge: true,
            sound: true,
          );
    } catch (e) {
      print('Error requesting permissions: $e');
    }
  }

  Future<void> _showLocalNotification({
    required int id,
    required String title,
    required String body,
    String? payload,
  }) async {
    AndroidNotificationDetails androidPlatformChannelSpecifics =
        AndroidNotificationDetails(
      'gym_channel',
      'METAH GYM Notifications',
      channelDescription: 'Уведомления от METAH GYM',
      importance: Importance.max,
      priority: Priority.high,
      showWhen: true,
      enableVibration: true,
      playSound: true,
      enableLights: true,
      ledColor: Colors.white,
      ledOnMs: 1000,
      ledOffMs: 500,
    );
    
    const DarwinNotificationDetails iosPlatformChannelSpecifics =
        DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );
    
    NotificationDetails platformChannelSpecifics = NotificationDetails(
      android: androidPlatformChannelSpecifics,
      iOS: iosPlatformChannelSpecifics,
    );

    await flutterLocalNotificationsPlugin.show(
      id,
      title,
      body,
      platformChannelSpecifics,
      payload: payload,
    );
  }

  Future<void> sendRegistrationNotification(String userName) async {
    await showNotification(
      id: DateTime.now().millisecondsSinceEpoch.remainder(1000000),
      title: 'Новый пользователь! 🎉',
      body: '$userName только что зарегистрировался',
      payload: 'admin_clients',
    );
  }

  Future<void> sendChatNotification({
    required String userName,
    required String message,
    required bool isForAdmin,
  }) async {
    if (isForAdmin) {
      await showNotification(
        id: DateTime.now().millisecondsSinceEpoch.remainder(1000000),
        title: 'Новое сообщение от $userName',
        body: message,
        payload: 'chat_$userName',
      );
    } else {
      await showNotification(
        id: DateTime.now().millisecondsSinceEpoch.remainder(1000000),
        title: 'Ответ от администратора',
        body: message,
        payload: 'chat',
      );
    }
  }

  Future<void> showNotification({
    required int id,
    required String title,
    required String body,
    String? payload,
  }) async {
    await _showLocalNotification(
      id: id,
      title: title,
      body: body,
      payload: payload,
    );
  }

  Future<void> scheduleMembershipNotification({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledDate,
    String? payload,
  }) async {
    const AndroidNotificationDetails androidPlatformChannelSpecifics =
        AndroidNotificationDetails(
      'gym_channel',
      'METAH GYM Notifications',
      channelDescription: 'Уведомления от METAH GYM',
      importance: Importance.max,
      priority: Priority.high,
    );

    const DarwinNotificationDetails iosPlatformChannelSpecifics =
        DarwinNotificationDetails();

    const NotificationDetails platformChannelSpecifics = NotificationDetails(
      android: androidPlatformChannelSpecifics,
      iOS: iosPlatformChannelSpecifics,
    );

    await flutterLocalNotificationsPlugin.zonedSchedule(
      id,
      title,
      body,
      tz.TZDateTime.from(scheduledDate, tz.local),
      platformChannelSpecifics,
      androidAllowWhileIdle: true,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      payload: payload,
    );
  }

  Future<void> cancelNotification(int id) async {
    await flutterLocalNotificationsPlugin.cancel(id);
  }

  Future<void> cancelAllNotifications() async {
    await flutterLocalNotificationsPlugin.cancelAll();
  }
}