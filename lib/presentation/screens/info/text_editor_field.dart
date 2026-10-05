import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/money_format.dart';

/// ویرایشگر متن حرفه‌ای برای صندوق اطلاعات
class TextEditorField extends StatefulWidget {
  final TextEditingController controller;
  final String? hint;

  const TextEditorField({
    super.key,
    required this.controller,
    this.hint,
  });

  @override
  State<TextEditorField> createState() => _TextEditorFieldState();
}

class _TextEditorFieldState extends State<TextEditorField> {
  TextAlign _align = TextAlign.right;
  TextDirection _dir = TextDirection.rtl;
  double _fontSize = 15;
  bool _bold = false;
  final _focus = FocusNode();

  void _onControllerChange() {
    if (!mounted) return;
    setState(() {});
  }

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_onControllerChange);
  }

  @override
  void didUpdateWidget(covariant TextEditorField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      oldWidget.controller.removeListener(_onControllerChange);
      widget.controller.addListener(_onControllerChange);
    }
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onControllerChange);
    _focus.dispose();
    super.dispose();
  }

  int get _chars => widget.controller.text.characters.length;
  int get _words {
    final t = widget.controller.text.trim();
    if (t.isEmpty) return 0;
    return t.split(RegExp(r'\s+')).where((e) => e.isNotEmpty).length;
  }

  int get _lines {
    final t = widget.controller.text;
    if (t.isEmpty) return 0;
    return '\n'.allMatches(t).length + 1;
  }

  void _insert(String before, [String after = '']) {
    if (!mounted) return;
    final c = widget.controller;
    final sel = c.selection;
    final text = c.text;
    final start = sel.start >= 0 ? sel.start : text.length;
    final end = sel.end >= 0 ? sel.end : text.length;
    final selected = text.substring(start, end);
    final next = text.replaceRange(start, end, '$before$selected$after');
    c.value = TextEditingValue(
      text: next,
      selection: TextSelection.collapsed(
        offset: start + before.length + selected.length + after.length,
      ),
    );
    _focus.requestFocus();
  }

  Future<void> _copy() async {
    final t = widget.controller.text;
    if (t.isEmpty) return;
    await Clipboard.setData(ClipboardData(text: t));
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
      content: Text('متن کپی شد'),
      behavior: SnackBarBehavior.fixed,
      duration: Duration(seconds: 1),
    ));
  }

  void _clear() {
    if (!mounted) return;
    widget.controller.clear();
  }

  Widget _tool({
    required IconData icon,
    required String tip,
    required VoidCallback onTap,
    bool active = false,
  }) {
    return Tooltip(
      message: tip,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          width: 36,
          height: 36,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: active ? AppColors.brand3.withOpacity(0.15) : null,
            borderRadius: BorderRadius.circular(8),
            border: active
                ? Border.all(color: AppColors.brand3.withOpacity(0.4))
                : null,
          ),
          child: Icon(icon,
              size: 18, color: active ? AppColors.brand3 : null),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
          decoration: BoxDecoration(
            color: theme.colorScheme.surfaceContainerHighest,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
            border: Border.all(color: theme.colorScheme.outline),
          ),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _tool(
                  icon: Icons.format_bold,
                  tip: 'پررنگ **',
                  active: _bold,
                  onTap: () {
                    setState(() => _bold = !_bold);
                    _insert('**', '**');
                  },
                ),
                _tool(
                  icon: Icons.format_italic,
                  tip: 'کج *',
                  onTap: () => _insert('*', '*'),
                ),
                _tool(
                  icon: Icons.format_underlined,
                  tip: 'زیرخط',
                  onTap: () => _insert('__', '__'),
                ),
                _tool(
                  icon: Icons.title,
                  tip: 'عنوان',
                  onTap: () => _insert('\n# ', ''),
                ),
                _tool(
                  icon: Icons.format_list_bulleted,
                  tip: 'لیست',
                  onTap: () => _insert('\n- ', ''),
                ),
                _tool(
                  icon: Icons.format_quote,
                  tip: 'نقل‌قول',
                  onTap: () => _insert('\n> ', ''),
                ),
                Container(
                    width: 1,
                    height: 22,
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    color: theme.colorScheme.outline),
                _tool(
                  icon: Icons.align_horizontal_right,
                  tip: 'راست‌چین',
                  active: _align == TextAlign.right,
                  onTap: () => setState(() {
                    _align = TextAlign.right;
                    _dir = TextDirection.rtl;
                  }),
                ),
                _tool(
                  icon: Icons.align_horizontal_left,
                  tip: 'چپ‌چین',
                  active: _align == TextAlign.left,
                  onTap: () => setState(() {
                    _align = TextAlign.left;
                    _dir = TextDirection.ltr;
                  }),
                ),
                _tool(
                  icon: Icons.format_align_center,
                  tip: 'وسط',
                  active: _align == TextAlign.center,
                  onTap: () => setState(() => _align = TextAlign.center),
                ),
                Container(
                    width: 1,
                    height: 22,
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    color: theme.colorScheme.outline),
                _tool(
                  icon: Icons.text_decrease,
                  tip: 'کوچک‌تر',
                  onTap: () => setState(
                      () => _fontSize = (_fontSize - 1).clamp(12, 22)),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: Text(
                    MoneyFormat.toPersianDigits('${_fontSize.round()}'),
                    style: const TextStyle(
                        fontWeight: FontWeight.w800, fontSize: 12),
                  ),
                ),
                _tool(
                  icon: Icons.text_increase,
                  tip: 'بزرگ‌تر',
                  onTap: () => setState(
                      () => _fontSize = (_fontSize + 1).clamp(12, 22)),
                ),
                Container(
                    width: 1,
                    height: 22,
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    color: theme.colorScheme.outline),
                _tool(icon: Icons.copy, tip: 'کپی', onTap: _copy),
                _tool(icon: Icons.delete_outline, tip: 'پاک', onTap: _clear),
              ],
            ),
          ),
        ),
        Container(
          height: 280,
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            border: Border(
              left: BorderSide(color: theme.colorScheme.outline),
              right: BorderSide(color: theme.colorScheme.outline),
              bottom: BorderSide(color: theme.colorScheme.outline),
            ),
            borderRadius:
                const BorderRadius.vertical(bottom: Radius.circular(12)),
          ),
          child: TextField(
            controller: widget.controller,
            focusNode: _focus,
            maxLines: null,
            expands: true,
            textAlign: _align,
            textDirection: _dir,
            style: TextStyle(
              fontSize: _fontSize,
              height: 1.65,
              fontWeight: _bold ? FontWeight.w700 : FontWeight.w500,
            ),
            decoration: InputDecoration(
              border: InputBorder.none,
              contentPadding: const EdgeInsets.all(14),
              hintText: widget.hint ?? 'متن خود را اینجا بنویس…',
              hintStyle: TextStyle(
                color: theme.colorScheme.onSurface.withOpacity(0.35),
              ),
            ),
          ),
        ),
        const SizedBox(height: 6),
        Row(
          children: [
            _stat(theme, 'کلمه', _words),
            const SizedBox(width: 12),
            _stat(theme, 'کاراکتر', _chars),
            const SizedBox(width: 12),
            _stat(theme, 'خط', _lines),
            const Spacer(),
            Text(
              _dir == TextDirection.rtl ? 'RTL' : 'LTR',
              style: theme.textTheme.labelSmall?.copyWith(
                fontWeight: FontWeight.w800,
                color: AppColors.brand3,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _stat(ThemeData theme, String label, int n) {
    return Text(
      '$label: ${MoneyFormat.toPersianDigits('$n')}',
      style: theme.textTheme.labelSmall?.copyWith(
        color: theme.colorScheme.onSurface.withOpacity(0.5),
      ),
    );
  }
}
