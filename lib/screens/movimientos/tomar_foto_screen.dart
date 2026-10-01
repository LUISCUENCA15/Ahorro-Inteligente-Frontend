import 'package:camera/camera.dart';
import 'package:flutter/material.dart';

class TomarFotoScreen extends StatefulWidget {
  const TomarFotoScreen({super.key});

  @override
  State<TomarFotoScreen> createState() =>
      _TomarFotoScreenState();
}

class _TomarFotoScreenState
    extends State<TomarFotoScreen> {
  CameraController? controller;
  bool inicializando = true;
  String? error;

  @override
  void initState() {
    super.initState();
    inicializarCamara();
  }

  Future<void> inicializarCamara() async {
    try {
      final camaras = await availableCameras();

      if (camaras.isEmpty) {
        setState(() {
          inicializando = false;
          error = 'No hay cámaras disponibles.';
        });
        return;
      }

      CameraDescription camaraTrasera;

      try {
        camaraTrasera = camaras.firstWhere(
          (camara) =>
              camara.lensDirection ==
              CameraLensDirection.back,
        );
      } catch (_) {
        camaraTrasera = camaras.first;
      }

      final nuevoController = CameraController(
        camaraTrasera,
        ResolutionPreset.medium,
        enableAudio: false,
      );

      await nuevoController.initialize();

      if (!mounted) {
        await nuevoController.dispose();
        return;
      }

      setState(() {
        controller = nuevoController;
        inicializando = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        inicializando = false;
        error = 'No se pudo inicializar la cámara.';
      });
    }
  }

  Future<void> capturarFoto() async {
    final camara = controller;

    if (camara == null ||
        !camara.value.isInitialized ||
        camara.value.isTakingPicture) {
      return;
    }

    try {
      final foto = await camara.takePicture();

      if (!mounted) return;

      Navigator.pop(
        context,
        foto.path,
      );
    } catch (_) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'No se pudo tomar la fotografía.',
          ),
        ),
      );
    }
  }

  @override
  void dispose() {
    controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Fotografiar comprobante',
        ),
      ),
      body: Builder(
        builder: (context) {
          if (inicializando) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          if (error != null) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(25),
                child: Text(
                  error!,
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }

          final camara = controller;

          if (camara == null ||
              !camara.value.isInitialized) {
            return const Center(
              child: Text(
                'La cámara no está disponible.',
              ),
            );
          }

          return Stack(
            fit: StackFit.expand,
            children: [
              CameraPreview(camara),

              Align(
                alignment: Alignment.bottomCenter,
                child: Padding(
                  padding: const EdgeInsets.all(25),
                  child: FloatingActionButton.large(
                    onPressed: capturarFoto,
                    child: const Icon(
                      Icons.camera_alt,
                      size: 32,
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
