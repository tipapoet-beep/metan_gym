class Membership {
  final int id;
  final String userPhone;
  final DateTime startDate;
  final DateTime expiryDate;
  final int months;
  final double price;
  final String? paymentId;

  Membership({
    required this.id,
    required this.userPhone,
    required this.startDate,
    required this.expiryDate,
    required this.months,
    required this.price,
    this.paymentId,
  });

  bool get isValid => expiryDate.isAfter(DateTime.now());

  int get daysLeft => expiryDate.difference(DateTime.now()).inDays;

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'user_phone': userPhone,
      'start_date': startDate.toIso8601String(),
      'expiry_date': expiryDate.toIso8601String(),
      'months': months,
      'price': price,
      'payment_id': paymentId,
    };
  }

  factory Membership.fromMap(Map<String, dynamic> map) {
    return Membership(
      id: map['id'],
      userPhone: map['user_phone'],
      startDate: DateTime.parse(map['start_date']),
      expiryDate: DateTime.parse(map['expiry_date']),
      months: map['months'],
      price: map['price'],
      paymentId: map['payment_id'],
    );
  }
}