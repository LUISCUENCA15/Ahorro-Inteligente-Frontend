import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:ahorro_inteligente_app/providers/auth_provider.dart';
import 'package:ahorro_inteligente_app/screens/movimientos/movimientos_screen.dart';
import 'package:ahorro_inteligente_app/services/movimiento_service.dart';

class FakeAuthProvider extends AuthProvider {
  @override
  String? get token => 'token-de-prueba';

  @override
  bool get estaAutenticado => true;
}

class FakeMovimientoService extends MovimientoService {
  final Future<List<dynamic>> Function(String token) cargar;

  FakeMovimientoService(this.cargar);

  @override
  Future<List<dynamic>> obtenerMovimientos(
    String token, {
    Future<String?> Function()? renovarToken,
  }) {
    return cargar(token);
  }
}

Widget crearAplicacion(
  MovimientoService servicio,
) {
  return MaterialApp(
    home: ChangeNotifierProvider<AuthProvider>.value(
      value: FakeAuthProvider(),
      child: MovimientosScreen(
        key: UniqueKey(),
        movimientoService: servicio,
      ),
    ),
  );
}

void main() {
  testWidgets(
    'La pantalla de movimientos gestiona cargando, datos, vacía y error',
    (WidgetTester tester) async {
      final cargando =
          Completer<List<dynamic>>();

      await tester.pumpWidget(
        crearAplicacion(
          FakeMovimientoService(
            (_) => cargando.future,
          ),
        ),
      );

      await tester.pump();

      // Estado 1: cargando.
      expect(
        find.byType(
          CircularProgressIndicator,
        ),
        findsOneWidget,
      );

      // Estado 2: con datos.
      cargando.complete([
        {
          'tipo': 'ingreso',
          'descripcion':
              'Prueba de movimientos',
          'monto': '100.00',
          'fecha': '2026-09-26',
        },
      ]);

      await tester.pumpAndSettle();

      expect(
        find.text(
          'Prueba de movimientos',
        ),
        findsOneWidget,
      );

      expect(
        find.text(
          '+ \$100.00',
        ),
        findsOneWidget,
      );

      // Estado 3: vacío.
      await tester.pumpWidget(
        crearAplicacion(
          FakeMovimientoService(
            (_) async => [],
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(
        find.text(
          'No existen movimientos registrados.',
        ),
        findsOneWidget,
      );

      // Estado 4: error.
      await tester.pumpWidget(
        crearAplicacion(
          FakeMovimientoService(
            (_) async {
              throw Exception(
                'Error de prueba',
              );
            },
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(
        find.text(
          'No se pudieron cargar los movimientos.',
        ),
        findsOneWidget,
      );
    },
  );
}