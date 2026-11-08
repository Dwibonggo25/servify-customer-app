import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/domain/repositories/auth_repository.dart';
import '../../features/auth/presentation/bloc/auth_bloc.dart';
import '../../features/auth/presentation/ui/login_page.dart';
import '../../features/auth/presentation/ui/register_page.dart';
import '../../features/auth/presentation/ui/role_gate_page.dart';
import '../../features/bookings/domain/entities/booking_record.dart';
import '../../features/bookings/domain/repositories/booking_repository.dart';
import '../../features/bookings/presentation/ui/booking_confirmation_page.dart';
import '../../features/bookings/presentation/ui/booking_detail_page.dart';
import '../../features/bookings/presentation/ui/booking_form_page.dart';
import '../../features/bookings/presentation/ui/booking_history_page.dart';
import '../../features/home/presentation/ui/home_page.dart';
import '../../features/notifications/domain/repositories/notification_repository.dart';
import '../../features/notifications/presentation/ui/notification_page.dart';
import '../../features/onboarding/presentation/ui/onboarding_page.dart';
import '../../features/profile/domain/repositories/profile_repository.dart';
import '../../features/profile/presentation/cubit/profile_cubit.dart';
import '../../features/profile/presentation/ui/profile_page.dart';
import '../../features/services/domain/repositories/service_category_repository.dart';
import '../../features/services/domain/repositories/service_repository.dart';
import '../../features/services/domain/entities/service_item.dart';
import '../../features/services/presentation/cubit/service_catalog_cubit.dart';
import '../../features/services/presentation/cubit/service_category_cubit.dart';
import '../../features/services/presentation/ui/service_detail_page.dart';
import '../../features/services/presentation/ui/service_list_page.dart';
import '../../features/splash/presentation/ui/splash_page.dart';
import '../../features/staff/presentation/ui/staff_dashboard_page.dart';
import '../../features/staff/presentation/ui/staff_profile_page.dart';
import '../session/app_session_controller.dart';

final class AppRouter {
  AppRouter({
    required AppSessionController sessionController,
    required AuthRepository authRepository,
    required BookingRepository bookingRepository,
    required NotificationRepository notificationRepository,
    required ProfileRepository profileRepository,
    required ServiceCategoryRepository serviceCategoryRepository,
    required ServiceRepository serviceRepository,
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
             return '/gate';
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
             path: '/gate',
             builder: (context, state) =>
                 RoleGatePage(profileRepository: profileRepository),
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
             builder: (context, state) => MultiBlocProvider(
               providers: [
                 BlocProvider(
                   create: (_) =>
                       ServiceCategoryCubit(serviceCategoryRepository)..load(),
                 ),
                 BlocProvider(
                   create: (_) =>
                       ServiceCatalogCubit(serviceRepository)..load(),
                 ),
               ],
               child: ServiceListPage(
                 initialCategory: state.uri.queryParameters['category'],
               ),
             ),
           ),
           GoRoute(
             path: '/services/:serviceId',
             builder: (context, state) {
               final serviceId = state.pathParameters['serviceId'] ?? '';
               return _ServiceLoaderPage(
                 serviceId: serviceId,
                 serviceRepository: serviceRepository,
                 builder: (service) => ServiceDetailPage(service: service),
               );
             },
           ),
           GoRoute(
             path: '/services/:serviceId/book',
             builder: (context, state) {
               final serviceId = state.pathParameters['serviceId'] ?? '';
               return _ServiceLoaderPage(
                 serviceId: serviceId,
                 serviceRepository: serviceRepository,
                 builder: (service) => BookingFormPage(
                   service: service,
                   bookingRepository: bookingRepository,
                   initialCustomerName:
                       sessionController.currentUser?.fullName ?? '',
                 ),
               );
             },
           ),
           GoRoute(
             path: '/booking/confirmation',
             builder: (context, state) {
               final booking = state.extra;
               return booking is BookingRecord
                   ? BookingConfirmationPage(booking: booking)
                   : const _MissingRouteDataPage();
             },
           ),
           GoRoute(
             path: '/orders',
             builder: (context, state) =>
                 BookingHistoryPage(repository: bookingRepository),
           ),
           GoRoute(
             path: '/orders/:bookingId',
             builder: (context, state) => BookingDetailPage(
               bookingId: state.pathParameters['bookingId'] ?? '',
               repository: bookingRepository,
             ),
           ),
           GoRoute(
             path: '/notifications',
             builder: (context, state) => NotificationPage(
               repository: notificationRepository,
               staffMode: false,
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
           GoRoute(
             path: '/staff',
             builder: (context, state) =>
                 StaffDashboardPage(repository: bookingRepository),
           ),
           GoRoute(
             path: '/staff/incoming',
             builder: (context, state) => StaffBookingListPage(
               repository: bookingRepository,
               historyMode: false,
             ),
           ),
           GoRoute(
             path: '/staff/history',
             builder: (context, state) => StaffBookingListPage(
               repository: bookingRepository,
               historyMode: true,
             ),
           ),
           GoRoute(
             path: '/staff/bookings/:bookingId',
             builder: (context, state) => BookingDetailPage(
               bookingId: state.pathParameters['bookingId'] ?? '',
               repository: bookingRepository,
               staffMode: true,
             ),
           ),
           GoRoute(
             path: '/staff/notifications',
             builder: (context, state) => NotificationPage(
               repository: notificationRepository,
               staffMode: true,
             ),
           ),
           GoRoute(
             path: '/staff/profile',
             builder: (context, state) => StaffProfilePage(
               profileRepository: profileRepository,
               authRepository: authRepository,
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

final class _ServiceLoaderPage extends StatefulWidget {
  const _ServiceLoaderPage({
    required this.serviceId,
    required this.serviceRepository,
    required this.builder,
  });

  final String serviceId;
  final ServiceRepository serviceRepository;
  final Widget Function(ServiceItem service) builder;

  @override
  State<_ServiceLoaderPage> createState() => _ServiceLoaderPageState();
}

final class _ServiceLoaderPageState extends State<_ServiceLoaderPage> {
  late Future<ServiceItem?> _serviceFuture;

  @override
  void initState() {
    super.initState();
    _load();
  }

  void _load() {
    _serviceFuture = widget.serviceRepository.getActiveServiceById(
      widget.serviceId,
    );
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<ServiceItem?>(
      future: _serviceFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        if (snapshot.hasError) {
          return Scaffold(
            appBar: AppBar(),
            body: Center(
              child: FilledButton.icon(
                onPressed: () => setState(_load),
                icon: const Icon(Icons.refresh_rounded),
                label: const Text('Coba lagi'),
              ),
            ),
          );
        }
        final service = snapshot.data;
        return service == null
            ? const _MissingRouteDataPage()
            : widget.builder(service);
      },
    );
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
