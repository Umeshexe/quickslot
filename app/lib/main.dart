import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:quickslot/core/theme/app_theme.dart';
import 'package:quickslot/core/router/app_router.dart';

void main() {
  runApp(
    // ProviderScope is the Riverpod root — wraps the entire app
    const ProviderScope(
      child: QuickSlotApp(),
    ),
  );
}

class QuickSlotApp extends ConsumerWidget {
  const QuickSlotApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(appRouterProvider);
    return MaterialApp.router(
      title: 'QuickSlot',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.dark,
      routerConfig: router,
    );
  }
}
