import 'dart:typed_data';

import 'package:excel/excel.dart';
import 'package:file_picker/file_picker.dart' as fp;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:path_provider/path_provider.dart';

import 'local_database.dart';
import '../utils/jalali.dart';
import '../utils/money_format.dart';
import 'finance_excel_io.dart';

/// خروجی و ورودی اکسل مالی — چند شیت استاندارد حسابداری شخصی
///
/// شیت‌ها:
/// ۱) راهنما  ۲) حساب‌ها  ۳) دفترروزنامه  ۴) بدهی_طلب
/// ۵) اقساط  ۶) بودجه  ۷) اهداف  ۸) قصد_خرید  ۹) خلاصه
class FinanceExcelService {
  FinanceExcelService._();
  static final FinanceExcelService instance = FinanceExcelService._();

  final _db = LocalDatabase.instance;

  static const sheetGuide = 'راهنما';
  static const sheetAccounts = 'حساب‌ها';
  static const sheetJournal = 'دفترروزنامه';
  static const sheetDebts = 'بدهی_طلب';
  static const sheetInstallments = 'اقساط';
  static const sheetBudgets = 'بودجه';
  static const sheetGoals = 'اهداف';
  static const sheetPurchase = 'قصد_خرید';
  static const sheetSummary = 'خلاصه';

  /// ساخت و ذخیره/دانلود فایل — مسیر یا نام برمی‌گردد
  Future<String> exportToFile() async {
    final bytes = await buildExcelBytes();
    final name = 'hawzhin_finance_${_fileStamp()}.xlsx';

    try {
      final path = await fp.FilePicker.saveFile(
        dialogTitle: 'ذخیره اکسل مالی هاوژین',
        fileName: name,
        type: fp.FileType.custom,
        allowedExtensions: const ['xlsx'],
        bytes: bytes,
      );
      if (path != null && path.isNotEmpty) return path;
    } catch (_) {}

    if (kIsWeb) return name;

    final dir = await getApplicationDocumentsDirectory();
    final full = '${dir.path}/$name';
    await writeBytesToPath(full, bytes);
    return full;
  }

  String _fileStamp() {
    final n = DateTime.now();
    String p2(int v) => v.toString().padLeft(2, '0');
    return '${n.year}${p2(n.month)}${p2(n.day)}_${p2(n.hour)}${p2(n.minute)}';
  }

  Future<Uint8List> buildExcelBytes() async {
    final excel = Excel.createExcel();
    _writeGuide(excel);
    await _writeAccounts(excel);
    await _writeJournal(excel);
    await _writeDebts(excel);
    await _writeInstallments(excel);
    await _writeBudgets(excel);
    await _writeGoals(excel);
    await _writePurchase(excel);
    await _writeSummary(excel);
    if (excel.sheets.containsKey('Sheet1')) {
      excel.delete('Sheet1');
    }
    final encoded = excel.encode();
    if (encoded == null) {
      throw StateError('ساخت فایل اکسل ناموفق بود');
    }
    return Uint8List.fromList(encoded);
  }

  void _header(Sheet sheet, List<String> cols) {
    for (var i = 0; i < cols.length; i++) {
      sheet
          .cell(CellIndex.indexByColumnRow(columnIndex: i, rowIndex: 0))
          .value = TextCellValue(cols[i]);
    }
  }

  void _row(Sheet sheet, int r, List<dynamic> values) {
    for (var i = 0; i < values.length; i++) {
      final v = values[i];
      final cell =
          sheet.cell(CellIndex.indexByColumnRow(columnIndex: i, rowIndex: r));
      if (v == null) {
        cell.value = TextCellValue('');
      } else if (v is int) {
        cell.value = IntCellValue(v);
      } else if (v is num) {
        cell.value = DoubleCellValue(v.toDouble());
      } else if (v is bool) {
        cell.value = TextCellValue(v ? 'بله' : 'خیر');
      } else {
        cell.value = TextCellValue('$v');
      }
    }
  }

  Sheet _sheet(Excel excel, String name) => excel[name];

