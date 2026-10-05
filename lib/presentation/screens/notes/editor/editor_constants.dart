import 'package:flutter/material.dart';

const noteCategories = ['عمومی', 'ایده‌ها', 'کاری', 'شخصی', 'مطالعه'];

const noteColorKeys = ['blue', 'purple', 'green', 'yellow', 'red', 'pink'];

const noteColorMap = {
  'blue': Color(0xFF3B82F6),
  'purple': Color(0xFF8B5CF6),
  'green': Color(0xFF10B981),
  'yellow': Color(0xFFF59E0B),
  'red': Color(0xFFEF4444),
  'pink': Color(0xFFEC4899),
};

const textColors = [
  Color(0xFF0F172A),
  Color(0xFFFFFFFF),
  Color(0xFFEF4444),
  Color(0xFF3B82F6),
  Color(0xFF10B981),
  Color(0xFFF59E0B),
  Color(0xFF8B5CF6),
  Color(0xFFEC4899),
];

const highlightColors = [
  Color(0xFFFEF08A),
  Color(0xFFBBF7D0),
  Color(0xFFBFDBFE),
  Color(0xFFFBCFE8),
  Color(0xFFDDD6FE),
  Color(0xFFFED7AA),
];

const emojis = [
  '😀','😁','😂','🤣','😃','😄','😅','😆','😉','😊','😋','😎','😍','😘','🥰',
  '😗','😙','😚','🙂','🤗','🤩','🤔','🤨','😐','😑','😶','🙄','😏','😣','😥',
  '😮','🤐','😯','😪','😫','🥱','😴','😌','😛','😜','😝','🤤','😒','😓','😔',
  '😕','🙃','🤑','😲','☹️','🙁','😖','😞','😟','😤','😢','😭','😦','😧','😨',
  '😩','🤯','😬','😰','😱','🥵','🥶','😳','🤪','😵','🥴','😠','😡','🤬','😷',
  '👍','👎','👏','🙌','👐','🤝','🙏','✌️','🤞','🤟','🤘','👌','❤️','🧡','💛',
  '💚','💙','💜','🖤','🤍','💔','⭐','🌟','✨','⚡','🔥','💥','☀️','🌈','🎉',
  '🎊','🎈','🎁','🏆','🥇','📝','📌','✅','❌','💡','📎','🔗','📅','⏰','🎵',
];

const specialChars = [
  '©','®','™','€','£','¥','₽','₹','§','¶','•','°','′','″','‰','«','»','‹','›',
  '–','—','…','·','×','÷','±','∞','≈','≠','≤','≥',
];

const greekLetters = [
  'α','β','γ','δ','ε','ζ','η','θ','ι','κ','λ','μ','ν','ξ','ο','π','ρ','σ','τ','υ','φ','χ','ψ','ω',
  'Α','Β','Γ','Δ','Ε','Ζ','Η','Θ','Ι','Κ','Λ','Μ','Ν','Ξ','Ο','Π','Ρ','Σ','Τ','Υ','Φ','Χ','Ψ','Ω',
];

const mathOperators = [
  '×','÷','±','∓','≠','≈','≡','≤','≥','∞','∑','∏','∫','∂','∇','√','∠','△','⊥','∈','∉','⊂','∪','∩','∀','∃','∴','∝',
];

const mathArrows = ['→','←','↑','↓','↔','⇒','⇐','⇔','⟶','↦','↪','↩'];

const geometrySymbols = ['∠','△','▲','▼','○','●','□','■','◇','◆','⟂','∥','∟'];

const formulas = [
  ('اینشتین', 'E = mc²'),
  ('فیثاغورس', 'a² + b² = c²'),
  ('مساحت دایره', 'A = πr²'),
  ('محیط دایره', 'C = 2πr'),
  ('حجم کره', 'V = (4/3)πr³'),
  ('قانون اهم', 'V = IR'),
  ('نیوتن دوم', 'F = ma'),
  ('گرانش', 'F = G(m₁m₂)/r²'),
  ('انرژی جنبشی', 'K = ½mv²'),
  ('پتانسیل', 'U = mgh'),
  ('موج', 'v = fλ'),
  ('پلانک', 'E = hν'),
  ('شرودینگر', 'iℏ ∂ψ/∂t = Ĥψ'),
  ('اتحاد مربع', '(a+b)² = a²+2ab+b²'),
  ('مزدوج', 'a²−b² = (a−b)(a+b)'),
  ('مجموع طبیعی', '∑ i = n(n+1)/2'),
  ('لگاریتم', 'log(ab) = log a + log b'),
  ('نپری', 'lim(1+1/n)ⁿ = e'),
  ('مشتق سینوس', 'd/dx sin x = cos x'),
  ('اتحاد مثلثاتی', 'sin²θ + cos²θ = 1'),
  ('دوبرابر زاویه', 'sin 2θ = 2 sinθ cosθ'),
  ('بویل', 'P₁V₁ = P₂V₂'),
  ('تیلور', 'eˣ = ∑ xⁿ/n!'),
  ('انتگرال نمایی', '∫ eˣ dx = eˣ + C'),
];

/// تب‌های ادیتور — بدون تکرار
enum EditorToolTab {
  format, // P H1–H4 نقل‌قول کد
  style, // bold italic ...
  color,
  align,
  list,
  insert, // لینک تصویر ویس
  table, // اکسل
  tools, // undo redo پاک‌سازی تاریخ ریاضی تمام‌صفحه
}

extension EditorToolTabX on EditorToolTab {
  String get label {
    switch (this) {
      case EditorToolTab.format:
        return 'قالب';
      case EditorToolTab.style:
        return 'سبک';
      case EditorToolTab.color:
        return 'رنگ';
      case EditorToolTab.align:
        return 'تراز';
      case EditorToolTab.list:
        return 'لیست';
      case EditorToolTab.insert:
        return 'درج';
      case EditorToolTab.table:
        return 'اکسل';
      case EditorToolTab.tools:
        return 'ابزار';
    }
  }

  IconData get icon {
    switch (this) {
      case EditorToolTab.format:
        return Icons.title_rounded;
      case EditorToolTab.style:
        return Icons.format_bold_rounded;
      case EditorToolTab.color:
        return Icons.palette_outlined;
      case EditorToolTab.align:
        return Icons.format_align_right_rounded;
      case EditorToolTab.list:
        return Icons.format_list_bulleted_rounded;
      case EditorToolTab.insert:
        return Icons.add_circle_outline_rounded;
      case EditorToolTab.table:
        return Icons.grid_on_rounded;
      case EditorToolTab.tools:
        return Icons.tune_rounded;
    }
  }
}
