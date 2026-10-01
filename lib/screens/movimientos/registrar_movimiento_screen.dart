import 'dart:io';

import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';

import '../../providers/auth_provider.dart';
import '../../services/movimiento_service.dart';
import '../../utils/movimiento_validators.dart';
import 'tomar_foto_screen.dart';

class RegistrarMovimientoScreen extends StatefulWidget {
  const RegistrarMovimientoScreen({super.key});

  @override
  State<RegistrarMovimientoScreen> createState() =>
      _RegistrarMovimientoScreenState();
}

class _RegistrarMovimientoScreenState
    extends State<RegistrarMovimientoScreen> {
  final descripcionController = TextEditingController();
  final montoController = TextEditingController();

  final formKey = GlobalKey<FormState>();

  final MovimientoService movimientoService =
      MovimientoService();

  String tipoSeleccionado = 'ingreso';
  DateTime fechaSeleccionada = DateTime.now();

  bool cargando = false;
  bool cargandoUbicacion = false;
  bool cargandoCamara = false;

  String? ubicacionTexto;
  String? fotoComprobante;

  @override
  void initState() {
    super.initState();
    cargarDatosLocales();
  }

  Future<void> cargarDatosLocales() async {
    final prefs = await SharedPreferences.getInstance();

    final latitud = prefs.getDouble('ultima_latitud');
    final longitud = prefs.getDouble('ultima_longitud');
    final foto = prefs.getString('ultimo_comprobante');

    if (!mounted) return;

    setState(() {
      if (latitud != null && longitud != null) {
        ubicacionTexto =
            '${latitud.toStringAsFixed(6)}, '
            '${longitud.toStringAsFixed(6)}';
      }

      fotoComprobante = foto;
    });
  }

  Future<bool> mostrarExplicacionPermiso({
    required String titulo,
    required String mensaje,
  }) async {
    final resultado = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(titulo),
          content: Text(mensaje),
          actions: [
            TextButton(
              onPressed: () =>
                  Navigator.pop(context, false),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () =>
                  Navigator.pop(context, true),
              child: const Text('Continuar'),
            ),
          ],
        );
      },
    );

    return resultado ?? false;
  }

  Future<void> mostrarPermisoDenegado({
    required String titulo,
    required String mensaje,
  }) async {
    if (!mounted) return;

    await showDialog<void>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(titulo),
          content: Text(mensaje),
          actions: [
            TextButton(
              onPressed: () =>
                  Navigator.pop(context),
              child: const Text('Entendido'),
            ),
          ],
        );
      },
    );
  }

  Future<void> mostrarAjustes({
    required String titulo,
    required String mensaje,
  }) async {
    if (!mounted) return;

    await showDialog<void>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(titulo),
          content: Text(mensaje),
          actions: [
            TextButton(
              onPressed: () =>
                  Navigator.pop(context),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.pop(context);
                await openAppSettings();
              },
              child: const Text('Abrir ajustes'),
            ),
          ],
        );
      },
    );
  }

  Future<void> obtenerUbicacion() async {
    setState(() {
      cargandoUbicacion = true;
    });

    try {
      final servicioActivo =
          await Geolocator.isLocationServiceEnabled();

      if (!servicioActivo) {
        await mostrarAjustes(
          titulo: 'Ubicación desactivada',
          mensaje:
              'El servicio de ubicación del dispositivo '
              'está desactivado. Puedes activarlo desde '
              'los ajustes del sistema.',
        );
        return;
      }

      var permiso =
          await Permission.locationWhenInUse.status;

      if (permiso.isDenied) {
        final continuar =
            await mostrarExplicacionPermiso(
          titulo: 'Permiso de ubicación',
          mensaje:
              'Ahorro Inteligente necesita tu ubicación '
              'para asociar el movimiento con el lugar '
              'donde fue registrado.',
        );

        if (!continuar) {
          return;
        }

        permiso =
            await Permission.locationWhenInUse.request();
      }

      if (permiso.isGranted) {
        final position =
            await Geolocator.getCurrentPosition(
          locationSettings: const LocationSettings(
            accuracy: LocationAccuracy.high,
          ),
        );

        final prefs =
            await SharedPreferences.getInstance();

        await prefs.setDouble(
          'ultima_latitud',
          position.latitude,
        );

        await prefs.setDouble(
          'ultima_longitud',
          position.longitude,
        );

        if (!mounted) return;

        setState(() {
          ubicacionTexto =
              '${position.latitude.toStringAsFixed(6)}, '
              '${position.longitude.toStringAsFixed(6)}';
        });
      } else if (permiso.isPermanentlyDenied) {
        await mostrarAjustes(
          titulo: 'Permiso bloqueado',
          mensaje:
              'El permiso de ubicación fue denegado '
              'permanentemente. Debes habilitarlo desde '
              'los ajustes de la aplicación.',
        );
      } else if (permiso.isRestricted) {
        await mostrarPermisoDenegado(
          titulo: 'Ubicación restringida',
          mensaje:
              'El sistema restringe actualmente el acceso '
              'a la ubicación. La aplicación continuará '
              'sin esta funcionalidad.',
        );
      } else {
        await mostrarPermisoDenegado(
          titulo: 'Permiso denegado',
          mensaje:
              'No se concedió el permiso de ubicación. '
              'Puedes registrar el movimiento sin utilizar '
              'esta funcionalidad.',
        );
      }
    } catch (e) {
      if (!mounted) return;

      await mostrarPermisoDenegado(
        titulo: 'No se pudo obtener la ubicación',
        mensaje:
            'La ubicación no está disponible en este momento. '
            'Puedes continuar usando el formulario.',
      );
    } finally {
      if (mounted) {
        setState(() {
          cargandoUbicacion = false;
        });
      }
    }
  }

  Future<void> tomarFoto() async {
    setState(() {
      cargandoCamara = true;
    });

    try {
      var permiso = await Permission.camera.status;

      if (permiso.isDenied) {
        final continuar =
            await mostrarExplicacionPermiso(
          titulo: 'Permiso de cámara',
          mensaje:
              'Ahorro Inteligente necesita la cámara '
              'para tomar una fotografía del comprobante '
              'del movimiento.',
        );

        if (!continuar) {
          return;
        }

        permiso = await Permission.camera.request();
      }

      if (permiso.isGranted) {
    if (!mounted) return;

    final rutaTemporal =
        await Navigator.push<String>(
      context,
      MaterialPageRoute(
        builder: (_) =>
            const TomarFotoScreen(),
      ),
    );

        if (rutaTemporal == null) {
          return;
        }

        final directorio =
            await getApplicationDocumentsDirectory();

        final nombreArchivo =
            'comprobante_${DateTime.now().millisecondsSinceEpoch}.jpg';

        final rutaFinal =
            '${directorio.path}/$nombreArchivo';

        await File(rutaTemporal).copy(rutaFinal);

        final prefs =
            await SharedPreferences.getInstance();

        await prefs.setString(
          'ultimo_comprobante',
          rutaFinal,
        );

        if (!mounted) return;

        setState(() {
          fotoComprobante = rutaFinal;
        });

        try {
          await File(rutaTemporal).delete();
        } catch (_) {}
      } else if (permiso.isPermanentlyDenied) {
        await mostrarAjustes(
          titulo: 'Permiso bloqueado',
          mensaje:
              'El permiso de cámara fue denegado '
              'permanentemente. Debes habilitarlo desde '
              'los ajustes de la aplicación.',
        );
      } else if (permiso.isRestricted) {
        await mostrarPermisoDenegado(
          titulo: 'Cámara restringida',
          mensaje:
              'El sistema restringe actualmente el acceso '
              'a la cámara. La aplicación continuará '
              'sin esta funcionalidad.',
        );
      } else {
        await mostrarPermisoDenegado(
          titulo: 'Permiso denegado',
          mensaje:
              'No se concedió el permiso de cámara. '
              'Puedes registrar el movimiento sin tomar '
              'una fotografía.',
        );
      }
    } catch (e) {
      if (!mounted) return;

      await mostrarPermisoDenegado(
        titulo: 'No se pudo utilizar la cámara',
        mensaje:
            'La cámara no está disponible en este momento. '
            'Puedes continuar usando el formulario.',
      );
    } finally {
      if (mounted) {
        setState(() {
          cargandoCamara = false;
        });
      }
    }
  }

  Future<void> seleccionarFecha() async {
    final fecha = await showDatePicker(
      context: context,
      initialDate: fechaSeleccionada,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );

    if (fecha != null) {
      setState(() {
        fechaSeleccionada = fecha;
      });
    }
  }

  Future<void> registrarMovimiento() async {
    if (!formKey.currentState!.validate()) {
      return;
    }

    final authProvider =
        Provider.of<AuthProvider>(
      context,
      listen: false,
    );

    if (!authProvider.estaAutenticado) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'La sesión no es válida. '
            'Inicie sesión nuevamente.',
          ),
        ),
      );
      return;
    }

    setState(() {
      cargando = true;
    });

    try {
      final fecha =
          DateFormat('yyyy-MM-dd')
              .format(fechaSeleccionada);

      final resultado =
          await movimientoService.registrarMovimiento(
        token: authProvider.token!,
        tipo: tipoSeleccionado,
        descripcion:
            descripcionController.text.trim(),
        monto: montoController.text.trim(),
        fecha: fecha,
      );

      if (!mounted) return;

      if (resultado) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Movimiento registrado correctamente.',
            ),
          ),
        );

        Navigator.pop(context, true);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'No se pudo registrar el movimiento.',
            ),
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Error de conexión con el servidor.',
          ),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          cargando = false;
        });
      }
    }
  }

  @override
  void dispose() {
    descripcionController.dispose();
    montoController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Registrar movimiento',
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(25),
        child: Form(
          key: formKey,
          child: Column(
            children: [
              const Icon(
                Icons.add_circle_outline,
                size: 80,
              ),

              const SizedBox(height: 20),

              const Text(
                'Nuevo movimiento',
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 25),

              DropdownButtonFormField<String>(
                initialValue: tipoSeleccionado,
                decoration: const InputDecoration(
                  labelText: 'Tipo de movimiento',
                  prefixIcon:
                      Icon(Icons.swap_vert),
                  border: OutlineInputBorder(),
                ),
                items: const [
                  DropdownMenuItem(
                    value: 'ingreso',
                    child: Text('Ingreso'),
                  ),
                  DropdownMenuItem(
                    value: 'gasto',
                    child: Text('Gasto'),
                  ),
                ],
                onChanged: (valor) {
                  if (valor != null) {
                    setState(() {
                      tipoSeleccionado = valor;
                    });
                  }
                },
              ),

              const SizedBox(height: 15),

              TextFormField(
                controller:
                    descripcionController,
                decoration:
                    const InputDecoration(
                  labelText: 'Descripción',
                  prefixIcon:
                      Icon(Icons.description),
                  border: OutlineInputBorder(),
                ),
                validator: MovimientoValidators.descripcion,
              ),

              const SizedBox(height: 15),

              TextFormField(
                controller: montoController,
                keyboardType:
                    const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                decoration:
                    const InputDecoration(
                  labelText: 'Monto',
                  prefixIcon:
                      Icon(Icons.attach_money),
                  border: OutlineInputBorder(),
                ),
                validator: MovimientoValidators.monto,
              ),

              const SizedBox(height: 15),

              InkWell(
                onTap: seleccionarFecha,
                child: InputDecorator(
                  decoration:
                      const InputDecoration(
                    labelText: 'Fecha',
                    prefixIcon:
                        Icon(Icons.calendar_today),
                    border: OutlineInputBorder(),
                  ),
                  child: Text(
                    DateFormat(
                      'dd/MM/yyyy',
                    ).format(fechaSeleccionada),
                  ),
                ),
              ),

              const SizedBox(height: 20),

              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed:
                      cargandoUbicacion
                          ? null
                          : obtenerUbicacion,
                  icon: cargandoUbicacion
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child:
                              CircularProgressIndicator(
                            strokeWidth: 2,
                          ),
                        )
                      : const Icon(
                          Icons.location_on,
                        ),
                  label: Text(
                    cargandoUbicacion
                        ? 'Obteniendo ubicación...'
                        : 'Obtener ubicación',
                  ),
                ),
              ),

              const SizedBox(height: 8),

              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  ubicacionTexto == null
                      ? 'Ubicación no registrada'
                      : 'Ubicación: $ubicacionTexto',
                  style: const TextStyle(
                    fontSize: 13,
                  ),
                ),
              ),

              const SizedBox(height: 15),

              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed:
                      cargandoCamara
                          ? null
                          : tomarFoto,
                  icon: cargandoCamara
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child:
                              CircularProgressIndicator(
                            strokeWidth: 2,
                          ),
                        )
                      : const Icon(
                          Icons.camera_alt,
                        ),
                  label: Text(
                    cargandoCamara
                        ? 'Abriendo cámara...'
                        : 'Tomar foto del comprobante',
                  ),
                ),
              ),

              const SizedBox(height: 8),

              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  fotoComprobante == null
                      ? 'Comprobante no registrado'
                      : 'Comprobante guardado localmente',
                  style: const TextStyle(
                    fontSize: 13,
                  ),
                ),
              ),

              const SizedBox(height: 25),

              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: cargando
                      ? null
                      : registrarMovimiento,
                  child: cargando
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child:
                              CircularProgressIndicator(),
                        )
                      : const Text(
                          'Guardar movimiento',
                          style: TextStyle(
                            fontSize: 18,
                          ),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