  void _writeGuide(Excel excel) {
    final s = _sheet(excel, sheetGuide);
    final lines = <List<String>>[
      ['هاوژین — خروجی مالی استاندارد'],
      ['نسخه قالب', '1.0'],
      ['واحد پول', 'تومان'],
      ['تاریخ خروجی', DateTime.now().toIso8601String()],
      [''],
      ['قواعد شیت دفترروزنامه'],
      [
        'نوع',
        'income | expense | saving | transfer یا فارسی: درآمد / هزینه / پس‌انداز / انتقال'
      ],
      ['مبلغ', 'همیشه مثبت؛ جهت از نوع تراکنش مشخص می‌شود'],
      ['تاریخ', 'ترجیحاً ISO مثل 2026-10-10'],
      ['شناسه', 'خالی = شناسه جدید هنگام ورود'],
      [''],
      ['قواعد ورود (ایمپورت)'],
      ['1', 'فقط داده‌های مالی؛ یادداشت‌ها و دم‌دستی دست‌نخورده می‌مانند'],
      ['2', 'شناسه موجود → به‌روزرسانی؛ شناسه جدید یا خالی → افزودن'],
      ['3', 'موجودی حساب‌ها از شیت حساب‌ها خوانده می‌شود'],
      ['4', 'رمز کارت بانکی در این فایل نیست'],
      [''],
      ['فهرست شیت‌ها'],
      ['حساب‌ها', 'لیست حساب‌ها و موجودی'],
      ['دفترروزنامه', 'ژورنال تراکنش‌ها با بدهکار/بستانکار'],
      ['بدهی_طلب', 'بدهی و طلب اشخاص'],
      ['اقساط', 'طرح‌های قسطی'],
      ['بودجه', 'سقف ماهانه (سال و ماه شمسی)'],
      ['اهداف', 'اهداف پس‌انداز'],
      ['قصد_خرید', 'خریدهای برنامه‌ریزی‌شده'],
      ['خلاصه', 'فقط خواندنی — جمع‌ها'],
    ];
    for (var i = 0; i < lines.length; i++) {
      _row(s, i, lines[i]);
    }
  }

  Future<void> _writeAccounts(Excel excel) async {
    final s = _sheet(excel, sheetAccounts);
    _header(s, ['شناسه', 'نام', 'نوع', 'موجودی_تومان', 'تاریخ_ایجاد']);
    final items = await _db.readAll(Collections.accounts);
    for (var i = 0; i < items.length; i++) {
      final m = items[i];
      _row(s, i + 1, [
        m['id'],
        m['name'],
        m['type'],
        (m['balance'] as num?)?.toDouble() ?? 0,
        m['createdAt'],
      ]);
    }
  }

  Future<void> _writeJournal(Excel excel) async {
    final s = _sheet(excel, sheetJournal);
    _header(s, [
      'شناسه',
      'تاریخ',
      'تاریخ_شمسی',
      'نوع',
      'عنوان',
      'مبلغ_تومان',
      'دسته',
      'شناسه_حساب',
      'شناسه_حساب_مقصد',
      'شرح',
      'بدهکار_تومان',
      'بستانکار_تومان',
    ]);
    final items = await _db.readAll(Collections.transactions);
    items.sort((a, b) {
      final da = DateTime.tryParse('${a['date']}') ?? DateTime(1970);
      final db = DateTime.tryParse('${b['date']}') ?? DateTime(1970);
      return db.compareTo(da);
    });
    for (var i = 0; i < items.length; i++) {
      final m = items[i];
      final type = '${m['type'] ?? ''}';
      final amount = (m['amount'] as num?)?.toDouble() ?? 0;
      final dt = DateTime.tryParse('${m['date']}') ?? DateTime.now();
      final j = Jalali.fromDateTime(dt);
      final debit =
          (type == 'expense' || type == 'transfer') ? amount : 0.0;
      final credit =
          (type == 'income' || type == 'saving') ? amount : 0.0;
      _row(s, i + 1, [
        m['id'],
        dt.toIso8601String().split('T').first,
        j.format(withMonthName: true),
        type,
        m['title'],
        amount,
        m['category'],
        m['accountId'] ?? '',
        m['toAccountId'] ?? '',
        m['description'] ?? '',
        debit,
        credit,
      ]);
    }
  }

