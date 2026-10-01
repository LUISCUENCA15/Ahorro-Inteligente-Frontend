import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:provider/provider.dart';

import 'package:ahorro_inteligente_app/main.dart';
import 'package:ahorro_inteligente_app/providers/auth_provider.dart';

const String testEmail =
    String.fromEnvironment('TEST_EMAIL');

const String testPassword =
    String.fromEnvironment('TEST_PASSWORD');

Future<void> esperarWidget(
  WidgetTester tester,
  Finder finder, {
  Duration timeout =
      const Duration(seconds: 30),
}) async {
  final limite =
      DateTime.now().add(timeout);

  while (DateTime.now().isBefore(limite)) {
    if (finder.evaluate().isNotEmpty) {
      return;
    }

    await tester.pump(
      const Duration(milliseconds: 300),
    );
  }

  throw TestFailure(
    'No apareció el elemento esperado: $finder',
  );
}

void main() {
  IntegrationTestWidgetsFlutterBinding
      .ensureInitialized();

  testWidgets(
    'Flujo crítico: login, registrar y consultar movimiento',
    (WidgetTester tester) async {
      if (testEmail.isEmpty ||
          testPassword.isEmpty) {
        throw TestFailure(
          'Faltan TEST_EMAIL y TEST_PASSWORD. '
          'Ejecute la prueba usando --dart-define.',
        );
      }

      await tester.pumpWidget(
        ChangeNotifierProvider(
          create: (_) => AuthProvider(),
          child: const AhorroInteligenteApp(),
        ),
      );

      await tester.pumpAndSettle();

      // 1. Inicio de sesión.
      final camposLogin =
          find.byType(TextFormField);

      expect(
        camposLogin,
        findsNWidgets(2),
      );

      await tester.enterText(
        camposLogin.at(0),
        testEmail,
      );

      await tester.enterText(
        camposLogin.at(1),
        testPassword,
      );

      await tester.tap(
        find.text('Ingresar'),
      );

      // Esperar a que la aplicación entre a Home.
      await esperarWidget(
        tester,
        find.textContaining('Bienvenido,'),
      );

      // 2. Abrir el formulario de registro.
      await tester.tap(
        find.text('Registrar ingreso'),
      );

      await tester.pumpAndSettle();

      final descripcion =
          'Prueba E2E ${DateTime.now().millisecondsSinceEpoch}';

      final camposMovimiento =
          find.byType(TextFormField);

      expect(
        camposMovimiento,
        findsNWidgets(2),
      );

      await tester.enterText(
        camposMovimiento.at(0),
        descripcion,
      );

      await tester.enterText(
        camposMovimiento.at(1),
        '1.00',
      );

      // 3. Registrar el movimiento en el backend real.
      await tester.tap(
        find.text('Guardar movimiento'),
      );

      // Esperar el regreso a Home.
      await esperarWidget(
        tester,
        find.text('Saldo actual'),
      );

      // 4. Consultar los movimientos.
      await tester.tap(
        find.text('Ver movimientos'),
      );

      await esperarWidget(
        tester,
        find.text(descripcion),
      );

      // 5. Verificar que el movimiento llegó
      //    al backend y volvió a la aplicación.
      expect(
        find.text(descripcion),
        findsOneWidget,
      );

      // Volver a Home para finalizar limpiamente.
    },
  );
}