import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:gym_app/providers/user_provider.dart';
import 'package:gym_app/models/user.dart';
import 'package:gym_app/screens/payments_screen.dart';
import 'package:gym_app/screens/promotions_screen.dart'; 
import 'package:gym_app/screens/calculators_screen.dart';
import 'package:gym_app/screens/programs_screen.dart';
import 'package:gym_app/screens/diary_screen.dart';
import 'package:gym_app/screens/support_screen.dart';
import 'package:gym_app/screens/contacts_screen.dart';
import 'package:gym_app/screens/auth_screen.dart';
import 'package:gym_app/widgets/membership_card.dart';
import 'package:gym_app/widgets/function_card.dart';
import 'package:gym_app/services/cloud_database_service.dart';
import 'package:gym_app/models/membership.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late CloudDatabaseService _cloudDatabaseService;
  late User _user;
  Membership? _membership;

  @override
  void initState() {
    super.initState();
    _cloudDatabaseService = Provider.of<CloudDatabaseService>(context, listen: false);
    _user = Provider.of<UserProvider>(context, listen: false).currentUser!;
    _loadMembership();
  }

  Future<void> _loadMembership() async {
    final membership = await _cloudDatabaseService.getMembership(_user.phone);
    if (mounted) {
      setState(() {
        _membership = membership;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 120,
            floating: true,
            backgroundColor: Colors.black,
            flexibleSpace: FlexibleSpaceBar(
              titlePadding: const EdgeInsets.only(left: 20, bottom: 20),
              title: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  const Text(
                    'METAH GYM',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    'Привет, ${_user.name}!',
                    style: TextStyle(
                      color: Colors.grey[400],
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.logout, color: Colors.white),
                onPressed: _logout,
              ),
            ],
          ),

          SliverPadding(
            padding: const EdgeInsets.all(20),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                MembershipCard(
                  membership: _membership,
                  onRenew: () => _navigateTo(PaymentsScreen()),
                ),

                const SizedBox(height: 20),

                const Text(
                  'Функции',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 10),

                GridView.count(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisCount: 2,
                  mainAxisSpacing: 10,
                  crossAxisSpacing: 10,
                  childAspectRatio: 1.2,
                  children: [
                    FunctionCard(
                      icon: Icons.local_offer,
                      title: 'Акции',
                      onTap: () => _navigateTo(PromotionsScreen()),
                    ),
                    FunctionCard(
                      icon: Icons.calculate,
                      title: 'Калькуляторы',
                      onTap: () => _navigateTo(CalculatorsScreen()),
                    ),
                    FunctionCard(
                      icon: Icons.fitness_center,
                      title: 'Программы',
                      onTap: () => _navigateTo(ProgramsScreen()),
                    ),
                    FunctionCard(
                      icon: Icons.book,
                      title: 'Дневник',
                      onTap: () => _navigateTo(DiaryScreen()),
                    ),
                    FunctionCard(
                      icon: Icons.chat,
                      title: 'Поддержка',
                      onTap: () => _navigateTo(SupportScreen()),
                    ),
                    FunctionCard(
                      icon: Icons.info,
                      title: 'Контакты',
                      onTap: () => _navigateTo(ContactsScreen()),
                    ),
                  ],
                ),
              ]),
            ),
          ),
        ],
      ),
    );
  }

  void _navigateTo(Widget screen) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => screen),
    );
  }

  void _logout() {
    Provider.of<UserProvider>(context, listen: false).logout();
    Navigator.of(context).pushReplacementNamed('/');
  }
}