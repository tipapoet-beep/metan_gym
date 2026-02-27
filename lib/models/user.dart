class User {
  final String phone;
  final String name;
  final DateTime registrationDate;

  User({
    required this.phone,
    required this.name,
    required this.registrationDate,
  });

  Map<String, dynamic> toMap() {
    return {
      'phone': phone,
      'name': name,
      'registration_date': registrationDate.toIso8601String(),
    };
  }

  factory User.fromMap(Map<String, dynamic> map) {
    return User(
      phone: map['phone'],
      name: map['name'],
      registrationDate: DateTime.parse(map['registration_date']),
    );
  }
}