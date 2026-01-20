// lib/view_model/create_client_view_model.dart
import '../model/clients.dart';

class CreateClientViewModel {
  String name = '';
  int? age;
  String gender = 'Male';
  int active = 0; // 0 = green, 1 = yellow, 2 = red
  DateTime? nextAppointment;
  String motivation = '';

  /// Exercises added while creating client
  final List<Exercise> exercises = [];

  // Movesense association captured during client creation
  String? movesenseDeviceId;
  String? movesenseDeviceName;

  String? validateName() {
    if (name.isEmpty) return 'Enter a name';
    return null;
  }

  String? validateAge() {
    if (age == null || age! <= 0) return 'Enter a valid age';
    return null;
  }

  String? validateNextAppointment() {
    if (nextAppointment == null) return 'Pick a next appointment';
    return null;
  }

  bool validateAll() {
    return validateName() == null &&
        validateAge() == null &&
        validateNextAppointment() == null;
  }

  Client createClient() {
    if (!validateAll()) {
      throw Exception('Cannot create client: invalid data');
    }

    return Client(
      clientId: DateTime.now().millisecondsSinceEpoch.toString(),
      name: name,
      age: age!,
      gender: gender,
      active: active,
      nextAppointment: nextAppointment!.millisecondsSinceEpoch ~/ 1000,
      motivation: motivation,
      exercises: List.unmodifiable(exercises),
      movesenseDeviceId: movesenseDeviceId,
      movesenseDeviceName: movesenseDeviceName,
    );
  }
}