  Future<void> _writeDebts(Excel excel) async {
    final s = _sheet(excel, sheetDebts);
    _header(s, [
      'شناسه',
      'نوع',
      'طرف',
      'مبلغ_تومان',
      'سررسید',
      'یادداشت',
      'تاریخ_ثبت',
    ]);
    final items = await _db.readAll(Collections.debts);
    for (var i = 0; i < items.length; i++) {
      final m = items[i];
      _row(s, i + 1, [
        m['id'],
        m['type'],
        m['name'],
        (m['amount'] as num?)?.toDouble() ?? 0,
        m['dueDate'] ?? '',
        m['note'] ?? '',
        m['createdAt'],
      ]);
    }
  }

  Future<void> _writeInstallments(Excel excel) async {
    final s = _sheet(excel, sheetInstallments);
    _header(s, [
      'شناسه',
      'عنوان',
      'مبلغ_کل',
      'تعداد_اقساط',
      'پرداخت_شده',
      'مبلغ_هر_قسط',
      'روز_سررسید',
      'شناسه_حساب',
      'یادداشت',
      'تاریخ_ثبت',
    ]);
    final items = await _db.readAll(Collections.installments);
    for (var i = 0; i < items.length; i++) {
      final m = items[i];
      _row(s, i + 1, [
        m['id'],
        m['title'],
        (m['totalAmount'] as num?)?.toDouble() ?? 0,
        m['totalCount'] ?? 0,
        m['paidCount'] ?? 0,
        (m['installmentAmount'] as num?)?.toDouble() ?? 0,
        m['dueDay'] ?? '',
        m['accountId'] ?? '',
        m['note'] ?? '',
        m['createdAt'],
      ]);
    }
  }

  Future<void> _writeBudgets(Excel excel) async {
    final s = _sheet(excel, sheetBudgets);
    _header(s, ['شناسه', 'سال_شمسی', 'ماه_شمسی', 'دسته', 'سقف_تومان']);
    final items = await _db.readAll(Collections.budgets);
    for (var i = 0; i < items.length; i++) {
      final m = items[i];
      _row(s, i + 1, [
        m['id'],
        m['year'],
        m['month'],
        m['category'],
        (m['limit'] as num?)?.toDouble() ?? 0,
      ]);
    }
  }

  Future<void> _writeGoals(Excel excel) async {
    final s = _sheet(excel, sheetGoals);
    _header(s, [
      'شناسه',
      'عنوان',
      'هدف_تومان',
      'موجود_تومان',
      'مهلت',
      'یادداشت',
      'تاریخ_ثبت',
    ]);
    final items = await _db.readAll(Collections.finGoals);
    for (var i = 0; i < items.length; i++) {
      final m = items[i];
      _row(s, i + 1, [
        m['id'],
        m['title'],
        (m['targetAmount'] as num?)?.toDouble() ?? 0,
        (m['currentAmount'] as num?)?.toDouble() ?? 0,
        m['deadline'] ?? '',
        m['note'] ?? '',
        m['createdAt'],
      ]);
    }
  }

  Future<void> _writePurchase(Excel excel) async {
    final s = _sheet(excel, sheetPurchase);
    _header(s, [
      'شناسه',
      'عنوان',
      'مبلغ_تقریبی',
      'تاریخ_هدف',
      'وضعیت',
      'اولویت',
      'آرشیو',
      'یادداشت',
      'تاریخ_ثبت',
    ]);
    final items = await _db.readAll(Collections.purchaseIntents);
    for (var i = 0; i < items.length; i++) {
      final m = items[i];
      _row(s, i + 1, [
        m['id'],
        m['title'],
        (m['amount'] as num?)?.toDouble(),
        m['plannedDate'],
        m['status'],
        m['priority'] ?? 2,
        m['archived'] == true,
        m['note'] ?? '',
        m['createdAt'],
      ]);
    }
  }

