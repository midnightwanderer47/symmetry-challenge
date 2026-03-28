import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

class AuthGate extends StatefulWidget {
  final Widget child;
  const AuthGate({Key? key, required this.child}) : super(key: key);

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  bool _signInCalled = false;

  Future<void> _signIn(BuildContext context) async {
    if (_signInCalled) return;
    _signInCalled = true;
    try {
      await FirebaseAuth.instance.signInAnonymously();
    } on FirebaseAuthException catch (e, stackTrace) {
      if (e.code == 'operation-not-allowed' || e.code == 'network-request-failed') {
        debugPrint('Auth error [${e.code}]: ${e.message}');
        debugPrintStack(stackTrace: stackTrace);
        if (context.mounted) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Auth failed: ${e.message}'),
                backgroundColor: Colors.red,
              ),
            );
          });
        }
      } else {
        debugPrint('Auth error [${e.code}]: ${e.message}');
        debugPrintStack(stackTrace: stackTrace);
      }
    } catch (e, stackTrace) {
      debugPrint('Unexpected auth error: $e');
      debugPrintStack(stackTrace: stackTrace);
    }
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const _LoadingScreen();
        }

        if (snapshot.hasError && kDebugMode) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Auth error: ${snapshot.error}')),
            );
          });
        }

        if (!snapshot.hasData) {
          _signIn(context);
          return const _LoadingScreen();
        }

        return widget.child;
      },
    );
  }
}

class _LoadingScreen extends StatelessWidget {
  const _LoadingScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        body: Center(child: CircularProgressIndicator()),
      ),
    );
  }
}
