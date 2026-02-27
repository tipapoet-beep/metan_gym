import 'package:sqflite/sqflite.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:gym_app/models/user.dart';
import 'package:gym_app/models/membership.dart';
import 'package:gym_app/models/diary_entry.dart';
import 'package:gym_app/models/promotion.dart';
import 'package:gym_app/models/training_program.dart';

class DatabaseService {
  static final DatabaseService _instance = DatabaseService._internal();
  factory DatabaseService() => _instance;
  DatabaseService._internal();

  static Database? _database;

  Future<Database> get database async {
    if (kIsWeb) {
      throw UnsupportedError('DatabaseService не поддерживается в вебе. Используйте CloudDatabaseService.');
    }
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    // Проверяем, что мы не в вебе
    if (kIsWeb) {
      throw UnsupportedError('DatabaseService не поддерживается в вебе.');
    }

    // Инициализация для Windows
    if (Platform.isWindows) {
      sqfliteFfiInit();
      databaseFactory = databaseFactoryFfi;
    }
    
    final documentsDirectory = await getApplicationDocumentsDirectory();
    final path = join(documentsDirectory.path, 'gym.db');
    
    return await openDatabase(
      path,
      version: 3,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  Future<void> initDatabase() async {
    if (!kIsWeb) {
      await database;
    }
  }

  Future<void> _onCreate(Database db, int version) async {
    // Таблица пользователей
    await db.execute('''
      CREATE TABLE users (
        phone TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        registration_date TEXT NOT NULL
      )
    ''');

    // Таблица абонементов
    await db.execute('''
      CREATE TABLE memberships (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        user_phone TEXT,
        start_date TEXT NOT NULL,
        expiry_date TEXT NOT NULL,
        months INTEGER NOT NULL,
        price REAL NOT NULL,
        payment_id TEXT,
        FOREIGN KEY (user_phone) REFERENCES users (phone)
      )
    ''');

    // Таблица акций
    await db.execute('''
      CREATE TABLE promotions (
        id INTEGER PRIMARY KEY,
        title TEXT NOT NULL,
        description TEXT NOT NULL,
        start_date TEXT NOT NULL,
        end_date TEXT,
        is_active INTEGER DEFAULT 1
      )
    ''');

    // Таблица дневника
    await db.execute('''
      CREATE TABLE diary_entries (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        user_phone TEXT,
        date TEXT NOT NULL,
        content TEXT NOT NULL,
        FOREIGN KEY (user_phone) REFERENCES users (phone)
      )
    ''');

    // Таблица сообщений поддержки (с новым полем sender_name)
    await db.execute('''
      CREATE TABLE support_messages (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        user_phone TEXT,
        message TEXT NOT NULL,
        sender_name TEXT,
        timestamp TEXT NOT NULL,
        is_from_user INTEGER DEFAULT 1,
        is_read INTEGER DEFAULT 0,
        FOREIGN KEY (user_phone) REFERENCES users (phone)
      )
    ''');

    // Таблица программ тренировок
    await db.execute('''
      CREATE TABLE training_programs (
        id INTEGER PRIMARY KEY,
        user_phone TEXT,
        name TEXT NOT NULL,
        days TEXT NOT NULL,
        created_at TEXT NOT NULL,
        updated_at TEXT,
        FOREIGN KEY (user_phone) REFERENCES users (phone)
      )
    ''');

    // Добавляем тестовые акции
    await db.insert('promotions', {
      'id': 1,
      'title': '🎁 Новичкам',
      'description': 'Персональная тренировка в подарок при покупке абонемента на месяц',
      'start_date': DateTime.now().toIso8601String(),
      'is_active': 1,
    });

    await db.insert('promotions', {
      'id': 2,
      'title': '👥 Приведи друга',
      'description': 'Получи скидку 10% за каждого приведенного друга',
      'start_date': DateTime.now().toIso8601String(),
      'is_active': 1,
    });
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 3) {
      // Добавляем поле sender_name в существующую таблицу
      await db.execute('ALTER TABLE support_messages ADD COLUMN sender_name TEXT');
    }
  }

  // ============= МЕТОДЫ ДЛЯ ПОЛЬЗОВАТЕЛЕЙ =============

  Future<void> addUser(User user) async {
    if (kIsWeb) return;
    final db = await database;
    await db.insert(
      'users',
      user.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<User?> getUser(String phone) async {
    if (kIsWeb) return null;
    final db = await database;
    final maps = await db.query(
      'users',
      where: 'phone = ?',
      whereArgs: [phone],
    );

    if (maps.isNotEmpty) {
      return User.fromMap(maps.first);
    }
    return null;
  }

  Future<List<User>> getAllUsers() async {
    if (kIsWeb) return [];
    final db = await database;
    final maps = await db.query('users', orderBy: 'name ASC');
    
    return List.generate(maps.length, (i) {
      return User.fromMap(maps[i]);
    });
  }

  Future<void> updateUser(User user) async {
    if (kIsWeb) return;
    final db = await database;
    await db.update(
      'users',
      user.toMap(),
      where: 'phone = ?',
      whereArgs: [user.phone],
    );
  }

  Future<void> deleteUser(String phone) async {
    if (kIsWeb) return;
    final db = await database;
    await db.delete(
      'users',
      where: 'phone = ?',
      whereArgs: [phone],
    );
  }

  // ============= МЕТОДЫ ДЛЯ АБОНЕМЕНТОВ =============

  Future<Membership?> getMembership(String phone) async {
    if (kIsWeb) return null;
    final db = await database;
    final maps = await db.query(
      'memberships',
      where: 'user_phone = ?',
      whereArgs: [phone],
      orderBy: 'expiry_date DESC',
      limit: 1,
    );

    if (maps.isNotEmpty) {
      return Membership.fromMap(maps.first);
    }
    return null;
  }

  Future<void> addMembership(Membership membership) async {
    if (kIsWeb) return;
    final db = await database;
    await db.insert('memberships', {
      'user_phone': membership.userPhone,
      'start_date': membership.startDate.toIso8601String(),
      'expiry_date': membership.expiryDate.toIso8601String(),
      'months': membership.months,
      'price': membership.price,
      'payment_id': membership.paymentId,
    });
  }

  // ============= МЕТОДЫ ДЛЯ АКЦИЙ =============

  Future<List<Promotion>> getAllPromotions() async {
    if (kIsWeb) return [];
    final db = await database;
    final maps = await db.query(
      'promotions',
      orderBy: 'start_date DESC',
    );
    
    return List.generate(maps.length, (i) {
      return Promotion(
        id: maps[i]['id'] as int,
        title: maps[i]['title'] as String,
        description: maps[i]['description'] as String,
        startDate: DateTime.parse(maps[i]['start_date'] as String),
        endDate: maps[i]['end_date'] != null ? DateTime.parse(maps[i]['end_date'] as String) : null,
        isActive: (maps[i]['is_active'] as int) == 1,
      );
    });
  }

  Future<List<Map<String, dynamic>>> getActivePromotions() async {
    if (kIsWeb) return [];
    final db = await database;
    return await db.query(
      'promotions',
      where: 'is_active = ?',
      whereArgs: [1],
      orderBy: 'start_date DESC',
    );
  }

  Future<void> addPromotion(Promotion promotion) async {
    if (kIsWeb) return;
    final db = await database;
    await db.insert('promotions', {
      'id': promotion.id,
      'title': promotion.title,
      'description': promotion.description,
      'start_date': promotion.startDate.toIso8601String(),
      'end_date': promotion.endDate?.toIso8601String(),
      'is_active': promotion.isActive ? 1 : 0,
    });
  }

  Future<void> updatePromotion(Promotion promotion) async {
    if (kIsWeb) return;
    final db = await database;
    await db.update(
      'promotions',
      {
        'title': promotion.title,
        'description': promotion.description,
        'is_active': promotion.isActive ? 1 : 0,
      },
      where: 'id = ?',
      whereArgs: [promotion.id],
    );
  }

  Future<void> deletePromotion(int id) async {
    if (kIsWeb) return;
    final db = await database;
    await db.delete(
      'promotions',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // ============= МЕТОДЫ ДЛЯ ДНЕВНИКА =============

  Future<void> addDiaryEntry(DiaryEntry entry) async {
    if (kIsWeb) return;
    final db = await database;
    await db.insert('diary_entries', {
      'user_phone': entry.userPhone,
      'date': entry.date.toIso8601String(),
      'content': entry.content,
    });
  }

  Future<List<DiaryEntry>> getDiaryEntries(String phone, {int limit = 20}) async {
    if (kIsWeb) return [];
    final db = await database;
    final maps = await db.query(
      'diary_entries',
      where: 'user_phone = ?',
      whereArgs: [phone],
      orderBy: 'date DESC',
      limit: limit,
    );

    return List.generate(maps.length, (i) {
      return DiaryEntry(
        id: maps[i]['id'] as int,
        userPhone: maps[i]['user_phone'] as String,
        date: DateTime.parse(maps[i]['date'] as String),
        content: maps[i]['content'] as String,
      );
    });
  }

  Future<void> deleteDiaryEntry(int id) async {
    if (kIsWeb) return;
    final db = await database;
    await db.delete(
      'diary_entries',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // ============= МЕТОДЫ ДЛЯ ПРОГРАММ ТРЕНИРОВОК =============

  Future<void> addTrainingProgram(TrainingProgram program) async {
    if (kIsWeb) return;
    final db = await database;
    await db.insert('training_programs', {
      'id': program.id,
      'user_phone': program.userPhone,
      'name': program.name,
      'days': jsonEncode(program.days.map((d) => d.toMap()).toList()),
      'created_at': program.createdAt.toIso8601String(),
      'updated_at': program.updatedAt?.toIso8601String(),
    });
  }

  Future<List<TrainingProgram>> getTrainingPrograms(String userPhone) async {
    if (kIsWeb) return [];
    final db = await database;
    final maps = await db.query(
      'training_programs',
      where: 'user_phone = ?',
      whereArgs: [userPhone],
      orderBy: 'created_at DESC',
    );
    
    return List.generate(maps.length, (i) {
      return TrainingProgram(
        id: maps[i]['id'] as int,
        userPhone: maps[i]['user_phone'] as String,
        name: maps[i]['name'] as String,
        days: List<WorkoutDay>.from(
          (jsonDecode(maps[i]['days'] as String) as List).map(
            (d) => WorkoutDay.fromMap(d as Map<String, dynamic>),
          ),
        ),
        createdAt: DateTime.parse(maps[i]['created_at'] as String),
        updatedAt: maps[i]['updated_at'] != null 
            ? DateTime.parse(maps[i]['updated_at'] as String) 
            : null,
      );
    });
  }

  Future<void> updateTrainingProgram(TrainingProgram program) async {
    if (kIsWeb) return;
    final db = await database;
    await db.update(
      'training_programs',
      {
        'name': program.name,
        'days': jsonEncode(program.days.map((d) => d.toMap()).toList()),
        'updated_at': DateTime.now().toIso8601String(),
      },
      where: 'id = ?',
      whereArgs: [program.id],
    );
  }

  Future<void> deleteTrainingProgram(int id) async {
    if (kIsWeb) return;
    final db = await database;
    await db.delete(
      'training_programs',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // ============= МЕТОДЫ ДЛЯ ПОДДЕРЖКИ =============
  
  Future<void> addSupportMessage(
    String phone, 
    String message, 
    bool isFromUser,
    String senderName,
  ) async {
    if (kIsWeb) return;
    final db = await database;
    await db.insert('support_messages', {
      'user_phone': phone,
      'message': message,
      'sender_name': senderName,
      'timestamp': DateTime.now().toIso8601String(),
      'is_from_user': isFromUser ? 1 : 0,
      'is_read': 0,
    });
  }

  Future<List<Map<String, dynamic>>> getSupportMessages(String phone) async {
    if (kIsWeb) return [];
    final db = await database;
    final result = await db.query(
      'support_messages',
      where: 'user_phone = ?',
      whereArgs: [phone],
      orderBy: 'timestamp ASC',
    );
    
    return result.map((map) {
      if (!map.containsKey('sender_name') || map['sender_name'] == null) {
        map['sender_name'] = map['is_from_user'] == 1 ? 'Клиент' : 'Администратор';
      }
      return map;
    }).toList();
  }

  Future<void> markMessagesAsRead(String phone) async {
    if (kIsWeb) return;
    final db = await database;
    await db.update(
      'support_messages',
      {'is_read': 1},
      where: 'user_phone = ? AND is_read = 0',
      whereArgs: [phone],
    );
  }

  Future<int> getUnreadMessagesCount(String phone) async {
    if (kIsWeb) return 0;
    final db = await database;
    final result = await db.query(
      'support_messages',
      where: 'user_phone = ? AND is_read = 0 AND is_from_user = 0',
      whereArgs: [phone],
    );
    return result.length;
  }

  Future<List<Map<String, dynamic>>> getAllChatUsers() async {
    if (kIsWeb) return [];
    final db = await database;
    final result = await db.rawQuery('''
      SELECT DISTINCT user_phone, 
        (SELECT name FROM users WHERE phone = support_messages.user_phone) as user_name,
        (SELECT timestamp FROM support_messages WHERE user_phone = support_messages.user_phone ORDER BY timestamp DESC LIMIT 1) as last_message_time,
        (SELECT message FROM support_messages WHERE user_phone = support_messages.user_phone ORDER BY timestamp DESC LIMIT 1) as last_message,
        (SELECT COUNT(*) FROM support_messages WHERE user_phone = support_messages.user_phone AND is_read = 0 AND is_from_user = 1) as unread_count
      FROM support_messages
      GROUP BY user_phone
      ORDER BY last_message_time DESC
    ''');
    
    return result;
  }
}