  Future<void> _writeSummary(Excel excel) async {
    final s = _sheet(excel, sheetSummary);
    final accounts = await _db.readAll(Collections.accounts);
    final txs = await _db.readAll(Collections.transactions);
    double bal = 0;
    for (final a in accounts) {
      bal += (a['balance'] as num?)?.toDouble() ?? 0;
    }
    double income = 0, expense = 0, saving = 0;
    for (final t in txs) {
      final type = '${t['type']}';
      final amt = (t['amount'] as num?)?.toDouble() ?? 0;
      if (type == 'income') income += amt;
      if (type == 'expense') expense += amt;
      if (type == 'saving') saving += amt;
    }
    final debts = await _db.readAll(Collections.debts);
    double owe = 0, owed = 0;
    for (final d in debts) {
      final a = (d['amount'] as num?)?.toDouble() ?? 0;
      if (d['type'] == 'owe') {
        owe += a;
      } else {
        owed += a;
      }
    }
    final rows = <List<dynamic>>[
      ['شاخص', 'مقدار_عددی', 'نمایش'],
      ['موجودی کل حساب‌ها', bal, MoneyFormat.toman(bal)],
      ['جمع درآمدها', income, MoneyFormat.toman(income)],
      ['جمع هزینه‌ها', expense, MoneyFormat.toman(expense)],
      ['جمع پس‌انداز ثبت‌شده', saving, MoneyFormat.toman(saving)],
      ['خالص (درآمد−هزینه)', income - expense, MoneyFormat.toman(income - expense)],
      ['بدهی من', owe, MoneyFormat.toman(owe)],
      ['طلب من', owed, MoneyFormat.toman(owed)],
      ['تعداد حساب', accounts.length, ''],
      ['تعداد تراکنش', txs.length, ''],
      ['زمان تولید', DateTime.now().toIso8601String(), ''],
    ];
    for (var i = 0; i < rows.length; i++) {
      _row(s, i, rows[i]);
    }
  }

  // ─── IMPORT ─────────────────────────────────────────────

  Future<FinanceExcelImportResult> importFromPicker({bool merge = true}) async {
    try {
      final pick = await fp.FilePicker.pickFiles(
        type: fp.FileType.custom,
        allowedExtensions: const ['xlsx', 'xls'],
        withData: true,
      );
      if (pick == null || pick.files.isEmpty) {
        return FinanceExcelImportResult.cancelled();
      }
      final bytes = pick.files.first.bytes;
      if (bytes == null) {
        final path = pick.files.first.path;
        if (path != null && path.isNotEmpty) {
          final b = await readBytesFromPath(path);
          return importBytes(b, merge: merge);
        }
        return FinanceExcelImportResult.error('خواندن فایل ممکن نشد');
      }
      return importBytes(bytes, merge: merge);
    } catch (e) {
      return FinanceExcelImportResult.error('انتخاب فایل: $e');
    }
  }

  Future<FinanceExcelImportResult> importBytes(
    Uint8List bytes, {
    bool merge = true,
  }) async {
    try {
      final excel = Excel.decodeBytes(bytes);
      final stats = <String, int>{
        sheetAccounts: await _importAccounts(excel, merge),
        sheetJournal: await _importJournal(excel, merge),
        sheetDebts: await _importDebts(excel, merge),
        sheetInstallments: await _importInstallments(excel, merge),
        sheetBudgets: await _importBudgets(excel, merge),
        sheetGoals: await _importGoals(excel, merge),
        sheetPurchase: await _importPurchase(excel, merge),
      };
      return FinanceExcelImportResult.ok(stats);
    } catch (e) {
      return FinanceExcelImportResult.error('$e');
    }
  }

  List<List<Data?>>? _table(Excel excel, String name) {
    final sheet = excel.sheets[name];
    if (sheet == null) return null;
    return sheet.rows;
  }

  String _cell(List<Data?> row, int i) {
    if (i >= row.length) return '';
    final v = row[i]?.value;
    if (v == null) return '';
    return '$v'.trim();
  }

  double? _num(List<Data?> row, int i) {
    final s = _cell(row, i).replaceAll(',', '').replaceAll('،', '');
    if (s.isEmpty) return null;
    return double.tryParse(MoneyFormat.fromPersianDigits(s));
  }

  String _idOrNew(String raw) {
    final t = raw.trim();
    if (t.isEmpty) return _db.generateId();
    return t;
  }

  Future<int> _upsertCollection(
    String collection,
    List<Map<String, dynamic>> rows, {
    required bool merge,
  }) async {
    if (!merge) {
      await _db.writeAll(collection, rows);
      return rows.length;
    }
    final existing = await _db.readAll(collection);
    final map = {for (final e in existing) '${e['id']}': Map<String, dynamic>.from(e)};
    for (final r in rows) {
      map['${r['id']}'] = r;
    }
    await _db.writeAll(collection, map.values.toList());
    return rows.length;
  }

