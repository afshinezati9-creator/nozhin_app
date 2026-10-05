import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import '../../../core/theme/app_colors.dart';
import '../../../domain/entities/info_item_entity.dart';
import '../../providers/info_provider.dart';
import 'code_editor_field.dart';
import 'info_input_formatters.dart';
import 'text_editor_field.dart';

class InfoFormScreen extends ConsumerStatefulWidget {
  final InfoItemEntity? existing;
  const InfoFormScreen({super.key, this.existing});

  @override
  ConsumerState<InfoFormScreen> createState() => _InfoFormScreenState();
}

class _InfoFormScreenState extends ConsumerState<InfoFormScreen> {
  static const _selectableTypes = [
    InfoItemType.card,
    InfoItemType.text,
    InfoItemType.link,
    InfoItemType.code,
    InfoItemType.address,
    InfoItemType.image,
    InfoItemType.prompt,
  ];

  late InfoItemType _type;
  late final TextEditingController _title;
  late final TextEditingController _value;
  late final TextEditingController _cardNumber;
  late final TextEditingController _holder;
  late final TextEditingController _iban;
  late final TextEditingController _expiry;
  late final TextEditingController _cvv;
  late final TextEditingController _password;
  late final TextEditingController _bank;
  late final TextEditingController _account;
  late final TextEditingController _lat;
  late final TextEditingController _lng;
  late final TextEditingController _city;
  late final TextEditingController _district;
  late final TextEditingController _street;
  late final TextEditingController _alley;
  late final TextEditingController _plaque;
  late final TextEditingController _postal;
  String _color = 'blue';
  String? _selectedBank;
  bool _saving = false;
  bool _manualBank = false;
  /// true = جدا · false = یک باکس
  bool _addressSplit = false;
  String? _codeLang;
  TextDirection _promptDir = TextDirection.rtl;
  Uint8List? _imageBytes;
  String? _imageDataUrl;

  bool get _isEdit => widget.existing != null;

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    var t = e?.type ?? InfoItemType.card;
    if (t == InfoItemType.note) t = InfoItemType.text;
    _type = t;
    _title = TextEditingController(text: e?.title ?? '');
    _value = TextEditingController(text: e?.value ?? '');
    final c = e?.card;
    _cardNumber = TextEditingController(
        text: c == null || c.cardNumber.isEmpty
            ? ''
            : _fmtCard(c.cardNumber));
    _holder = TextEditingController(text: c?.holderName ?? '');
    _iban = TextEditingController(
        text: c == null || c.iban.isEmpty ? 'IR' : _fmtIban(c.iban));
    _expiry = TextEditingController(text: c?.expiry ?? '');
    _cvv = TextEditingController(text: c?.cvv ?? '');
    _password = TextEditingController(text: c?.password ?? '');
    _bank = TextEditingController(text: c?.bankName ?? '');
    _account = TextEditingController(
        text: c == null || c.accountNumber.isEmpty
            ? ''
            : _fmtCard(c.accountNumber));
    _lat = TextEditingController();
    _lng = TextEditingController();
    _city = TextEditingController();
    _district = TextEditingController();
    _street = TextEditingController();
    _alley = TextEditingController();
    _plaque = TextEditingController();
    _postal = TextEditingController();
    _color = e?.color ?? 'blue';

    if (c != null && c.bankName.isNotEmpty) {
      if (iranianBanks.contains(c.bankName)) {
        _selectedBank = c.bankName;
        _manualBank = c.bankName == 'سایر / دستی';
      } else {
        _selectedBank = 'سایر / دستی';
        _manualBank = true;
      }
    }

