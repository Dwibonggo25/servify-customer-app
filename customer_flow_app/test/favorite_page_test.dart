import 'dart:typed_data';

import 'package:customer_flow_app/features/favorites/domain/repositories/favorite_repository.dart';
import 'package:customer_flow_app/features/favorites/presentation/cubit/favorite_cubit.dart';
import 'package:customer_flow_app/features/favorites/presentation/ui/favorite_page.dart';
import 'package:customer_flow_app/features/services/domain/entities/service_draft.dart';
import 'package:customer_flow_app/features/services/domain/entities/service_item.dart';
import 'package:customer_flow_app/features/services/domain/repositories/service_repository.dart';
import 'package:customer_flow_app/features/services/presentation/cubit/service_catalog_cubit.dart';
import 'package:customer_flow_app/libraries/core/localization/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('favorite page fits an iPhone-sized screen', (tester) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('id'),
        supportedLocales: AppLocalizations.supportedLocales,
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        home: MultiBlocProvider(
          providers: [
            BlocProvider(
              create: (_) => FavoriteCubit(_FakeFavoriteRepository())..load(),
            ),
            BlocProvider(
              create: (_) =>
                  ServiceCatalogCubit(_FakeServiceRepository())..load(),
            ),
          ],
          child: const FavoritePage(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Favorit'), findsWidgets);
    expect(find.text('1 layanan tersimpan'), findsOneWidget);
    expect(find.text('Kebersihan Rumah'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}

final _service = ServiceItem(
  id: 'service-1',
  categoryId: 'category-1',
  name: 'Kebersihan Rumah',
  slug: 'kebersihan-rumah',
  shortDescription: 'Rumah bersih tanpa repot bersama tenaga profesional.',
  description: 'Layanan kebersihan rumah.',
  category: 'Kebersihan',
  price: 150000,
  durationMinutes: 120,
  rating: 4.8,
  reviewCount: 32,
  icon: Icons.cleaning_services_rounded,
  imageUrl: null,
  color: const Color(0xFF4F46E5),
  includes: const ['Peralatan kebersihan'],
  isActive: true,
);

final class _FakeFavoriteRepository implements FavoriteRepository {
  Set<String> ids = {'service-1'};

  @override
  Future<Set<String>> getFavoriteServiceIds() async => Set.of(ids);

  @override
  Future<Set<String>> toggleFavorite(String serviceId) async {
    ids = Set.of(ids);
    if (!ids.add(serviceId)) ids.remove(serviceId);
    return Set.of(ids);
  }
}

final class _FakeServiceRepository implements ServiceRepository {
  @override
  Future<List<ServiceItem>> getActiveServices() async => [_service];

  @override
  Future<ServiceItem?> getActiveServiceById(String id) async => _service;

  @override
  Future<List<ServiceItem>> getAllServicesForAdmin() async => [_service];

  @override
  Future<String> saveService({String? id, required ServiceDraft draft}) =>
      throw UnimplementedError();

  @override
  Future<String> uploadServiceImage({
    required Uint8List bytes,
    required String fileExtension,
  }) => throw UnimplementedError();

  @override
  Future<void> deleteService(String id) => throw UnimplementedError();
}