  Future<int> _importAccounts(Excel excel, bool merge) async {
    final table = _table(excel, sheetAccounts);
    if (table == null || table.length < 2) return 0;
    final rows = <Map<String, dynamic>>[];
    for (var i = 1; i < table.length; i++) {
      final r = table[i];
      final name = _cell(r, 1);
      if (name.isEmpty) continue;
      rows.add({
        'id': _idOrNew(_cell(r, 0)),
        'name': name,
        'type': _normalizeAccountType(_cell(r, 2)),
        'balance': _num(r, 3) ?? 0,
        'icon': 'bank',
        'createdAt': _cell(r, 4).isEmpty
            ? DateTime.now().toIso8601String()
            : _cell(r, 4),
      });
    }
    return _upsertCollection(Collections.accounts, rows, merge: merge);
  }

  String _normalizeAccountType(String t) {
    final x = t.toLowerCase();
    if (x.contains('cash') || t.contains('نقد')) return 'cash';
    if (x.contains('wallet') || t.contains('کیف')) return 'wallet';
    if (x.contains('saving') || t.contains('پس')) return 'savings';
    if (x == 'bank' || x == 'cash' || x == 'wallet' || x == 'savings') return x;
    return 'bank';
  }

  Future<int> _importJournal(Excel excel, bool merge) async {
    final table = _table(excel, sheetJournal);
    if (table == null || table.length < 2) return 0;
    final rows = <Map<String, dynamic>>[];
    for (var i = 1; i < table.length; i++) {
      final r = table[i];
      final title = _cell(r, 4);
      final amount = _num(r, 5);
      if (title.isEmpty || amount == null || amount <= 0) continue;
      final date = DateTime.tryParse(_cell(r, 1)) ?? DateTime.now();
      rows.add({
        'id': _idOrNew(_cell(r, 0)),
        'type': _normalizeTxType(_cell(r, 3)),
        'title': title,
        'amount': amount,
        'category': _cell(r, 6).isEmpty ? 'سایر' : _cell(r, 6),
        'accountId': _cell(r, 7),
        'toAccountId': _cell(r, 8).isEmpty ? null : _cell(r, 8),
        'description': _cell(r, 9).isEmpty ? null : _cell(r, 9),
        'date': date.toIso8601String(),
      });
    }
    return _upsertCollection(Collections.transactions, rows, merge: merge);
  }

  String _normalizeTxType(String t) {
    final x = t.toLowerCase().trim();
    if (x == 'income' || t.contains('درآمد')) return 'income';
    if (x == 'expense' || t.contains('هزینه')) return 'expense';
    if (x == 'saving' || t.contains('پس')) return 'saving';
    if (x == 'transfer' || t.contains('انتقال')) return 'transfer';
    return 'expense';
  }

  Future<int> _importDebts(Excel excel, bool merge) async {
    final table = _table(excel, sheetDebts);
    if (table == null || table.length < 2) return 0;
    final rows = <Map<String, dynamic>>[];
    for (var i = 1; i < table.length; i++) {
      final r = table[i];
      final name = _cell(r, 2);
      final amount = _num(r, 3);
      if (name.isEmpty || amount == null) continue;
      final typeRaw = _cell(r, 1).toLowerCase();
      final type =
          (typeRaw.contains('owed') || typeRaw.contains('طلب')) ? 'owed' : 'owe';
      rows.add({
        'id': _idOrNew(_cell(r, 0)),
        'type': type,
        'name': name,
        'amount': amount,
        'dueDate': _cell(r, 4).isEmpty ? null : _cell(r, 4),
        'note': _cell(r, 5).isEmpty ? null : _cell(r, 5),
        'createdAt': _cell(r, 6).isEmpty
            ? DateTime.now().toIso8601String()
            : _cell(r, 6),
      });
    }
    return _upsertCollection(Collections.debts, rows, merge: merge);
  }