    // parse address coords from value if present
    if (e?.type == InfoItemType.address && e!.value.contains('مختصات:')) {
      final m = RegExp(r'مختصات:\s*([-\d.]+)\s*,\s*([-\d.]+)').firstMatch(e.value);
      if (m != null) {
        _lat.text = m.group(1)!;
        _lng.text = m.group(2)!;
      }
    }
    if (e?.type == InfoItemType.image &&
        (e!.value.startsWith('data:image'))) {
      _imageDataUrl = e.value;
      try {
        final b64 = e.value.split(',').last;
        _imageBytes = base64Decode(b64);
      } catch (_) {}
    }
  }

  String _fmtCard(String raw) {
    final d = raw.replaceAll(RegExp(r'\D'), '');
    final buf = StringBuffer();
    for (var i = 0; i < d.length && i < 16; i++) {
      if (i > 0 && i % 4 == 0) buf.write(' ');
      buf.write(d[i]);
    }
    return buf.toString();
  }

  String _fmtIban(String raw) {
    var s = raw.replaceAll(RegExp(r'\s'), '').toUpperCase();
    if (s.startsWith('IR')) s = s.substring(2);
    final digits = s.replaceAll(RegExp(r'\D'), '');
    final buf = StringBuffer('IR');
    for (var i = 0; i < digits.length && i < 24; i++) {
      if (i % 4 == 0) buf.write(' ');
      buf.write(digits[i]);
    }
    return buf.toString().trimRight();
  }

  @override
  void dispose() {
    for (final c in [
      _title, _value, _cardNumber, _holder, _iban, _expiry, _cvv, _password,
      _bank, _account, _lat, _lng, _city, _district, _street, _alley, _plaque,
      _postal,
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final file = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 1600,
      imageQuality: 85,
    );
    if (file == null) return;
    final bytes = await file.readAsBytes();
    if (bytes.length > 2 * 1024 * 1024) {
      _toast('حداکثر حجم تصویر ۲ مگابایت');
      return;
    }
    final b64 = base64Encode(bytes);
    final mime = file.mimeType ?? 'image/jpeg';
    setState(() {
      _imageBytes = bytes;
      _imageDataUrl = 'data:$mime;base64,$b64';
      _value.text = _imageDataUrl!;
    });
  }

  String _buildAddressValue() {
    final postal = _postal.text.trim();
    final coords = (_lat.text.isNotEmpty && _lng.text.isNotEmpty)
        ? 'مختصات: ${_lat.text}, ${_lng.text}'
        : '';
    String body;
    if (_addressSplit) {
      final parts = <String>[];
      if (_city.text.trim().isNotEmpty) parts.add('شهر: ${_city.text.trim()}');
      if (_district.text.trim().isNotEmpty) {
        parts.add('منطقه: ${_district.text.trim()}');
      }
      if (_street.text.trim().isNotEmpty) {
        parts.add('خیابان: ${_street.text.trim()}');
      }
      if (_alley.text.trim().isNotEmpty) {
        parts.add('کوچه: ${_alley.text.trim()}');
      }
      if (_plaque.text.trim().isNotEmpty) {
        parts.add('پلاک: ${_plaque.text.trim()}');
      }
      body = parts.join('\n');
    } else {
      body = _value.text.trim();
    }
    final lines = <String>[];
    if (body.isNotEmpty) lines.add(body);
    if (postal.isNotEmpty) lines.add('کد پستی: $postal');
    if (coords.isNotEmpty) lines.add(coords);
    return lines.join('\n');
  }

  Future<void> _save() async {
    if (_saving) return;
    setState(() => _saving = true);
    try {
      final notifier = ref.read(infoProvider.notifier);
      if (_type == InfoItemType.card) {
        final digits = _cardNumber.text.replaceAll(RegExp(r'\D'), '');
        if (digits.isEmpty && _holder.text.trim().isEmpty) {
          _toast('حداقل شماره کارت یا نام دارنده را وارد کن');
          return;
        }
        final bankName = _manualBank
            ? _bank.text.trim()
            : (_selectedBank == 'سایر / دستی'
                ? _bank.text.trim()
                : (_selectedBank ?? ''));
        final card = CardDetails(
          cardNumber: digits,
          holderName: _holder.text.trim(),
          iban: _iban.text.replaceAll(RegExp(r'\s'), '').toUpperCase(),
          expiry: _expiry.text.trim(),
          cvv: _cvv.text.replaceAll(RegExp(r'\D'), ''),
          password: '', // B2: رمز کارت عمداً ذخیره نمی‌شود
          bankName: bankName,
          accountNumber: _account.text.replaceAll(RegExp(r'\D'), ''),
        );
        final title = _title.text.trim().isEmpty
            ? (bankName.isEmpty ? 'کارت بانکی' : 'کارت $bankName')
            : _title.text.trim();
        if (_isEdit) {
          await notifier.update(widget.existing!.copyWith(
            title: title,
            type: InfoItemType.card,
            card: card,
            color: _color,
          ));
        } else {
          await notifier.create(
              title: title, type: InfoItemType.card, card: card, color: _color);
        }
      } else if (_type == InfoItemType.address) {
        final address = _buildAddressValue();
        if (address.isEmpty) {
          _toast('آدرس، کد پستی یا موقعیت را وارد کن');
          return;
        }
        final title =
            _title.text.trim().isEmpty ? 'آدرس' : _title.text.trim();
        if (_isEdit) {
          await notifier.update(widget.existing!.copyWith(
            title: title,
            type: InfoItemType.address,
            value: address,
            clearCard: true,
          ));
        } else {
          await notifier.create(
              title: title, type: InfoItemType.address, value: address);
        }
      } else if (_type == InfoItemType.image) {
        final val = _imageDataUrl ?? _value.text.trim();
        if (val.isEmpty) {
          _toast('تصویر انتخاب کن یا آدرس بگذار');
          return;
        }
        final title =
            _title.text.trim().isEmpty ? 'تصویر' : _title.text.trim();
        if (_isEdit) {
          await notifier.update(widget.existing!.copyWith(
            title: title,
            type: InfoItemType.image,
            value: val,
            clearCard: true,
          ));
        } else {
          await notifier.create(
              title: title, type: InfoItemType.image, value: val);
        }
      } else {
        if (_value.text.trim().isEmpty && _title.text.trim().isEmpty) {
          _toast('عنوان یا مقدار را وارد کن');
          return;
        }
        final title = _title.text.trim().isEmpty
            ? _type.label
            : _title.text.trim();
        if (_isEdit) {
          await notifier.update(widget.existing!.copyWith(
            title: title,
            type: _type,
            value: _value.text.trim(),
            clearCard: true,
            color: _color,
          ));
        } else {
          await notifier.create(
            title: title,
            type: _type,
            value: _value.text.trim(),
            color: _color,
          );
        }
      }
      if (mounted) Navigator.pop(context, true);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  void _toast(String m) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(m), behavior: SnackBarBehavior.fixed),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEdit ? 'ویرایش اطلاعات' : 'اطلاعات جدید'),
        actions: [
          TextButton(
            onPressed: _saving ? null : _save,
            child: Text('ذخیره',
                style: TextStyle(
                    fontWeight: FontWeight.w900, color: AppColors.brand3)),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 40),
        children: [
          Text('نوع',
              style: theme.textTheme.titleSmall
                  ?.copyWith(fontWeight: FontWeight.w800)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _selectableTypes.map((t) {
              final sel = _type == t;
              return ChoiceChip(
                label: Text(t.label),
                selected: sel,
                onSelected: (_) => setState(() => _type = t),
                selectedColor: AppColors.brand3.withOpacity(0.2),
              );
            }).toList(),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _title,
            decoration: const InputDecoration(
              labelText: 'عنوان',
              hintText: 'مثلاً کارت حقوق / لینک گیت‌هاب',
            ),
          ),
          const SizedBox(height: 12),
          if (_type == InfoItemType.card) ..._cardFields(theme),
          if (_type == InfoItemType.code) ...[
            CodeEditorField(
              controller: _value,
              onLanguageDetected: (l) {
              if (!mounted) return;
              if (_codeLang == l) return;
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (mounted) setState(() => _codeLang = l);
              });
            },
            ),
            if (_codeLang != null)
              Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Text('اعتبارسنجی: $_codeLang',
                    style: theme.textTheme.labelSmall),
              ),
          ],
          if (_type == InfoItemType.link) ...[
            TextField(
              controller: _value,
              textDirection: TextDirection.ltr,
              textAlign: TextAlign.left,
              keyboardType: TextInputType.url,
              decoration: const InputDecoration(
                labelText: 'آدرس سایت',
                hintText: 'https://example.com',
                prefixIcon: Icon(Icons.link),
                helperText: 'چپ‌چین · با یا بدون https',
              ),
            ),
          ],
          if (_type == InfoItemType.address) ..._addressFields(theme),
          if (_type == InfoItemType.image) ..._imageFields(theme),
          if (_type == InfoItemType.text) ..._textEditor(theme),
          if (_type == InfoItemType.prompt) ..._promptEditor(theme),
          const SizedBox(height: 24),
          FilledButton(
            onPressed: _saving ? null : _save,
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.brand3,
              padding: const EdgeInsets.symmetric(vertical: 14),
            ),
            child: Text(_saving ? '…' : 'ذخیره',
                style: const TextStyle(fontWeight: FontWeight.w900)),
          ),
        ],
      ),
    );
  }

  List<Widget> _textEditor(ThemeData theme) {
    return [
      const Text(
        'ویرایشگر متن',
        style: TextStyle(fontWeight: FontWeight.w900, fontSize: 14),
      ),
      const SizedBox(height: 8),
      TextEditorField(
        controller: _value,
        hint: 'یادداشت، توضیح، متن آزاد…',
      ),
    ];
  }

  List<Widget> _imageFields(ThemeData theme) {
    return [
      if (_imageBytes != null) ...[
        ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Image.memory(
            _imageBytes!,
            height: 180,
            width: double.infinity,
            fit: BoxFit.cover,
          ),
        ),
        const SizedBox(height: 8),
      ] else
        Container(
          height: 120,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: theme.colorScheme.outline),
            color: theme.colorScheme.surfaceContainerHighest,
          ),
          child: const Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.image_outlined, size: 36),
              SizedBox(height: 6),
              Text('پیش‌نمایش تصویر'),
            ],
          ),
        ),
      const SizedBox(height: 10),
      FilledButton.icon(
        onPressed: _pickImage,
        style: FilledButton.styleFrom(backgroundColor: AppColors.brand3),
        icon: const Icon(Icons.upload_rounded),
        label: const Text('انتخاب از گالری / فایل'),
      ),
      const SizedBox(height: 8),
      TextField(
        controller: _value,
        maxLines: 2,
        decoration: const InputDecoration(
          labelText: 'یا data URL / آدرس',
          helperText: 'با انتخاب فایل به‌صورت خودکار پر می‌شود',
        ),
      ),
    ];
  }

  List<Widget> _addressFields(ThemeData theme) {
    return [
      // مختصات دستی (بدون نقشه آنلاین — آفلاین کامل)
      Text(
        'مختصات جغرافیایی (اختیاری — دستی)',
        style: theme.textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w800),
      ),
      const SizedBox(height: 6),
      Row(
        children: [
          Expanded(
            child: TextField(
              controller: _lat,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              textDirection: TextDirection.ltr,
              decoration: const InputDecoration(
                labelText: 'عرض',
                hintText: '35.6892',
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: TextField(
              controller: _lng,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              textDirection: TextDirection.ltr,
              decoration: const InputDecoration(
                labelText: 'طول',
                hintText: '51.3890',
              ),
            ),
          ),
        ],
      ),
      const SizedBox(height: 12),
      SegmentedButton<bool>(
        segments: const [
          ButtonSegment(value: false, label: Text('یک باکس'), icon: Icon(Icons.notes, size: 16)),
          ButtonSegment(value: true, label: Text('جداگانه'), icon: Icon(Icons.view_agenda, size: 16)),
        ],
        selected: {_addressSplit},
        onSelectionChanged: (s) => setState(() => _addressSplit = s.first),
      ),
      const SizedBox(height: 12),
      if (!_addressSplit)
        TextField(
          controller: _value,
          maxLines: 4,
          decoration: const InputDecoration(
            labelText: 'آدرس کامل',
            hintText: 'همه آدرس را یکجا بنویس…',
            prefixIcon: Icon(Icons.location_on_outlined),
            alignLabelWithHint: true,
          ),
        )
      else ...[
        TextField(
          controller: _city,
          decoration: const InputDecoration(labelText: 'شهر'),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _district,
          decoration: const InputDecoration(labelText: 'منطقه / محله'),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _street,
          decoration: const InputDecoration(labelText: 'خیابان'),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _alley,
          decoration: const InputDecoration(labelText: 'کوچه'),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _plaque,
          decoration: const InputDecoration(labelText: 'پلاک'),
        ),
      ],
      const SizedBox(height: 10),
      TextField(
        controller: _postal,
        keyboardType: TextInputType.number,
        textDirection: TextDirection.ltr,
        decoration: const InputDecoration(
          labelText: 'کد پستی',
          hintText: '۱۰ رقم',
          prefixIcon: Icon(Icons.local_post_office_outlined),
          helperText: 'برای هر دو حالت فعال است',
        ),
      ),
    ];
  }

  List<Widget> _cardFields(ThemeData theme) {
    return [
      Container(
        padding: const EdgeInsets.all(12),
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: const Color(0xFFF59E0B).withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border:
              Border.all(color: const Color(0xFFF59E0B).withOpacity(0.35)),
        ),
        child: const Text(
          'پیشنهاد نمی‌شود رمز کارت را داخل برنامه ذخیره کنید. کپی همه هم شامل رمز نمی‌شود.',
          style: TextStyle(height: 1.4, fontSize: 12),
        ),
      ),
      DropdownButtonFormField<String>(
        value: _selectedBank,
        decoration: const InputDecoration(
          labelText: 'بانک',
          prefixIcon: Icon(Icons.account_balance_rounded),
        ),
        items: iranianBanks
            .map((b) => DropdownMenuItem(value: b, child: Text(b)))
            .toList(),
        onChanged: (v) {
          setState(() {
            _selectedBank = v;
            _manualBank = v == 'سایر / دستی';
            if (!_manualBank && v != null) _bank.text = v;
          });
        },
      ),
      if (_manualBank) ...[
        const SizedBox(height: 10),
        TextField(
          controller: _bank,
          decoration: const InputDecoration(labelText: 'نام بانک (دستی)'),
        ),
      ],
      const SizedBox(height: 10),
      TextField(
        controller: _cardNumber,
        keyboardType: TextInputType.number,
        textDirection: TextDirection.ltr,
        inputFormatters: [CardNumberFormatter()],
        decoration: const InputDecoration(
          labelText: 'شماره کارت',
          hintText: '6037 9911 2233 4455',
          helperText: 'حداکثر ۱۶ رقم · خودکار ۴رقم‌۴رقم',
          prefixIcon: Icon(Icons.credit_card),
        ),
      ),
      const SizedBox(height: 10),
      TextField(
        controller: _holder,
        decoration: const InputDecoration(
          labelText: 'نام دارنده',
          prefixIcon: Icon(Icons.person_outline),
        ),
      ),
      const SizedBox(height: 10),
      TextField(
        controller: _iban,
        textDirection: TextDirection.ltr,
        inputFormatters: [IbanFormatter()],
        decoration: const InputDecoration(
          labelText: 'شبا',
          helperText: 'پیشوند IR خودکار',
          prefixIcon: Icon(Icons.account_balance_wallet_outlined),
        ),
      ),
      const SizedBox(height: 10),
      TextField(
        controller: _account,
        textDirection: TextDirection.ltr,
        keyboardType: TextInputType.number,
        inputFormatters: [AccountNumberFormatter()],
        decoration: const InputDecoration(
          labelText: 'شماره حساب',
          prefixIcon: Icon(Icons.tag),
        ),
      ),
      const SizedBox(height: 10),
      Row(
        children: [
          Expanded(
            child: TextField(
              controller: _expiry,
              keyboardType: TextInputType.number,
              textDirection: TextDirection.ltr,
              inputFormatters: [ExpiryFormatter()],
              decoration: const InputDecoration(
                  labelText: 'انقضا', hintText: 'MM/YY'),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: TextField(
              controller: _cvv,
              keyboardType: TextInputType.number,
              textDirection: TextDirection.ltr,
              inputFormatters: [CvvFormatter()],
              decoration: const InputDecoration(labelText: 'CVV2'),
            ),
          ),
        ],
      ),
      const SizedBox(height: 10),
      TextField(
        controller: _password,
        obscureText: true,
        decoration: const InputDecoration(
          labelText: 'رمز (ذخیره نمی‌شود — فقط برای یادآوری شما)',
          prefixIcon: Icon(Icons.lock_outline),
        ),
      ),
      const SizedBox(height: 14),
      Text('رنگ کارت',
          style:
              theme.textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w800)),
      const SizedBox(height: 8),
      Wrap(
        spacing: 8,
        children: ['blue', 'purple', 'green', 'red', 'dark'].map((c) {
          final sel = _color == c;
          final colors = {
            'blue': const Color(0xFF2563EB),
            'purple': const Color(0xFF7C3AED),
            'green': const Color(0xFF059669),
            'red': const Color(0xFFDC2626),
            'dark': const Color(0xFF1E293B),
          };
          return GestureDetector(
            onTap: () => setState(() => _color = c),
            child: Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: colors[c],
                shape: BoxShape.circle,
                border: Border.all(
                    color: sel ? Colors.white : Colors.transparent, width: 3),
              ),
            ),
          );
        }).toList(),
      ),
    ];
  }

  List<Widget> _promptEditor(ThemeData theme) {
    return [
      Container(
        padding: const EdgeInsets.all(10),
        margin: const EdgeInsets.only(bottom: 8),
        decoration: BoxDecoration(
          color: const Color(0xFF8B5CF6).withOpacity(0.1),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: const Color(0xFF8B5CF6).withOpacity(0.3)),
        ),
        child: const Text(
          'پرامپت برای هوش مصنوعی — نقش، وظیفه، محدودیت و فرمت خروجی را مشخص کن.',
          style: TextStyle(fontSize: 12, height: 1.4),
        ),
      ),
      Text('جهت نوشتار',
          style: theme.textTheme.labelLarge
              ?.copyWith(fontWeight: FontWeight.w800)),
      const SizedBox(height: 6),
      SegmentedButton<TextDirection>(
        segments: const [
          ButtonSegment(
            value: TextDirection.rtl,
            label: Text('فارسی (راست به چپ)'),
            icon: Icon(Icons.format_textdirection_r_to_l, size: 16),
          ),
          ButtonSegment(
            value: TextDirection.ltr,
            label: Text('English (LTR)'),
            icon: Icon(Icons.format_textdirection_l_to_r, size: 16),
          ),
        ],
        selected: {_promptDir},
        onSelectionChanged: (s) => setState(() => _promptDir = s.first),
      ),
      const SizedBox(height: 10),
      TextField(
        controller: _value,
        maxLines: 12,
        textDirection: _promptDir,
        textAlign:
            _promptDir == TextDirection.rtl ? TextAlign.right : TextAlign.left,
        style: const TextStyle(height: 1.55, fontSize: 15),
        decoration: InputDecoration(
          labelText: 'متن پرامپت',
          alignLabelWithHint: true,
          hintText: _promptDir == TextDirection.rtl
              ? 'تو یک … هستی. وظیفه تو … است.'
              : 'You are a … Your task is …',
          prefixIcon: const Icon(Icons.auto_awesome),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
    ];
  }

}
