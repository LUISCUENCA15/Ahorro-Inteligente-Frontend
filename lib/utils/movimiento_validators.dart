class MovimientoValidators {
  static String? descripcion(String? valor) {
    if (valor == null || valor.trim().isEmpty) {
      return 'Ingrese una descripción';
    }

    return null;
  }

  static String? monto(String? valor) {
    if (valor == null || valor.trim().isEmpty) {
      return 'Ingrese un monto';
    }

    final monto = double.tryParse(valor.trim());

    if (monto == null || monto <= 0) {
      return 'Ingrese un monto válido mayor que 0';
    }

    return null;
  }
}