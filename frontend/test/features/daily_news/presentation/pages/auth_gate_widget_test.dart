import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:news_app_clean_architecture/features/daily_news/presentation/pages/auth/auth_gate.dart';
import 'package:news_app_clean_architecture/features/daily_news/presentation/pages/auth/auth_screen.dart';

class _MockUser extends Mock implements User {}

void main() {
  group('AuthGate', () {
    testWidgets('shows loading indicator while waiting for auth state',
        (tester) async {
      final controller = StreamController<User?>();

      await tester.pumpWidget(
        AuthGate(
          authStateStream: controller.stream,
          child: const MaterialApp(home: Scaffold(body: Text('Home'))),
        ),
      );

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.text('Home'), findsNothing);

      await controller.close();
    });

    testWidgets('shows AuthScreen when user is null', (tester) async {
      await tester.pumpWidget(
        AuthGate(
          authStateStream: Stream.value(null),
          child: const MaterialApp(home: Scaffold(body: Text('Home'))),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(AuthScreen), findsOneWidget);
      expect(find.text('Home'), findsNothing);
    });

    testWidgets('shows AuthScreen when user is anonymous', (tester) async {
      final mockUser = _MockUser();
      when(() => mockUser.isAnonymous).thenReturn(true);

      await tester.pumpWidget(
        AuthGate(
          authStateStream: Stream.value(mockUser),
          child: const MaterialApp(home: Scaffold(body: Text('Home'))),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(AuthScreen), findsOneWidget);
      expect(find.text('Home'), findsNothing);
    });

    testWidgets('shows child when user is authenticated (non-anonymous)',
        (tester) async {
      final mockUser = _MockUser();
      when(() => mockUser.isAnonymous).thenReturn(false);

      await tester.pumpWidget(
        AuthGate(
          authStateStream: Stream.value(mockUser),
          child: const MaterialApp(home: Scaffold(body: Text('Home'))),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Home'), findsOneWidget);
      expect(find.byType(AuthScreen), findsNothing);
    });

    testWidgets('transitions from auth screen to child when user signs in',
        (tester) async {
      final controller = StreamController<User?>();
      final mockUser = _MockUser();
      when(() => mockUser.isAnonymous).thenReturn(false);

      await tester.pumpWidget(
        AuthGate(
          authStateStream: controller.stream,
          child: const MaterialApp(home: Scaffold(body: Text('Home'))),
        ),
      );

      controller.add(null);
      await tester.pumpAndSettle();
      expect(find.byType(AuthScreen), findsOneWidget);

      controller.add(mockUser);
      await tester.pumpAndSettle();
      expect(find.text('Home'), findsOneWidget);

      await controller.close();
    });
  });
}
