import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:gym_app/models/user.dart';
import 'package:gym_app/models/membership.dart';
import 'package:gym_app/models/promotion.dart';
import 'package:gym_app/models/training_program.dart';
import 'package:gym_app/models/diary_entry.dart';
import 'dart:convert';

class CloudDatabaseService {
  static final CloudDatabaseService _instance = CloudDatabaseService._internal();
  factory CloudDatabaseService() => _instance;
  CloudDatabaseService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // ============= ПОЛЬЗОВАТЕЛИ =============

  Future<void> addUser(User user) async {
    try {
      await _firestore.collection('users').doc(user.phone).set({
        'phone': user.phone,
        'name': user.name,
        'registrationDate': Timestamp.fromDate(user.registrationDate),
        'lastActive': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('Add user error: $e');
    }
  }

  Future<User?> getUser(String phone) async {
    try {
      final doc = await _firestore.collection('users').doc(phone).get();
      if (doc.exists) {
        final data = doc.data()!;
        return User(
          phone: data['phone'],
          name: data['name'],
          registrationDate: (data['registrationDate'] as Timestamp).toDate(),
        );
      }
      return null;
    } catch (e) {
      print('Get user error: $e');
      return null;
    }
  }

  Future<List<User>> getAllUsers() async {
    try {
      final snapshot = await _firestore
          .collection('users')
          .orderBy('name')
          .get();
      
      return snapshot.docs.map((doc) {
        final data = doc.data();
        return User(
          phone: data['phone'],
          name: data['name'],
          registrationDate: (data['registrationDate'] as Timestamp).toDate(),
        );
      }).toList();
    } catch (e) {
      print('Get all users error: $e');
      return [];
    }
  }

  Future<void> updateUser(User user) async {
    try {
      await _firestore.collection('users').doc(user.phone).update({
        'name': user.name,
        'lastActive': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('Update user error: $e');
    }
  }

  Future<void> deleteUser(String phone) async {
    try {
      await _firestore.collection('users').doc(phone).delete();
    } catch (e) {
      print('Delete user error: $e');
    }
  }

  Future<void> saveUserFcmToken(String phone, String token) async {
    try {
      await _firestore.collection('users').doc(phone).update({
        'fcmToken': token,
        'lastTokenUpdate': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('Save FCM token error: $e');
    }
  }

  // ============= АБОНЕМЕНТЫ =============

  Future<void> addMembership(Membership membership) async {
    try {
      await _firestore.collection('memberships').add({
        'userPhone': membership.userPhone,
        'startDate': Timestamp.fromDate(membership.startDate),
        'expiryDate': Timestamp.fromDate(membership.expiryDate),
        'months': membership.months,
        'price': membership.price,
        'paymentId': membership.paymentId,
      });
    } catch (e) {
      print('Add membership error: $e');
    }
  }

  Future<Membership?> getMembership(String phone) async {
    try {
      final snapshot = await _firestore
          .collection('memberships')
          .where('userPhone', isEqualTo: phone)
          .orderBy('expiryDate', descending: true)
          .limit(1)
          .get();

      if (snapshot.docs.isNotEmpty) {
        final data = snapshot.docs.first.data();
        return Membership(
          id: int.tryParse(snapshot.docs.first.id) ?? 0,
          userPhone: data['userPhone'],
          startDate: (data['startDate'] as Timestamp).toDate(),
          expiryDate: (data['expiryDate'] as Timestamp).toDate(),
          months: data['months'],
          price: data['price'],
          paymentId: data['paymentId'],
        );
      }
      return null;
    } catch (e) {
      print('Get membership error: $e');
      return null;
    }
  }

  // ============= АКЦИИ =============

  Future<List<Promotion>> getAllPromotions() async {
    try {
      final snapshot = await _firestore
          .collection('promotions')
          .orderBy('startDate', descending: true)
          .get();

      return snapshot.docs.map((doc) {
        final data = doc.data();
        return Promotion(
          id: int.tryParse(doc.id) ?? 0,
          title: data['title'],
          description: data['description'],
          startDate: (data['startDate'] as Timestamp).toDate(),
          endDate: data['endDate'] != null ? (data['endDate'] as Timestamp).toDate() : null,
          isActive: data['isActive'] ?? true,
        );
      }).toList();
    } catch (e) {
      print('Get promotions error: $e');
      return [];
    }
  }

  Future<void> addPromotion(Promotion promotion) async {
    try {
      await _firestore.collection('promotions').doc(promotion.id.toString()).set({
        'title': promotion.title,
        'description': promotion.description,
        'startDate': Timestamp.fromDate(promotion.startDate),
        'endDate': promotion.endDate != null ? Timestamp.fromDate(promotion.endDate!) : null,
        'isActive': promotion.isActive,
        'createdAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('Add promotion error: $e');
    }
  }

  Future<void> updatePromotion(Promotion promotion) async {
    try {
      await _firestore.collection('promotions').doc(promotion.id.toString()).update({
        'title': promotion.title,
        'description': promotion.description,
        'isActive': promotion.isActive,
      });
    } catch (e) {
      print('Update promotion error: $e');
    }
  }

  Future<void> deletePromotion(int id) async {
    try {
      await _firestore.collection('promotions').doc(id.toString()).delete();
    } catch (e) {
      print('Delete promotion error: $e');
    }
  }

  // ============= ПРОГРАММЫ ТРЕНИРОВОК =============

  Future<void> addTrainingProgram(TrainingProgram program) async {
    try {
      await _firestore.collection('training_programs').doc(program.id.toString()).set({
        'userPhone': program.userPhone,
        'name': program.name,
        'days': jsonEncode(program.days.map((d) => d.toMap()).toList()),
        'createdAt': Timestamp.fromDate(program.createdAt),
        'updatedAt': program.updatedAt != null ? Timestamp.fromDate(program.updatedAt!) : null,
      });
    } catch (e) {
      print('Add program error: $e');
    }
  }

  Future<List<TrainingProgram>> getTrainingPrograms(String userPhone) async {
    try {
      final snapshot = await _firestore
          .collection('training_programs')
          .where('userPhone', isEqualTo: userPhone)
          .orderBy('createdAt', descending: true)
          .get();

      return snapshot.docs.map((doc) {
        final data = doc.data();
        return TrainingProgram(
          id: int.tryParse(doc.id) ?? 0,
          userPhone: data['userPhone'],
          name: data['name'],
          days: List<WorkoutDay>.from(
            (jsonDecode(data['days']) as List).map(
              (d) => WorkoutDay.fromMap(d as Map<String, dynamic>),
            ),
          ),
          createdAt: (data['createdAt'] as Timestamp).toDate(),
          updatedAt: data['updatedAt'] != null ? (data['updatedAt'] as Timestamp).toDate() : null,
        );
      }).toList();
    } catch (e) {
      print('Get programs error: $e');
      return [];
    }
  }

  Future<void> updateTrainingProgram(TrainingProgram program) async {
    try {
      await _firestore.collection('training_programs').doc(program.id.toString()).update({
        'name': program.name,
        'days': jsonEncode(program.days.map((d) => d.toMap()).toList()),
        'updatedAt': Timestamp.fromDate(DateTime.now()),
      });
    } catch (e) {
      print('Update program error: $e');
    }
  }

  Future<void> deleteTrainingProgram(int id) async {
    try {
      await _firestore.collection('training_programs').doc(id.toString()).delete();
    } catch (e) {
      print('Delete program error: $e');
    }
  }

  // ============= ДНЕВНИК =============

  Future<void> addDiaryEntry(DiaryEntry entry) async {
    try {
      await _firestore.collection('diary_entries').add({
        'userPhone': entry.userPhone,
        'date': Timestamp.fromDate(entry.date),
        'content': entry.content,
      });
    } catch (e) {
      print('Add diary entry error: $e');
    }
  }

  Future<List<DiaryEntry>> getDiaryEntries(String phone, {int limit = 20}) async {
    try {
      final snapshot = await _firestore
          .collection('diary_entries')
          .where('userPhone', isEqualTo: phone)
          .orderBy('date', descending: true)
          .limit(limit)
          .get();

      return snapshot.docs.map((doc) {
        final data = doc.data();
        return DiaryEntry(
          id: int.tryParse(doc.id) ?? 0,
          userPhone: data['userPhone'],
          date: (data['date'] as Timestamp).toDate(),
          content: data['content'],
        );
      }).toList();
    } catch (e) {
      print('Get diary entries error: $e');
      return [];
    }
  }

  Future<void> deleteDiaryEntry(int id) async {
    try {
      await _firestore.collection('diary_entries').doc(id.toString()).delete();
    } catch (e) {
      print('Delete diary entry error: $e');
    }
  }
}