import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/domain/repositories/auth_repository.dart';
import '../../features/auth/presentation/bloc/auth_bloc.dart';
import '../../features/auth/presentation/ui/login_page.dart';
import '../../features/auth/presentation/ui/register_page.dart';
import '../../features/bookings/domain/entities/booking_draft.dart';
import '../../features/bookings/presentation/ui/booking_confirmation_page.dart';
import '../../features/bookings/presentation/ui/booking_form_page.dart';
import '../../features/bookings/presentation/ui/booking_history_page.dart';
import '../../features/home/presentation/ui/home_page.dart';
import '../../features/onboarding/presentation/ui/onboarding_page.dart';
import '../../features/profile/domain/repositories/profile_repository.dart';
import '../../features/profile/presentation/cubit/profile_cubit.dart';
import '../../features/profile/presentation/ui/profile_page.dart';
import '../../features/services/data/mock_service_catalog.dart';
import '../../features/services/domain/repositories/service_category_repository.dart';
import '../../features/services/presentation/cubit/service_category_cubit.dart';
import '../../features/services/presentation/ui/service_detail_page.dart';
import '../../features/services/presentation/ui/service_list_page.dart';
import '../../features/splash/presentation/ui/splash_page.dart';
import '../session/app_session_controller.dart';

final class AppRouter {
  AppRouter({
    required AppSessionController sessionController,
    required AuthRepository authRepository,
    required ProfileRepository profileRepository,
    required ServiceCategoryRepository serviceCategoryRepository,
  }) : _sessionController = sessionController,
       router = GoRouter(
         initialLocation: '/',
         refreshListenable: sessionController,
         redirect: (context, state) {
           final location = state.matchedLocation;
           if (location == '/') return null;

           if (!sessionController.onboardingCompleted) {
             return location == '/onboarding' ? null : '/onboarding';
           }

           if (location == '/onboarding') {
             return sessionController.isAuthenticated ? '/home' : '/login';
           }

           final isAuthRoute = location == '/login' || location == '/register';
           if (!sessionController.isAuthenticated && !isAuthRoute) {
             return '/login';
           }
           if (sessionController.isAuthenticated && isAuthRoute) {
             return '/home';
           }
           return null;
         },
         routes: [
           GoRoute(
             path: '/',
             builder: (context, state) =>
                 SplashPage(sessionController: sessionController),
           ),
           GoRoute(
             path: '/onboarding',
             builder: (context, state) =>
                 OnboardingPage(sessionController: sessionController),
           ),
           GoRoute(
             path: '/login',
             builder: (context, state) => BlocProvider(
               create: (_) => AuthBloc(authRepository),
               child: const LoginPage(),
             ),
           ),
           GoRoute(
             path: '/register',
             builder: (context, state) => BlocProvider(
               create: (_) => AuthBloc(authRepository),
               child: const RegisterPage(),
             ),
           ),
           GoRoute(
             path: '/home',
             builder: (context, state) => MultiBlocProvider(
               providers: [
                 BlocProvider(create: (_) => AuthBloc(authRepository)),
                 BlocProvider(
                   create: (_) =>
                       ServiceCategoryCubit(serviceCategoryRepository)..load(),
                 ),
               ],
               child: HomePage(sessionController: sessionController),
             ),
           ),
           GoRoute(
             path: '/services',
             builder: (context, state) => BlocProvider(
               create: (_) =>
                   ServiceCategoryCubit(serviceCategoryRepository)..load(),
               child: ServiceListPage(
                 initialCategory: state.uri.queryParameters['category'],
               ),
             ),
           ),
           GoRoute(
             path: '/services/:serviceId',
             builder: (context, state) {
               final service = MockServiceCatalog.findById(
                 state.pathParameters['serviceId'] ?? '',
               );
               return service == null
                   ? const _MissingRouteDataPage()
                   : ServiceDetailPage(service: service);
             },
           ),
           GoRoute(
             path: '/services/:serviceId/book',
             builder: (context, state) {
               final service = MockServiceCatalog.findById(
                 state.pathParameters['serviceId'] ?? '',
               );
               return service == null
                   ? const _MissingRouteDataPage()
                   : BookingFormPage(
                       service: service,
                       initialCustomerName:
                           sessionController.currentUser?.fullName ?? '',
                     );
             },
           ),
           GoRoute(
             path: '/booking/confirmation',
             builder: (context, state) {
               final booking = state.extra;
               return booking is BookingDraft
                   ? BookingConfirmationPage(booking: booking)
                   : const _MissingRouteDataPage();
             },
           ),
           GoRoute(
             path: '/orders',
             builder: (context, state) => BookingHistoryPage(
               latestBooking: state.extra is BookingDraft
                   ? state.extra! as BookingDraft
                   : null,
             ),
           ),
           GoRoute(
             path: '/profile',
             builder: (context, state) => MultiBlocProvider(
               providers: [
                 BlocProvider(
                   create: (_) => ProfileCubit(profileRepository)..load(),
                 ),
                 BlocProvider(create: (_) => AuthBloc(authRepository)),
               ],
               child: const ProfilePage(),
             ),
           ),
         ],
       );

  final AppSessionController _sessionController;
  final GoRouter router;

  void dispose() {
    router.dispose();
    _sessionController.dispose();
  }
}

final class _MissingRouteDataPage extends StatelessWidget {
  const _MissingRouteDataPage();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline_rounded, size: 52),
              const SizedBox(height: 12),
              const Text('Data halaman tidak ditemukan.'),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: () => context.go('/home'),
                child: const Text('Kembali ke beranda'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
