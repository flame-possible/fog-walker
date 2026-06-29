import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:fog_walker/providers/app_settings_provider.dart';

void main() {
  late Directory tempDir;
  late Box<dynamic> box;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('fogwalker_settings_test');
    Hive.init(tempDir.path);
    box = await Hive.openBox<dynamic>('appSettings_test');
  });

  tearDown(() async {
    await box.clear();
    await box.close();
    await tempDir.delete(recursive: true);
  });

  group('AppSettingsProvider', () {
    test('starts with walking-focused defaults', () {
      final provider = AppSettingsProvider(box: box);

      expect(provider.highAccuracy, isTrue);
      expect(provider.autoRecord, isTrue);
      expect(provider.mapStyle, MapStyle.street);
    });

    test('persists high accuracy, auto record, and map style choices', () {
      final provider = AppSettingsProvider(box: box);

      provider.setHighAccuracy(false);
      provider.setAutoRecord(false);
      provider.setMapStyle(MapStyle.dark);

      final restored = AppSettingsProvider(box: box);
      expect(restored.highAccuracy, isFalse);
      expect(restored.autoRecord, isFalse);
      expect(restored.mapStyle, MapStyle.dark);
    });

    test('map styles expose real tile URLs', () {
      expect(MapStyle.street.tileUrlTemplate, contains('openstreetmap.org'));
      expect(MapStyle.light.tileUrlTemplate, contains('basemaps.cartocdn.com'));
      expect(MapStyle.dark.tileUrlTemplate, contains('dark_all'));
    });
  });
}
