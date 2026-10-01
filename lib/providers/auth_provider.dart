import 'dart:convert';

import 'package:flutter/foundation.dart';

import '../services/auth_service.dart';
import '../services/secure_storage_service.dart';

class AuthProvider extends ChangeNotifier {
  final AuthService _authService;
  final SecureStorageService _storage;

  String? _token;
  String? _refreshToken;
  Map<String, dynamic>? _usuario;
  bool _cargando = false;

  AuthProvider({
    AuthService? authService,
    SecureStorageService? storage,
  })  : _authService =
            authService ?? AuthService(),
        _storage =
            storage ?? FlutterSecureStorageService();

  String? get token => _token;

  String? get refreshToken => _refreshToken;

  Map<String, dynamic>? get usuario => _usuario;

  bool get cargando => _cargando;

  bool get estaAutenticado {
    return _token != null &&
        _token!.isNotEmpty;
  }

  Future<bool> iniciarSesion({
    required String correo,
    required String password,
  }) async {
    _cargando = true;
    notifyListeners();

    try {
      final respuesta =
          await _authService.login(
        correo: correo,
        password: password,
      );

      if (respuesta['token'] != null) {
        _token =
            respuesta['token'].toString();

        _refreshToken =
            respuesta['refreshToken']
                ?.toString();

        _usuario =
            respuesta['usuario'];

        await _storage.write(
          key: 'token',
          value: _token!,
        );

        if (_refreshToken != null &&
            _refreshToken!.isNotEmpty) {
          await _storage.write(
            key: 'refreshToken',
            value: _refreshToken!,
          );
        }

        if (_usuario != null) {
          await _storage.write(
            key: 'usuario',
            value: jsonEncode(_usuario),
          );
        }

        return true;
      }

      return false;
    } catch (_) {
      return false;
    } finally {
      _cargando = false;
      notifyListeners();
    }
  }

  Future<void> cargarSesion() async {
    _token = await _storage.read(
      key: 'token',
    );

    _refreshToken =
        await _storage.read(
      key: 'refreshToken',
    );

    final usuarioGuardado =
        await _storage.read(
      key: 'usuario',
    );

    if (usuarioGuardado != null &&
        usuarioGuardado.isNotEmpty) {
      try {
        _usuario =
            Map<String, dynamic>.from(
          jsonDecode(usuarioGuardado),
        );
      } catch (_) {
        _usuario = null;
      }
    }

    notifyListeners();
  }

  Future<String?> renovarToken() async {
    if (_refreshToken == null ||
        _refreshToken!.isEmpty) {
      return null;
    }

    try {
      final respuesta =
          await _authService.refresh(
        refreshToken: _refreshToken!,
      );

      final nuevoToken =
          respuesta['token']?.toString();

      if (nuevoToken == null ||
          nuevoToken.isEmpty) {
        return null;
      }

      _token = nuevoToken;

      await _storage.write(
        key: 'token',
        value: _token!,
      );

      notifyListeners();

      return _token;
    } catch (_) {
      return null;
    }
  }

  Future<void> cerrarSesion() async {
    _token = null;
    _refreshToken = null;
    _usuario = null;

    await _storage.delete(
      key: 'token',
    );

    await _storage.delete(
      key: 'refreshToken',
    );

    await _storage.delete(
      key: 'usuario',
    );

    notifyListeners();
  }
}