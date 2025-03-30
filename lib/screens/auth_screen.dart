import 'package:flutter/material.dart';
import 'package:supabase_auth_ui/supabase_auth_ui.dart';
import 'home_screen.dart';

class AuthScreen extends StatelessWidget {
  const AuthScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'Welcome',
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
                const SizedBox(height: 32.0),
                SupaEmailAuth(
                  onSignInComplete: (response) {
                    _handleAuthSuccess(context, response.session);
                  },
                  onSignUpComplete: (response) {
                    _handleAuthSuccess(context, response.session);
                  },
                ),
                const SizedBox(height: 24.0),
                SupaSocialsAuth(
                  socialProviders: [OAuthProvider.google],
                  colored: true,
                  onSuccess: (session) {
                    _handleAuthSuccess(context, session);
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _handleAuthSuccess(BuildContext context, Session? session) {
    if (session != null && session.user.email != null) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (context) => HomeScreen(email: session.user.email!),
        ),
      );
    }
  }
}
