class Promotion {
  final int id;
  final String title;
  final String description;
  final DateTime startDate;
  final DateTime? endDate;
  final bool isActive;

  Promotion({
    required this.id,
    required this.title,
    required this.description,
    required this.startDate,
    this.endDate,
    required this.isActive,
  });

  factory Promotion.fromMap(Map<String, dynamic> map) {
    return Promotion(
      id: map['id'] as int,
      title: map['title'] as String,
      description: map['description'] as String,
      startDate: DateTime.parse(map['start_date'] as String),
      endDate: map['end_date'] != null ? DateTime.parse(map['end_date'] as String) : null,
      isActive: (map['is_active'] as int) == 1,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'start_date': startDate.toIso8601String(),
      'end_date': endDate?.toIso8601String(),
      'is_active': isActive ? 1 : 0,
    };
  }
}