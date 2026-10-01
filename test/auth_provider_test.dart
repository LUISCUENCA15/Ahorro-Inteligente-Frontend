import 'package:flutter_test/flutter_test.dart';

import 'package:ahorro_inteligente_app/providers/auth_provider.dart';
import 'package:ahorro_inteligente_app/services/auth_service.dart';
import 'package:ahorro_inteligente_app/services/secure_storage_service.dart';

class FakeAuthService extends AuthService {
  @override
  Future<Map<String, dynamic>> login({
    required String correo,
    required String password,
  }) async {
    return {
      'token': 'token-de-prueba',
      'refreshToken': 'refresh-de-prueba',
      'usuario': {
        'id': 1,
        'nombre': 'Usuario Prueba',
        'correo': correo,
      },
    };
  }

  @override
  Future<Map<String, dynamic>> refresh({
    required String refreshToken,
  }) async {
    return {
      'token': 'token-renovado',
    };
  }
}

class MemorySecureStorage
    implements SecureStorageService {
  final Map<String, String> _data = {};

  @override
  Future<void> write({
    required String key,
    required String value,
  }) async {
    _data[key] = value;
  }

  @override
  Future<String?> read({
    required String key,
  }) async {
    return _data[key];
  }

  @override
  Future<void> delete({
    required String key,
  }) async {
    _data.remove(key);
  }
}

void main() {
  test(
    'La sesión se persiste, se recupera y se elimina al cerrar sesión',
    () async {
      final storage =
          MemorySecureStorage();

      final proveedor1 = AuthProvider(
        authService: FakeAuthService(),
        storage: storage,
      );

      final inicioExitoso =
          await proveedor1.iniciarSesion(
        correo: 'prueba@correo.com',
        password: '123456',
      );

      expect(
        inicioExitoso,
        true,
      );

      expect(
        proveedor1.estaAutenticado,
        true,
      );

      expect(
        proveedor1.token,
        'token-de-prueba',
      );

      final proveedor2 = AuthProvider(
        authService: FakeAuthService(),
        storage: storage,
      );

      await proveedor2.cargarSesion();

      expect(
        proveedor2.estaAutenticado,
        true,
      );

      expect(
        proveedor2.token,
        'token-de-prueba',
      );

      expect(
        proveedor2.usuario?['nombre'],
        'Usuario Prueba',
      );

      await proveedor2.cerrarSesion();

      expect(
        proveedor2.estaAutenticado,
        false,
      );

      expect(
        await storage.read(key: 'token'),
        isNull,
      );

      expect(
        await storage.read(
          key: 'refreshToken',
        ),
        isNull,
      );

      expect(
        await storage.read(
          key: 'usuario',
        ),
        isNull,
      );
    },
  );
}