import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../pages/login_page.dart';
import '../pages/main_page.dart';
import '../services/auth_service.dart';

final GoRouter appRouter = GoRouter(
  redirect: (context, state) {
    bool loggedIn = authService.isLoggedIn;
    bool isLoginPage = state.uri.path == '/login';

    if (!loggedIn && !isLoginPage) {
      return '/login';
    }

    if (loggedIn && isLoginPage) {
      return '/';
    }

    return null;
  },
  routes: [
    GoRoute(
      path: '/login',
      pageBuilder: (context, state) => MaterialPage(
        child: LoginPage(),
      ),
    ),
    GoRoute(
      path: '/',
      pageBuilder: (context, state) => MaterialPage(
        child: MainPage(order: 1),
      ),
    ),
    GoRoute(
      path: '/notification',
      pageBuilder: (context, state) => MaterialPage(
        child: MainPage(order: 2),
      ),
    ),
    GoRoute(
      path: '/class',
      pageBuilder: (context, state) => MaterialPage(
        child: MainPage(order: 3),
      ),
    ),
    GoRoute(
      path: '/exercise',
      pageBuilder: (context, state) => MaterialPage(
        child: MainPage(order: 4),
      ),
    ),
    GoRoute(
      path: '/class/exercise',
      pageBuilder: (context, state) => MaterialPage(
        child: MainPage(order: 5),
      ),
    ),
    GoRoute(
      path: '/test',
      pageBuilder: (context, state) => MaterialPage(
        child: MainPage(order: 6),
      ),
    ),
    GoRoute(
      path: '/test/history',
      pageBuilder: (context, state) => MaterialPage(
        child: MainPage(order: 7),
      ),
    ),
    GoRoute(
      path: '/flashcard',
      pageBuilder: (context, state) => MaterialPage(
        child: MainPage(order: 8),
      ),
    ),
    GoRoute(
      path: '/ticket',
      pageBuilder: (context, state) => MaterialPage(
        child: MainPage(order: 9),
      ),
    ),
    GoRoute(
      path: '/exercises',
      pageBuilder: (context, state) => MaterialPage(
        child: MainPage(order: 10),
      ),
    ),
    GoRoute(
      path: '/tests',
      pageBuilder: (context, state) => MaterialPage(
        child: MainPage(order: 11),
      ),
    ),
    GoRoute(
      path: '/questions',
      pageBuilder: (context, state) => MaterialPage(
        child: MainPage(order: 12),
      ),
    ),
    GoRoute(
      path: '/classes',
      pageBuilder: (context, state) => MaterialPage(
        child: MainPage(order: 13),
      ),
    ),
  ],
);