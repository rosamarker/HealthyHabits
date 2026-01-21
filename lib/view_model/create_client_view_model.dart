// lib/view_model/create_client_view_model.dart
import 'dart:math';
import 'package:flutter/material.dart';

import '../model/clients.dart';

class CreateClientViewModel extends ChangeNotifier {
  final TextEditingController nameController = TextEditingController();
  final TextEditingController ageController = TextEditingController();
  final TextEditingController motivationController = TextEditingController();

  String gender = 'Male';
  int active = 0;

  DateTime? nextAppointment;

  final List<Exercise> exercises = [];

  String? movesenseDeviceId;
  String? movesenseDeviceName;

  CreateClientViewModel({Client? initialClient}) {
    if (initialClient != null) {
      nameController.text = initialClient.name;
      ageController.text = initialClient.age.toString();
      motivationController.text = initialClient.motivation;
      gender = initialClient.gender;
      active = initialClient.active;

      if (initialClient.nextAppointment > 0) {
        nextAppointment =
            DateTime.fromMillisecondsSinceEpoch(initialClient.nextAppointment * 1000);
      }

      exercises.clear();
      exercises.addAll(initialClient.exercises);

      movesenseDeviceId = initialClient.movesenseDeviceId;
      movesenseDeviceName = initialClient.movesenseDeviceName;
    }
  }

  void setGender(String value) {
    gender = value;
    notifyListeners();
  }

  void setActive(int value) {
    active = value;
    notifyListeners();
  }

  void setNextAppointment(DateTime? value) {
    nextAppointment = value;
    notifyListeners();
  }

  void setMovesenseLink({String? deviceId, String? deviceName}) {
    movesenseDeviceId = deviceId;
    movesenseDeviceName = deviceName;
    notifyListeners();
  }

  void addExercise(Exercise exercise) {
    exercises.add(exercise);
    notifyListeners();
  }

  void removeExercise(String exerciseId) {
    exercises.removeWhere((e) => e.exerciseId == exerciseId);
    notifyListeners();
  }

  Client buildClient({String? existingClientId}) {
    final id = existingClientId ?? _randomId();

    final age = int.tryParse(ageController.text.trim()) ?? 0;

    final nextApptSeconds = nextAppointment == null
        ? 0
        : (nextAppointment!.millisecondsSinceEpoch / 1000).round();

    return Client(
      clientId: id,
      name: nameController.text.trim().isEmpty ? 'Unnamed' : nameController.text.trim(),
      age: age,
      gender: gender,
      active: active,
      nextAppointment: nextApptSeconds,
      motivation: motivationController.text.trim(),
      exercises: List.of(exercises),
      movesenseDeviceId: movesenseDeviceId,
      movesenseDeviceName: movesenseDeviceName,
    );
  }

  String _randomId() {
    final rng = Random();
    final ts = DateTime.now().millisecondsSinceEpoch.toString();
    final r = rng.nextInt(999999).toString().padLeft(6, '0');
    return '$ts$r';
  }

  @override
  void dispose() {
    nameController.dispose();
    ageController.dispose();
    motivationController.dispose();
    super.dispose();
  }
}