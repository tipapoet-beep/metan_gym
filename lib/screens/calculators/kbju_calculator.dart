import 'package:flutter/material.dart';

class KBJUCalculator extends StatefulWidget {
  const KBJUCalculator({Key? key}) : super(key: key);

  @override
  State<KBJUCalculator> createState() => _KBJUCalculatorState();
}

class _KBJUCalculatorState extends State<KBJUCalculator> {
  // Все контроллеры объявлены как late
  late final TextEditingController _weightController;
  late final TextEditingController _heightController;
  late final TextEditingController _ageController;
  
  String _gender = 'male';
  String _activityLevel = '1.55';
  String _goal = 'maintain';
  String _result = '';

  final Map<String, String> _activityLevels = {
    '1.2': 'Минимальная (сидячая работа, нет спорта)',
    '1.375': 'Низкая (тренировки 1-3 раза в неделю)',
    '1.55': 'Средняя (тренировки 3-5 раз в неделю)',
    '1.725': 'Высокая (тренировки 6-7 раз в неделю)',
    '1.9': 'Очень высокая (физическая работа + тренировки)',
  };

  @override
  void initState() {
    super.initState();
    // Инициализация в initState
    _weightController = TextEditingController();
    _heightController = TextEditingController();
    _ageController = TextEditingController();
  }

  @override
  void dispose() {
    // ВАЖНО: очищаем все контроллеры
    _weightController.dispose();
    _heightController.dispose();
    _ageController.dispose();
    super.dispose();
  }

  void _calculate() {
    try {
      final weight = double.parse(_weightController.text);
      final height = double.parse(_heightController.text);
      final age = double.parse(_ageController.text);
      final activity = double.parse(_activityLevel);

      double bmr;
      if (_gender == 'male') {
        bmr = 88.36 + (13.4 * weight) + (4.8 * height) - (5.7 * age);
      } else {
        bmr = 447.6 + (9.2 * weight) + (3.1 * height) - (4.3 * age);
      }

      final tdee = bmr * activity;

      double targetCalories;
      String goalText;
      
      switch (_goal) {
        case 'lose':
          targetCalories = tdee * 0.85;
          goalText = 'Для похудения';
          break;
        case 'gain':
          targetCalories = tdee * 1.15;
          goalText = 'Для набора массы';
          break;
        default:
          targetCalories = tdee;
          goalText = 'Для поддержания веса';
      }

      final protein = (targetCalories * 0.3 / 4).round();
      final fat = (targetCalories * 0.3 / 9).round();
      final carbs = (targetCalories * 0.4 / 4).round();

      if (mounted) {
        setState(() {
          _result = '''
📊 **$goalText**

Калории: ${targetCalories.round()} ккал

🥩 Белки: $protein г
🧈 Жиры: $fat г
🍚 Углеводы: $carbs г

---
Базальный метаболизм: ${bmr.round()} ккал
Суточная норма: ${tdee.round()} ккал
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
            'Калькулятор КБЖУ',
            style: TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 20),

          TextField(
            controller: _weightController,
            style: const TextStyle(color: Colors.white),
            keyboardType: TextInputType.number,
            decoration: _inputDecoration('Вес (кг)'),
          ),
          const SizedBox(height: 15),

          TextField(
            controller: _heightController,
            style: const TextStyle(color: Colors.white),
            keyboardType: TextInputType.number,
            decoration: _inputDecoration('Рост (см)'),
          ),
          const SizedBox(height: 15),

          TextField(
            controller: _ageController,
            style: const TextStyle(color: Colors.white),
            keyboardType: TextInputType.number,
            decoration: _inputDecoration('Возраст'),
          ),
          const SizedBox(height: 15),

          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: Colors.grey[900],
              borderRadius: BorderRadius.circular(8),
            ),
            child: DropdownButton<String>(
              value: _gender,
              dropdownColor: Colors.grey[900],
              style: const TextStyle(color: Colors.white),
              underline: Container(),
              isExpanded: true,
              items: const [
                DropdownMenuItem(value: 'male', child: Text('Мужской')),
                DropdownMenuItem(value: 'female', child: Text('Женский')),
              ],
              onChanged: (value) {
                if (value != null && mounted) {
                  setState(() {
                    _gender = value;
                  });
                }
              },
            ),
          ),
          const SizedBox(height: 15),

          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: Colors.grey[900],
              borderRadius: BorderRadius.circular(8),
            ),
            child: DropdownButton<String>(
              value: _activityLevel,
              dropdownColor: Colors.grey[900],
              style: const TextStyle(color: Colors.white),
              underline: Container(),
              isExpanded: true,
              items: _activityLevels.entries.map((entry) {
                return DropdownMenuItem(
                  value: entry.key,
                  child: Text(entry.value),
                );
              }).toList(),
              onChanged: (value) {
                if (value != null && mounted) {
                  setState(() {
                    _activityLevel = value;
                  });
                }
              },
            ),
          ),
          const SizedBox(height: 15),

          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: Colors.grey[900],
              borderRadius: BorderRadius.circular(8),
            ),
            child: DropdownButton<String>(
              value: _goal,
              dropdownColor: Colors.grey[900],
              style: const TextStyle(color: Colors.white),
              underline: Container(),
              isExpanded: true,
              items: const [
                DropdownMenuItem(value: 'lose', child: Text('Похудение')),
                DropdownMenuItem(value: 'maintain', child: Text('Поддержание')),
                DropdownMenuItem(value: 'gain', child: Text('Набор массы')),
              ],
              onChanged: (value) {
                if (value != null && mounted) {
                  setState(() {
                    _goal = value;
                  });
                }
              },
            ),
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
              child: const Text('Рассчитать'),
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