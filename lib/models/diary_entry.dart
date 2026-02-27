class DiaryEntry {
  final int id;
  final String userPhone;
  final DateTime date;
  final String content;

  DiaryEntry({
    required this.id,
    required this.userPhone,
    required this.date,
    required this.content,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'user_phone': userPhone,
      'date': date.toIso8601String(),
      'content': content,
    };
  }

  factory DiaryEntry.fromMap(Map<String, dynamic> map) {
    return DiaryEntry(
      id: map['id'],
      userPhone: map['user_phone'],
      date: DateTime.parse(map['date']),
      content: map['content'],
    );
  }
}