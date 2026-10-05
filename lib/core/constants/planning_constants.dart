/// ثابت‌ها و کاتالوگ برنامه‌ها — مطابق دمو نوژین

enum PlanningSubTab {
  home, // نمای اصلی مثل دمو
  habits,
  priorities,
}

extension PlanningSubTabX on PlanningSubTab {
  String get label {
    switch (this) {
      case PlanningSubTab.home:
        return 'اصلی';
      case PlanningSubTab.habits:
        return 'عادت‌ها';
      case PlanningSubTab.priorities:
        return 'اولویت‌ها';
    }
  }
}

enum ProgramCategory { all, jp, focus, psy, mgmt }

class ProgramDef {
  final String id;
  final String name;
  final String desc;
  final String origin;
  final ProgramCategory category;
  final String colorKey;

  const ProgramDef({
    required this.id,
    required this.name,
    required this.desc,
    required this.origin,
    required this.category,
    required this.colorKey,
  });
}

const defaultActivePrograms = <String>['eisen', 'habits', 'pomodoro'];

/// کاتالوگ کامل مطابق دمو
const programCatalog = <ProgramDef>[
  // ژاپنی
  ProgramDef(id: 'kaizen', name: 'کایزن', desc: 'بهبود ۱٪ روزانه', origin: 'ژاپن', category: ProgramCategory.jp, colorKey: 'success'),
  ProgramDef(id: 'fiveS', name: '۵S', desc: 'نظم محیط کار', origin: 'ژاپن', category: ProgramCategory.jp, colorKey: 'info'),
  ProgramDef(id: 'kanban', name: 'کانبان', desc: 'تخته کارها', origin: 'ژاپن', category: ProgramCategory.jp, colorKey: 'purple'),
  ProgramDef(id: 'ikigai', name: 'ایکیگای', desc: 'دلیل زندگی', origin: 'ژاپن', category: ProgramCategory.jp, colorKey: 'pink'),
  ProgramDef(id: 'pdca', name: 'PDCA', desc: 'طرح، اجرا، بررسی', origin: 'ژاپن', category: ProgramCategory.jp, colorKey: 'warn'),
  ProgramDef(id: 'hoshin', name: 'هوشین کانری', desc: 'هم‌راستاسازی', origin: 'ژاپن', category: ProgramCategory.jp, colorKey: 'success'),
  // تمرکز
  ProgramDef(id: 'pomodoro', name: 'پومودورو', desc: 'تمرکز ۲۵ دقیقه', origin: 'ایتالیا', category: ProgramCategory.focus, colorKey: 'danger'),
  ProgramDef(id: 'deepwork', name: 'کار عمیق', desc: 'تمرکز عمیق', origin: 'آمریکا', category: ProgramCategory.focus, colorKey: 'info'),
  ProgramDef(id: 'frog', name: 'قورباغه', desc: 'سخت‌ترین کار روز', origin: 'روانشناسی', category: ProgramCategory.focus, colorKey: 'success'),
  ProgramDef(id: 'twoMin', name: '۲ دقیقه', desc: 'کارهای کوچک', origin: 'روانشناسی', category: ProgramCategory.focus, colorKey: 'warn'),
  // روان‌شناسی
  ProgramDef(id: 'mood', name: 'مود تراکر', desc: 'ردیابی حال', origin: 'روانشناسی', category: ProgramCategory.psy, colorKey: 'pink'),
  ProgramDef(id: 'gratitude', name: 'شکرگزاری', desc: 'سه نعمت امروز', origin: 'روانشناسی', category: ProgramCategory.psy, colorKey: 'success'),
  ProgramDef(id: 'cbt', name: 'ژورنال CBT', desc: 'بازنویسی افکار', origin: 'روانشناسی', category: ProgramCategory.psy, colorKey: 'info'),
  ProgramDef(id: 'growth', name: 'ذهن رشد', desc: 'ذهنیت رشد', origin: 'روانشناسی', category: ProgramCategory.psy, colorKey: 'purple'),
  // مدیریت
  ProgramDef(id: 'eisen', name: 'آیزنهاور', desc: 'ماتریس فوری/مهم', origin: 'مدیریت', category: ProgramCategory.mgmt, colorKey: 'info'),
  ProgramDef(id: 'smart', name: 'هدف SMART', desc: 'اهداف دقیق', origin: 'مدیریت', category: ProgramCategory.mgmt, colorKey: 'purple'),
  ProgramDef(id: 'timeblock', name: 'تایم بلاکینگ', desc: 'تقسیم روز', origin: 'مدیریت', category: ProgramCategory.mgmt, colorKey: 'warn'),
  ProgramDef(id: 'wheel', name: 'چرخ زندگی', desc: 'تعادل ۸ حوزه', origin: 'کوچینگ', category: ProgramCategory.mgmt, colorKey: 'success'),
  ProgramDef(id: 'habits', name: 'ردیاب عادت', desc: 'پیگیری روزانه', origin: 'عمومی', category: ProgramCategory.mgmt, colorKey: 'danger'),
];

String programCategoryLabel(ProgramCategory c) {
  switch (c) {
    case ProgramCategory.all:
      return 'همه';
    case ProgramCategory.jp:
      return 'ژاپنی';
    case ProgramCategory.focus:
      return 'تمرکز';
    case ProgramCategory.psy:
      return 'روانشناسی';
    case ProgramCategory.mgmt:
      return 'مدیریتی';
  }
}
