import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:gym_app/services/notification_service.dart';
import 'package:gym_app/services/cloud_database_service.dart';
import 'package:gym_app/models/user.dart';

class AdminNotificationsScreen extends StatefulWidget {
  const AdminNotificationsScreen({Key? key}) : super(key: key);

  @override
  State<AdminNotificationsScreen> createState() => _AdminNotificationsScreenState();
}

class _AdminNotificationsScreenState extends State<AdminNotificationsScreen> {
  final _titleController = TextEditingController();
  final _messageController = TextEditingController();
  bool _isSending = false;
  String _status = '';

  @override
  Widget build(BuildContext context) {
    final notificationService = Provider.of<NotificationService>(context);
    final cloudDb = Provider.of<CloudDatabaseService>(context);

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: const Text(
          'Рассылка уведомлений',
          style: TextStyle(color: Colors.white),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Создать уведомление',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 20),

              TextField(
                controller: _titleController,
                style: const TextStyle(color: Colors.white),
                keyboardType: TextInputType.text,
                textInputAction: TextInputAction.next,
                decoration: InputDecoration(
                  labelText: 'Заголовок',
                  labelStyle: TextStyle(color: Colors.grey[400]),
                  enabledBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.grey[800]!),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderSide: const BorderSide(color: Colors.white),
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
              const SizedBox(height: 15),

              TextField(
                controller: _messageController,
                style: const TextStyle(color: Colors.white),
                keyboardType: TextInputType.multiline,
                maxLines: 3,
                textInputAction: TextInputAction.done,
                decoration: InputDecoration(
                  labelText: 'Текст сообщения',
                  labelStyle: TextStyle(color: Colors.grey[400]),
                  enabledBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.grey[800]!),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderSide: const BorderSide(color: Colors.white),
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Информация о получателях
              FutureBuilder<List<User>>(
                future: cloudDb.getAllUsers(),
                builder: (context, snapshot) {
                  final userCount = snapshot.data?.length ?? 0;
                  return Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.grey[900],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.people, color: Colors.white),
                        const SizedBox(width: 10),
                        Text(
                          'Получателей: $userCount',
                          style: const TextStyle(color: Colors.white),
                        ),
                      ],
                    ),
                  );
                },
              ),

              const SizedBox(height: 20),

              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _isSending ? null : () => _sendNotification(notificationService, cloudDb),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: Colors.black,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: Text(
                    _isSending ? 'Отправка...' : 'Отправить всем',
                  ),
                ),
              ),

              const SizedBox(height: 20),

              if (_status.isNotEmpty)
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: _status.contains('Ошибка') ? Colors.red[900] : Colors.green[900],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    _status,
                    style: const TextStyle(color: Colors.white),
                  ),
                ),

              const SizedBox(height: 30),

              // Инструкция
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey[900],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.info_outline, color: Colors.white, size: 20),
                        const SizedBox(width: 8),
                        const Text(
                          'Как это работает:',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      '• Уведомления отправляются всем пользователям\n'
                      '• Для работы push-уведомлений требуется интернет\n'
                      '• Уведомления приходят даже когда приложение закрыто\n'
                      '• При добавлении новой акции уведомления отправляются автоматически',
                      style: TextStyle(color: Colors.grey, fontSize: 12),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _sendNotification(
    NotificationService notificationService,
    CloudDatabaseService cloudDb,
  ) async {
    if (_titleController.text.isEmpty || _messageController.text.isEmpty) {
      setState(() {
        _status = 'Ошибка: Заполните все поля';
      });
      return;
    }

    setState(() {
      _isSending = true;
      _status = '';
    });

    try {
      // Получаем всех пользователей
      final users = await cloudDb.getAllUsers();
      
      if (users.isEmpty) {
        setState(() {
          _status = 'Ошибка: Нет пользователей для рассылки';
          _isSending = false;
        });
        return;
      }

      // Отправляем каждому пользователю
      int successCount = 0;
      for (var i = 0; i < users.length; i++) {
        try {
          await notificationService.showNotification(
            id: DateTime.now().millisecondsSinceEpoch + i,
            title: _titleController.text,
            body: _messageController.text,
          );
          successCount++;
          await Future.delayed(const Duration(milliseconds: 100));
        } catch (e) {
          print('Error sending to user ${users[i].phone}: $e');
        }
      }

      setState(() {
        _status = '✓ Уведомление отправлено $successCount из ${users.length} пользователям';
        if (successCount == users.length) {
          _titleController.clear();
          _messageController.clear();
        }
      });

      // Здесь мы убрали вызов addNotificationHistory, так как его нет в сервисе
      // Если хотите сохранять историю, добавьте этот метод в CloudDatabaseService

    } catch (e) {
      setState(() {
        _status = 'Ошибка: ${e.toString()}';
      });
    } finally {
      setState(() {
        _isSending = false;
      });
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _messageController.dispose();
    super.dispose();
  }
}