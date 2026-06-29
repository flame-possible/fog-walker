import 'package:flutter/foundation.dart';
import 'package:hive/hive.dart';

enum MapStyle {
  street,
  light,
  dark;

  String get labelKo {
    switch (this) {
      case MapStyle.street:
        return '기본';
      case MapStyle.light:
        return '밝음';
      case MapStyle.dark:
        return '다크';
    }
  }

  String get tileUrlTemplate {
    switch (this) {
      case MapStyle.street:
        return 'https://tile.openstreetmap.org/{z}/{x}/{y}.png';
      case MapStyle.light:
        return 'https://a.basemaps.cartocdn.com/light_all/{z}/{x}/{y}.png';
      case MapStyle.dark:
        return 'https://a.basemaps.cartocdn.com/dark_all/{z}/{x}/{y}.png';
    }
  }

  static MapStyle fromName(String? name) {
    for (final style in MapStyle.values) {
      if (style.name == name) return style;
    }
    return MapStyle.street;
  }
}

class AppSettingsProvider extends ChangeNotifier {
  AppSettingsProvider({Box<dynamic>? box}) : _box = box {
    _highAccuracy = _box?.get(_highAccuracyKey) as bool? ?? true;
    _autoRecord = _box?.get(_autoRecordKey) as bool? ?? true;
    _mapStyle = MapStyle.fromName(_box?.get(_mapStyleKey) as String?);
  }

  static const _highAccuracyKey = 'highAccuracy';
  static const _autoRecordKey = 'autoRecord';
  static const _mapStyleKey = 'mapStyle';

  final Box<dynamic>? _box;

  late bool _highAccuracy;
  late bool _autoRecord;
  late MapStyle _mapStyle;

  bool get highAccuracy => _highAccuracy;
  bool get autoRecord => _autoRecord;
  MapStyle get mapStyle => _mapStyle;

  void setHighAccuracy(bool value) {
    if (_highAccuracy == value) return;
    _highAccuracy = value;
    _box?.put(_highAccuracyKey, value);
    notifyListeners();
  }

  void setAutoRecord(bool value) {
    if (_autoRecord == value) return;
    _autoRecord = value;
    _box?.put(_autoRecordKey, value);
    notifyListeners();
  }

  void setMapStyle(MapStyle value) {
    if (_mapStyle == value) return;
    _mapStyle = value;
    _box?.put(_mapStyleKey, value.name);
    notifyListeners();
  }
}
