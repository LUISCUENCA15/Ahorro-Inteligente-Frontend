import 'package:flutter_secure_storage/flutter_secure_storage.dart';

abstract class SecureStorageService {
  Future<void> write({
    required String key,
    required String value,
  });

  Future<String?> read({
    required String key,
  });

  Future<void> delete({
    required String key,
  });
}

class FlutterSecureStorageService
    implements SecureStorageService {
  final FlutterSecureStorage _storage;

  FlutterSecureStorageService({
    FlutterSecureStorage? storage,
  }) : _storage =
            storage ?? const FlutterSecureStorage();

  @override
  Future<void> write({
    required String key,
    required String value,
  }) {
    return _storage.write(
      key: key,
      value: value,
    );
  }

  @override
  Future<String?> read({
    required String key,
  }) {
    return _storage.read(
      key: key,
    );
  }

  @override
  Future<void> delete({
    required String key,
  }) {
    return _storage.delete(
      key: key,
    );
  }
}