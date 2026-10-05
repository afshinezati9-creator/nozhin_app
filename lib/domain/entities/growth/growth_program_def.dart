/// تعریف کاتالوگ برنامه (ثابت) — آموزش باید بدون اپ هم قابل استفاده باشد
class GrowthProgramDef {
  final String id;
  final String nameFa;
  final String oneLiner;
  final String categoryId;
  final String origin;
  final int approxMinutes;
  final String difficulty; // ساده | متوسط | پیشرفته
  final List<String> suitableFor;
  final String whatIs;
  final String whyMatters;
  final String howSteps; // مراحل قابل اجرا بیرون از اپ
  final String notFor; // انتظارات غلط
  final List<String> learnCriteria; // چه می‌سنجیم

  const GrowthProgramDef({
    required this.id,
    required this.nameFa,
    required this.oneLiner,
    required this.categoryId,
    required this.origin,
    required this.approxMinutes,
    required this.difficulty,
    required this.suitableFor,
    required this.whatIs,
    required this.whyMatters,
    required this.howSteps,
    required this.notFor,
    required this.learnCriteria,
  });
}
