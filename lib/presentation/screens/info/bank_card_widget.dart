import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/utils/money_format.dart';
import '../../../domain/entities/info_item_entity.dart';

String formatCardNumber(String raw) {
  final d = raw.replaceAll(RegExp(r'\D'), '');
  final buf = StringBuffer();
  for (var i = 0; i < d.length; i++) {
    if (i > 0 && i % 4 == 0) buf.write(' ');
    buf.write(d[i]);
  }
  return buf.toString();
}

String cleanDigits(String raw) => raw.replaceAll(RegExp(r'\D'), '');

String formatIban(String raw) {
  var s = raw.replaceAll(RegExp(r'\s'), '').toUpperCase();
  if (s.startsWith('IR')) {
    final rest = s.substring(2).replaceAll(RegExp(r'\D'), '');
    final buf = StringBuffer('IR');
    for (var i = 0; i < rest.length; i++) {
      if (i % 4 == 0) buf.write(' ');
      buf.write(rest[i]);
    }
    return buf.toString().trim();
  }
  final d = s.replaceAll(RegExp(r'\D'), '');
  final buf = StringBuffer();
  for (var i = 0; i < d.length; i++) {
    if (i > 0 && i % 4 == 0) buf.write(' ');
    buf.write(d[i]);
  }
  return buf.toString();
}

String cleanIban(String raw) =>
    raw.replaceAll(RegExp(r'\s'), '').toUpperCase();

class BankCardWidget extends StatelessWidget {
  final InfoItemEntity item;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;
  final void Function(String fieldLabel)? onCopied;

  const BankCardWidget({
    super.key,
    required this.item,
    this.onEdit,
    this.onDelete,
    this.onCopied,
  });

