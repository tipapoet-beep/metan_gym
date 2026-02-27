import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:gym_app/providers/user_provider.dart';
import 'package:gym_app/screens/admin_promotions_screen.dart';
import 'package:gym_app/screens/admin_notifications_screen.dart';
import 'package:gym_app/screens/admin_clients_screen.dart';
import 'package:gym_app/screens/admin_chat_list_screen.dart';
import 'package:gym_app/screens/admin_add_client_screen.dart';

class AdminScreen extends StatefulWidget {
  const AdminScreen({Key? key}) : super(key: key);

  @override
  State<AdminScreen> createState() => _AdminScreenState();
}

class _AdminScreenState extends State<AdminScreen> {
  int _selectedIndex = 0;

  late List<Widget> _screens;
  late List<String> _titles;

  @override
  void initState() {
    super.initState();
    _screens = [
      AdminClientsScreen(key: UniqueKey()), // Добавляем ключ для обновления
      const AdminPromotionsScreen(),
      const AdminNotificationsScreen(),
      const AdminChatListScreen(),
    ];
    _titles = [
      'Клиенты',
      'Акции',
      'Рассылка',
      'Чаты',
    ];
  }

  void _refreshClients() {
    setState(() {
      // Обновляем экран клиентов, создавая новый экземпляр с новым ключом
      _screens[0] = AdminClientsScreen(key: UniqueKey());
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: Text(
          'METAH GYM - ${_titles[_selectedIndex]}',
          style: const TextStyle(color: Colors.white),
        ),
        actions: [
          // Кнопка добавления клиента на экране клиентов
          if (_selectedIndex == 0)
            IconButton(
              icon: const Icon(Icons.person_add, color: Colors.white),
              onPressed: () async {
                final result = await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const AdminAddClientScreen(),
                  ),
                );
                // Если клиент был добавлен, обновляем список
                if (result == true) {
                  _refreshClients();
                }
              },
            ),
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.white),
            onPressed: () {
              Provider.of<UserProvider>(context, listen: false).logout();
              Navigator.of(context).pushReplacementNamed('/');
            },
          ),
        ],
      ),
      body: _screens[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        backgroundColor: Colors.grey[900],
        selectedItemColor: Colors.white,
        unselectedItemColor: Colors.grey[600],
        currentIndex: _selectedIndex,
        type: BottomNavigationBarType.fixed,
        onTap: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.people),
            label: 'Клиенты',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.local_offer),
            label: 'Акции',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.notifications),
            label: 'Рассылка',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.chat),
            label: 'Чаты',
          ),
        ],
      ),
    );
  }
}