import 'package:flutter/services.dart';

/// شماره کارت: فقط رقم، حداکثر ۱۶، نمایش ۴-۴-۴-۴
class CardNumberFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final digits = newValue.text.replaceAll(RegExp(r'\D'), '');
    final limited = digits.length > 16 ? digits.substring(0, 16) : digits;
    final buf = StringBuffer();
    for (var i = 0; i < limited.length; i++) {
      if (i > 0 && i % 4 == 0) buf.write(' ');
      buf.write(limited[i]);
    }
    final formatted = buf.toString();
    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}

/// شبا: پیشوند IR، فقط رقم بعد از آن، حداکثر ۲۴ رقم، گروه‌بندی ۴تایی
class IbanFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    var t = newValue.text.toUpperCase().replaceAll(RegExp(r'[^0-9IR]'), '');
    // فقط یک IR در ابتدا
    t = t.replaceAll('IR', '');
    final digits = t.replaceAll(RegExp(r'\D'), '');
    final limited = digits.length > 24 ? digits.substring(0, 24) : digits;
    final buf = StringBuffer('IR');
    for (var i = 0; i < limited.length; i++) {
      if (i % 4 == 0) buf.write(' ');
      buf.write(limited[i]);
    }
    final formatted = buf.toString().trimRight();
    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}

/// شماره حساب: فقط رقم، حداکثر ۱۳، گروه‌بندی اختیاری ۳تایی از راست سخت است — ساده ۴تایی
class AccountNumberFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final digits = newValue.text.replaceAll(RegExp(r'\D'), '');
    final limited = digits.length > 16 ? digits.substring(0, 16) : digits;
    final buf = StringBuffer();
    for (var i = 0; i < limited.length; i++) {
      if (i > 0 && i % 4 == 0) buf.write(' ');
      buf.write(limited[i]);
    }
    final formatted = buf.toString();
    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}

/// انقضا: MM/YY حداکثر
class ExpiryFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final digits = newValue.text.replaceAll(RegExp(r'\D'), '');
    final limited = digits.length > 4 ? digits.substring(0, 4) : digits;
    String formatted;
    if (limited.isEmpty) {
      formatted = '';
    } else if (limited.length <= 2) {
      // ماه ۱–۱۲
      var m = limited;
      if (limited.length == 1 && int.tryParse(limited)! > 1) {
        // اجازه تایپ
      }
      if (limited.length == 2) {
        final mi = int.tryParse(limited) ?? 0;
        if (mi > 12) m = '12';
        if (mi == 0) m = '01';
      }
      formatted = m;
    } else {
      var mm = limited.substring(0, 2);
      final mi = int.tryParse(mm) ?? 0;
      if (mi > 12) mm = '12';
      if (mi == 0) mm = '01';
      formatted = '$mm/${limited.substring(2)}';
    }
    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}

/// CVV: فقط رقم، حداکثر ۴
class CvvFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final digits = newValue.text.replaceAll(RegExp(r'\D'), '');
    final limited = digits.length > 4 ? digits.substring(0, 4) : digits;
    return TextEditingValue(
      text: limited,
      selection: TextSelection.collapsed(offset: limited.length),
    );
  }
}

/// بانک‌های رایج ایران
const iranianBanks = <String>[
  'ملی',
  'ملت',
  'صادرات',
  'تجارت',
  'سپه',
  'کشاورزی',
  'مسکن',
  'رفاه',
  'پاسارگاد',
  'پارسیان',
  'سامان',
  'اقتصاد نوین',
  'سینا',
  'شهر',
  'دی',
  'کارآفرین',
  'گردشگری',
  'ایران‌زمین',
  'آینده',
  'خاورمیانه',
  'رسالت',
  'قوامین',
  'انصار',
  'حکمت ایرانیان',
  'مهر ایران',
  'بلو',
  'بلوبانک',
  'سایر / دستی',
];
