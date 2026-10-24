import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:memora_mobile/src/design_system/catalog/component_catalog_screen.dart';
import 'package:memora_mobile/src/features/home/presentation/home_screen.dart';
import 'package:memora_mobile/src/features/quiz/presentation/quiz_screen.dart';

final GoRouter appRouter = GoRouter(
  initialLocation: '/',
  routes: <RouteBase>[
    GoRoute(
      path: '/',
      name: 'home',
      builder: (BuildContext context, GoRouterState state) {
        return const HomeScreen();
      },
    ),
    GoRoute(
      path: '/catalog',
      name: 'catalog',
      builder: (BuildContext context, GoRouterState state) {
        return const ComponentCatalogScreen();
      },
    ),
    GoRoute(
      path: '/quiz',
      name: 'quiz',
      builder: (BuildContext context, GoRouterState state) {
        return const QuizScreen();
      },
    ),
  ],
);
