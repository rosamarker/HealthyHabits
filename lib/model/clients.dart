// lib/model/clients.dart
import 'dart:convert';

/// Exercise model
class Exercise {
  final String exerciseId;
  final String name;
  final String description;

  /// Repetition-based
  final int sets;
  final int reps;

  /// Time-based (seconds)
  final int time;

  /// true = repetition-based, false = time-based
  final bool isCountable;

  const Exercise({
    required this.exerciseId,
    required this.name,
    required this.description,
    required this.sets,
    required this.reps,
    required this.time,
    required this.isCountable,
  });

  Exercise copyWith({
    String? exerciseId,
    String? name,
    String? description,
    int? sets,
    int? reps,
    int? time,
    bool? isCountable,
  }) {
    return Exercise(
      exerciseId: exerciseId ?? this.exerciseId,
      name: name ?? this.name,
      description: description ?? this.description,
      sets: sets ?? this.sets,
      reps: reps ?? this.reps,
      time: time ?? this.time,
      isCountable: isCountable ?? this.isCountable,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'exerciseId': exerciseId,
      'name': name,
      'description': description,
      'sets': sets,
      'reps': reps,
      'time': time,
      'isCountable': isCountable,
    };
  }

  factory Exercise.fromMap(Map<String, dynamic> map) {
    return Exercise(
      exerciseId: map['exerciseId'] as String,
      name: map['name'] as String,
      description: (map['description'] ?? '') as String,
      sets: (map['sets'] ?? 0) as int,
      reps: (map['reps'] ?? 0) as int,
      time: (map['time'] ?? 0) as int,
      isCountable: (map['isCountable'] ?? true) as bool,
    );
  }

  String toJson() => jsonEncode(toMap());

  factory Exercise.fromJson(String source) =>
      Exercise.fromMap(jsonDecode(source) as Map<String, dynamic>);
}

/// Client model
class Client {
  final String clientId;
  final String name;
  final int age;
  final String gender;

  /// 0 = green, 1 = yellow, 2 = red
  final int active;

  /// stored as UNIX timestamp seconds (based on your CreateClientViewModel)
  final int nextAppointment;

  final String motivation;

  final List<Exercise> exercises;

  // Movesense association (persisted on the Client)
  final String? movesenseDeviceId;
  final String? movesenseDeviceName;

  const Client({
    required this.clientId,
    required this.name,
    required this.age,
    required this.gender,
    required this.active,
    required this.nextAppointment,
    required this.motivation,
    required this.exercises,
    this.movesenseDeviceId,
    this.movesenseDeviceName,
  });

  Client copyWith({
    String? clientId,
    String? name,
    int? age,
    String? gender,
    int? active,
    int? nextAppointment,
    String? motivation,
    List<Exercise>? exercises,
    String? movesenseDeviceId,
    String? movesenseDeviceName,
  }) {
    return Client(
      clientId: clientId ?? this.clientId,
      name: name ?? this.name,
      age: age ?? this.age,
      gender: gender ?? this.gender,
      active: active ?? this.active,
      nextAppointment: nextAppointment ?? this.nextAppointment,
      motivation: motivation ?? this.motivation,
      exercises: exercises ?? this.exercises,
      movesenseDeviceId: movesenseDeviceId ?? this.movesenseDeviceId,
      movesenseDeviceName: movesenseDeviceName ?? this.movesenseDeviceName,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'clientId': clientId,
      'name': name,
      'age': age,
      'gender': gender,
      'active': active,
      'nextAppointment': nextAppointment,
      'motivation': motivation,
      'exercises': exercises.map((e) => e.toMap()).toList(),
      'movesenseDeviceId': movesenseDeviceId,
      'movesenseDeviceName': movesenseDeviceName,
    };
  }

  factory Client.fromMap(Map<String, dynamic> map) {
    return Client(
      clientId: map['clientId'] as String,
      name: map['name'] as String,
      age: (map['age'] ?? 0) as int,
      gender: (map['gender'] ?? 'Male') as String,
      active: (map['active'] ?? 0) as int,
      nextAppointment: (map['nextAppointment'] ?? 0) as int,
      motivation: (map['motivation'] ?? '') as String,
      exercises: ((map['exercises'] ?? []) as List<dynamic>)
          .map((e) => Exercise.fromMap(e as Map<String, dynamic>))
          .toList(),
      movesenseDeviceId: map['movesenseDeviceId'] as String?,
      movesenseDeviceName: map['movesenseDeviceName'] as String?,
    );
  }

  String toJson() => jsonEncode(toMap());

  factory Client.fromJson(String source) =>
      Client.fromMap(jsonDecode(source) as Map<String, dynamic>);
}