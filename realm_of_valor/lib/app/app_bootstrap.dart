import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'app_router.dart';
import 'app_theme.dart';

Future<void> bootstrapAndRunApp() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Best-effort Firebase initialization. Real options should be generated via
  // FlutterFire CLI and imported here. We keep this guarded so the app can run
  // without Firebase during early development.
  try {
    await Firebase.initializeApp();
    FirebaseFirestore.instance.settings = const Settings(
      persistenceEnabled: true,
    );
  } catch (error) {
    debugPrint('Firebase init skipped or failed: $error');
  }

  runApp(const ProviderScope(child: _ROVApp()));
}

class _ROVApp extends ConsumerWidget {
  const _ROVApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);

    return MaterialApp.router(
      title: 'Realm of Valor',
      theme: buildAppTheme(context),
      routerConfig: router,
    );
  }
}
