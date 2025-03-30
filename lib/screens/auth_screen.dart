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
    if (session != null && session.user != null) {
      // Get the display name from user metadata if available
      String? displayName;

      // First, try to get name from user_metadata (from social providers)
      if (session.user.userMetadata != null) {
        displayName = session.user.userMetadata?['full_name'] as String?;

        // If full_name isn't available, try name
        if (displayName == null) {
          displayName = session.user.userMetadata?['name'] as String?;
        }
      }

      // If still no name, try to get from user attributes
      if (displayName == null) {
        displayName = session.user.email?.split('@')[0];
      }

      // Ensure we have at least some display name
      displayName ??= "User";

      // Pass both email and name to HomeScreen
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder:
              (context) => HomeScreen(
                email: session.user.email ?? "",
                displayName: displayName ?? "User",
              ),
        ),
      );
    }
  }
}
