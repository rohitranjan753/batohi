import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../blocs/authentication/authentication_bloc.dart';
import '../blocs/authentication/authentication_event.dart';
import '../config/app_routes.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final user = context.select(
      (AuthenticationBloc bloc) => bloc.state.user,
    );
    return Scaffold(
      appBar: AppBar(
        title: const Text('Batohi Home'),
        actions: <Widget>[
          IconButton(
            key: const Key('homePage_logout_iconButton'),
            icon: const Icon(Icons.exit_to_app),
            onPressed: () {
              context
                  .read<AuthenticationBloc>()
                  .add(const AuthenticationLogoutRequested());
              // GoRouter will automatically redirect to login page
            },
          )
        ],
      ),
      body: Align(
        alignment: const Alignment(0, -1 / 3),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Avatar(photo: user.photoURL),
            const SizedBox(height: 4),
            Text(user.email ?? '', style: const TextStyle(fontSize: 24)),
            const SizedBox(height: 4),
            Text(user.displayName ?? 'No Name', style: const TextStyle(fontSize: 18)),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () {
                // Example of programmatic navigation with GoRouter
                context.go(AppRoutes.profile);
              },
              child: const Text('Go to Profile (Demo)'),
            ),
          ],
        ),
      ),
    );
  }
}

class Avatar extends StatelessWidget {
  const Avatar({super.key, this.photo});

  final String? photo;

  @override
  Widget build(BuildContext context) {
    return CircleAvatar(
      radius: 48,
      backgroundImage: photo != null ? NetworkImage(photo!) : null,
      child: photo == null
          ? const Icon(Icons.person_outline, size: 64)
          : null,
    );
  }
}