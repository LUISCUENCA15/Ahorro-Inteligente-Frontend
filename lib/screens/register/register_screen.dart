
import 'package:flutter/material.dart';

import '../../services/auth_service.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final nombreController = TextEditingController();
  final correoController = TextEditingController();
  final passwordController = TextEditingController();

  final AuthService authService = AuthService();

  final formKey = GlobalKey<FormState>();

  bool cargando = false;
  bool ocultarPassword = true;

  Future<void> registrar() async {
    if (!formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      cargando = true;
    });

    try {
      final respuesta = await authService.register(
        nombre: nombreController.text.trim(),
        correo: correoController.text.trim(),
        password: passwordController.text,
      );

      if (!mounted) return;

      if (respuesta['usuario'] != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Usuario registrado correctamente',
            ),
          ),
        );

        Navigator.pop(context);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              respuesta['error'] ??
                  'No se pudo registrar el usuario',
            ),
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Error de conexión con el servidor',
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
    nombreController.dispose();
    correoController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Registro'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(25),
        child: Form(
          key: formKey,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.person_add,
                size: 80,
              ),

              const SizedBox(height: 20),

              const Text(
                'Crear una cuenta',
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 25),

              TextFormField(
                controller: nombreController,
                textCapitalization:
                    TextCapitalization.words,
                decoration: const InputDecoration(
                  labelText: 'Nombre',
                  prefixIcon: Icon(Icons.person),
                  border: OutlineInputBorder(),
                ),
                validator: (valor) {
                  if (valor == null ||
                      valor.trim().isEmpty) {
                    return 'Ingrese su nombre';
                  }

                  if (valor.trim().length < 3) {
                    return 'El nombre debe tener al menos 3 caracteres';
                  }

                  return null;
                },
              ),

              const SizedBox(height: 15),

              TextFormField(
                controller: correoController,
                keyboardType:
                    TextInputType.emailAddress,
                decoration: const InputDecoration(
                  labelText: 'Correo electrónico',
                  prefixIcon: Icon(Icons.email),
                  border: OutlineInputBorder(),
                ),
                validator: (valor) {
                  if (valor == null ||
                      valor.trim().isEmpty) {
                    return 'Ingrese su correo electrónico';
                  }

                  final expresion = RegExp(
                    r'^[^@\s]+@[^@\s]+\.[^@\s]+$',
                  );

                  if (!expresion.hasMatch(
                    valor.trim(),
                  )) {
                    return 'Ingrese un correo electrónico válido';
                  }

                  return null;
                },
              ),

              const SizedBox(height: 15),

              TextFormField(
                controller: passwordController,
                obscureText: ocultarPassword,
                decoration: InputDecoration(
                  labelText: 'Contraseña',
                  prefixIcon: const Icon(Icons.lock),
                  border: const OutlineInputBorder(),
                  suffixIcon: IconButton(
                    icon: Icon(
                      ocultarPassword
                          ? Icons.visibility
                          : Icons.visibility_off,
                    ),
                    onPressed: () {
                      setState(() {
                        ocultarPassword =
                            !ocultarPassword;
                      });
                    },
                  ),
                ),
                validator: (valor) {
                  if (valor == null ||
                      valor.isEmpty) {
                    return 'Ingrese una contraseña';
                  }

                  if (valor.length < 6) {
                    return 'La contraseña debe tener al menos 6 caracteres';
                  }

                  return null;
                },
              ),

              const SizedBox(height: 25),

              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed:
                      cargando ? null : registrar,
                  child: cargando
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child:
                              CircularProgressIndicator(),
                        )
                      : const Text(
                          'Registrarse',
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