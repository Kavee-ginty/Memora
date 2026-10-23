import 'package:flutter/material.dart';
import 'package:memora_mobile/src/routing/app_router.dart';
import 'package:memora_mobile/src/theme/memora_theme.dart';

class MemoraApp extends StatelessWidget {
  const MemoraApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Memora',
      debugShowCheckedModeBanner: false,
      theme: MemoraTheme.light(),
      routerConfig: appRouter,
    );
  }
}
