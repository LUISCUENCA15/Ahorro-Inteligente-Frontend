import 'dart:async';
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import 'package:ahorro_inteligente_app/services/movimiento_service.dart';

void main() {
  test(
    'El cliente HTTP gestiona 200, 401 con renovación, 422 y timeout',
    () async {
      // Caso 1: 200
      final client200 = MockClient((request) async {
        return http.Response(
          jsonEncode([
            {
              'tipo': 'ingreso',
              'descripcion': 'Ingreso de prueba',
              'monto': '100.00',
              'fecha': '2026-09-26',
            },
          ]),
          200,
        );
      });

      final service200 = MovimientoService(
        client: client200,
      );

      final resultado200 =
          await service200.obtenerMovimientos(
        'token-valido',
      );

      expect(resultado200.length, 1);
      expect(
        resultado200.first['descripcion'],
        'Ingreso de prueba',
      );

      // Caso 2: 401 -> renovación -> 200
      var cantidadSolicitudes = 0;
      String? ultimoToken;

      final client401 = MockClient((request) async {
        cantidadSolicitudes++;

        ultimoToken =
            request.headers['authorization'];

        if (cantidadSolicitudes == 1) {
          return http.Response(
            jsonEncode({
              'error': 'Token inválido o expirado.',
            }),
            401,
          );
        }

        return http.Response(
          jsonEncode([
            {
              'tipo': 'gasto',
              'descripcion': 'Compra renovada',
              'monto': '20.00',
              'fecha': '2026-09-26',
            },
          ]),
          200,
        );
      });

      var renovaciones = 0;

      final service401 = MovimientoService(
        client: client401,
      );

      final resultado401 =
          await service401.obtenerMovimientos(
        'token-expirado',
        renovarToken: () async {
          renovaciones++;
          return 'token-nuevo';
        },
      );

      expect(cantidadSolicitudes, 2);
      expect(renovaciones, 1);
      expect(ultimoToken, 'Bearer token-nuevo');
      expect(
        resultado401.first['descripcion'],
        'Compra renovada',
      );

      // Caso 3: 401 -> renovación sin token -> 401 final
      final client401SinRenovacion =
          MockClient((request) async {
        return http.Response(
          jsonEncode({
            'error': 'Token inválido o expirado.',
          }),
          401,
        );
      });

      final service401SinRenovacion =
          MovimientoService(
        client: client401SinRenovacion,
      );

      await expectLater(
        service401SinRenovacion.obtenerMovimientos(
          'token-expirado',
          renovarToken: () async {
            return null;
          },
        ),
        throwsA(
          isA<ApiException>().having(
            (error) => error.statusCode,
            'statusCode',
            401,
          ),
        ),
      );

      // Caso 4: 422
      final client422 = MockClient((request) async {
        return http.Response(
          jsonEncode({
            'error': 'Datos no válidos',
          }),
          422,
        );
      });

      final service422 = MovimientoService(
        client: client422,
      );

      await expectLater(
        service422.obtenerMovimientos(
          'token-valido',
        ),
        throwsA(
          isA<ApiException>().having(
            (error) => error.statusCode,
            'statusCode',
            422,
          ),
        ),
      );

      // Caso 5: timeout
      final clientTimeout =
          MockClient((request) async {
        await Future.delayed(
          const Duration(seconds: 1),
        );

        return http.Response(
          jsonEncode([]),
          200,
        );
      });

      final serviceTimeout = MovimientoService(
        client: clientTimeout,
        timeout: const Duration(
          milliseconds: 50,
        ),
      );

      await expectLater(
        serviceTimeout.obtenerMovimientos(
          'token-valido',
        ),
        throwsA(isA<TimeoutException>()),
      );
    },
  );
}