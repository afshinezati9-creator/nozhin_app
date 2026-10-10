import 'package:equatable/equatable.dart';

/// انواع آیتم صندوق اطلاعات
enum InfoItemType { text, link, code, card, address, note, image, prompt }

extension InfoItemTypeX on InfoItemType {
  String get label {
    switch (this) {
      case InfoItemType.text:
        return 'متن';
      case InfoItemType.link:
        return 'لینک';
      case InfoItemType.code:
        return 'کد';
      case InfoItemType.card:
        return 'کارت';
      case InfoItemType.address:
        return 'آدرس';
      case InfoItemType.note:
        return 'یادداشت';
      case InfoItemType.image:
        return 'تصویر';
      case InfoItemType.prompt:
        return 'پرامپت';
    }
  }

  String get key {
    switch (this) {
      case InfoItemType.text:
        return 'text';
      case InfoItemType.link:
        return 'link';
      case InfoItemType.code:
        return 'code';
      case InfoItemType.card:
        return 'card';
      case InfoItemType.address:
        return 'address';
      case InfoItemType.note:
        return 'note';
      case InfoItemType.image:
        return 'image';
      case InfoItemType.prompt:
        return 'prompt';
    }
  }

  static InfoItemType fromKey(String? k) {
    switch (k) {
      case 'link':
        return InfoItemType.link;
      case 'code':
        return InfoItemType.code;
      case 'card':
        return InfoItemType.card;
      case 'address':
        return InfoItemType.address;
      case 'note':
        return InfoItemType.note;
      case 'image':
        return InfoItemType.image;
      case 'prompt':
        return InfoItemType.prompt;
      default:
        return InfoItemType.text;
    }
  }
}

/// فیلدهای اختصاصی کارت بانکی (عابر بانک)
class CardDetails extends Equatable {
  final String cardNumber; // فقط رقم
  final String holderName;
  final String iban; // شبا بدون IR یا با IR
  final String expiry; // مثلاً 1405/12 یا 12/25
  final String cvv; // اختیاری
  final String password; // اختیاری — کپی نمی‌شود
  final String bankName; // اختیاری
  final String accountNumber; // شماره حساب

  const CardDetails({
    this.cardNumber = '',
    this.holderName = '',
    this.iban = '',
    this.expiry = '',
    this.cvv = '',
    this.password = '',
    this.bankName = '',
    this.accountNumber = '',
  });

  CardDetails copyWith({
    String? cardNumber,
    String? holderName,
    String? iban,
    String? expiry,
    String? cvv,
    String? password,
    String? bankName,
    String? accountNumber,
  }) {
    return CardDetails(
      cardNumber: cardNumber ?? this.cardNumber,
      holderName: holderName ?? this.holderName,
      iban: iban ?? this.iban,
      expiry: expiry ?? this.expiry,
      cvv: cvv ?? this.cvv,
      password: password ?? this.password,
      bankName: bankName ?? this.bankName,
      accountNumber: accountNumber ?? this.accountNumber,
    );
  }

  Map<String, dynamic> toMap() => {
        'cardNumber': cardNumber,
        'holderName': holderName,
        'iban': iban,
        'expiry': expiry,
        'cvv': cvv,
        'password': password,
        'bankName': bankName,
        'accountNumber': accountNumber,
      };

  factory CardDetails.fromMap(Map<String, dynamic>? m) {
    if (m == null) return const CardDetails();
    return CardDetails(
      cardNumber: m['cardNumber'] as String? ?? '',
      holderName: m['holderName'] as String? ?? '',
      iban: m['iban'] as String? ?? '',
      expiry: m['expiry'] as String? ?? '',
      cvv: m['cvv'] as String? ?? '',
      password: m['password'] as String? ?? '',
      bankName: m['bankName'] as String? ?? '',
      accountNumber: m['accountNumber'] as String? ?? '',
    );
  }

  /// شماره گروه‌بندی‌شده برای نمایش: 6037 9911 2233 4455
  String get formattedNumber {
    final d = cardNumber.replaceAll(RegExp(r'\D'), '');
    final buf = StringBuffer();
    for (var i = 0; i < d.length; i++) {
      if (i > 0 && i % 4 == 0) buf.write(' ');
      buf.write(d[i]);
    }
    return buf.toString();
  }

  bool get isEmpty =>
      cardNumber.isEmpty &&
      holderName.isEmpty &&
      iban.isEmpty &&
      expiry.isEmpty;

  @override
  List<Object?> get props =>
      [cardNumber, holderName, iban, expiry, cvv, password, bankName, accountNumber];
}

/// آیتم صندوق اطلاعات
class InfoItemEntity extends Equatable {
  final String id;
  final String title;
  final InfoItemType type;
  /// مقدار اصلی برای انواع غیرکارت (متن، لینک، کد، آدرس، یادداشت، dataUrl تصویر)
  final String value;
  /// جزئیات کارت — فقط وقتی type == card
  final CardDetails? card;
  final DateTime createdAt;
  final DateTime updatedAt;
  final int uses;
  /// رنگ تم کارت: blue, purple, green, red, dark
  final String color;

  const InfoItemEntity({
    required this.id,
    required this.title,
    required this.type,
    this.value = '',
    this.card,
    required this.createdAt,
    required this.updatedAt,
    this.uses = 0,
    this.color = 'blue',
  });

  InfoItemEntity copyWith({
    String? id,
    String? title,
    InfoItemType? type,
    String? value,
    CardDetails? card,
    bool clearCard = false,
    DateTime? createdAt,
    DateTime? updatedAt,
    int? uses,
    String? color,
  }) {
    return InfoItemEntity(
      id: id ?? this.id,
      title: title ?? this.title,
      type: type ?? this.type,
      value: value ?? this.value,
      card: clearCard ? null : (card ?? this.card),
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      uses: uses ?? this.uses,
      color: color ?? this.color,
    );
  }

  String get typeLabel => type.label;

  /// متن قابل جستجو
  String get searchBlob {
    final c = card;
    if (type == InfoItemType.card && c != null) {
      return '$title ${c.cardNumber} ${c.holderName} ${c.iban} ${c.bankName} ${c.accountNumber}';
    }
    return '$title $value';
  }

  @override
  List<Object?> get props =>
      [id, title, type, value, card, createdAt, updatedAt, uses, color];
}
