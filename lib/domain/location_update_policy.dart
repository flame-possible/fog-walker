/// 위치 신호를 어디까지 앱에 반영할지 판단한다.
///
/// 브라우저 위치는 GPS가 아니라 Wi-Fi/IP 기반일 수 있어 정확도가 수백 m 이상으로
/// 나오는 경우가 많다. 이런 신호도 지도 중심과 마커에는 유용하지만, 안개 해금에는
/// 너무 넓은 오차를 만들 수 있어 더 엄격하게 걸러낸다.
class LocationUpdatePolicy {
  LocationUpdatePolicy._();

  static const double maxFogAccuracyMeters = 50;

  static bool canUpdateMap({required double accuracy}) {
    return accuracy.isFinite && accuracy >= 0;
  }

  static bool canClearFog({required double accuracy}) {
    return canUpdateMap(accuracy: accuracy) && accuracy <= maxFogAccuracyMeters;
  }
}
