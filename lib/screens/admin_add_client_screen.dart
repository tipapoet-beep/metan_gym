import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:gym_app/services/cloud_database_service.dart';
import 'package:gym_app/services/notification_service.dart';
import 'package:gym_app/models/user.dart';
import 'package:gym_app/models/membership.dart';

class AdminAddClientScreen extends StatefulWidget {
  const AdminAddClientScreen({Key? key}) : super(key: key);

  @override
  State<AdminAddClientScreen> createState() => _AdminAddClientScreenState();
}

class _AdminAddClientScreenState extends State<AdminAddClientScreen> {
  final _phoneController = TextEditingController();
  final _nameController = TextEditingController();
  String? _selectedMonths;
  bool _isLoading = false;
  String _status = '';

  final Map<String, Map<String, dynamic>> _prices = {
    '1': {'price': 2900, 'text': '1 месяц'},
    '3': {'price': 7500, 'text': '3 месяца'},
    '6': {'price': 13500, 'text': '6 месяцев'},
    '12': {'price': 24900, 'text': '12 месяцев'},
  };

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: const Text(
          'Добавить клиента',
          style: TextStyle(color: Colors.white),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Данные клиента',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),

            TextField(
              controller: _phoneController,
              style: const TextStyle(color: Colors.white),
              keyboardType: TextInputType.phone,
              maxLength: 10,
              decoration: InputDecoration(
                labelText: 'Телефон клиента',
                labelStyle: TextStyle(color: Colors.grey[400]),
                prefixText: '+7 ',
                prefixStyle: const TextStyle(color: Colors.white),
                counterText: '',
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
              controller: _nameController,
              style: const TextStyle(color: Colors.white),
              keyboardType: TextInputType.name,
              textInputAction: TextInputAction.next,
              decoration: InputDecoration(
                labelText: 'ФИО клиента',
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

            const Text(
              'Абонемент',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 10),

            ..._prices.entries.map((entry) {
              final isSelected = _selectedMonths == entry.key;
              return GestureDetector(
                onTap: () {
                  setState(() {
                    _selectedMonths = entry.key;
                  });
                },
                child: Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: isSelected ? Colors.grey[800] : Colors.grey[900],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: isSelected ? Colors.white : Colors.transparent,
                      width: 1,
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        entry.value['text'],
                        style: const TextStyle(color: Colors.white),
                      ),
                      Text(
                        '${entry.value['price']} ₽',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),

            const SizedBox(height: 20),

            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _addClient,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: Colors.black,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: Text(
                  _isLoading ? 'Добавление...' : 'Добавить клиента',
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
          ],
        ),
      ),
    );
  }

  Future<void> _addClient() async {
    if (_phoneController.text.isEmpty) {
      setState(() => _status = 'Ошибка: Введите телефон');
      return;
    }
    if (_phoneController.text.length != 10) {
      setState(() => _status = 'Ошибка: Телефон должен содержать 10 цифр');
      return;
    }
    if (_nameController.text.isEmpty) {
      setState(() => _status = 'Ошибка: Введите имя клиента');
      return;
    }
    if (_selectedMonths == null) {
      setState(() => _status = 'Ошибка: Выберите срок абонемента');
      return;
    }

    setState(() {
      _isLoading = true;
      _status = '';
    });

    try {
      final cloudDb = Provider.of<CloudDatabaseService>(context, listen: false);
      final notificationService = Provider.of<NotificationService>(context, listen: false);

      final phone = '+7${_phoneController.text}';
      final months = int.parse(_selectedMonths!);
      final price = _prices[_selectedMonths]!['price'];

      // Проверяем, существует ли пользователь
      var user = await cloudDb.getUser(phone);
      
      if (user == null) {
        // Создаем нового пользователя
        user = User(
          phone: phone,
          name: _nameController.text,
          registrationDate: DateTime.now(),
        );
        await cloudDb.addUser(user);
      }

      // Создаем абонемент
      final membership = Membership(
        id: 0,
        userPhone: phone,
        startDate: DateTime.now(),
        expiryDate: DateTime.now().add(Duration(days: 30 * months)),
        months: months,
        price: price.toDouble(),
      );
      
      await cloudDb.addMembership(membership);

      // Отправляем уведомление клиенту
      await notificationService.showNotification(
        id: DateTime.now().millisecondsSinceEpoch,
        title: 'Добро пожаловать в METAH GYM!',
        body: 'Ваш абонемент на $months месяцев оформлен администратором',
      );

      setState(() {
        _status = '✓ Клиент успешно добавлен!';
        _phoneController.clear();
        _nameController.clear();
        _selectedMonths = null;
        _isLoading = false;
      });

    } catch (e) {
      setState(() {
        _status = 'Ошибка: ${e.toString()}';
        _isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    _phoneController.dispose();
    _nameController.dispose();
    super.dispose();
  }
}