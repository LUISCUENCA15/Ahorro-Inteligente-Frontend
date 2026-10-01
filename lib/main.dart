import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sentry_flutter/sentry_flutter.dart';

import 'providers/auth_provider.dart';
import 'screens/login/login_screen.dart';

const String sentryDsn = String.fromEnvironment(
  'SENTRY_DSN',
);

Future<void> main() async {
  await SentryFlutter.init(
    (options) {
      options.dsn = sentryDsn;

      // No enviar información personal adicional.
      options.sendDefaultPii = false;

      // Para esta práctica no utilizamos monitoreo de rendimiento
      // mediante Sentry.
      options.tracesSampleRate = 0.0;
    },
    appRunner: () {
      runApp(
        ChangeNotifierProvider(
          create: (_) => AuthProvider(),
          child: const AhorroInteligenteApp(),
        ),
      );
    },
  );
}

class AhorroInteligenteApp extends StatelessWidget {
  const AhorroInteligenteApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Ahorro Inteligente',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.green,
        ),
        useMaterial3: true,
      ),
      home: const LoginScreen(),
    );
  }
}