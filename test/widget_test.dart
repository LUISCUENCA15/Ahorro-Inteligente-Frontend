import 'package:flutter_test/flutter_test.dart';

import 'package:ahorro_inteligente_app/utils/movimiento_validators.dart';

void main() {
  test(
    'Los validadores de movimientos rechazan datos inválidos',
    () {
      expect(
        MovimientoValidators.descripcion(''),
        'Ingrese una descripción',
      );

      expect(
        MovimientoValidators.descripcion('   '),
        'Ingrese una descripción',
      );

      expect(
        MovimientoValidators.descripcion('Almuerzo'),
        isNull,
      );

      expect(
        MovimientoValidators.monto(''),
        'Ingrese un monto',
      );

      expect(
        MovimientoValidators.monto('abc'),
        'Ingrese un monto válido mayor que 0',
      );

      expect(
        MovimientoValidators.monto('0'),
        'Ingrese un monto válido mayor que 0',
      );

      expect(
        MovimientoValidators.monto('-10'),
        'Ingrese un monto válido mayor que 0',
      );

      expect(
        MovimientoValidators.monto('20.50'),
        isNull,
      );
    },
  );
}