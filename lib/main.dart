import 'package:flutter/material.dart';
import 'package:supabase_auth_ui/supabase_auth_ui.dart';

import 'util.dart';
import 'theme.dart';
import 'screens/auth_screen.dart';

void main() async {
  await Supabase.initialize(
    url: 'https://jbpeszoljhnymgqhufmd.supabase.co',
    anonKey:
        'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImpicGVzem9samhueW1ncWh1Zm1kIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NDMyNTAzMDIsImV4cCI6MjA1ODgyNjMwMn0.NX3h_DpXqnpabbla3wR-RHQTuZskM3aJeX2qU1HNUe0',
  );
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final brightness = View.of(context).platformDispatcher.platformBrightness;

    TextTheme textTheme = createTextTheme(
      context,
      "Roboto Flex",
      "Abyssinica SIL",
    );

    MaterialTheme theme = MaterialTheme(textTheme);
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Flutter Demo',
      theme: brightness == Brightness.light ? theme.light() : theme.dark(),
      home: const AuthScreen(),
    );
  }
}
