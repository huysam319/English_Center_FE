import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../pages/admin/class_management/add_class_session_page.dart';
import '../pages/admin/student_management/add_enrolment.dart';
import '../pages/admin/class_management/class_detail_page.dart';
import '../pages/admin/class_management/create_class_page.dart';
import '../pages/admin/student_management/create_student_page.dart';
import '../pages/admin/teacher_management/create_teacher_page.dart';
import '../pages/admin/student_management/student_detail_page.dart';
import '../pages/admin/teacher_management/teacher_detail_page.dart';
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
import '../pages/side_menu/students/learning_support_page.dart';
import '../pages/side_menu/teachers/classes_page.dart';
import '../pages/side_menu/teachers/exercises_page.dart';
import '../pages/side_menu/teachers/questions_page.dart';
import '../pages/students/flashcard_set_page.dart';
import '../pages/students/learning_support_quiz_page.dart';
import '../pages/students/student_exercise_item_page.dart';
import '../pages/students/student_exercise_submission_page.dart';
import '../pages/students/student_class_item_page.dart';
import '../pages/students/test_item_page.dart';
import '../pages/teachers/ai_reading_assignments_page.dart';
import '../pages/teachers/class_writing_exercise_grade_page.dart';
import '../pages/teachers/create_test_page.dart';
import '../pages/teachers/teacher_class_attendances_page.dart';
import '../pages/teachers/teacher_class_create_exercise_page.dart';
import '../pages/teachers/teacher_class_exercise_detail_page.dart';
import '../pages/teachers/teacher_class_exercises_page.dart';
import '../pages/teachers/teacher_class_item_page.dart';
import '../pages/teachers/teacher_class_students_page.dart';
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
      pageBuilder: (context, state) => MaterialPage(child: LoginPage()),
    ),
    GoRoute(
      path: '/authenticate',
      pageBuilder: (context, state) =>
          MaterialPage(child: AuthenticationPage()),
    ),
    GoRoute(
      path: '/update-account',
      pageBuilder: (context, state) => MaterialPage(child: UpdateAccountPage()),
    ),

    GoRoute(
      path: '/',
      pageBuilder: (context, state) => MaterialPage(child: HomePage()),
    ),
    GoRoute(
      path: '/notification',
      pageBuilder: (context, state) => MaterialPage(child: NotificationPage()),
    ),
    GoRoute(
      path: '/class',
      pageBuilder: (context, state) => MaterialPage(child: ClassPage()),
    ),
    GoRoute(
      path: '/class/exercise',
      pageBuilder: (context, state) => MaterialPage(child: ClassExercisePage()),
    ),
    GoRoute(
      path: '/class/:classId',
      pageBuilder: (context, state) {
        final classId = state.pathParameters['classId'];
        return MaterialPage(
          child: StudentClassItemPage(classId: classId ?? ''),
        );
      },
    ),
    GoRoute(
      path: '/exercise',
      pageBuilder: (context, state) => MaterialPage(child: ExercisePage()),
    ),
    GoRoute(
      path: '/exercise/:exerciseId',
      pageBuilder: (context, state) {
        final exerciseId = state.pathParameters['exerciseId'];
        final attemptId = state.uri.queryParameters['attemptId'];

        if (attemptId != null && attemptId.isNotEmpty) {
          return MaterialPage(
            child: StudentExerciseSubmissionPage(
              exerciseId: exerciseId ?? '',
              attemptId: attemptId,
            ),
          );
        }

        return MaterialPage(
          child: StudentExerciseItemPage(exerciseId: exerciseId ?? ''),
        );
      },
    ),
    GoRoute(
      path: '/test',
      pageBuilder: (context, state) => MaterialPage(child: TestPage()),
    ),
    GoRoute(
      path: '/test/history',
      pageBuilder: (context, state) => MaterialPage(child: TestHistoryPage()),
    ),
    GoRoute(
      path: '/test/:testId',
      pageBuilder: (context, state) {
        final testId = state.pathParameters['testId'];
        return MaterialPage(child: TestItemPage(testId: testId ?? ''));
      },
    ),
    GoRoute(
      path: '/flashcard',
      pageBuilder: (context, state) => MaterialPage(child: FlashcardPage()),
    ),
    GoRoute(
      path: '/flashcard/:flashcardSetId',
      pageBuilder: (context, state) {
        final flashcardSetId = state.pathParameters['flashcardSetId'];
        return MaterialPage(
          child: FlashcardSetPage(flashcardSetId: flashcardSetId ?? ''),
        );
      },
    ),
    GoRoute(
      path: '/ticket',
      pageBuilder: (context, state) =>
          MaterialPage(child: LearningSupportPage()),
    ),
    GoRoute(
      path: '/learning-support',
      pageBuilder: (context, state) =>
          MaterialPage(child: LearningSupportPage()),
    ),
    GoRoute(
      path: '/learning-support/quiz',
      pageBuilder: (context, state) =>
          MaterialPage(child: LearningSupportQuizPage()),
    ),
    GoRoute(
      path: '/exercises',
      pageBuilder: (context, state) => MaterialPage(child: ExercisesPage()),
    ),
    GoRoute(
      path: '/tests',
      pageBuilder: (context, state) => MaterialPage(child: TestsPage()),
    ),
    GoRoute(
      path: '/ai-reading-teacher',
      pageBuilder: (context, state) => MaterialPage(child: ExercisesPage()),
    ),
    GoRoute(
      path: '/ai-reading',
      pageBuilder: (context, state) => MaterialPage(child: ClassExercisePage()),
    ),
    GoRoute(
      path: '/classes/:classId/ai-reading',
      pageBuilder: (context, state) {
        final classId = state.pathParameters['classId'];
        return MaterialPage(child: AiReadingAssignmentsPage(classId: classId));
      },
    ),
    GoRoute(
      path: '/tests/create',
      pageBuilder: (context, state) => MaterialPage(child: CreateTestPage()),
    ),
    GoRoute(
      path: '/questions',
      pageBuilder: (context, state) => MaterialPage(child: QuestionsPage()),
    ),
    GoRoute(
      path: '/classes',
      pageBuilder: (context, state) => MaterialPage(child: ClassesPage()),
    ),
    GoRoute(
      path: '/classes/:classId',
      pageBuilder: (context, state) {
        final classId = state.pathParameters['classId'];
        return MaterialPage(
          child: TeacherClassItemPage(classId: classId ?? ''),
        );
      },
    ),
    GoRoute(
      path: '/classes/:classId/students',
      pageBuilder: (context, state) {
        final classId = state.pathParameters['classId'];
        return MaterialPage(
          child: TeacherClassStudentsPage(classId: classId ?? ''),
        );
      },
    ),
    GoRoute(
      path: '/classes/:classId/exercises',
      pageBuilder: (context, state) {
        final classId = state.pathParameters['classId'];
        return MaterialPage(
          child: TeacherClassExercisesPage(classId: classId ?? ''),
        );
      },
    ),
    GoRoute(
      path: '/classes/:classId/exercises/create',
      pageBuilder: (context, state) {
        final classId = state.pathParameters['classId'];
        return MaterialPage(
          child: TeacherClassCreateExercisePage(classId: classId ?? ''),
        );
      },
    ),
    GoRoute(
      path: '/classes/:classId/exercises/:exerciseId',
      pageBuilder: (context, state) {
        final classId = state.pathParameters['classId'];
        final exerciseId = state.pathParameters['exerciseId'];
        return MaterialPage(
          child: TeacherClassExerciseDetailPage(
            classId: classId ?? '',
            exerciseId: exerciseId ?? '',
          ),
        );
      },
    ),
    GoRoute(
      path: '/classes/:classId/exercises/:exerciseId/grading',
      pageBuilder: (context, state) {
        final classId = state.pathParameters['classId'];
        final exerciseId = state.pathParameters['exerciseId'];
        return MaterialPage(
          child: ClassWritingExerciseGradePage(
            classId: classId ?? '',
            exerciseId: exerciseId ?? '',
          ),
        );
      },
    ),
    GoRoute(
      path: '/classes/:classId/attendances',
      pageBuilder: (context, state) {
        final classId = state.pathParameters['classId'];
        return MaterialPage(
          child: TeacherClassAttendancesPage(classId: classId ?? ''),
        );
      },
    ),

    GoRoute(
      path: '/teacher-management',
      pageBuilder: (context, state) =>
          MaterialPage(child: TeacherManagementPage()),
    ),
    GoRoute(
      path: '/student-management',
      pageBuilder: (context, state) =>
          MaterialPage(child: StudentManagementPage()),
    ),
    GoRoute(
      path: '/class-management',
      pageBuilder: (context, state) =>
          MaterialPage(child: ClassManagementPage()),
    ),

    GoRoute(
      path: '/class-management/create',
      pageBuilder: (context, state) => MaterialPage(child: CreateClassPage()),
    ),
    GoRoute(
      path: '/teacher-management/create',
      pageBuilder: (context, state) => MaterialPage(child: CreateTeacherPage()),
    ),
    GoRoute(
      path: '/student-management/create',
      pageBuilder: (context, state) => MaterialPage(child: CreateStudentPage()),
    ),

    GoRoute(
      path: '/teacher-management/:id',
      pageBuilder: (context, state) {
        final teacherId = state.pathParameters['id'];
        return MaterialPage(child: TeacherDetailPage(id: teacherId ?? ''));
      },
    ),
    GoRoute(
      path: '/student-management/:id',
      pageBuilder: (context, state) {
        final studentId = state.pathParameters['id'];
        return MaterialPage(
          child: StudentDetailPage(studentId: studentId ?? ''),
        );
      },
    ),
    GoRoute(
      path: '/student-management/:id/add-enrolment',
      pageBuilder: (context, state) {
        final studentId = state.pathParameters['id'];
        return MaterialPage(
          child: AddEnrolmentPage(studentId: studentId ?? ''),
        );
      },
    ),
    GoRoute(
      path: '/class-management/:classId',
      pageBuilder: (context, state) {
        final classId = state.pathParameters['classId'];
        return MaterialPage(child: ClassDetailPage(classId: classId ?? ''));
      },
    ),
    GoRoute(
      path: '/class-management/:classId/add-class-session',
      pageBuilder: (context, state) {
        final classId = state.pathParameters['classId'];
        return MaterialPage(child: AddClassSessionPage(classId: classId ?? ''));
      },
    ),

    GoRoute(
      path: '/profile',
      pageBuilder: (context, state) => MaterialPage(child: ProfilePage()),
    ),
  ],
);
