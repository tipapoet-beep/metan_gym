import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:gym_app/services/cloud_chat_service.dart';
import 'package:gym_app/services/notification_service.dart';

class AdminChatScreen extends StatefulWidget {
  final String userPhone;
  final String userName;

  const AdminChatScreen({
    Key? key,
    required this.userPhone,
    required this.userName,
  }) : super(key: key);

  @override
  State<AdminChatScreen> createState() => _AdminChatScreenState();
}

class _AdminChatScreenState extends State<AdminChatScreen> {
  final _controller = TextEditingController();
  late CloudChatService _cloudChatService;
  late NotificationService _notificationService;
  final ScrollController _scrollController = ScrollController();
  bool _isSending = false;

  @override
  void initState() {
    super.initState();
    _cloudChatService = Provider.of<CloudChatService>(context, listen: false);
    _notificationService = Provider.of<NotificationService>(context, listen: false);
    
    // Отмечаем сообщения как прочитанные при открытии чата
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _cloudChatService.markMessagesAsRead(widget.userPhone);
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
        userPhone: widget.userPhone,
        message: message,
        isFromUser: false,
        senderName: 'Администратор',
      );

      // Отправляем уведомление клиенту
      await _notificationService.sendChatNotification(
        userName: widget.userName,
        message: message,
        isForAdmin: false,
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
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Чат с клиентом',
              style: TextStyle(color: Colors.white, fontSize: 16),
            ),
            Text(
              widget.userName,
              style: const TextStyle(color: Colors.grey, fontSize: 12),
            ),
          ],
        ),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _cloudChatService.getMessages(widget.userPhone),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Center(
                    child: Text(
                      'Ошибка: ${snapshot.error}',
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

                // Отмечаем как прочитанные при получении новых сообщений
                if (messages.isNotEmpty) {
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    _cloudChatService.markMessagesAsRead(widget.userPhone);
                  });
                }

                return ListView.builder(
                  controller: _scrollController,
                  reverse: true,
                  padding: const EdgeInsets.all(16),
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final msg = messages[index].data() as Map<String, dynamic>;
                    final isFromUser = msg['isFromUser'] ?? false;
                    final sender = isFromUser ? widget.userName : 'Админ';
                    final timestamp = msg['timestamp'] as Timestamp?;
                    final time = timestamp?.toDate() ?? DateTime.now();
                    final isRead = msg['isRead'] ?? false;

                    return Container(
                      margin: EdgeInsets.only(
                        bottom: 10,
                        left: isFromUser ? 0 : 50,
                        right: isFromUser ? 50 : 0,
                      ),
                      child: Column(
                        crossAxisAlignment: isFromUser ? CrossAxisAlignment.start : CrossAxisAlignment.end,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: isFromUser ? Colors.grey[900] : Colors.grey[800],
                              borderRadius: BorderRadius.circular(16).copyWith(
                                bottomLeft: Radius.circular(isFromUser ? 4 : 16),
                                bottomRight: Radius.circular(isFromUser ? 16 : 4),
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  sender,
                                  style: TextStyle(
                                    color: isFromUser ? Colors.grey[400] : Colors.grey[300],
                                    fontSize: 10,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  msg['text'] ?? '',
                                  style: const TextStyle(color: Colors.white),
                                ),
                                if (!isFromUser && isRead) ...[
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
                      hintText: _isSending ? 'Отправка...' : 'Напишите ответ...',
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