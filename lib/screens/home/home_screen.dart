import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/auth_provider.dart';
import '../../services/movimiento_service.dart';
import '../login/login_screen.dart';
import '../movimientos/movimientos_screen.dart';
import '../movimientos/registrar_movimiento_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final MovimientoService movimientoService = MovimientoService();

  double saldoActual = 0.0;
  bool cargandoSaldo = true;

  @override
  void initState() {
    super.initState();
    cargarSaldo();
  }

  Future<void> cargarSaldo() async {
    final authProvider = Provider.of<AuthProvider>(
      context,
      listen: false,
    );

    if (!authProvider.estaAutenticado ||
        authProvider.token == null) {
      setState(() {
        saldoActual = 0.0;
        cargandoSaldo = false;
      });
      return;
    }

    try {
      final movimientos =
          await movimientoService.obtenerMovimientos(
        authProvider.token!,
        renovarToken: authProvider.renovarToken,
      );

      double saldo = 0.0;

      for (final movimiento in movimientos) {
        final tipo = movimiento['tipo']?.toString() ?? '';
        final montoTexto =
            movimiento['monto']?.toString() ?? '0';

        final monto =
            double.tryParse(montoTexto) ?? 0.0;

        if (tipo == 'ingreso') {
          saldo += monto;
        } else if (tipo == 'gasto') {
          saldo -= monto;
        }
      }

      if (!mounted) return;

      setState(() {
        saldoActual = saldo;
        cargandoSaldo = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        cargandoSaldo = false;
      });
    }
  }

  Future<void> cerrarSesion(BuildContext context) async {
    final authProvider = Provider.of<AuthProvider>(
      context,
      listen: false,
    );

    await authProvider.cerrarSesion();

    if (!context.mounted) return;

    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(
        builder: (_) => const LoginScreen(),
      ),
      (route) => false,
    );
  }

  Future<void> abrirRegistrarMovimiento(
    BuildContext context,
  ) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) =>
            const RegistrarMovimientoScreen(),
      ),
    );

    // Actualizar el saldo al regresar
    await cargarSaldo();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, authProvider, child) {
        if (!authProvider.estaAutenticado) {
          return const LoginScreen();
        }

        final usuario = authProvider.usuario;
        final nombreUsuario =
            usuario?['nombre'] ?? 'Usuario';

        return Scaffold(
          appBar: AppBar(
            title: const Text(
              'Ahorro Inteligente',
            ),
            centerTitle: true,
            automaticallyImplyLeading: false,
            actions: [
              IconButton(
                onPressed: () =>
                    cerrarSesion(context),
                icon: const Icon(
                  Icons.logout,
                ),
                tooltip: 'Cerrar sesión',
              ),
            ],
          ),
          body: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment:
                    CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'Bienvenido, $nombreUsuario',
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),

                  const SizedBox(height: 20),

                  Card(
                    elevation: 5,
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        children: [
                          const Text(
                            'Saldo actual',
                            style: TextStyle(
                              fontSize: 18,
                            ),
                          ),
                          const SizedBox(height: 10),
                          cargandoSaldo
                              ? const CircularProgressIndicator()
                              : Text(
                                  '\$${saldoActual.toStringAsFixed(2)}',
                                  style: TextStyle(
                                    fontSize: 34,
                                    fontWeight:
                                        FontWeight.bold,
                                    color: saldoActual >= 0
                                        ? Colors.green
                                        : Colors.red,
                                  ),
                                ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 25),

                  ElevatedButton.icon(
                    onPressed: () =>
                        abrirRegistrarMovimiento(
                      context,
                    ),
                    icon: const Icon(
                      Icons.add,
                    ),
                    label: const Text(
                      'Registrar ingreso',
                    ),
                  ),

                  const SizedBox(height: 12),

                  ElevatedButton.icon(
                    onPressed: () =>
                        abrirRegistrarMovimiento(
                      context,
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
                    ),
                    icon: const Icon(
                      Icons.remove,
                    ),
                    label: const Text(
                      'Registrar gasto',
                    ),
                  ),

                  const SizedBox(height: 12),

                  OutlinedButton.icon(
                    onPressed: () async {
                      await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) =>
                              const MovimientosScreen(),
                        ),
                      );

                      await cargarSaldo();
                    },
                    icon: const Icon(
                      Icons.list_alt,
                    ),
                    label: const Text(
                      'Ver movimientos',
                    ),
                  ),

                  const SizedBox(height: 20),

                  const Text(
                    'Últimos movimientos',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 10),

                  const Center(
                    child: Text(
                      'Consulta tus movimientos registrados\n'
                      'desde la opción "Ver movimientos".',
                      textAlign: TextAlign.center,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}