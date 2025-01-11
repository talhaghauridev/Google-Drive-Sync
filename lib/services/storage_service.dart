import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class StorageService {
  final _storage = FlutterSecureStorage();

  Future<bool> getSignInStatus() async {
    final data = await _storage.read(key: "userData");
    print("data: $data");
    if (data != null) {
      return true;
    }
    return false;
  }

  Future<void> saveUserData(Map<String, String?> userData) async {
    await _storage.write(key: "userData", value: json.encode(userData));
  }

  Future<Map<String, dynamic>?> getUserData() async {
    final data = await _storage.read(key: "userData");
    print("getData: $data");
    if (data != null) {
      return json.decode(data);
    }
    return null;
  }

  Future<void> clearStorage() async {
    await _storage.deleteAll();
  }
}
