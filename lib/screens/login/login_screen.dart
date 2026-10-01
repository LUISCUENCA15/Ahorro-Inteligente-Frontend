
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/auth_provider.dart';
import '../home/home_screen.dart';
import '../register/register_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final correoController = TextEditingController();
  final passwordController = TextEditingController();

  final formKey = GlobalKey<FormState>();

  bool ocultarPassword = true;

  Future<void> iniciarSesion() async {
    if (!formKey.currentState!.validate()) {
      return;
    }

    final authProvider = Provider.of<AuthProvider>(
      context,
      listen: false,
    );

    final resultado = await authProvider.iniciarSesion(
      correo: correoController.text.trim(),
      password: passwordController.text,
    );

    if (!mounted) return;

    if (resultado) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => const HomeScreen(),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Correo o contraseña incorrectos.',
          ),
        ),
      );
    }
  }

  @override
  void dispose() {
    correoController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, authProvider, child) {
        return Scaffold(
          resizeToAvoidBottomInset: true,
          appBar: AppBar(
            title: const Text(
              'Ahorro Inteligente',
            ),
            centerTitle: true,
          ),
          body: SafeArea(
            child: SingleChildScrollView(
              keyboardDismissBehavior:
                  ScrollViewKeyboardDismissBehavior.onDrag,
              padding: const EdgeInsets.all(25),
              child: Form(
                key: formKey,
                child: Column(
                  children: [
                    const SizedBox(height: 20),

                    const Icon(
                      Icons.account_balance_wallet,
                      size: 90,
                    ),

                    const SizedBox(height: 25),

                    const Text(
                      'Iniciar sesión',
                      style: TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    const SizedBox(height: 25),

                    TextFormField(
                      controller: correoController,
                      keyboardType:
                          TextInputType.emailAddress,
                      decoration: const InputDecoration(
                        labelText: 'Correo electrónico',
                        prefixIcon:
                            Icon(Icons.email),
                        border:
                            OutlineInputBorder(),
                      ),
                      validator: (valor) {
                        if (valor == null ||
                            valor.trim().isEmpty) {
                          return 'Ingrese su correo electrónico';
                        }

                        final correo = valor.trim();

                        final expresion = RegExp(
                          r'^[^@\s]+@[^@\s]+\.[^@\s]+$',
                        );

                        if (!expresion.hasMatch(correo)) {
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
                        prefixIcon:
                            const Icon(Icons.lock),
                        border:
                            const OutlineInputBorder(),
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
                          return 'Ingrese su contraseña';
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
                            authProvider.cargando
                                ? null
                                : iniciarSesion,
                        child: authProvider.cargando
                            ? const SizedBox(
                                width: 24,
                                height: 24,
                                child:
                                    CircularProgressIndicator(),
                              )
                            : const Text(
                                'Ingresar',
                                style: TextStyle(
                                  fontSize: 18,
                                ),
                              ),
                      ),
                    ),

                    const SizedBox(height: 15),

                    TextButton(
                      onPressed:
                          authProvider.cargando
                              ? null
                              : () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) =>
                                          const RegisterScreen(),
                                    ),
                                  );
                                },
                      child: const Text(
                        'Crear una cuenta',
                      ),
                    ),

                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}