  static LinearGradient gradientFor(String color) {
    switch (color) {
      case 'purple':
        return const LinearGradient(
          colors: [Color(0xFF7C3AED), Color(0xFF4C1D95)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        );
      case 'green':
        return const LinearGradient(
          colors: [Color(0xFF059669), Color(0xFF064E3B)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        );
      case 'red':
        return const LinearGradient(
          colors: [Color(0xFFDC2626), Color(0xFF7F1D1D)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        );
      case 'dark':
        return const LinearGradient(
          colors: [Color(0xFF1E293B), Color(0xFF0F172A)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        );
      default:
        return const LinearGradient(
          colors: [Color(0xFF2563EB), Color(0xFF1E3A8A)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        );
    }
  }

  Future<void> _copy(
    BuildContext context,
    String label,
    String copyValue, {
    bool allowed = true,
  }) async {
    if (!allowed) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'پیشنهاد نمی‌شود رمز را داخل برنامه نگه دارید — کپی غیرفعال است',
          ),
          behavior: SnackBarBehavior.fixed,
          duration: Duration(seconds: 3),
        ),
      );
      return;
    }
    if (copyValue.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('$label خالی است'),
          behavior: SnackBarBehavior.fixed,
          duration: const Duration(seconds: 1),
        ),
      );
      return;
    }
    await Clipboard.setData(ClipboardData(text: copyValue.trim()));
    onCopied?.call(label);
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('$label کپی شد'),
          behavior: SnackBarBehavior.fixed,
          duration: const Duration(seconds: 1),
        ),
      );
    }
  }

  Future<void> _copyAll(BuildContext context, CardDetails c) async {
    final parts = <String>[];
    final num = cleanDigits(c.cardNumber);
    if (num.isNotEmpty) parts.add('شماره کارت: $num');
    if (c.holderName.trim().isNotEmpty) {
      parts.add('دارنده: ${c.holderName.trim()}');
    }
    if (c.expiry.trim().isNotEmpty) {
      parts.add('انقضا: ${c.expiry.replaceAll(RegExp(r'\s'), '')}');
    }
    final cvv = cleanDigits(c.cvv);
    if (cvv.isNotEmpty) parts.add('CVV2: $cvv');
    final iban = cleanIban(c.iban);
    if (iban.isNotEmpty) parts.add('شبا: $iban');
    final acc = cleanDigits(c.accountNumber);
    if (acc.isNotEmpty) parts.add('شماره حساب: $acc');
    if (c.bankName.trim().isNotEmpty) {
      parts.add('بانک: ${c.bankName.trim()}');
    }
    // رمز عمداً اضافه نمی‌شود
    if (parts.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('چیزی برای کپی نیست'),
        behavior: SnackBarBehavior.fixed,
      ));
      return;
    }
    await Clipboard.setData(ClipboardData(text: parts.join('\n')));
    onCopied?.call('همه');
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('اطلاعات کارت کپی شد (بدون رمز)'),
        behavior: SnackBarBehavior.fixed,
        duration: Duration(seconds: 2),
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = item.card ?? const CardDetails();
    final theme = Theme.of(context);
    final displayNum = formatCardNumber(c.cardNumber);
    final copyNum = cleanDigits(c.cardNumber);
    final displayIban = c.iban.isEmpty ? '' : formatIban(c.iban);
    final copyIban = cleanIban(c.iban);
    final copyAccount = cleanDigits(c.accountNumber);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            gradient: gradientFor(item.color),
            borderRadius: BorderRadius.circular(18),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.18),
                blurRadius: 12,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  const Icon(Icons.credit_card_rounded,
                      color: Colors.white70, size: 22),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      item.title.isEmpty
                          ? (c.bankName.isEmpty ? 'کارت بانکی' : c.bankName)
                          : item.title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w900,
                        fontSize: 14,
                      ),
                    ),
                  ),
                  if (c.bankName.isNotEmpty && item.title.isNotEmpty)
                    Text(
                      c.bankName,
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 20),
              InkWell(
                onTap: () => _copy(context, 'شماره کارت', copyNum),
                borderRadius: BorderRadius.circular(8),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Text(
                    displayNum.isEmpty ? '•••• •••• •••• ••••' : displayNum,
                    textDirection: TextDirection.ltr,
                    textAlign: TextAlign.left,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.2,
                      fontFamily: 'monospace',
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _Field(
                      label: 'دارنده',
                      value: c.holderName.isEmpty ? '—' : c.holderName,
                      onTap: () =>
                          _copy(context, 'نام دارنده', c.holderName),
                    ),
                  ),
                  const SizedBox(width: 8),
                  _Field(
                    label: 'انقضا',
                    value: c.expiry.isEmpty ? '—/—' : c.expiry,
                    onTap: () => _copy(
                      context,
                      'تاریخ انقضا',
                      c.expiry.replaceAll(RegExp(r'\s'), ''),
                    ),
                  ),
                  const SizedBox(width: 8),
                  _Field(
                    label: 'CVV2',
                    value: c.cvv.isEmpty ? '•••' : c.cvv,
                    onTap: () => _copy(context, 'CVV2', cleanDigits(c.cvv)),
                  ),
                ],
              ),
              if (c.iban.isNotEmpty) ...[
                const SizedBox(height: 8),
                _Field(
                  label: 'شبا',
                  value: displayIban,
                  ltr: true,
                  onTap: () => _copy(context, 'شبا', copyIban),
                ),
              ],
              if (c.accountNumber.isNotEmpty) ...[
                const SizedBox(height: 8),
                _Field(
                  label: 'شماره حساب',
                  value: formatCardNumber(c.accountNumber),
                  ltr: true,
                  onTap: () => _copy(context, 'شماره حساب', copyAccount),
                ),
              ],
              if (c.password.isNotEmpty) ...[
                const SizedBox(height: 8),
                _Field(
                  label: 'رمز',
                  value: '••••••',
                  warning: true,
                  onTap: () =>
                      _copy(context, 'رمز', c.password, allowed: false),
                ),
              ],
            ],
          ),
        ),
        if (c.password.isNotEmpty)
          Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xFFF59E0B).withOpacity(0.12),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                  color: const Color(0xFFF59E0B).withOpacity(0.35)),
            ),
            child: Row(
              children: [
                const Icon(Icons.warning_amber_rounded,
                    size: 18, color: Color(0xFFD97706)),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'پیشنهاد نمی‌شود رمز کارت را داخل برنامه ذخیره کنید. این فیلد کپی نمی‌شود.',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: const Color(0xFFB45309),
                      height: 1.35,
                    ),
                  ),
                ),
              ],
            ),
          ),
        Row(
          children: [
            Text(
              '${MoneyFormat.toPersianDigits('${item.uses}')} بار استفاده',
              style: theme.textTheme.labelSmall?.copyWith(
                color: theme.colorScheme.onSurface.withOpacity(0.45),
              ),
            ),
            const Spacer(),
            TextButton.icon(
              onPressed: () => _copyAll(context, c),
              icon: const Icon(Icons.copy_all_rounded, size: 16),
              label: const Text('کپی همه'),
            ),
            if (onEdit != null)
              TextButton.icon(
                onPressed: onEdit,
                icon: const Icon(Icons.edit_outlined, size: 16),
                label: const Text('ویرایش'),
              ),
            if (onDelete != null)
              TextButton.icon(
                onPressed: onDelete,
                icon: const Icon(Icons.delete_outline,
                    size: 16, color: Colors.red),
                label:
                    const Text('حذف', style: TextStyle(color: Colors.red)),
              ),
          ],
        ),
      ],
    );
  }
}

class _Field extends StatelessWidget {
  final String label;
  final String value;
  final VoidCallback onTap;
  final bool ltr;
  final bool warning;

  const _Field({
    required this.label,
    required this.value,
    required this.onTap,
    this.ltr = false,
    this.warning = false,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(warning ? 0.08 : 0.12),
          borderRadius: BorderRadius.circular(8),
          border: warning
              ? Border.all(color: Colors.amber.withOpacity(0.5))
              : null,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: TextStyle(
                color: Colors.white.withOpacity(0.65),
                fontSize: 10,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              value,
              textDirection: ltr ? TextDirection.ltr : null,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w800,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
