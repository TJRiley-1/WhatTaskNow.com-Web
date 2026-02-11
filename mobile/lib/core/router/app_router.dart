import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../features/auth/screens/welcome_screen.dart';
import '../../features/auth/screens/login_screen.dart';
import '../../features/onboarding/screens/tutorial_screen.dart';
import '../../features/home/screens/home_screen.dart';
import '../../features/add_task/screens/add_type_screen.dart';
import '../../features/add_task/screens/add_time_screen.dart';
import '../../features/add_task/screens/add_social_screen.dart';
import '../../features/add_task/screens/add_energy_screen.dart';
import '../../features/add_task/screens/add_details_screen.dart';
import '../../features/add_task/screens/add_schedule_screen.dart';
import '../../features/multi_add/screens/multi_type_screen.dart';
import '../../features/multi_add/screens/multi_time_screen.dart';
import '../../features/multi_add/screens/multi_social_screen.dart';
import '../../features/multi_add/screens/multi_energy_screen.dart';
import '../../features/multi_add/screens/multi_names_screen.dart';
import '../../features/import_tasks/screens/import_screen.dart';
import '../../features/import_tasks/screens/import_review_screen.dart';
import '../../features/import_tasks/screens/import_setup_screen.dart';
import '../../features/templates/screens/templates_screen.dart';
import '../../features/what_next/screens/state_selection_screen.dart';
import '../../features/what_next/screens/swipe_screen.dart';
import '../../features/what_next/screens/accepted_screen.dart';
import '../../features/timer/screens/timer_screen.dart';
import '../../features/celebration/screens/celebration_screen.dart';
import '../../features/manage_tasks/screens/manage_tasks_screen.dart';
import '../../features/manage_tasks/screens/edit_task_screen.dart';
import '../../features/gallery/screens/gallery_screen.dart';
import '../../features/calendar/screens/calendar_screen.dart';
import '../../features/notifications/screens/notifications_screen.dart';
import '../../features/profile/screens/profile_screen.dart';
import '../../features/groups/screens/groups_screen.dart';
import '../../features/groups/screens/leaderboard_screen.dart';
import '../../features/settings/screens/subscription_screen.dart';
import '../../features/auth/screens/forgot_password_screen.dart';
import '../../features/auth/screens/reset_password_screen.dart';
import '../../features/help/screens/help_screen.dart';
import '../widgets/glass_bottom_nav.dart';
import '../constants/app_colors.dart';
import '../utils/analytics.dart';

final _rootNavigatorKey = GlobalKey<NavigatorState>();
final _shellNavigatorKey = GlobalKey<NavigatorState>();

GoRouter createRouter({required bool isOnboardingComplete}) {
  return GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: isOnboardingComplete ? '/home' : '/welcome',
    observers: [Analytics.observer],
    routes: [
      // --- Auth / Onboarding (no bottom nav) ---
      GoRoute(path: '/welcome', builder: (_, __) => const WelcomeScreen()),
      GoRoute(path: '/login', builder: (_, __) => const LoginScreen()),
      GoRoute(path: '/tutorial', builder: (_, __) => const TutorialScreen()),

      // --- Shell route with bottom nav ---
      ShellRoute(
        navigatorKey: _shellNavigatorKey,
        builder: (context, state, child) => _ShellScaffold(child: child),
        routes: [
          GoRoute(path: '/home', builder: (_, __) => const HomeScreen()),
          GoRoute(path: '/calendar', builder: (_, __) => const CalendarScreen()),
          GoRoute(path: '/add-type', builder: (_, __) => const AddTypeScreen()),
          GoRoute(path: '/gallery', builder: (_, __) => const GalleryScreen()),
          GoRoute(path: '/profile', builder: (_, __) => const ProfileScreen()),
          GoRoute(path: '/manage', builder: (_, __) => const ManageTasksScreen()),
          GoRoute(path: '/notifications', builder: (_, __) => const NotificationsScreen()),
          GoRoute(path: '/groups', builder: (_, __) => const GroupsScreen()),
        ],
      ),

      // --- Full-screen routes (no bottom nav) ---
      GoRoute(path: '/add-time', builder: (_, __) => const AddTimeScreen()),
      GoRoute(path: '/add-social', builder: (_, __) => const AddSocialScreen()),
      GoRoute(path: '/add-energy', builder: (_, __) => const AddEnergyScreen()),
      GoRoute(path: '/add-details', builder: (_, __) => const AddDetailsScreen()),
      GoRoute(path: '/add-schedule', builder: (_, __) => const AddScheduleScreen()),
      GoRoute(path: '/multi-type', builder: (_, __) => const MultiTypeScreen()),
      GoRoute(path: '/multi-time', builder: (_, __) => const MultiTimeScreen()),
      GoRoute(path: '/multi-social', builder: (_, __) => const MultiSocialScreen()),
      GoRoute(path: '/multi-energy', builder: (_, __) => const MultiEnergyScreen()),
      GoRoute(path: '/multi-names', builder: (_, __) => const MultiNamesScreen()),
      GoRoute(path: '/import', builder: (_, __) => const ImportScreen()),
      GoRoute(path: '/import-review', builder: (_, __) => const ImportReviewScreen()),
      GoRoute(path: '/import-setup', builder: (_, __) => const ImportSetupScreen()),
      GoRoute(path: '/templates', builder: (_, __) => const TemplatesScreen()),
      GoRoute(path: '/state', builder: (_, __) => const StateSelectionScreen()),
      GoRoute(path: '/swipe', builder: (_, __) => const SwipeScreen()),
      GoRoute(path: '/accepted', builder: (_, __) => const AcceptedScreen()),
      GoRoute(path: '/timer', builder: (_, __) => const TimerScreen()),
      GoRoute(path: '/celebration', builder: (_, __) => const CelebrationScreen()),
      GoRoute(
        path: '/edit-task/:id',
        builder: (_, state) => EditTaskScreen(taskId: state.pathParameters['id']!),
      ),
      GoRoute(
        path: '/leaderboard/:groupId',
        builder: (_, state) => LeaderboardScreen(groupId: state.pathParameters['groupId']!),
      ),
      GoRoute(path: '/subscription', builder: (_, __) => const SubscriptionScreen()),
      GoRoute(path: '/forgot-password', builder: (_, __) => const ForgotPasswordScreen()),
      GoRoute(path: '/reset-password', builder: (_, __) => const ResetPasswordScreen()),
      GoRoute(path: '/help', builder: (_, __) => const HelpScreen()),
    ],
  );
}

class _ShellScaffold extends StatelessWidget {
  final Widget child;
  const _ShellScaffold({required this.child});

  @override
  Widget build(BuildContext context) {
    final location = GoRouterState.of(context).uri.toString();
    int currentIndex = 0;
    if (location.startsWith('/calendar')) currentIndex = 1;
    if (location.startsWith('/add-type')) currentIndex = 2;
    if (location.startsWith('/gallery')) currentIndex = 3;
    if (location.startsWith('/profile')) currentIndex = 4;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: child,
      bottomNavigationBar: GlassBottomNav(
        currentIndex: currentIndex,
        onTap: (index) {
          switch (index) {
            case 0: context.go('/home');
            case 1: context.go('/calendar');
            case 2: context.go('/add-type');
            case 3: context.go('/gallery');
            case 4: context.go('/profile');
          }
        },
      ),
    );
  }
}
