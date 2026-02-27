import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:gym_app/models/user.dart';

class UserProvider extends ChangeNotifier {
  User? _currentUser;
  bool _isAdmin = false;
  bool _isLoading = true;

  User? get currentUser => _currentUser;
  bool get isAdmin => _isAdmin;
  bool get isLoading => _isLoading;

  UserProvider() {
    _loadSavedUser();
  }

  Future<void> _loadSavedUser() async {
    final prefs = await SharedPreferences.getInstance();
    final savedPhone = prefs.getString('user_phone');
    final savedName = prefs.getString('user_name');
    final savedRegDate = prefs.getString('user_reg_date');

    if (savedPhone != null && savedName != null && savedRegDate != null) {
      _currentUser = User(
        phone: savedPhone,
        name: savedName,
        registrationDate: DateTime.parse(savedRegDate),
      );
      _isAdmin = savedPhone == '+70000000000';
    }
    
    _isLoading = false;
    notifyListeners();
  }

  Future<void> setUser(User user) async {
    _currentUser = user;
    _isAdmin = user.phone == '+70000000000';
    
    // Сохраняем в SharedPreferences
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('user_phone', user.phone);
    await prefs.setString('user_name', user.name);
    await prefs.setString('user_reg_date', user.registrationDate.toIso8601String());
    
    notifyListeners();
  }

  Future<void> logout() async {
    _currentUser = null;
    _isAdmin = false;
    
    // Очищаем сохраненные данные
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('user_phone');
    await prefs.remove('user_name');
    await prefs.remove('user_reg_date');
    
    notifyListeners();
  }
}