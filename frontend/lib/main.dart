import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:news_app_clean_architecture/config/routes/routes.dart';
import 'package:news_app_clean_architecture/features/daily_news/presentation/pages/auth/auth_gate.dart';
import 'package:news_app_clean_architecture/features/daily_news/presentation/pages/main/main_screen.dart';
import 'config/theme/app_themes.dart';
import 'features/daily_news/presentation/bloc/article/remote/remote_articles_cubit.dart';
import 'firebase_options.dart';
import 'injection_container.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  await initializeDependencies();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return AuthGate(
      child: BlocProvider<RemoteArticlesCubit>(
        create: (context) => sl<RemoteArticlesCubit>(),
        child: MaterialApp(
            debugShowCheckedModeBanner: false,
            theme: theme(),
            onGenerateRoute: AppRoutes.onGenerateRoutes,
            home: const MainScreen()),
      ),
    );
  }
}
