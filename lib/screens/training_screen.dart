import 'package:flutter/material.dart';

class TrainingScreen extends StatelessWidget {
  const TrainingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: const Text(
          'Программа тренировок',
          style: TextStyle(color: Colors.white),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: ListView(
          children: [
            _buildDayCard(
              'День 1 - Грудь + Трицепс',
              ['Жим лежа: 4x8-10', 'Жим гантелей: 3x10-12', 'Французский жим: 3x10-12'],
            ),
            const SizedBox(height: 10),
            _buildDayCard(
              'День 2 - Спина + Бицепс',
              ['Подтягивания: 4x8-10', 'Тяга штанги: 4x8-10', 'Подъем штанги: 3x10-12'],
            ),
            const SizedBox(height: 10),
            _buildDayCard(
              'День 3 - Ноги',
              ['Приседания: 4x8-10', 'Жим ногами: 3x10-12', 'Разгибания: 3x12-15'],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDayCard(String title, List<String> exercises) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[900],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 10),
          ...exercises.map((e) => Padding(
            padding: const EdgeInsets.only(left: 8, bottom: 4),
            child: Text(
              '• $e',
              style: TextStyle(color: Colors.grey[400]),
            ),
          )),
        ],
      ),
    );
  }
}