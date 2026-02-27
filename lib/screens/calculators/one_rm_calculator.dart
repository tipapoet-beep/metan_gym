import 'package:flutter/material.dart';

class OneRMCalculator extends StatefulWidget {
  const OneRMCalculator({Key? key}) : super(key: key);

  @override
  State<OneRMCalculator> createState() => _OneRMCalculatorState();
}

class _OneRMCalculatorState extends State<OneRMCalculator> {
  late final TextEditingController _weightController;
  late final TextEditingController _repsController;
  String _result = '';

  @override
  void initState() {
    super.initState();
    _weightController = TextEditingController();
    _repsController = TextEditingController();
  }

  @override
  void dispose() {
    _weightController.dispose();
    _repsController.dispose();
    super.dispose();
  }

  void _calculate() {
    try {
      final weight = double.parse(_weightController.text);
      final reps = double.parse(_repsController.text);

      if (reps < 1 || reps > 12) {
        if (mounted) {
          setState(() {
            _result = '❌ Количество повторений должно быть от 1 до 12';
          });
        }
        return;
      }

      final epley = weight * (1 + 0.0333 * reps);
      final brzycki = weight * (36 / (37 - reps));
      final lander = (100 * weight) / (101.3 - 2.67123 * reps);
      final average = (epley + brzycki + lander) / 3;

      if (mounted) {
        setState(() {
          _result = '''
🏋️ **1ПМ (максимум на один повтор)**

📊 По разным формулам:

Эйпли: ${epley.toStringAsFixed(1)} кг
Бжицки: ${brzycki.toStringAsFixed(1)} кг
Лэндера: ${lander.toStringAsFixed(1)} кг

🎯 Среднее значение: ${average.toStringAsFixed(1)} кг

---
Вес: $weight кг
Повторения: $reps
''';
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _result = '❌ Пожалуйста, заполните все поля корректно';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Калькулятор 1ПМ',
            style: TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 20),
          
          const Text(
            'Рассчитайте свой максимум в одном повторении',
            style: TextStyle(color: Colors.grey, fontSize: 14),
          ),
          const SizedBox(height: 20),

          TextField(
            controller: _weightController,
            style: const TextStyle(color: Colors.white),
            keyboardType: TextInputType.number,
            decoration: _inputDecoration('Вес снаряда (кг)'),
          ),
          const SizedBox(height: 15),

          TextField(
            controller: _repsController,
            style: const TextStyle(color: Colors.white),
            keyboardType: TextInputType.number,
            decoration: _inputDecoration('Количество повторений (1-12)'),
          ),
          const SizedBox(height: 20),

          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              onPressed: _calculate,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: Colors.black,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text('Рассчитать 1ПМ'),
            ),
          ),

          const SizedBox(height: 20),

          if (_result.isNotEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey[900],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                _result,
                style: const TextStyle(color: Colors.white),
              ),
            ),

          const SizedBox(height: 20),

          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.grey[900],
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Text(
              'ℹ️ Калькулятор наиболее точен для повторений от 1 до 10. Для 11-12 повторений погрешность увеличивается.',
              style: TextStyle(color: Colors.grey, fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }

  InputDecoration _inputDecoration(String label) {
    return InputDecoration(
      labelText: label,
      labelStyle: TextStyle(color: Colors.grey[400]),
      enabledBorder: OutlineInputBorder(
        borderSide: BorderSide(color: Colors.grey[800]!),
        borderRadius: BorderRadius.circular(8),
      ),
      focusedBorder: OutlineInputBorder(
        borderSide: const BorderSide(color: Colors.white),
        borderRadius: BorderRadius.circular(8),
      ),
    );
  }
}