import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:firebase_core/firebase_core.dart';
import 'blocs/authentication/authentication_bloc.dart';
import 'blocs/mytrips/mytrips_bloc.dart';
import 'repositories/authentication_repository.dart';
import 'config/app_router.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();

  final authenticationRepository = AuthenticationRepository();

  runApp(MyApp(authenticationRepository: authenticationRepository));
}

class MyApp extends StatelessWidget {
  const MyApp({super.key, required this.authenticationRepository});

  final AuthenticationRepository authenticationRepository;

  @override
  Widget build(BuildContext context) {
    return RepositoryProvider.value(
      value: authenticationRepository,
      child: MultiBlocProvider(
        providers: [
          BlocProvider(
            create: (_) => AuthenticationBloc(
              authenticationRepository: authenticationRepository,
            ),
          ),
          BlocProvider(create: (_) => MyTripsBloc()),
        ],
        child: const AppView(),
      ),
    );
  }
}

class AppView extends StatelessWidget {
  const AppView({super.key});

  @override
  Widget build(BuildContext context) {
    final authenticationBloc = context.read<AuthenticationBloc>();
    final router = AppRouter.router(authenticationBloc);

    return MaterialApp.router(
      title: 'Batohi',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      routerConfig: router,
    );
  }
}
