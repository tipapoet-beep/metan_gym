import 'package:flutter/material.dart';
import 'calculators/kbju_calculator.dart';
import 'calculators/one_rm_calculator.dart';
import 'calculators/wilks_calculator.dart';

class CalculatorsScreen extends StatefulWidget {
  const CalculatorsScreen({Key? key}) : super(key: key);

  @override
  State<CalculatorsScreen> createState() => _CalculatorsScreenState();
}

class _CalculatorsScreenState extends State<CalculatorsScreen> {
  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        backgroundColor: Colors.black,
        appBar: AppBar(
          backgroundColor: Colors.black,
          title: const Text(
            'Калькуляторы',
            style: TextStyle(color: Colors.white),
          ),
          iconTheme: const IconThemeData(color: Colors.white),
          bottom: const TabBar(
            indicatorColor: Colors.white,
            labelColor: Colors.white,
            unselectedLabelColor: Colors.grey,
            tabs: [
              Tab(text: 'КБЖУ'),
              Tab(text: '1ПМ'),
              Tab(text: 'Вилкс'),
            ],
          ),
        ),
        body: const TabBarView(
          children: [
            KBJUCalculator(),
            OneRMCalculator(),
            WilksCalculator(),
          ],
        ),
      ),
    );
  }
}