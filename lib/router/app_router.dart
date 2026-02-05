import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../pages/admin/create_class.dart';
import '../pages/admin/create_student.dart';
import '../pages/admin/create_teacher.dart';
import '../pages/authentication/authentication_page.dart';
import '../pages/authentication/login_page.dart';
import '../pages/authentication/update_account_page.dart';
import '../pages/side_menu/admin/class_management_page.dart';
import '../pages/side_menu/admin/student_management_page.dart';
import '../pages/side_menu/admin/teacher_management_page.dart';
import '../pages/side_menu/home_page.dart';
import '../pages/side_menu/students/class_exercise_page.dart';
import '../pages/side_menu/students/class_page.dart';
import '../pages/side_menu/students/exercise_page.dart';
import '../pages/side_menu/students/flashcard_page.dart';
import '../pages/side_menu/students/notification_page.dart';
import '../pages/side_menu/students/test_history_page.dart';
import '../pages/side_menu/students/test_page.dart';
import '../pages/side_menu/students/ticket_page.dart';
import '../pages/side_menu/teachers/classes_page.dart';
import '../pages/side_menu/teachers/exercises_page.dart';
import '../pages/side_menu/teachers/questions_page.dart';
import '../pages/side_menu/teachers/tests_page.dart';
import '../pages/user/profile_page.dart';
import '../services/auth_service.dart';

final GoRouter appRouter = GoRouter(
  redirect: (context, state) {
    bool loggedIn = authService.isLoggedIn;
    bool isLoginPage = state.uri.path == '/login';
    bool isAuthCallback = state.uri.path == '/authenticate';

    if (!loggedIn && !(isLoginPage || isAuthCallback)) {
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
      path: '/authenticate',
      pageBuilder: (context, state) => MaterialPage(
        child: AuthenticationPage(),
      ),
    ),
    GoRoute(
      path: '/update-account',
      pageBuilder: (context, state) => MaterialPage(
        child: UpdateAccountPage(),
      ),
    ),

    GoRoute(
      path: '/',
      pageBuilder: (context, state) => MaterialPage(
        child: HomePage(),
      ),
    ),
    GoRoute(
      path: '/notification',
      pageBuilder: (context, state) => MaterialPage(
        child: NotificationPage(),
      ),
    ),
    GoRoute(
      path: '/class',
      pageBuilder: (context, state) => MaterialPage(
        child: ClassPage(),
      ),
    ),
    GoRoute(
      path: '/exercise',
      pageBuilder: (context, state) => MaterialPage(
        child: ExercisePage(),
      ),
    ),
    GoRoute(
      path: '/class/exercise',
      pageBuilder: (context, state) => MaterialPage(
        child: ClassExercisePage(),
      ),
    ),
    GoRoute(
      path: '/test',
      pageBuilder: (context, state) => MaterialPage(
        child: TestPage(),
      ),
    ),
    GoRoute(
      path: '/test/history',
      pageBuilder: (context, state) => MaterialPage(
        child: TestHistoryPage(),
      ),
    ),
    GoRoute(
      path: '/flashcard',
      pageBuilder: (context, state) => MaterialPage(
        child: FlashcardPage(),
      ),
    ),
    GoRoute(
      path: '/ticket',
      pageBuilder: (context, state) => MaterialPage(
        child: TicketPage(),
      ),
    ),
    GoRoute(
      path: '/exercises',
      pageBuilder: (context, state) => MaterialPage(
        child: ExercisesPage(),
      ),
    ),
    GoRoute(
      path: '/tests',
      pageBuilder: (context, state) => MaterialPage(
        child: TestsPage(),
      ),
    ),
    GoRoute(
      path: '/questions',
      pageBuilder: (context, state) => MaterialPage(
        child: QuestionsPage(),
      ),
    ),
    GoRoute(
      path: '/classes',
      pageBuilder: (context, state) => MaterialPage(
        child: ClassesPage(),
      ),
    ),
    GoRoute(
      path: '/teacher-management',
      pageBuilder: (context, state) => MaterialPage(
        child: TeacherManagementPage(),
      ),
    ),
    GoRoute(
      path: '/student-management',
      pageBuilder: (context, state) => MaterialPage(
        child: StudentManagementPage(),
      ),
    ),
    GoRoute(
      path: '/class-management',
      pageBuilder: (context, state) => MaterialPage(
        child: ClassManagementPage(),
      ),
    ),
    
    GoRoute(
      path: '/class-management/create',
      pageBuilder: (context, state) => MaterialPage(
        child: CreateClassPage(),
      ),
    ),
    GoRoute(
      path: '/teacher-management/create',
      pageBuilder: (context, state) => MaterialPage(
        child: CreateTeacherPage(),
      ),
    ),
    GoRoute(
      path: '/student-management/create',
      pageBuilder: (context, state) => MaterialPage(
        child: CreateStudentPage(),
      ),
    ),
    
    GoRoute(
      path: '/profile',
      pageBuilder: (context, state) => MaterialPage(
        child: ProfilePage(),
      ),
    ),
  ],
);