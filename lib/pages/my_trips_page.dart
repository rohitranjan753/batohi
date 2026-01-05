import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import '../blocs/authentication/authentication_bloc.dart';
import '../blocs/authentication/authentication_event.dart';
import '../config/app_routes.dart';

class MyTripsPage extends StatelessWidget {
  const MyTripsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final user = context.select(
      (AuthenticationBloc bloc) => bloc.state.user,
    );
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Trips'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: <Widget>[
          IconButton(
            key: const Key('myTripsPage_logout_iconButton'),
            icon: Icon(PhosphorIcons.signOut()),
            onPressed: () {
              context
                  .read<AuthenticationBloc>()
                  .add(const AuthenticationLogoutRequested());
            },
          )
        ],
      ),
      body: Column(
        children: [
          // User Profile Section
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.inversePrimary.withOpacity(0.1),
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(20),
                bottomRight: Radius.circular(20),
              ),
            ),
            child: Column(
              children: [
                Avatar(photo: user.photoURL),
                const SizedBox(height: 12),
                Text(
                  user.displayName ?? 'No Name',
                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                Text(
                  user.email ?? '',
                  style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                ),
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  onPressed: () {
                    context.go(AppRoutes.profile);
                  },
                  icon: Icon(PhosphorIcons.user(), size: 16),
                  label: const Text('View Profile'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).primaryColor,
                    foregroundColor: Colors.white,
                  ),
                ),
              ],
            ),
          ),
          // Trips Content
          Expanded(
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    PhosphorIcons.airplane(),
                    size: 64,
                    color: Colors.blue,
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Your Trips',
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Plan and track your adventures',
                    style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton.icon(
                    onPressed: () {
                      // TODO: Navigate to add trip page
                    },
                    icon: Icon(PhosphorIcons.plus(), size: 20),
                    label: const Text('Add New Trip'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
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
      radius: 40,
      backgroundImage: photo != null ? NetworkImage(photo!) : null,
      child: photo == null
          ? Icon(PhosphorIcons.user(), size: 48)
          : null,
    );
  }
}