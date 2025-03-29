import 'package:flutter/material.dart';
import 'package:supabase_auth_ui/supabase_auth_ui.dart';


import 'util.dart';
import 'theme.dart';

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

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    final brightness = View.of(context).platformDispatcher.platformBrightness;

    // Retrieves the default theme for the platform
    //TextTheme textTheme = Theme.of(context).textTheme;

    // Use with Google Fonts package to use downloadable fonts
    TextTheme textTheme = createTextTheme(
      context,
      "Roboto Flex",
      "Abyssinica SIL",
    );

    MaterialTheme theme = MaterialTheme(textTheme);
    return MaterialApp(
      title: 'Flutter Demo',
      theme: brightness == Brightness.light ? theme.light() : theme.dark(),
      home: const MyHomePage(title: 'Flutter Demo Home Page'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  // This widget is the home page of your application. It is stateful, meaning
  // that it has a State object (defined below) that contains fields that affect
  // how it looks.

  // This class is the configuration for the state. It holds the values (in this
  // case the title) provided by the parent (in this case the App widget) and
  // used by the build method of the State. Fields in a Widget subclass are
  // always marked "final".

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> with SingleTickerProviderStateMixin {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text(widget.title),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SupaEmailAuth(
              onSignInComplete: (response) {},
              onSignUpComplete: (response) {},
            ),
            SupaSocialsAuth(
              socialProviders: [
                // OAuthProvider.apple,
                OAuthProvider.google,
              ],
              colored: true,
              onSuccess: (response) {},
            ),
          ],
        ),
      ),
    );
  }
}
