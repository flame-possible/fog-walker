import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:geolocator/geolocator.dart';
import 'package:fog_walker/services/location_service.dart';

void main() {
  late GeolocatorPlatform originalPlatform;
  late FakeGeolocatorPlatform fakePlatform;

  setUp(() {
    originalPlatform = GeolocatorPlatform.instance;
    fakePlatform = FakeGeolocatorPlatform();
    GeolocatorPlatform.instance = fakePlatform;
  });

  tearDown(() {
    GeolocatorPlatform.instance = originalPlatform;
  });

  test(
    'openAppSettings returns false when platform settings are unsupported',
    () async {
      fakePlatform.openAppSettingsError = UnsupportedError('web unsupported');

      final opened = await LocationService().openAppSettings();

      expect(opened, isFalse);
    },
  );

  test(
    'currentPosition returns null when platform position lookup fails',
    () async {
      fakePlatform.currentPositionError = TimeoutException('no position');

      final position = await LocationService().currentPosition();

      expect(position, isNull);
    },
  );

  test('currentPosition returns platform position when available', () async {
    fakePlatform.currentPosition = _position(latitude: 37.5, longitude: 127.0);

    final position = await LocationService().currentPosition();

    expect(position?.latitude, 37.5);
    expect(position?.longitude, 127.0);
  });

  test('uses high accuracy when high accuracy mode is enabled', () async {
    await LocationService().currentPosition(highAccuracy: true);

    expect(
      fakePlatform.lastCurrentPositionSettings?.accuracy,
      LocationAccuracy.high,
    );
  });

  test('uses medium accuracy when high accuracy mode is disabled', () async {
    LocationService().positionStream(highAccuracy: false);

    expect(fakePlatform.lastStreamSettings?.accuracy, LocationAccuracy.medium);
  });
}

class FakeGeolocatorPlatform extends GeolocatorPlatform {
  bool serviceEnabled = true;
  LocationPermission permission = LocationPermission.whileInUse;
  bool openAppSettingsResult = true;
  Object? openAppSettingsError;
  Position? currentPosition;
  Object? currentPositionError;
  LocationSettings? lastCurrentPositionSettings;
  LocationSettings? lastStreamSettings;

  @override
  Future<bool> isLocationServiceEnabled() async => serviceEnabled;

  @override
  Future<LocationPermission> checkPermission() async => permission;

  @override
  Future<LocationPermission> requestPermission() async => permission;

  @override
  Future<bool> openAppSettings() async {
    final error = openAppSettingsError;
    if (error != null) throw error;
    return openAppSettingsResult;
  }

  @override
  Future<Position> getCurrentPosition({LocationSettings? locationSettings}) {
    lastCurrentPositionSettings = locationSettings;
    final error = currentPositionError;
    if (error != null) return Future.error(error);
    return Future.value(currentPosition ?? _position());
  }

  @override
  Future<Position?> getLastKnownPosition({
    bool forceLocationManager = false,
  }) async {
    return null;
  }

  @override
  Stream<Position> getPositionStream({LocationSettings? locationSettings}) {
    lastStreamSettings = locationSettings;
    return const Stream.empty();
  }
}

Position _position({double latitude = 37.0, double longitude = 127.0}) {
  return Position(
    longitude: longitude,
    latitude: latitude,
    timestamp: DateTime(2026, 6, 28),
    accuracy: 5,
    altitude: 0,
    altitudeAccuracy: 0,
    heading: 0,
    headingAccuracy: 0,
    speed: 0,
    speedAccuracy: 0,
  );
}
