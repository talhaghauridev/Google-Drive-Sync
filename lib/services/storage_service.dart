import 'dart:convert';
import 'package:file_upload_app/constants/constants.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class StorageService {
  final _storage = FlutterSecureStorage();

  Future<bool> getSignInStatus() async {
    final data = await _storage.read(key: AppConstants.userStorageKey);
    if (data != null) {
      return true;
    }
    return false;
  }

  Future<void> saveUserData(Map<String, String?> userData) async {
    await _storage.write(
        key: AppConstants.userStorageKey, value: json.encode(userData));
  }

  Future<Map<String, dynamic>?> getUserData() async {
    final data = await _storage.read(key: AppConstants.userStorageKey);
    if (data != null) {
      return json.decode(data);
    }
    return null;
  }

  Future<void> clearStorage() async {
    await _storage.deleteAll();
  }
}
