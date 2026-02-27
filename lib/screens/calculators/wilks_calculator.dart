import 'package:flutter/material.dart';

class WilksCalculator extends StatefulWidget {
  const WilksCalculator({Key? key}) : super(key: key);

  @override
  State<WilksCalculator> createState() => _WilksCalculatorState();
}

class _WilksCalculatorState extends State<WilksCalculator> {
  late final TextEditingController _bodyWeightController;
  late final TextEditingController _squatController;
  late final TextEditingController _benchController;
  late final TextEditingController _deadliftController;
  
  String _gender = 'male';
  String _result = '';

  @override
  void initState() {
    super.initState();
    _bodyWeightController = TextEditingController();
    _squatController = TextEditingController();
    _benchController = TextEditingController();
    _deadliftController = TextEditingController();
  }

  @override
  void dispose() {
    _bodyWeightController.dispose();
    _squatController.dispose();
    _benchController.dispose();
    _deadliftController.dispose();
    super.dispose();
  }

  void _calculate() {
    try {
      final bodyWeight = double.parse(_bodyWeightController.text);
      final squat = double.parse(_squatController.text);
      final bench = double.parse(_benchController.text);
      final deadlift = double.parse(_deadliftController.text);
      
      final total = squat + bench + deadlift;

      double a, b, c, d, e;
      
      if (_gender == 'male') {
        a = -216.0475144;
        b = 16.2606339;
        c = -0.002388645;
        d = -0.00113732;
        e = 7.01863e-06;
      } else {
        a = 594.31747775582;
        b = -27.23842536447;
        c = 0.82112226871;
        d = -0.00930733913;
        e = 0.00004731582;
      }

      final coefficient = 500 / (a + b * bodyWeight + c * bodyWeight * bodyWeight + 
                                d * bodyWeight * bodyWeight * bodyWeight + 
                                e * bodyWeight * bodyWeight * bodyWeight * bodyWeight);
      
      final wilksTotal = total * coefficient;
      final wilksSquat = squat * coefficient;
      final wilksBench = bench * coefficient;
      final wilksDeadlift = deadlift * coefficient;

      if (mounted) {
        setState(() {
          _result = '''
🏋️ **Очки Вилкса**

Сумма: ${wilksTotal.toStringAsFixed(2)}

🦵 Присед: ${wilksSquat.toStringAsFixed(2)}
💪 Жим: ${wilksBench.toStringAsFixed(2)}
🦍 Тяга: ${wilksDeadlift.toStringAsFixed(2)}

---
Вес атлета: ${bodyWeight} кг
Сумма троеборья: $total кг
Коэффициент: ${coefficient.toStringAsFixed(4)}
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
            'Калькулятор Вилкса',
            style: TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 20),

          TextField(
            controller: _bodyWeightController,
            style: const TextStyle(color: Colors.white),
            keyboardType: TextInputType.number,
            decoration: _inputDecoration('Вес атлета (кг)'),
          ),
          const SizedBox(height: 15),

          TextField(
            controller: _squatController,
            style: const TextStyle(color: Colors.white),
            keyboardType: TextInputType.number,
            decoration: _inputDecoration('Присед (кг)'),
          ),
          const SizedBox(height: 15),

          TextField(
            controller: _benchController,
            style: const TextStyle(color: Colors.white),
            keyboardType: TextInputType.number,
            decoration: _inputDecoration('Жим лежа (кг)'),
          ),
          const SizedBox(height: 15),

          TextField(
            controller: _deadliftController,
            style: const TextStyle(color: Colors.white),
            keyboardType: TextInputType.number,
            decoration: _inputDecoration('Становая тяга (кг)'),
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