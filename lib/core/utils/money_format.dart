import 'jalali.dart';

/// فرمت مبلغ و اعداد فارسی برای ماژول مالی
class MoneyFormat {
  MoneyFormat._();

  static const _en = ['0', '1', '2', '3', '4', '5', '6', '7', '8', '9'];
  static const _fa = ['۰', '۱', '۲', '۳', '۴', '۵', '۶', '۷', '۸', '۹'];

  static String toPersianDigits(String input) {
    var s = input;
    for (var i = 0; i < 10; i++) {
      s = s.replaceAll(_en[i], _fa[i]);
    }
    return s;
  }

  static String fromPersianDigits(String input) {
    var s = input;
    for (var i = 0; i < 10; i++) {
      s = s.replaceAll(_fa[i], _en[i]);
    }
    return s;
  }

  /// ۱۲۳۴۵۶۷ → ۱,۲۳۴,۵۶۷
  static String formatNumber(num value, {bool persian = true}) {
    final neg = value < 0;
    final abs = value.abs();
    final intPart = abs.floor();
    final frac = abs - intPart;
    final raw = intPart.toString();
    final buf = StringBuffer();
    for (var i = 0; i < raw.length; i++) {
      if (i > 0 && (raw.length - i) % 3 == 0) buf.write(',');
      buf.write(raw[i]);
    }
    var result = buf.toString();
    if (frac > 0.001) {
      result = '$result.${(frac * 100).round().toString().padLeft(2, '0')}';
    }
    if (neg) result = '-$result';
    return persian ? toPersianDigits(result) : result;
  }

  static String toman(num value, {bool withUnit = true}) {
    final n = formatNumber(value);
    return withUnit ? '$n تومان' : n;
  }

  static double? parseAmount(String input) {
    final cleaned = fromPersianDigits(input)
        .replaceAll(',', '')
        .replaceAll('،', '')
        .replaceAll('تومان', '')
        .replaceAll(' ', '')
        .trim();
    return double.tryParse(cleaned);
  }

  /// ماه/سال شمسی فعلی
  static (int year, int month) currentJalaliYm() {
    final j = Jalali.fromDateTime(DateTime.now());
    return (j.year, j.month);
  }

  /// مبلغ به حروف فارسی (تومان)
  static String toWordsToman(num value) {
    final n = value.round().abs();
    if (n == 0) return 'صفر تومان';
    return '${_intToWords(n)} تومان';
  }

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
    'یکصد',
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
    if (n == 0) return '';
    if (n < 20) return _ones[n];
    if (n < 100) {
      final t = n ~/ 10;
      final o = n % 10;
      if (o == 0) return _tens[t];
      return '${_tens[t]} و ${_ones[o]}';
    }
    final h = n ~/ 100;
    final rest = n % 100;
    if (rest == 0) return _hundreds[h];
    return '${_hundreds[h]} و ${_threeDigits(rest)}';
  }

  static String _intToWords(int n) {
    if (n == 0) return 'صفر';
    final parts = <String>[];
    var scale = 0;
    var x = n;
    while (x > 0 && scale < _scales.length) {
      final chunk = x % 1000;
      if (chunk != 0) {
        final w = _threeDigits(chunk);
        final s = _scales[scale];
        parts.insert(0, s.isEmpty ? w : '$w $s');
      }
      x ~/= 1000;
      scale++;
    }
    return parts.join(' و ');
  }
}
