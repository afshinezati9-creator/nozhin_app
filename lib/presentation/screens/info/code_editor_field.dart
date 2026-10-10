import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/utils/money_format.dart';

/// ویرایشگر کد تیره — مشابه دمو: پس‌زمینه تیره، متن روشن، شماره خط، LTR
class CodeEditorField extends StatefulWidget {
  final TextEditingController controller;
  final ValueChanged<String>? onLanguageDetected;

  const CodeEditorField({
    super.key,
    required this.controller,
    this.onLanguageDetected,
  });

  @override
  State<CodeEditorField> createState() => _CodeEditorFieldState();
}

class _CodeEditorFieldState extends State<CodeEditorField> {
  final _scroll = ScrollController();
  final _lineScroll = ScrollController();
  final _focus = FocusNode();
  int _lineCount = 1;
  String _lang = 'متن';
  String _hint = 'هنوز کدی نوشته نشده';
  Color _langColor = const Color(0xFFA5B4FC);
  double _fontSize = 13;

  static const _bg = Color(0xFF0D1117);
  static const _panel = Color(0xFF151B26);
  static const _lineBg = Color(0xFF161B22);
  static const _border = Color(0xFF21262D);
  static const _text = Color(0xFFE6EDF3);
  static const _muted = Color(0xFF8B949E);
  static const _accent = Color(0xFF58A6FF);

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_onChange);
    _scroll.addListener(_syncLines);
    WidgetsBinding.instance.addPostFrameCallback((_) => _onChange());
  }

  void _syncLines() {
    if (!_lineScroll.hasClients) return;
    final max = _lineScroll.position.maxScrollExtent;
    final target = _scroll.offset.clamp(0.0, max);
    if ((target - _lineScroll.offset).abs() > 0.5) {
      _lineScroll.jumpTo(target);
    }
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onChange);
    _scroll.dispose();
    _lineScroll.dispose();
    _focus.dispose();
    super.dispose();
  }

  void _onChange() {
    if (!mounted) return;
    final text = widget.controller.text;
    final lines = text.isEmpty ? 1 : '\n'.allMatches(text).length + 1;
    final detected = _detectLang(text);
    final lang = detected.$1;
    final hint = detected.$2;
    final color = detected.$3;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      setState(() {
        _lineCount = lines;
        _lang = lang;
        _hint = hint;
        _langColor = color;
      });
      widget.onLanguageDetected?.call(lang);
    });
  }

  (String, String, Color) _detectLang(String t) {
    final s = t.trim();
    if (s.isEmpty) return ('خالی', 'هنوز کدی نوشته نشده', const Color(0xFF6E7681));
    if ((s.startsWith('{') || s.startsWith('[')) && s.contains('"')) {
      return ('JSON', 'داده ساختاریافته', const Color(0xFFFBBF24));
    }
    if (s.contains('def ') || s.contains('print(') || s.contains('import ')) {
      return ('Python', 'پایتون', const Color(0xFF3FB950));
    }
    if (s.contains('function') || s.contains('const ') || s.contains('=>') ||
        s.contains('console.log') || s.contains('let ')) {
      return ('JS', 'جاوااسکریپت', const Color(0xFFA5B4FC));
    }
    if (RegExp(r'\b(SELECT|FROM|INSERT|UPDATE)\b', caseSensitive: false).hasMatch(s)) {
      return ('SQL', 'پایگاه‌داده', const Color(0xFF58A6FF));
    }
    if (s.contains('package ') && s.contains('import')) {
      return ('Dart', 'دارت / فلاتر', const Color(0xFF22D3EE));
    }
    if (s.contains('<html') || s.contains('<div') || s.contains('</')) {
      return ('HTML', 'نشانه‌گذاری', const Color(0xFF7EE787));
    }
    if (s.contains('{') && s.contains(';') && s.contains(':')) {
      return ('CSS', 'استایل', const Color(0xFF79C0FF));
    }
    return ('متن', 'زبان مشخص نشد', _muted);
  }

  Future<void> _test() async {
    final text = widget.controller.text;
    final (lang, hint, _) = _detectLang(text);
    if (!mounted) return;
    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: _panel,
        title: const Text('بررسی کد', style: TextStyle(color: _text)),
        content: Text(
          'زبان: $lang\n$hint\nخطوط: ${MoneyFormat.toPersianDigits('$_lineCount')}',
          style: const TextStyle(color: _text, height: 1.5),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('باشه', style: TextStyle(color: _accent)),
          ),
        ],
      ),
    );
  }

  Future<void> _copy() async {
    if (widget.controller.text.isEmpty) return;
    await Clipboard.setData(ClipboardData(text: widget.controller.text));
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
      content: Text('کد کپی شد'),
      behavior: SnackBarBehavior.fixed,
      duration: Duration(seconds: 1),
    ));
  }

  void _clear() {
    widget.controller.clear();
    _onChange();
  }

  @override
  Widget build(BuildContext context) {
    // Theme override so Material TextField stays dark
    return Theme(
      data: ThemeData.dark().copyWith(
        inputDecorationTheme: const InputDecorationTheme(
          filled: true,
          fillColor: _bg,
          border: InputBorder.none,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // نوار بالا — نقاط + زبان
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: const BoxDecoration(
              color: _panel,
              borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
              border: Border(bottom: BorderSide(color: _border)),
            ),
            child: Row(
              children: [
                _dot(const Color(0xFFFF5F56)),
                const SizedBox(width: 6),
                _dot(const Color(0xFFFFBD2E)),
                const SizedBox(width: 6),
                _dot(const Color(0xFF27C93F)),
                const SizedBox(width: 10),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: _langColor.withOpacity(0.18),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    _lang,
                    style: TextStyle(
                      color: _langColor,
                      fontSize: 11,
                      fontWeight: FontWeight.w900,
                      fontFamily: 'monospace',
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _hint,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: _muted, fontSize: 11),
                  ),
                ),
                Text(
                  '${MoneyFormat.toPersianDigits('$_lineCount')} خط',
                  style: const TextStyle(
                    color: _muted,
                    fontSize: 11,
                    fontFamily: 'monospace',
                  ),
                ),
              ],
            ),
          ),
          // نوار ابزار
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            color: const Color(0xFF11161F),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _barBtn('A+', () => setState(
                      () => _fontSize = (_fontSize + 1).clamp(10, 22))),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 6),
                    child: Text(
                      MoneyFormat.toPersianDigits('${_fontSize.round()}'),
                      style: const TextStyle(
                          color: _muted,
                          fontFamily: 'monospace',
                          fontWeight: FontWeight.w700),
                    ),
                  ),
                  _barBtn('A−', () => setState(
                      () => _fontSize = (_fontSize - 1).clamp(10, 22))),
                  const SizedBox(width: 8),
                  _barBtn('پاک', _clear, danger: true),
                  _barBtn('کپی', _copy),
                  _barBtn('تست', _test),
                ],
              ),
            ),
          ),
          // بدنه — در RTL: اول شماره خط (راست)، بعد کد (چپ)
          Container(
            height: 300,
            decoration: BoxDecoration(
              color: _bg,
              border: Border.all(color: _border),
              borderRadius:
                  const BorderRadius.vertical(bottom: Radius.circular(12)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              textDirection: TextDirection.ltr, // شماره خط سمت چپ (شروع کد)
              children: [
                // شماره خطوط (چپ — کنار شروع نوشتار)
                Container(
                  width: 44,
                  color: _lineBg,
                  child: ListView.builder(
                    controller: _lineScroll,
                    physics: const NeverScrollableScrollPhysics(),
                    padding: const EdgeInsets.only(top: 14, bottom: 14),
                    itemCount: _lineCount,
                    itemBuilder: (_, i) {
                      final h = _fontSize * 1.65;
                      return SizedBox(
                        height: h,
                        child: Center(
                          child: Text(
                            '${i + 1}',
                            style: TextStyle(
                              color: _muted.withOpacity(0.9),
                              fontSize: _fontSize - 1,
                              fontFamily: 'monospace',
                              height: 1.65,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
                Container(width: 1, color: _border),
                // ناحیه کد (چپ، LTR)
                Expanded(
                  child: Directionality(
                    textDirection: TextDirection.ltr,
                    child: TextField(
                      controller: widget.controller,
                      focusNode: _focus,
                      maxLines: null,
                      expands: true,
                      scrollController: _scroll,
                      textDirection: TextDirection.ltr,
                      textAlign: TextAlign.left,
                      cursorColor: _accent,
                      style: TextStyle(
                        fontFamily: 'monospace',
                        fontSize: _fontSize,
                        height: 1.65,
                        color: _text,
                        letterSpacing: 0.2,
                      ),
                      keyboardType: TextInputType.multiline,
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: _bg,
                        border: InputBorder.none,
                        enabledBorder: InputBorder.none,
                        focusedBorder: InputBorder.none,
                        contentPadding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
                        hintText: '// code from left...',
                        hintStyle: TextStyle(
                          color: const Color(0xFF484F58),
                          fontFamily: 'monospace',
                          fontSize: _fontSize,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _dot(Color c) => Container(
        width: 11,
        height: 11,
        decoration: BoxDecoration(color: c, shape: BoxShape.circle),
      );

  Widget _barBtn(String label, VoidCallback onTap, {bool danger = false}) {
    return Padding(
      padding: const EdgeInsets.only(left: 4),
      child: Material(
        color: const Color(0xFF131A22),
        borderRadius: BorderRadius.circular(8),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(8),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: _border),
            ),
            child: Text(
              label,
              style: TextStyle(
                color: danger ? const Color(0xFFF85149) : _muted,
                fontSize: 12,
                fontWeight: FontWeight.w700,
                fontFamily: 'monospace',
              ),
            ),
          ),
        ),
      ),
    );
  }
}
