import 'package:shared_preferences/shared_preferences.dart';

/// Persistencia simple del JWT del backend + datos basicos del paciente.
/// En produccion: usar `flutter_secure_storage` para tokens.
class TokenStorage {
  static const _kToken = 'auth_token';
  static const _kPatientId = 'patient_id';
  static const _kPatientEmail = 'patient_email';
  static const _kPatientName = 'patient_name';

  Future<void> save({
    required String token,
    required String patientId,
    required String email,
    required String fullName,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kToken, token);
    await prefs.setString(_kPatientId, patientId);
    await prefs.setString(_kPatientEmail, email);
    await prefs.setString(_kPatientName, fullName);
  }

  Future<String?> token() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_kToken);
  }

  Future<({String id, String email, String fullName})?> patient() async {
    final prefs = await SharedPreferences.getInstance();
    final id = prefs.getString(_kPatientId);
    final email = prefs.getString(_kPatientEmail);
    final name = prefs.getString(_kPatientName);
    if (id == null || email == null || name == null) return null;
    return (id: id, email: email, fullName: name);
  }

  Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_kToken);
    await prefs.remove(_kPatientId);
    await prefs.remove(_kPatientEmail);
    await prefs.remove(_kPatientName);
  }
}