  Future<int> _importInstallments(Excel excel, bool merge) async {
    final table = _table(excel, sheetInstallments);
    if (table == null || table.length < 2) return 0;
    final rows = <Map<String, dynamic>>[];
    for (var i = 1; i < table.length; i++) {
      final r = table[i];
      final title = _cell(r, 1);
      final total = _num(r, 2);
      if (title.isEmpty || total == null) continue;
      rows.add({
        'id': _idOrNew(_cell(r, 0)),
        'title': title,
        'totalAmount': total,
        'totalCount': _num(r, 3)?.toInt() ?? 1,
        'paidCount': _num(r, 4)?.toInt() ?? 0,
        'installmentAmount': _num(r, 5) ?? total,
        'dueDay': _cell(r, 6).isEmpty ? null : _cell(r, 6),
        'accountId': _cell(r, 7).isEmpty ? null : _cell(r, 7),
        'note': _cell(r, 8).isEmpty ? null : _cell(r, 8),
        'createdAt': _cell(r, 9).isEmpty
            ? DateTime.now().toIso8601String()
            : _cell(r, 9),
      });
    }
    return _upsertCollection(Collections.installments, rows, merge: merge);
  }

  Future<int> _importBudgets(Excel excel, bool merge) async {
    final table = _table(excel, sheetBudgets);
    if (table == null || table.length < 2) return 0;
    final rows = <Map<String, dynamic>>[];
    for (var i = 1; i < table.length; i++) {
      final r = table[i];
      final cat = _cell(r, 3);
      final limit = _num(r, 4);
      if (cat.isEmpty || limit == null) continue;
      rows.add({
        'id': _idOrNew(_cell(r, 0)),
        'year': _num(r, 1)?.toInt() ?? Jalali.fromDateTime(DateTime.now()).year,
        'month': _num(r, 2)?.toInt() ?? 1,
        'category': cat,
        'limit': limit,
      });
    }
    return _upsertCollection(Collections.budgets, rows, merge: merge);
  }

  Future<int> _importGoals(Excel excel, bool merge) async {
    final table = _table(excel, sheetGoals);
    if (table == null || table.length < 2) return 0;
    final rows = <Map<String, dynamic>>[];
    for (var i = 1; i < table.length; i++) {
      final r = table[i];
      final title = _cell(r, 1);
      final target = _num(r, 2);
      if (title.isEmpty || target == null) continue;
      rows.add({
        'id': _idOrNew(_cell(r, 0)),
        'title': title,
        'targetAmount': target,
        'currentAmount': _num(r, 3) ?? 0,
        'deadline': _cell(r, 4).isEmpty ? null : _cell(r, 4),
        'note': _cell(r, 5).isEmpty ? null : _cell(r, 5),
        'createdAt': _cell(r, 6).isEmpty
            ? DateTime.now().toIso8601String()
            : _cell(r, 6),
      });
    }
    return _upsertCollection(Collections.finGoals, rows, merge: merge);
  }

  Future<int> _importPurchase(Excel excel, bool merge) async {
    final table = _table(excel, sheetPurchase);
    if (table == null || table.length < 2) return 0;
    final rows = <Map<String, dynamic>>[];
    for (var i = 1; i < table.length; i++) {
      final r = table[i];
      final title = _cell(r, 1);
      if (title.isEmpty) continue;
      final arch = _cell(r, 6);
      rows.add({
        'id': _idOrNew(_cell(r, 0)),
        'title': title,
        'amount': _num(r, 2),
        'plannedDate': _cell(r, 3).isEmpty
            ? DateTime.now().toIso8601String()
            : _cell(r, 3),
        'status': _cell(r, 4).isEmpty ? 'pending' : _cell(r, 4),
        'priority': _num(r, 5)?.toInt() ?? 2,
        'archived': arch == 'بله' || arch.toLowerCase() == 'true',
        'note': _cell(r, 7),
        'createdAt': _cell(r, 8).isEmpty
            ? DateTime.now().toIso8601String()
            : _cell(r, 8),
      });
    }
    return _upsertCollection(Collections.purchaseIntents, rows, merge: merge);
  }
}

class FinanceExcelImportResult {
  final bool cancelled;
  final String? error;
  final Map<String, int> counts;

  FinanceExcelImportResult._({
    this.cancelled = false,
    this.error,
    this.counts = const {},
  });

  factory FinanceExcelImportResult.cancelled() =>
      FinanceExcelImportResult._(cancelled: true);
  factory FinanceExcelImportResult.error(String e) =>
      FinanceExcelImportResult._(error: e);
  factory FinanceExcelImportResult.ok(Map<String, int> c) =>
      FinanceExcelImportResult._(counts: c);

  bool get success => !cancelled && error == null;
}
