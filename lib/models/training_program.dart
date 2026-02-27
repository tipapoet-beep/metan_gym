class TrainingProgram {
  final int id;
  final String userPhone;
  final String name;
  final List<WorkoutDay> days;
  final DateTime createdAt;
  final DateTime? updatedAt;

  TrainingProgram({
    required this.id,
    required this.userPhone,
    required this.name,
    required this.days,
    required this.createdAt,
    this.updatedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'user_phone': userPhone,
      'name': name,
      'days': days.map((d) => d.toMap()).toList(),
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }

  factory TrainingProgram.fromMap(Map<String, dynamic> map) {
    return TrainingProgram(
      id: map['id'],
      userPhone: map['user_phone'],
      name: map['name'],
      days: (map['days'] as List).map((d) => WorkoutDay.fromMap(d)).toList(),
      createdAt: DateTime.parse(map['created_at']),
      updatedAt: map['updated_at'] != null ? DateTime.parse(map['updated_at']) : null,
    );
  }
}

class WorkoutDay {
  final String name;
  final List<Exercise> exercises;

  WorkoutDay({
    required this.name,
    required this.exercises,
  });

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'exercises': exercises.map((e) => e.toMap()).toList(),
    };
  }

  factory WorkoutDay.fromMap(Map<String, dynamic> map) {
    return WorkoutDay(
      name: map['name'],
      exercises: (map['exercises'] as List).map((e) => Exercise.fromMap(e)).toList(),
    );
  }
}

class Exercise {
  final String name;
  final String sets;
  final String reps;
  final String? notes;

  Exercise({
    required this.name,
    required this.sets,
    required this.reps,
    this.notes,
  });

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'sets': sets,
      'reps': reps,
      'notes': notes,
    };
  }

  factory Exercise.fromMap(Map<String, dynamic> map) {
    return Exercise(
      name: map['name'],
      sets: map['sets'],
      reps: map['reps'],
      notes: map['notes'],
    );
  }
}