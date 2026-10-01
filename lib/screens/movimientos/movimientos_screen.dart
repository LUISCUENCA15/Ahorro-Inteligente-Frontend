import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/auth_provider.dart';
import '../../services/movimiento_service.dart';

class MovimientosScreen extends StatefulWidget {
  final MovimientoService? movimientoService;

  const MovimientosScreen({
    super.key,
    this.movimientoService,
  });

  @override
  State<MovimientosScreen> createState() =>
      _MovimientosScreenState();
}

class _MovimientosScreenState extends State<MovimientosScreen> {
  late final MovimientoService movimientoService;

  List<dynamic> movimientos = [];
  bool cargando = true;
  String? error;

  @override
  void initState() {
    super.initState();

    movimientoService =
        widget.movimientoService ??
        MovimientoService();

    cargarMovimientos();
  }

  Future<void> cargarMovimientos() async {
    final authProvider = Provider.of<AuthProvider>(
      context,
      listen: false,
    );

    if (!authProvider.estaAutenticado) {
      if (!mounted) return;

      setState(() {
        cargando = false;
        error = 'Sesión no válida.';
      });
      return;
    }

    try {
      final resultado =
          await movimientoService.obtenerMovimientos(
        authProvider.token!,
        renovarToken: authProvider.renovarToken,
      );

      if (!mounted) return;

      setState(() {
        movimientos = resultado;
        cargando = false;
        error = null;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        cargando = false;
        error =
            'No se pudieron cargar los movimientos.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Mis movimientos',
        ),
      ),
      body: RefreshIndicator(
        onRefresh: cargarMovimientos,
        child: cargarContenido(),
      ),
    );
  }

  Widget cargarContenido() {
    if (cargando) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (error != null) {
      return ListView(
        children: [
          const SizedBox(height: 150),
          Center(
            child: Text(error!),
          ),
        ],
      );
    }

    if (movimientos.isEmpty) {
      return ListView(
        children: const [
          SizedBox(height: 150),
          Center(
            child: Text(
              'No existen movimientos registrados.',
            ),
          ),
        ],
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: movimientos.length,
      itemBuilder: (context, index) {
        final movimiento = movimientos[index];

        final tipo =
            movimiento['tipo'] ?? '';

        final descripcion =
            movimiento['descripcion'] ?? '';

        final monto =
            movimiento['monto'] ?? '0.00';

        final fecha =
            movimiento['fecha'] ?? '';

        final esIngreso =
            tipo == 'ingreso';

        return Card(
          margin: const EdgeInsets.only(
            bottom: 12,
          ),
          child: ListTile(
            leading: CircleAvatar(
              child: Icon(
                esIngreso
                    ? Icons.arrow_downward
                    : Icons.arrow_upward,
              ),
            ),
            title: Text(
              descripcion,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
              ),
            ),
            subtitle: Text(
              '$tipo • $fecha',
            ),
            trailing: Text(
              '${esIngreso ? '+' : '-'} \$$monto',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: esIngreso
                    ? Colors.green
                    : Colors.red,
              ),
            ),
          ),
        );
      },
    );
  }
}