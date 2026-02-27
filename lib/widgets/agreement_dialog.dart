import 'package:flutter/material.dart';

class AgreementDialog extends StatelessWidget {
  final Function(bool) onAgreementChanged;
  final bool isAgreed;

  const AgreementDialog({
    super.key,
    required this.onAgreementChanged,
    required this.isAgreed,
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: Colors.grey[900],
      title: const Text(
        'Согласие на обработку персональных данных',
        style: TextStyle(color: Colors.white, fontSize: 18),
      ),
      content: SizedBox(
        width: double.maxFinite,
        height: 300,
        child: const SingleChildScrollView(
          child: Column(
            children: [
              Text(
                'Настоящим я, являясь Пользователем мобильного приложения METAH GYM, даю свое согласие на обработку моих персональных данных в соответствии с Федеральным законом от 27.07.2006 № 152-ФЗ «О персональных данных».\n\n'
                'Персональные данные, на обработку которых дается согласие:\n'
                '• Фамилия, имя, отчество\n'
                '• Номер телефона\n'
                '• Дата рождения\n'
                '• Адрес электронной почты\n\n'
                'Цели обработки персональных данных:\n'
                '• Идентификация пользователя\n'
                '• Оформление и обслуживание абонемента\n'
                '• Направление уведомлений о статусе абонемента\n'
                '• Проведение маркетинговых акций и опросов\n\n'
                'Согласие действует до момента его отзыва. Я уведомлен о своем праве отозвать согласие путем направления письменного заявления.\n\n'
                'METAH GYM гарантирует конфиденциальность и защиту персональных данных.',
                style: TextStyle(color: Colors.grey, fontSize: 12),
              ),
            ],
          ),
        ),
      ),
      actions: [
        Row(
          children: [
            Checkbox(
              value: isAgreed,
              onChanged: (value) => onAgreementChanged(value ?? false),
              checkColor: Colors.black,
              activeColor: Colors.white,
            ),
            const Expanded(
              child: Text(
                'Я принимаю условия обработки персональных данных',
                style: TextStyle(color: Colors.white, fontSize: 12),
              ),
            ),
          ],
        ),
        TextButton(
          onPressed: isAgreed ? () => Navigator.of(context).pop(true) : null,
          style: TextButton.styleFrom(
            foregroundColor: isAgreed ? Colors.white : Colors.grey,
          ),
          child: const Text('Продолжить'),
        ),
      ],
    );
  }
}