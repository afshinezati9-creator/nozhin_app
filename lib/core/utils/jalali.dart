/// تبدیل میلادی ↔ شمسی (الگوریتم استاندارد)
class Jalali {
  final int year;
  final int month;
  final int day;

  const Jalali(this.year, this.month, this.day);

  static Jalali fromDateTime(DateTime dt) {
    final gy = dt.year;
    final gm = dt.month;
    final gd = dt.day;

    final gdm = [0, 31, 59, 90, 120, 151, 181, 212, 243, 273, 304, 334];
    var gy2 = (gm > 2) ? (gy + 1) : gy;
    var days = 355666 +
        (365 * gy) +
        ((gy2 + 3) ~/ 4) -
        ((gy2 + 99) ~/ 100) +
        ((gy2 + 399) ~/ 400) +
        gd +
        gdm[gm - 1];
    var jy = -1595 + (33 * (days ~/ 12053));
    days %= 12053;
    jy += 4 * (days ~/ 1461);
    days %= 1461;
    if (days > 365) {
      jy += (days - 1) ~/ 365;
      days = (days - 1) % 365;
    }
    int jm;
    int jd;
    if (days < 186) {
      jm = 1 + (days ~/ 31);
      jd = 1 + (days % 31);
    } else {
      jm = 7 + ((days - 186) ~/ 30);
      jd = 1 + ((days - 186) % 30);
    }
    return Jalali(jy, jm, jd);
  }

  /// شمسی → میلادی
  DateTime toDateTime() {
    final jy = year + 1595;
    var days = -355668 +
        (365 * jy) +
        ((jy ~/ 33) * 8) +
        (((jy % 33) + 3) ~/ 4) +
        day +
        ((month < 7) ? (month - 1) * 31 : ((month - 7) * 30 + 186));
    var gy = 400 * (days ~/ 146097);
    days %= 146097;
    if (days > 36524) {
      gy += 100 * (--days ~/ 36524);
      days %= 36524;
      if (days >= 365) days++;
    }
    gy += 4 * (days ~/ 1461);
    days %= 1461;
    if (days > 365) {
      gy += (days - 1) ~/ 365;
      days = (days - 1) % 365;
    }
    var gd = days + 1;
    final salA = [0, 31, (gy % 4 == 0 && gy % 100 != 0) || (gy % 400 == 0) ? 29 : 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31];
    var gm = 0;
    for (gm = 1; gm <= 12 && gd > salA[gm]; gm++) {
      gd -= salA[gm];
    }
    return DateTime(gy, gm, gd);
  }

  static const months = [
    'فروردین',
    'اردیبهشت',
    'خرداد',
    'تیر',
    'مرداد',
    'شهریور',
    'مهر',
    'آبان',
    'آذر',
    'دی',
    'بهمن',
    'اسفند',
  ];

  String get monthName => months[month - 1];

  int get monthLength {
    if (month <= 6) return 31;
    if (month <= 11) return 30;
    // اسفند
    final y = year;
    final leap = (((y + 12) % 33) % 4) == 1;
    return leap ? 30 : 29;
  }

  String format({bool withMonthName = false}) {
    final y = year.toString();
    final m = month.toString().padLeft(2, '0');
    final d = day.toString().padLeft(2, '0');
    if (withMonthName) return '$d $monthName $y';
    return '$y/$m/$d';
  }

  static String nowString({bool withTime = true, bool withMonthName = false}) {
    final n = DateTime.now();
    final j = fromDateTime(n);
    final date = j.format(withMonthName: withMonthName);
    if (!withTime) return date;
    final h = n.hour.toString().padLeft(2, '0');
    final min = n.minute.toString().padLeft(2, '0');
    return '$date  $h:$min';
  }
}
