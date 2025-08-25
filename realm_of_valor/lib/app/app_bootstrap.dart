import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../firebase_options.dart';
import '../core/di.dart';
import 'app_router.dart';
import 'app_theme.dart';

Future<void> bootstrapAndRunApp() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    FirebaseFirestore.instance.settings = const Settings(
      persistenceEnabled: true,
    );
    debugPrint('Firebase initialized successfully');
  } catch (error) {
    debugPrint('Firebase init failed: $error');
    // Continue running in offline mode
  }

  runApp(const ProviderScope(child: _ROVApp()));
}

class _ROVApp extends ConsumerWidget {
  const _ROVApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);

    ref.listen(orchestratorProvider, (prev, next) async {
      await next.initialize();
    });

    return MaterialApp.router(
      title: 'Realm of Valor',
      theme: buildAppTheme(context),
      routerConfig: router,
    );
  }
}

