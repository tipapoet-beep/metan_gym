import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';

/// Сервис для работы с Firestore с кастомной базой данных
class FirestoreService {
  static final FirestoreService _instance = FirestoreService._internal();
  factory FirestoreService() => _instance;
  FirestoreService._internal();

  // Имя вашей кастомной базы данных
  static const String _databaseId = 'metangym';
  
  // Ленивая инициализация Firestore instance
  FirebaseFirestore? _firestore;

  /// Получить экземпляр Firestore для кастомной базы
  Future<FirebaseFirestore> get firestore async {
    if (_firestore != null) return _firestore!;
    
    _firestore = FirebaseFirestore.instanceFor(
      app: Firebase.app(),
      databaseId: _databaseId,
    );
    
    return _firestore!;
  }

  /// Проверка соединения с базой данных
  Future<bool> checkConnection() async {
    try {
      final db = await firestore;
      await db.collection('_connection_test').doc('test').get();
      return true;
    } catch (e) {
      print('Firestore connection error: $e');
      return false;
    }
  }

  /// Получить ссылку на коллекцию (для использования в других сервисах)
  Future<CollectionReference<Map<String, dynamic>>> collection(String path) async {
    final db = await firestore;
    return db.collection(path);
  }

  /// Получить ссылку на документ
  Future<DocumentReference<Map<String, dynamic>>> document(String path) async {
    final db = await firestore;
    return db.doc(path);
  }
}