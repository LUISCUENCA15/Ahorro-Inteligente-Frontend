import 'dart:convert';

import 'package:http/http.dart' as http;

import '../config/api_config.dart';

class ApiException implements Exception {
  final int statusCode;
  final String message;

  const ApiException({
    required this.statusCode,
    required this.message,
  });

  @override
  String toString() {
    return 'ApiException($statusCode): $message';
  }
}

class MovimientoService {
  final http.Client client;
  final Duration timeout;

  MovimientoService({
    http.Client? client,
    this.timeout = const Duration(seconds: 10),
  }) : client = client ?? http.Client();

  Future<List<dynamic>> obtenerMovimientos(
    String token, {
    Future<String?> Function()? renovarToken,
  }) async {
    var tokenActual = token;

    var response = await _obtener(
      tokenActual,
    );

    // Si el token expiró, se intenta renovar una sola vez.
    if (response.statusCode == 401 &&
        renovarToken != null) {
      final nuevoToken = await renovarToken();

      if (nuevoToken != null &&
          nuevoToken.isNotEmpty) {
        tokenActual = nuevoToken;

        response = await _obtener(
          tokenActual,
        );
      }
    }

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    }

    if (response.statusCode == 401) {
      throw const ApiException(
        statusCode: 401,
        message: 'Sesión no autorizada.',
      );
    }

    if (response.statusCode == 422) {
      throw const ApiException(
        statusCode: 422,
        message: 'Datos no válidos.',
      );
    }

    throw ApiException(
      statusCode: response.statusCode,
      message: 'Error en la API.',
    );
  }

  Future<http.Response> _obtener(
    String token,
  ) {
    return client
        .get(
          Uri.parse(
            '${ApiConfig.baseUrl}/movimientos',
          ),
          headers: {
            'Authorization': 'Bearer $token',
            'Content-Type': 'application/json',
          },
        )
        .timeout(timeout);
  }

  Future<bool> registrarMovimiento({
    required String token,
    required String tipo,
    required String descripcion,
    required String monto,
    required String fecha,
  }) async {
    final response = await client
        .post(
          Uri.parse(
            '${ApiConfig.baseUrl}/movimientos',
          ),
          headers: {
            'Authorization': 'Bearer $token',
            'Content-Type': 'application/json',
          },
          body: jsonEncode({
            'tipo': tipo,
            'descripcion': descripcion,
            'monto': monto,
            'fecha': fecha,
          }),
        )
        .timeout(timeout);

    return response.statusCode == 201;
  }
}