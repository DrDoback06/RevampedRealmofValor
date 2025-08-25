import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants.dart';
import 'providers.dart';

class LoginScreen extends ConsumerWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final actions = ref.watch(authActionsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Realm of Valor')),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ElevatedButton(
              onPressed: () => context.push(Routes.register),
              child: const Text('Create account'),
            ),
            const SizedBox(height: 12),
            OutlinedButton(
              onPressed: () async => actions.signInAnonymously(),
              child: const Text('Continue as guest'),
            ),
          ],
        ),
      ),
    );
  }
}

