import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class CloudChatService {
  static final CloudChatService _instance = CloudChatService._internal();
  factory CloudChatService() => _instance;
  CloudChatService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Анонимный вход для пользователей
  Future<User?> signInAnonymously(String phone, String name) async {
    try {
      final userCredential = await _auth.signInAnonymously();
      
      await _firestore.collection('users').doc(userCredential.user!.uid).set({
        'phone': phone,
        'name': name,
        'lastActive': FieldValue.serverTimestamp(),
      });
      
      return userCredential.user;
    } catch (e) {
      print('Auth error: $e');
      return null;
    }
  }

  // Отправка сообщения
  Future<void> sendMessage({
    required String userPhone,
    required String message,
    required bool isFromUser,
    required String senderName,
  }) async {
    try {
      final chatRef = _firestore.collection('chats').doc(userPhone);
      
      // Добавляем сообщение в подколлекцию
      await chatRef.collection('messages').add({
        'text': message,
        'senderName': senderName,
        'senderPhone': isFromUser ? userPhone : 'admin',
        'isFromUser': isFromUser,
        'isFromAdmin': !isFromUser,
        'timestamp': FieldValue.serverTimestamp(),
        'isRead': false,
      });
      
      // Получаем имя пользователя если это сообщение от админа
      String userName = senderName;
      if (!isFromUser) {
        final userDoc = await _firestore
            .collection('users')
            .where('phone', isEqualTo: userPhone)
            .limit(1)
            .get();
        if (userDoc.docs.isNotEmpty) {
          userName = userDoc.docs.first.data()['name'] ?? 'Клиент';
        }
      }
      
      // Получаем текущий unreadCount
      final chatDoc = await chatRef.get();
      int currentUnread = 0;
      if (chatDoc.exists) {
        final data = chatDoc.data();
        currentUnread = data?['unreadCount'] ?? 0;
      }
      
      // Обновляем метаданные чата
      await chatRef.set({
        'userPhone': userPhone,
        'userName': userName,
        'lastMessage': message,
        'lastMessageTime': FieldValue.serverTimestamp(),
        'unreadCount': currentUnread + (isFromUser ? 1 : 0),
        'lastSender': isFromUser ? 'user' : 'admin',
      }, SetOptions(merge: true));
      
    } catch (e) {
      print('Send message error: $e');
    }
  }

  // Получение потока сообщений для конкретного чата
  Stream<QuerySnapshot> getMessages(String userPhone) {
    return _firestore
        .collection('chats')
        .doc(userPhone)
        .collection('messages')
        .orderBy('timestamp', descending: true)
        .snapshots();
  }

  // Получение списка всех чатов для админа
  Stream<QuerySnapshot> getAllChats() {
    return _firestore
        .collection('chats')
        .orderBy('lastMessageTime', descending: true)
        .snapshots();
  }

  // Отметить сообщения как прочитанные
  Future<void> markMessagesAsRead(String userPhone) async {
    try {
      final batch = _firestore.batch();
      
      // Получаем все непрочитанные сообщения от пользователя
      final messages = await _firestore
          .collection('chats')
          .doc(userPhone)
          .collection('messages')
          .where('isFromUser', isEqualTo: true)
          .where('isRead', isEqualTo: false)
          .get();

      // Отмечаем каждое сообщение как прочитанное
      for (var doc in messages.docs) {
        batch.update(doc.reference, {'isRead': true});
      }
      
      // Сбрасываем счетчик непрочитанных в метаданных чата
      batch.update(
        _firestore.collection('chats').doc(userPhone),
        {'unreadCount': 0}
      );
      
      await batch.commit();
      
    } catch (e) {
      print('Error marking messages as read: $e');
    }
  }

  // Получить количество непрочитанных сообщений для админа (однократно)
  Future<int> getUnreadCountForAdmin() async {
    try {
      final snapshot = await _firestore
          .collection('chats')
          .get();
      
      int totalUnread = 0;
      for (var doc in snapshot.docs) {
        final data = doc.data();
        // Безопасно получаем значение unreadCount
        totalUnread += (data['unreadCount'] as int?) ?? 0;
      }
      
      return totalUnread;
    } catch (e) {
      print('Error getting unread count: $e');
      return 0;
    }
  }

  // Получить количество непрочитанных сообщений для конкретного пользователя
  Stream<int> getUnreadCountForUser(String userPhone) {
    return _firestore
        .collection('chats')
        .doc(userPhone)
        .snapshots()
        .map((doc) {
          if (doc.exists) {
            final data = doc.data();
            // Безопасно получаем значение
            final unreadFromAdmin = (data?['unreadFromAdmin'] as int?) ?? 0;
            return unreadFromAdmin;
          }
          return 0;
        });
  }

  // Подписка на изменения непрочитанных сообщений для админа
  Stream<int> getUnreadCountStream() {
    return _firestore
        .collection('chats')
        .snapshots()
        .map((snapshot) {
          int total = 0;
          for (var doc in snapshot.docs) {
            final data = doc.data();
            // Безопасно получаем значение unreadCount
            total += (data['unreadCount'] as int?) ?? 0;
          }
          return total;
        });
  }

  // Получить имя пользователя по телефону
  Future<String> getUserName(String phone) async {
    try {
      final snapshot = await _firestore
          .collection('users')
          .where('phone', isEqualTo: phone)
          .limit(1)
          .get();
      
      if (snapshot.docs.isNotEmpty) {
        return snapshot.docs.first.data()['name'] ?? 'Клиент';
      }
      return 'Клиент';
    } catch (e) {
      return 'Клиент';
    }
  }

  // Выход из Firebase
  Future<void> signOut() async {
    await _auth.signOut();
  }
}