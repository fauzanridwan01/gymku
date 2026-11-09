import 'package:go_router/go_router.dart';

import '../widgets/common.dart';
import '../screens/auth_screens.dart';
import '../screens/home_screen.dart';
import '../screens/booking_screen.dart';
import '../screens/package_screens.dart';
import '../screens/profile_screens.dart';
import '../screens/target_screens.dart';
import '../screens/freeze_screens.dart';
import '../screens/face_enroll_screen.dart';
import '../screens/admin/admin_common.dart';
import '../screens/admin/admin_dashboard.dart';
import '../screens/admin/admin_members.dart';
import '../screens/admin/admin_scan.dart';
import '../screens/admin/admin_packages.dart';
import '../screens/admin/admin_info.dart';
import '../screens/admin/admin_security.dart';
import 'models.dart';
import 'app_state.dart';

GoRouter buildRouter(AppState app) {
  return GoRouter(
    initialLocation: '/welcome',
    refreshListenable: app,
    redirect: (context, state) {
      final loggedIn = app.currentUser != null;
      final loc = state.matchedLocation;
      final isAuth = loc == '/welcome' || loc == '/login' || loc == '/register';
      if (!loggedIn) return isAuth ? null : '/welcome';
      if (isAuth) return app.isAdmin ? '/admin' : '/home';
      if (app.isAdmin && !loc.startsWith('/admin')) return '/admin';
      if (!app.isAdmin && loc.startsWith('/admin')) return '/home';
      return null;
    },
    routes: [
      GoRoute(path: '/welcome', builder: (_, _) => const WelcomeScreen()),
      GoRoute(path: '/login', builder: (_, _) => const LoginScreen()),
      GoRoute(path: '/register', builder: (_, _) => const RegisterScreen()),

      // Admin: halaman dengan bottom nav
      ShellRoute(
        builder: (_, _, child) => AdminShell(child: child),
        routes: [
          GoRoute(
            path: '/admin',
            builder: (_, _) => const AdminDashboardScreen(),
          ),
          GoRoute(
            path: '/admin/reports',
            builder: (_, _) => const AdminReportsScreen(),
          ),
          GoRoute(
            path: '/admin/scan',
            builder: (_, _) => const AdminScanScreen(),
          ),
          GoRoute(
            path: '/admin/packages',
            builder: (_, _) => const AdminPackagesScreen(),
          ),
          GoRoute(
            path: '/admin/security',
            builder: (_, _) => const AdminSecurityScreen(),
          ),
        ],
      ),
      // Admin: layar penuh
      GoRoute(
        path: '/admin/members',
        builder: (_, _) => const AdminMemberListScreen(),
      ),
      GoRoute(
        path: '/admin/members/:id',
        builder: (_, state) =>
            AdminMemberDetailScreen(userId: state.pathParameters['id']!),
      ),
      GoRoute(
        path: '/admin/search',
        builder: (_, _) => const AdminSearchScreen(),
      ),
      GoRoute(
        path: '/admin/unfreeze',
        builder: (_, _) => const AdminUnfreezeScreen(),
      ),
      GoRoute(path: '/admin/logs', builder: (_, _) => const AdminLogsScreen()),
      GoRoute(
        path: '/admin/promo',
        builder: (_, state) => PromoFormScreen(editing: state.extra as Promo?),
      ),
      GoRoute(
        path: '/admin/info',
        builder: (_, state) =>
            InfoFormScreen(editing: state.extra as Announcement?),
      ),

      // Daftar wajah member (layar penuh)
      GoRoute(
        path: '/face/enroll',
        builder: (_, _) => const FaceEnrollScreen(),
      ),

      // Alur layar penuh (tanpa bottom nav)
      GoRoute(path: '/payment', builder: (_, _) => const PaymentScreen()),
      GoRoute(
        path: '/payment/pay',
        builder: (_, _) => const PaymentInstructionScreen(),
      ),
      GoRoute(
        path: '/payment/success',
        builder: (_, _) => const PaymentSuccessScreen(),
      ),
      GoRoute(path: '/freeze', builder: (_, _) => const FreezeScreen()),
      GoRoute(
        path: '/freeze/status',
        builder: (_, _) => const FreezeStatusScreen(),
      ),

      // Halaman member dengan bottom nav
      ShellRoute(
        builder: (_, _, child) => MemberShell(child: child),
        routes: [
          GoRoute(path: '/home', builder: (_, _) => const HomeScreen()),
          GoRoute(path: '/info', builder: (_, _) => const InfoCenterScreen()),
          GoRoute(path: '/classes', builder: (_, _) => const BookingScreen()),
          GoRoute(path: '/packages', builder: (_, _) => const PackagesScreen()),
          GoRoute(path: '/profile', builder: (_, _) => const ProfileScreen()),
          GoRoute(
            path: '/profile/data',
            builder: (_, _) => const PersonalDataScreen(),
          ),
          GoRoute(
            path: '/profile/password',
            builder: (_, _) => const ChangePasswordScreen(),
          ),
          GoRoute(
            path: '/profile/checkins',
            builder: (_, _) => const CheckInHistoryScreen(),
          ),
          GoRoute(
            path: '/profile/payments',
            builder: (_, _) => const PaymentHistoryScreen(),
          ),
          GoRoute(path: '/target', builder: (_, _) => const TargetScreen()),
          GoRoute(
            path: '/target/new',
            builder: (_, _) => const CreateTargetScreen(),
          ),
        ],
      ),
    ],
  );
}
