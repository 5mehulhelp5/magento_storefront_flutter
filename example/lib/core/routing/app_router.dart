import 'package:go_router/go_router.dart';
import '../../services/magento_service.dart';
import '../../features/splash/splash_screen.dart';
import '../../features/auth/auth_screen.dart';
import '../../features/dashboard/dashboard_screen.dart';
import '../../features/dashboard/config_screen.dart';
import '../../features/cart/cart_screen.dart';
import '../../features/products/products_screen.dart';
import '../../features/store/store_info_screen.dart';

class AppRouter {
  static final router = GoRouter(
    initialLocation: '/splash',
    debugLogDiagnostics: true,
    redirect: (context, state) {
      final isInitialized = MagentoService.isInitialized;
      final isSplash = state.matchedLocation == '/splash';
      final isConfig = state.matchedLocation == '/config';

      if (!isInitialized && !isConfig && !isSplash) {
        return '/config';
      }
      return null;
    },
    routes: [
      GoRoute(
        path: '/splash',
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: '/config',
        builder: (context, state) => const ConfigScreen(),
      ),
      GoRoute(
        path: '/auth',
        builder: (context, state) => const AuthScreen(),
      ),
      GoRoute(
        path: '/cart',
        builder: (context, state) => const CartScreen(),
      ),
      GoRoute(
        path: '/',
        builder: (context, state) => const DashboardScreen(),
        routes: [
          GoRoute(
            path: 'products',
            builder: (context, state) => const ProductsScreen(),
          ),
          GoRoute(
            path: 'store-info',
            builder: (context, state) => const StoreInfoScreen(),
          ),
        ],
      ),
    ],
  );
}



