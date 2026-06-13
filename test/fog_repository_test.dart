import 'package:flutter_test/flutter_test.dart';
import 'package:fog_walker/data/fog_repository.dart';

void main() {
  group('FogRepository 키 직렬화', () {
    test('셀 → 키 → 셀 왕복이 보존된다', () {
      const cells = [(0, 0), (1234, 5678), (-12, -34), (-1, 9999)];
      for (final c in cells) {
        final key = FogRepository.keyOf(c);
        expect(FogRepository.parseKey(key), c);
      }
    });

    test('키 형식이 예상대로다', () {
      expect(FogRepository.keyOf((12, -3)), '12,-3');
    });

    test('깨진 키는 null을 반환한다', () {
      expect(FogRepository.parseKey('not-a-cell'), isNull);
      expect(FogRepository.parseKey('1,2,3'), isNull);
      expect(FogRepository.parseKey('1'), isNull);
      expect(FogRepository.parseKey('a,b'), isNull);
    });
  });
}
