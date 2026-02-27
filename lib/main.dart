import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'screens/auth_screen.dart';
import 'screens/home_screen.dart';
import 'screens/admin_screen.dart';
import 'services/database_service.dart';
import 'services/cloud_database_service.dart';
import 'services/cloud_chat_service.dart';
import 'theme/app_theme.dart';
import 'providers/user_provider.dart';
import 'services/notification_service.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  
  final bool isWeb = kIsWeb;
  
  DatabaseService? databaseService;
  if (!isWeb) {
    databaseService = DatabaseService();
    await databaseService!.initDatabase();
  }
  
  final cloudDatabaseService = CloudDatabaseService();
  final notificationService = NotificationService();
  
  // Инициализируем сервис уведомлений без ожидания разрешений
  await notificationService.init();
  
  // Запрашиваем разрешения в фоне (не блокируем загрузку)
  Future.microtask(() => notificationService.requestPermissionsIfNeeded());
  
  final cloudChatService = CloudChatService();
  
  runApp(MyApp(
    databaseService: databaseService,
    cloudDatabaseService: cloudDatabaseService,
    notificationService: notificationService,
    cloudChatService: cloudChatService,
  ));
}

class MyApp extends StatelessWidget {
  final DatabaseService? databaseService;
  final CloudDatabaseService cloudDatabaseService;
  final NotificationService notificationService;
  final CloudChatService cloudChatService;
  
  const MyApp({
    super.key, 
    this.databaseService,
    required this.cloudDatabaseService,
    required this.notificationService,
    required this.cloudChatService,
  });

  @override
  Widget build(BuildContext context) {
    notificationService.onNotificationTap = (payload) {
      if (payload != null) {
        _handleNotificationTap(context, payload);
      }
    };

    return MultiProvider(
      providers: [
        if (databaseService != null) Provider<DatabaseService>.value(value: databaseService!),
        Provider<CloudDatabaseService>.value(value: cloudDatabaseService),
        Provider<NotificationService>.value(value: notificationService),
        Provider<CloudChatService>.value(value: cloudChatService),
        ChangeNotifierProvider(create: (_) => UserProvider()),
      ],
      child: MaterialApp(
        title: 'METAH GYM',
        theme: AppTheme.darkTheme,
        debugShowCheckedModeBanner: false,
        initialRoute: '/',
        routes: {
          '/': (context) => const AuthScreen(),
          '/home': (context) => const HomeScreen(),
          '/admin': (context) => const AdminScreen(),
        },
      ),
    );
  }

  void _handleNotificationTap(BuildContext context, String payload) {
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    
    if (userProvider.currentUser == null) return;

    if (payload == 'admin_clients' && userProvider.isAdmin) {
      Navigator.of(context).pushNamedAndRemoveUntil('/admin', (route) => false);
    } else if (payload.startsWith('chat_')) {
      final userPhone = payload.replaceFirst('chat_', '');
      if (userProvider.isAdmin) {
        Navigator.of(context).pushNamedAndRemoveUntil('/admin', (route) => false);
      } else {
        Navigator.of(context).pushNamed('/home');
      }
    }
  }
}