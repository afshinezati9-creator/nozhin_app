/// تبدیل عدد به حروف فارسی (تومان)
class PersianAmountWords {
  PersianAmountWords._();

  static const _ones = [
    '',
    'یک',
    'دو',
    'سه',
    'چهار',
    'پنج',
    'شش',
    'هفت',
    'هشت',
    'نه',
  ];
  static const _teens = [
    'ده',
    'یازده',
    'دوازده',
    'سیزده',
    'چهارده',
    'پانزده',
    'شانزده',
    'هفده',
    'هجده',
    'نوزده',
  ];
  static const _tens = [
    '',
    '',
    'بیست',
    'سی',
    'چهل',
    'پنجاه',
    'شصت',
    'هفتاد',
    'هشتاد',
    'نود',
  ];
  static const _hundreds = [
    '',
    'صد',
    'دویست',
    'سیصد',
    'چهارصد',
    'پانصد',
    'ششصد',
    'هفتصد',
    'هشتصد',
    'نهصد',
  ];
  static const _scales = ['', 'هزار', 'میلیون', 'میلیارد', 'تریلیون'];

  static String _threeDigits(int n) {
    if (n <= 0) return '';
    final parts = <String>[];
    final h = n ~/ 100;
    final rem = n % 100;
    if (h > 0) parts.add(_hundreds[h]);
    if (rem >= 10 && rem <= 19) {
      parts.add(_teens[rem - 10]);
    } else {
      final t = rem ~/ 10;
      final o = rem % 10;
      if (t > 0) parts.add(_tens[t]);
      if (o > 0) parts.add(_ones[o]);
    }
    return parts.join(' و ');
  }

  /// عدد صحیح (بدون اعشار) → حروف
  static String fromNumber(num value) {
    var n = value.floor().abs();
    if (n == 0) return 'صفر';

    final parts = <String>[];
    var scale = 0;
    while (n > 0 && scale < _scales.length) {
      final chunk = n % 1000;
      if (chunk > 0) {
        final words = _threeDigits(chunk);
        final scaleName = _scales[scale];
        parts.insert(0, scaleName.isEmpty ? words : '$words $scaleName');
      }
      n ~/= 1000;
      scale++;
    }
    return parts.join(' و ');
  }

  static String toman(num value) {
    if (value < 0) return 'منفی ${toman(-value)}';
    return '${fromNumber(value)} تومان';
  }
}
