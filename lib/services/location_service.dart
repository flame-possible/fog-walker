import 'package:geolocator/geolocator.dart';

/// 위치 권한/서비스 상태를 앱 관점으로 단순화한 enum.
enum LocationStatus {
  /// 권한·서비스 모두 정상.
  ready,

  /// 위치 서비스(GPS) 자체가 꺼져 있음.
  serviceDisabled,

  /// 권한 거부됨 (다시 요청 가능).
  denied,

  /// 영구 거부됨 (앱 설정에서 켜야 함).
  deniedForever,
}

/// geolocator를 감싼 위치 서비스.
///
/// 권한 흐름과 위치 스트림 설정을 한곳에 모은다. 노이즈 필터(정확도/순간이동)는
/// 이 스트림을 받는 FogProvider에서 적용한다 — 서비스는 원시 위치만 제공.
class LocationService {
  /// 현재 권한·서비스 상태를 확인하고, 필요 시 권한을 요청한다.
  Future<LocationStatus> ensurePermission() async {
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return LocationStatus.serviceDisabled;

    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    if (permission == LocationPermission.deniedForever) {
      return LocationStatus.deniedForever;
    }
    if (permission == LocationPermission.denied) {
      return LocationStatus.denied;
    }
    return LocationStatus.ready;
  }

  /// 위치 변경 스트림. 10m 이상 움직였을 때만 이벤트(배터리·노이즈 절감).
  Stream<Position> positionStream({bool highAccuracy = true}) {
    final settings = LocationSettings(
      accuracy: highAccuracy ? LocationAccuracy.high : LocationAccuracy.medium,
      distanceFilter: highAccuracy ? 10 : 25,
    );
    return Geolocator.getPositionStream(locationSettings: settings);
  }

  /// 현재 위치 1회 조회 (지도 초기 중심용).
  ///
  /// 브라우저 권한 거부, 타임아웃, 플랫폼 미지원 등은 지도 초기화 전체를
  /// 멈추지 않도록 null로 접는다.
  Future<Position?> currentPosition({bool highAccuracy = true}) async {
    try {
      return await Geolocator.getCurrentPosition(
        locationSettings: LocationSettings(
          accuracy: highAccuracy
              ? LocationAccuracy.high
              : LocationAccuracy.medium,
          timeLimit: const Duration(seconds: 12),
        ),
      );
    } catch (_) {
      return null;
    }
  }

  /// 마지막으로 알려진 위치 (빠른 초기화용, 없으면 null).
  ///
  /// 웹 등 일부 플랫폼은 getLastKnownPosition을 지원하지 않으므로 예외를
  /// 삼키고 null을 반환한다. (초기 중심은 currentPosition으로 보완)
  Future<Position?> lastKnown() async {
    try {
      return await Geolocator.getLastKnownPosition();
    } catch (_) {
      return null;
    }
  }

  /// 앱 설정 화면 열기 (영구 거부 시).
  ///
  /// 웹은 이 API를 지원하지 않으므로 false로 반환한다.
  Future<bool> openAppSettings() async {
    try {
      return await Geolocator.openAppSettings();
    } catch (_) {
      return false;
    }
  }
}
