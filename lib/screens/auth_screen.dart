import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:gym_app/providers/user_provider.dart';
import 'package:gym_app/models/user.dart';
import 'package:gym_app/services/database_service.dart';
import 'package:gym_app/services/cloud_database_service.dart';
import 'package:gym_app/services/cloud_chat_service.dart';
import 'package:gym_app/services/notification_service.dart';
import 'package:gym_app/widgets/agreement_dialog.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

class AuthScreen extends StatefulWidget {
  const AuthScreen({Key? key}) : super(key: key);

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final _formKey = GlobalKey<FormState>();
  final _phoneController = TextEditingController();
  final _nameController = TextEditingController();
  
  bool _showNameField = false;
  bool _isLoading = false;
  bool _isAgreed = false;

  @override
  void initState() {
    super.initState();
    _checkSavedUser();
  }

  Future<void> _checkSavedUser() async {
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    if (!userProvider.isLoading && userProvider.currentUser != null) {
      Future.microtask(() {
        if (userProvider.isAdmin) {
          Navigator.of(context).pushReplacementNamed('/admin');
        } else {
          Navigator.of(context).pushReplacementNamed('/home');
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final userProvider = Provider.of<UserProvider>(context);

    if (userProvider.isLoading) {
      return Scaffold(
        backgroundColor: Colors.black,
        body: const Center(
          child: CircularProgressIndicator(color: Colors.white),
        ),
      );
    }

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.black, Colors.grey[900]!],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Image.asset(
                    'assets/images/logo.png',
                    width:320,
                    height: 320,
                    fit: BoxFit.contain,
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'METAH GYM',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 2,
                    ),
                  ),
                  Text(
                    'Твой путь к рекордам',
                    style: TextStyle(
                      color: Colors.grey[400],
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 50),

                  TextFormField(
                    controller: _phoneController,
                    style: const TextStyle(color: Colors.white),
                    keyboardType: TextInputType.phone,
                    maxLength: 10,
                    decoration: InputDecoration(
                      labelText: 'Номер телефона',
                      labelStyle: TextStyle(color: Colors.grey[400]),
                      prefixText: '+7 ',
                      prefixStyle: const TextStyle(color: Colors.white),
                      enabledBorder: OutlineInputBorder(
                        borderSide: BorderSide(color: Colors.grey[800]!),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderSide: BorderSide(color: Colors.white),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      counterText: '',
                    ),
                    validator: (value) {
                      if (value == null || value.length != 10) {
                        return 'Введите 10 цифр';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  if (_showNameField)
                    TextFormField(
                      controller: _nameController,
                      style: const TextStyle(color: Colors.white),
                      keyboardType: TextInputType.name,
                      textInputAction: TextInputAction.done,
                      decoration: InputDecoration(
                        labelText: 'Ваше имя',
                        labelStyle: TextStyle(color: Colors.grey[400]),
                        enabledBorder: OutlineInputBorder(
                          borderSide: BorderSide(color: Colors.grey[800]!),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderSide: BorderSide(color: Colors.white),
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Введите имя';
                        }
                        return null;
                      },
                    ),

                  const SizedBox(height: 20),

                  Row(
                    children: [
                      Checkbox(
                        value: _isAgreed,
                        onChanged: (value) {
                          setState(() => _isAgreed = value ?? false);
                        },
                        checkColor: Colors.black,
                        activeColor: Colors.white,
                      ),
                      Expanded(
                        child: GestureDetector(
                          onTap: () {
                            showDialog(
                              context: context,
                              builder: (context) => AgreementDialog(
                                isAgreed: _isAgreed,
                                onAgreementChanged: (value) {
                                  setState(() => _isAgreed = value);
                                  Navigator.of(context).pop();
                                },
                              ),
                            );
                          },
                          child: Text(
                            'Согласие на обработку персональных данных',
                            style: TextStyle(
                              color: Colors.grey[400],
                              fontSize: 12,
                              decoration: TextDecoration.underline,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 20),

                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: (_isLoading || !_isAgreed) ? null : _handleAuth,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: Colors.black,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: Text(
                        _isLoading ? 'Загрузка...' : 'Войти / Зарегистрироваться',
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _handleAuth() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    final phone = '+7${_phoneController.text}';
    
    // DatabaseService теперь опциональный
    final databaseService = kIsWeb ? null : Provider.of<DatabaseService>(context, listen: false);
    final cloudDb = Provider.of<CloudDatabaseService>(context, listen: false);
    final cloudChat = Provider.of<CloudChatService>(context, listen: false);
    final notificationService = Provider.of<NotificationService>(context, listen: false);
    final firebaseMessaging = FirebaseMessaging.instance;

    // Админ вход
    if (_phoneController.text == '0000000000') {
      final adminUser = User(
        phone: phone,
        name: 'Admin',
        registrationDate: DateTime.now(),
      );
      if (mounted) {
        await Provider.of<UserProvider>(context, listen: false).setUser(adminUser);
        Navigator.of(context).pushReplacementNamed('/admin');
      }
      setState(() => _isLoading = false);
      return;
    }

    try {
      // Ищем пользователя сначала в облаке
      var existingUser = await cloudDb.getUser(phone);
      
      // Если не нашли в облаке и есть локальная БД, пробуем там
      if (existingUser == null && databaseService != null) {
        existingUser = await databaseService.getUser(phone);
        
        // Если нашли в локальной БД, сохраняем в облако
        if (existingUser != null) {
          await cloudDb.addUser(existingUser);
        }
      }

      if (existingUser != null) {
        // Пользователь существует - просто входим
        if (mounted) {
          await Provider.of<UserProvider>(context, listen: false).setUser(existingUser);
          
          await cloudChat.signInAnonymously(phone, existingUser.name);
          
          // FCM токен только не в вебе
          if (!kIsWeb) {
            String? fcmToken = await firebaseMessaging.getToken();
            if (fcmToken != null) {
              await cloudDb.saveUserFcmToken(phone, fcmToken);
            }
          }
          
          // Локальное уведомление пользователю (только не в вебе)
          if (!kIsWeb) {
            await notificationService.showNotification(
              id: DateTime.now().millisecondsSinceEpoch.remainder(1000000),
              title: 'С возвращением!',
              body: 'Рады видеть вас снова, ${existingUser.name}!',
            );
          }
          
          Navigator.of(context).pushReplacementNamed('/home');
        }
      } else {
        // Новый пользователь
        if (!_showNameField) {
          setState(() {
            _showNameField = true;
            _isLoading = false;
          });
        } else if (_nameController.text.isNotEmpty && mounted) {
          final newUser = User(
            phone: phone,
            name: _nameController.text,
            registrationDate: DateTime.now(),
          );
          
          // Сохраняем в облако
          await cloudDb.addUser(newUser);
          
          // Если есть локальная БД, сохраняем и туда
          if (databaseService != null) {
            await databaseService.addUser(newUser);
          }
          
          await cloudChat.signInAnonymously(phone, newUser.name);
          
          // FCM токен только не в вебе
          if (!kIsWeb) {
            String? fcmToken = await firebaseMessaging.getToken();
            if (fcmToken != null) {
              await cloudDb.saveUserFcmToken(phone, fcmToken);
            }
          }
          
          // Уведомление админу (можно и в вебе отправлять)
          await notificationService.sendRegistrationNotification(newUser.name);
          
          // Приветственное уведомление пользователю (только не в вебе)
          if (!kIsWeb) {
            await notificationService.showNotification(
              id: DateTime.now().millisecondsSinceEpoch.remainder(1000000),
              title: 'Добро пожаловать в METAH GYM!',
              body: '${newUser.name}, спасибо за регистрацию!',
            );
          }
          
          await Provider.of<UserProvider>(context, listen: false).setUser(newUser);
          Navigator.of(context).pushReplacementNamed('/home');
        }
      }
    } catch (e) {
      print('Auth error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Ошибка при входе: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }

    if (mounted) {
      setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _phoneController.dispose();
    _nameController.dispose();
    super.dispose();
  }
}