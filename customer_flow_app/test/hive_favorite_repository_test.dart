import 'dart:io';

import 'package:customer_flow_app/features/favorites/data/repositories/hive_favorite_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_ce/hive.dart';

void main() {
  test(
    'stores favorite service ids locally and separates each account',
    () async {
      final directory = await Directory.systemTemp.createTemp(
        'servify_favorite',
      );
      Hive.init(directory.path);
      final box = await Hive.openBox<dynamic>('favorites_test');
      addTearDown(() async {
        await box.close();
        await directory.delete(recursive: true);
      });

      var ownerId = 'customer-a';
      final repository = HiveFavoriteRepository(
        box: box,
        ownerId: () => ownerId,
      );

      expect(await repository.getFavoriteServiceIds(), isEmpty);
      expect(await repository.toggleFavorite('service-1'), {'service-1'});

      final reloadedRepository = HiveFavoriteRepository(
        box: box,
        ownerId: () => ownerId,
      );
      expect(await reloadedRepository.getFavoriteServiceIds(), {'service-1'});

      ownerId = 'customer-b';
      expect(await repository.getFavoriteServiceIds(), isEmpty);

      ownerId = 'customer-a';
      expect(await repository.toggleFavorite('service-1'), isEmpty);
    },
  );
}
