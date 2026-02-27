import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:gym_app/providers/user_provider.dart';
import 'package:gym_app/services/cloud_chat_service.dart';
import 'package:gym_app/services/notification_service.dart';

class SupportScreen extends StatefulWidget {
  const SupportScreen({Key? key}) : super(key: key);

  @override
  State<SupportScreen> createState() => _SupportScreenState();
}

class _SupportScreenState extends State<SupportScreen> {
  final _controller = TextEditingController();
  late CloudChatService _cloudChatService;
  late NotificationService _notificationService;
  late String _userPhone;
  late String _userName;
  final ScrollController _scrollController = ScrollController();
  bool _isSending = false;
  int _unreadCount = 0;

  @override
  void initState() {
    super.initState();
    _cloudChatService = Provider.of<CloudChatService>(context, listen: false);
    _notificationService = Provider.of<NotificationService>(context, listen: false);
    final user = Provider.of<UserProvider>(context, listen: false).currentUser!;
    _userPhone = user.phone;
    _userName = user.name;
    
    _cloudChatService.signInAnonymously(_userPhone, _userName);
    _setupUnreadListener();
  }

  void _setupUnreadListener() {
    _cloudChatService.getUnreadCountForUser(_userPhone).listen((count) {
      if (mounted) {
        setState(() {
          _unreadCount = count;
        });
      }
    });
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          0,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _sendMessage() async {
    if (_controller.text.isEmpty || _isSending) return;

    setState(() => _isSending = true);

    final message = _controller.text;
    _controller.clear();

    try {
      await _cloudChatService.sendMessage(
        userPhone: _userPhone,
        message: message,
        isFromUser: true,
        senderName: _userName,
      );

      // Отправляем уведомление админу
      await _notificationService.sendChatNotification(
        userName: _userName,
        message: message,
        isForAdmin: true,
      );
      
      _scrollToBottom();
    } catch (e) {
      print('Error sending message: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Ошибка при отправке: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() => _isSending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: const Text(
          'Чат с поддержкой',
          style: TextStyle(color: Colors.white),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _cloudChatService.getMessages(_userPhone),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Center(
                    child: Text(
                      'Ошибка загрузки: ${snapshot.error}',
                      style: const TextStyle(color: Colors.white),
                    ),
                  );
                }

                if (!snapshot.hasData) {
                  return const Center(
                    child: CircularProgressIndicator(color: Colors.white),
                  );
                }

                final messages = snapshot.data!.docs;
                
                // Отмечаем как прочитанные при открытии
                if (messages.isNotEmpty) {
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    _cloudChatService.markMessagesAsRead(_userPhone);
                  });
                }

                return ListView.builder(
                  controller: _scrollController,
                  reverse: true,
                  padding: const EdgeInsets.all(16),
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final msg = messages[index].data() as Map<String, dynamic>;
                    final isUser = msg['isFromUser'] ?? false;
                    final sender = msg['senderName'] ?? (isUser ? 'Вы' : 'Админ');
                    final timestamp = msg['timestamp'] as Timestamp?;
                    final time = timestamp?.toDate() ?? DateTime.now();
                    final isRead = msg['isRead'] ?? false;

                    return Container(
                      margin: EdgeInsets.only(
                        bottom: 10,
                        left: isUser ? 50 : 0,
                        right: isUser ? 0 : 50,
                      ),
                      child: Column(
                        crossAxisAlignment: isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: isUser ? Colors.grey[800] : Colors.grey[900],
                              borderRadius: BorderRadius.circular(16).copyWith(
                                bottomLeft: Radius.circular(isUser ? 16 : 4),
                                bottomRight: Radius.circular(isUser ? 4 : 16),
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  sender,
                                  style: TextStyle(
                                    color: isUser ? Colors.grey[300] : Colors.grey[400],
                                    fontSize: 10,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  msg['text'] ?? '',
                                  style: const TextStyle(color: Colors.white),
                                ),
                                if (!isUser && isRead) ...[
                                  const SizedBox(height: 2),
                                  Text(
                                    'Прочитано',
                                    style: TextStyle(
                                      color: Colors.grey[600],
                                      fontSize: 8,
                                    ),
                                    textAlign: TextAlign.right,
                                  ),
                                ],
                              ],
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${time.hour}:${time.minute.toString().padLeft(2, '0')}',
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 10,
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                );
              },
            ),
          ),
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.grey[900],
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    style: const TextStyle(color: Colors.white),
                    maxLines: null,
                    textInputAction: TextInputAction.send,
                    onSubmitted: (_) => _sendMessage(),
                    enabled: !_isSending,
                    decoration: InputDecoration(
                      hintText: _isSending ? 'Отправка...' : 'Напишите сообщение...',
                      hintStyle: TextStyle(
                        color: _isSending ? Colors.grey[600] : Colors.grey[400],
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(25),
                        borderSide: BorderSide.none,
                      ),
                      filled: true,
                      fillColor: Colors.black,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 10,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Stack(
                  children: [
                    CircleAvatar(
                      backgroundColor: _isSending ? Colors.grey : Colors.white,
                      radius: 22,
                      child: IconButton(
                        icon: Icon(
                          Icons.send,
                          color: _isSending ? Colors.grey[800] : Colors.black,
                          size: 20,
                        ),
                        onPressed: _isSending ? null : _sendMessage,
                      ),
                    ),
                    if (_unreadCount > 0)
                      Positioned(
                        right: 0,
                        top: 0,
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: const BoxDecoration(
                            color: Colors.red,
                            shape: BoxShape.circle,
                          ),
                          constraints: const BoxConstraints(
                            minWidth: 16,
                            minHeight: 16,
                          ),
                          child: Text(
                            _unreadCount.toString(),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }
}