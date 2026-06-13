/// 한글 행정동/자치구 이름을 로마자로 변환.
///
/// 국립국어원 로마자 표기법(2000)을 단순 적용. 음운 변화(자음동화 등)는
/// 완벽히 반영하지 않지만 지명 표기에는 충분한 수준. 잘 알려진 동/구는
/// [knownRomanizations] 사전으로 정확히 덮어쓴다.
library;

/// 초성/중성/종성 로마자 표.
const _initials = [
  'g', 'kk', 'n', 'd', 'tt', 'r', 'm', 'b', 'pp',
  's', 'ss', '', 'j', 'jj', 'ch', 'k', 't', 'p', 'h',
];

const _medials = [
  'a', 'ae', 'ya', 'yae', 'eo', 'e', 'yeo', 'ye', 'o', 'wa',
  'wae', 'oe', 'yo', 'u', 'wo', 'we', 'wi', 'yu', 'eu', 'ui', 'i',
];

// 종성은 'ㄱ→k, ㄴ→n' 식 받침 로마자. 빈 문자열은 받침 없음.
const _finals = [
  '', 'k', 'k', 'k', 'n', 'n', 'n', 't', 'l', 'l',
  'l', 'l', 'l', 'l', 'l', 'l', 'm', 'p', 'p', 't',
  't', 'ng', 't', 't', 'k', 't', 'p', 't',
];

/// 한 글자(음절)를 로마자로. 한글이 아니면 그대로 반환.
String _romanizeChar(int code) {
  if (code < 0xAC00 || code > 0xD7A3) return String.fromCharCode(code);
  final s = code - 0xAC00;
  final ini = s ~/ (21 * 28);
  final med = (s % (21 * 28)) ~/ 28;
  final fin = s % 28;
  return _initials[ini] + _medials[med] + _finals[fin];
}

/// 자주 쓰이는 자치구/동의 정확한 영문 표기.
const Map<String, String> knownRomanizations = {
  // 자치구
  '종로구': 'Jongno-gu',
  '중구': 'Jung-gu',
  '용산구': 'Yongsan-gu',
  '성동구': 'Seongdong-gu',
  '광진구': 'Gwangjin-gu',
  '동대문구': 'Dongdaemun-gu',
  '중랑구': 'Jungnang-gu',
  '성북구': 'Seongbuk-gu',
  '강북구': 'Gangbuk-gu',
  '도봉구': 'Dobong-gu',
  '노원구': 'Nowon-gu',
  '은평구': 'Eunpyeong-gu',
  '서대문구': 'Seodaemun-gu',
  '마포구': 'Mapo-gu',
  '양천구': 'Yangcheon-gu',
  '강서구': 'Gangseo-gu',
  '구로구': 'Guro-gu',
  '금천구': 'Geumcheon-gu',
  '영등포구': 'Yeongdeungpo-gu',
  '동작구': 'Dongjak-gu',
  '관악구': 'Gwanak-gu',
  '서초구': 'Seocho-gu',
  '강남구': 'Gangnam-gu',
  '송파구': 'Songpa-gu',
  '강동구': 'Gangdong-gu',
  // 잘 알려진 동
  '한남동': 'Hannam-dong',
  '이태원동': 'Itaewon-dong',
  '사직동': 'Sajik-dong',
  '삼청동': 'Samcheong-dong',
  '청운효자동': 'Cheongunhyoja-dong',
  '가회동': 'Gahoe-dong',
  '소공동': 'Sogong-dong',
  '명동': 'Myeong-dong',
  '회현동': 'Hoehyeon-dong',
  '약수동': 'Yaksu-dong',
  '여의동': 'Yeouido-dong',
  '신사동': 'Sinsa-dong',
  '압구정동': 'Apgujeong-dong',
  '청담동': 'Cheongdam-dong',
  '역삼동': 'Yeoksam-dong',
  '삼성동': 'Samseong-dong',
  '논현동': 'Nonhyeon-dong',
  '서교동': 'Seogyo-dong',
  '연남동': 'Yeonnam-dong',
  '망원동': 'Mangwon-dong',
  '성수동': 'Seongsu-dong',
  '잠실동': 'Jamsil-dong',
};

/// 동/구 한글명을 영문으로. 알려진 표기가 있으면 그걸, 없으면 자동 변환.
String romanizeDong(String ko) {
  if (knownRomanizations.containsKey(ko)) return knownRomanizations[ko]!;

  // 접미사 분리: '동'/'구'/'가' 등을 하이픈으로 처리
  String suffix = '';
  String stem = ko;
  for (final suf in ['동', '구', '가', '읍', '면', '리']) {
    if (ko.endsWith(suf) && ko.length > 1) {
      suffix = '-${_suffixRoman(suf)}';
      stem = ko.substring(0, ko.length - 1);
      break;
    }
  }

  final buf = StringBuffer();
  for (final c in stem.runes) {
    buf.write(_romanizeChar(c));
  }
  var roman = buf.toString();
  // 숫자 동(예: 사직동, 신당5동) — 숫자는 그대로 유지됨
  if (roman.isEmpty) return ko;
  // 첫 글자 대문자
  roman = roman[0].toUpperCase() + roman.substring(1);
  return roman + suffix;
}

String _suffixRoman(String suf) {
  switch (suf) {
    case '동':
      return 'dong';
    case '구':
      return 'gu';
    case '가':
      return 'ga';
    case '읍':
      return 'eup';
    case '면':
      return 'myeon';
    case '리':
      return 'ri';
    default:
      return '';
  }
}
