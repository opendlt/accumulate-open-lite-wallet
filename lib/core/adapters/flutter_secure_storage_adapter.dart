// Flutter adapter for secure storage - bridges core interface with Flutter implementation
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../services/storage/secure_storage_interface.dart';

class FlutterSecureStorageAdapter implements SecureStorageInterface {
  final FlutterSecureStorage _storage;

  const FlutterSecureStorageAdapter(this._storage);

  @override
  Future<String?> read(String key) async {
    return await _storage.read(key: key);
  }

  @override
  Future<void> write(String key, String value) async {
    await _storage.write(key: key, value: value);
  }

  @override
  Future<void> delete(String key) async {
    await _storage.delete(key: key);
  }

  @override
  Future<void> deleteAll() async {
    await _storage.deleteAll();
  }

  @override
  Future<Map<String, String>> readAll() async {
    return await _storage.readAll();
  }
}
