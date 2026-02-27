import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:gym_app/models/user.dart';
import 'package:gym_app/models/membership.dart';
import 'package:gym_app/services/cloud_database_service.dart';
import 'package:gym_app/services/notification_service.dart';

class AdminClientsScreen extends StatefulWidget {
  const AdminClientsScreen({Key? key}) : super(key: key);

  @override
  State<AdminClientsScreen> createState() => _AdminClientsScreenState();
}

class _AdminClientsScreenState extends State<AdminClientsScreen> {
  List<User> _users = [];
  List<User> _filteredUsers = [];
  final Map<String, Membership?> _memberships = {};
  final TextEditingController _searchController = TextEditingController();
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadClients();
    _searchController.addListener(_filterUsers);
  }

  void refresh() {
    _loadClients();
  }

  Future<void> _loadClients() async {
    final cloudDb = Provider.of<CloudDatabaseService>(context, listen: false);
    final users = await cloudDb.getAllUsers();
    
    for (var user in users) {
      final membership = await cloudDb.getMembership(user.phone);
      _memberships[user.phone] = membership;
    }
    
    if (mounted) {
      setState(() {
        _users = users;
        _filteredUsers = users;
        _isLoading = false;
      });
    }
  }

  void _filterUsers() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      _filteredUsers = _users.where((user) {
        return user.name.toLowerCase().contains(query) ||
               user.phone.contains(query);
      }).toList();
    });
  }

  // ============= ДИАЛОГ РЕДАКТИРОВАНИЯ =============
  void _showEditDialog(User user) {
    final nameController = TextEditingController(text: user.name);
    final phoneController = TextEditingController(text: user.phone.replaceAll('+7', ''));

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.grey[900],
        title: const Text(
          'Редактировать клиента',
          style: TextStyle(color: Colors.white),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              style: const TextStyle(color: Colors.white),
              keyboardType: TextInputType.name,
              textInputAction: TextInputAction.next,
              decoration: InputDecoration(
                labelText: 'Имя',
                labelStyle: TextStyle(color: Colors.grey[400]),
                enabledBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: Colors.grey[800]!),
                ),
                focusedBorder: const OutlineInputBorder(
                  borderSide: BorderSide(color: Colors.white),
                ),
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: phoneController,
              style: const TextStyle(color: Colors.white),
              keyboardType: TextInputType.phone,
              maxLength: 10,
              textInputAction: TextInputAction.done,
              decoration: InputDecoration(
                labelText: 'Телефон',
                labelStyle: TextStyle(color: Colors.grey[400]),
                prefixText: '+7 ',
                counterText: '',
                enabledBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: Colors.grey[800]!),
                ),
                focusedBorder: const OutlineInputBorder(
                  borderSide: BorderSide(color: Colors.white),
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Отмена'),
          ),
          TextButton(
            onPressed: () async {
              final cloudDb = Provider.of<CloudDatabaseService>(context, listen: false);
              final updatedUser = User(
                phone: '+7${phoneController.text}',
                name: nameController.text,
                registrationDate: user.registrationDate,
              );
              await cloudDb.updateUser(updatedUser);
              Navigator.pop(context);
              await _loadClients();
            },
            child: const Text('Сохранить'),
          ),
        ],
      ),
    );
  }

  // ============= ДИАЛОГ УДАЛЕНИЯ =============
  void _showDeleteDialog(User user) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.grey[900],
        title: const Text(
          'Удаление клиента',
          style: TextStyle(color: Colors.white),
        ),
        content: Text(
          'Вы уверены, что хотите удалить клиента ${user.name}?',
          style: const TextStyle(color: Colors.white),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Отмена'),
          ),
          TextButton(
            onPressed: () async {
              final cloudDb = Provider.of<CloudDatabaseService>(context, listen: false);
              await cloudDb.deleteUser(user.phone);
              Navigator.pop(context);
              await _loadClients();
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Удалить'),
          ),
        ],
      ),
    );
  }

  // ============= ДИАЛОГ ОФОРМЛЕНИЯ АБОНЕМЕНТА =============
  void _showAddMembershipDialog(User user) {
    String? selectedMonths;
    final Map<String, Map<String, dynamic>> _prices = {
      '1': {'price': 2900, 'text': '1 месяц'},
      '3': {'price': 7500, 'text': '3 месяца'},
      '6': {'price': 13500, 'text': '6 месяцев'},
      '12': {'price': 24900, 'text': '12 месяцев'},
    };

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          backgroundColor: Colors.grey[900],
          title: const Text(
            'Оформление абонемента',
            style: TextStyle(color: Colors.white),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Клиент: ${user.name}',
                style: const TextStyle(color: Colors.white),
              ),
              const SizedBox(height: 10),
              DropdownButtonFormField<String>(
                value: selectedMonths,
                dropdownColor: Colors.grey[900],
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  labelText: 'Срок абонемента',
                  labelStyle: TextStyle(color: Colors.grey[400]),
                  enabledBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.grey[800]!),
                  ),
                  focusedBorder: const OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.white),
                  ),
                ),
                items: _prices.entries.map((entry) {
                  return DropdownMenuItem(
                    value: entry.key,
                    child: Text('${entry.value['text']} - ${entry.value['price']}₽'),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    selectedMonths = value;
                  });
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Отмена'),
            ),
            TextButton(
              onPressed: selectedMonths == null ? null : () async {
                final cloudDb = Provider.of<CloudDatabaseService>(context, listen: false);
                final notificationService = Provider.of<NotificationService>(context, listen: false);
                
                final months = int.parse(selectedMonths!);
                final price = _prices[selectedMonths]!['price'];
                
                final membership = Membership(
                  id: 0,
                  userPhone: user.phone,
                  startDate: DateTime.now(),
                  expiryDate: DateTime.now().add(Duration(days: 30 * months)),
                  months: months,
                  price: price.toDouble(),
                );
                
                await cloudDb.addMembership(membership);
                
                await notificationService.showNotification(
                  id: DateTime.now().millisecondsSinceEpoch,
                  title: 'Абонемент оформлен',
                  body: 'Ваш абонемент на $months месяцев оформлен!',
                );
                
                await _scheduleExpiryNotifications(user.phone, membership.expiryDate);
                
                Navigator.pop(context);
                await _loadClients();
              },
              child: const Text('Оформить'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _scheduleExpiryNotifications(String phone, DateTime expiryDate) async {
    final notificationService = Provider.of<NotificationService>(context, listen: false);
    
    await notificationService.scheduleMembershipNotification(
      id: DateTime.now().millisecondsSinceEpoch + 1,
      title: 'Абонемент скоро закончится',
      body: 'До окончания абонемента осталось 7 дней. Продлите сейчас!',
      scheduledDate: expiryDate.subtract(const Duration(days: 7)),
    );
    
    await notificationService.scheduleMembershipNotification(
      id: DateTime.now().millisecondsSinceEpoch + 2,
      title: 'Абонемент заканчивается',
      body: 'Осталось всего 3 дня! Успейте продлить абонемент.',
      scheduledDate: expiryDate.subtract(const Duration(days: 3)),
    );
    
    await notificationService.scheduleMembershipNotification(
      id: DateTime.now().millisecondsSinceEpoch + 3,
      title: 'Последний день абонемента',
      body: 'Сегодня последний день действия абонемента. Продлите его!',
      scheduledDate: expiryDate.subtract(const Duration(days: 1)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('dd.MM.yyyy');

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: const Text(
          'Управление клиентами',
          style: TextStyle(color: Colors.white),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _searchController,
              style: const TextStyle(color: Colors.white),
              keyboardType: TextInputType.text,
              textInputAction: TextInputAction.search,
              decoration: InputDecoration(
                hintText: 'Поиск по имени или телефону...',
                hintStyle: TextStyle(color: Colors.grey[600]),
                prefixIcon: const Icon(Icons.search, color: Colors.grey),
                filled: true,
                fillColor: Colors.grey[900],
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),

          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator(color: Colors.white))
                : _filteredUsers.isEmpty
                    ? Center(
                        child: Text(
                          'Клиенты не найдены',
                          style: TextStyle(color: Colors.grey[600]),
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: _filteredUsers.length,
                        itemBuilder: (context, index) {
                          final user = _filteredUsers[index];
                          final membership = _memberships[user.phone];
                          
                          return Container(
                            margin: const EdgeInsets.only(bottom: 10),
                            decoration: BoxDecoration(
                              color: Colors.grey[900],
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: ExpansionTile(
                              leading: CircleAvatar(
                                backgroundColor: Colors.grey[800],
                                child: Text(
                                  user.name[0].toUpperCase(),
                                  style: const TextStyle(color: Colors.white),
                                ),
                              ),
                              title: Text(
                                user.name,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              subtitle: Text(
                                user.phone,
                                style: TextStyle(color: Colors.grey[400]),
                              ),
                              children: [
                                Padding(
                                  padding: const EdgeInsets.all(16),
                                  child: Column(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.all(12),
                                        decoration: BoxDecoration(
                                          color: Colors.black,
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        child: Column(
                                          children: [
                                            Row(
                                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                              children: [
                                                const Text(
                                                  'Абонемент:',
                                                  style: TextStyle(color: Colors.grey),
                                                ),
                                                Text(
                                                  membership != null
                                                      ? 'до ${dateFormat.format(membership.expiryDate)}'
                                                      : 'Не оформлен',
                                                  style: TextStyle(
                                                    color: membership != null
                                                        ? (membership.daysLeft < 7
                                                            ? Colors.orange
                                                            : Colors.green)
                                                        : Colors.grey,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                              ],
                                            ),
                                            if (membership != null) ...[
                                              const SizedBox(height: 8),
                                              Row(
                                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                                children: [
                                                  const Text(
                                                    'Осталось дней:',
                                                    style: TextStyle(color: Colors.grey),
                                                  ),
                                                  Text(
                                                    '${membership.daysLeft}',
                                                    style: const TextStyle(color: Colors.white),
                                                  ),
                                                ],
                                              ),
                                            ],
                                          ],
                                        ),
                                      ),
                                      
                                      const SizedBox(height: 10),
                                      
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                        children: [
                                          ElevatedButton(
                                            onPressed: () => _showAddMembershipDialog(user),
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor: Colors.green,
                                              foregroundColor: Colors.white,
                                            ),
                                            child: const Text('Оформить'),
                                          ),
                                          ElevatedButton(
                                            onPressed: () => _showEditDialog(user),
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor: Colors.blue,
                                              foregroundColor: Colors.white,
                                            ),
                                            child: const Text('Редакт.'),
                                          ),
                                          ElevatedButton(
                                            onPressed: () => _showDeleteDialog(user),
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor: Colors.red,
                                              foregroundColor: Colors.white,
                                            ),
                                            child: const Text('Удалить'),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
}