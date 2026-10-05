import '../../domain/entities/growth/growth_enums.dart';
import 'growth_catalog.dart';

/// سنسور کشف — قواعد ساده، بدون AI
class SensorOption {
  final String id;
  final String label;
  const SensorOption(this.id, this.label);
}

class SensorResult {
  final String primaryProgramId;
  final List<String> alternatives;
  final String why;
  final GrowthNeedArea area;

  const SensorResult({
    required this.primaryProgramId,
    required this.alternatives,
    required this.why,
    required this.area,
  });
}

class GrowthSensor {
  static const areas = <SensorOption>[
    SensorOption('focus', 'تمرکز'),
    SensorOption('habit', 'عادت'),
    SensorOption('time', 'زمان'),
    SensorOption('goal', 'هدف'),
    SensorOption('decision', 'تصمیم‌گیری'),
    SensorOption('self', 'خودشناسی'),
    SensorOption('unknown', 'هنوز نمی‌دانم'),
  ];

  static List<SensorOption> questionsFor(String areaId) {
    switch (areaId) {
      case 'focus':
        return const [
          SensorOption('start', 'شروع کار سخت است'),
          SensorOption('distract', 'زود حواس‌پرت می‌شوم'),
          SensorOption('deep', 'نیاز به کار عمیق دارم'),
        ];
      case 'habit':
        return const [
          SensorOption('small', 'کارهای کوچک جمع می‌شوند'),
          SensorOption('track', 'می‌خواهم تداوم را ببینم'),
          SensorOption('improve', 'بهبود خیلی کوچک روزانه'),
          SensorOption('space', 'محیط کارم شلوغ و نامرتب است'),
        ];
      case 'time':
        return const [
          SensorOption('plan_day', 'روز را واقع‌بینانه بچینم'),
          SensorOption('priority', 'اولویت‌ها قاطی است'),
          SensorOption('flow', 'چند کار موازی دارم و گیر می‌کنم'),
          SensorOption('next', 'پروژه‌ها مبهم‌اند؛ نمی‌دانم قدم بعدی چیست'),
        ];
      case 'goal':
        return const [
          SensorOption('clarify', 'هدفم مبهم است'),
          SensorOption('review', 'روز را جمع‌بندی کنم'),
          SensorOption('align', 'چند هدف دارم و هم‌راستا نیستند'),
          SensorOption('measure', 'می‌خواهم نتیجه کلیدی قابل‌سنجش داشته باشم'),
        ];
      case 'decision':
        return const [
          SensorOption('hard_first', 'کار سخت را عقب می‌اندازم'),
          SensorOption('matrix', 'نمی‌دانم چه چیزی مهم است'),
          SensorOption('strategy', 'برای یک موضوع مهم باید قوت/ضعف را ببینم'),
          SensorOption('focus20', 'لیستم شلوغ است؛ می‌خواهم روی اثرگذارها بمانم'),
        ];
      case 'self':
        return const [
          SensorOption('mood', 'می‌خواهم حال روز را ببینم'),
          SensorOption('reflect', 'نیاز به مرور کوتاه دارم'),
          SensorOption('meaning', 'جهت زندگی / معنا برایم گنگ است'),
          SensorOption('thought', 'فکرهای مزاحم را می‌خواهم بازنویسی کنم'),
          SensorOption('balance', 'حس می‌کنم زندگی‌ام نامتعادل است'),
        ];
      case 'unknown':
      default:
        return const [
          SensorOption('overwhelm', 'سردرگم و پراکنده‌ام'),
          SensorOption('tired', 'خسته‌ام و انرژی کم است'),
          SensorOption('curious', 'فقط می‌خواهم یک شروع کوچک'),
        ];
    }
  }

  static SensorResult resolve(String areaId, String answerId) {
    String primary;
    List<String> alts;
    String why;

    if (areaId == 'focus') {
      if (answerId == 'deep') {
        primary = 'deep_work';
        alts = ['pomodoro', 'timeblock', 'frog'];
        why =
            'برای کار ذهنی سنگین، بازه بدون حواس‌پرتی (کار عمیق) مناسب است؛ پومودورو و تایم‌بلاک پشتیبانند.';
      } else if (answerId == 'distract') {
        primary = 'pomodoro';
        alts = ['deep_work', 'two_minute', 'daily_review'];
        why =
            'جلسه کوتاه با استراحت مشخص معمولاً بهتر از اجبار طولانی جلوی حواس‌پرتی می‌ایستد.';
      } else {
        primary = 'two_minute';
        alts = ['pomodoro', 'frog', 'gtd_next'];
        why =
            'برای شکستن مقاومت شروع، قانون ۲ دقیقه کم‌اصطکاک‌ترین قدم است.';
      }
    } else if (areaId == 'habit') {
      if (answerId == 'small') {
        primary = 'two_minute';
        alts = ['habit_tracker', 'gtd_next', 'kaizen'];
        why =
            'کارهای ریز با ۲ دقیقه بسته می‌شوند؛ ردیاب عادت و اقدام بعدی جلوی انباشت دوباره را می‌گیرند.';
      } else if (answerId == 'improve') {
        primary = 'kaizen';
        alts = ['habit_tracker', 'five_s', 'daily_review'];
        why =
            'بهبود ۱٪ روزانه (کایزن) با ثبت تداوم، الگوی واقعی را می‌سازد.';
      } else if (answerId == 'space') {
        primary = 'five_s';
        alts = ['kaizen', 'habit_tracker', 'two_minute'];
        why =
            'وقتی محیط شلوغ است، ۵S مستقیماً روی نظم فضا کار می‌کند.';
      } else {
        primary = 'habit_tracker';
        alts = ['kaizen', 'two_minute', 'gratitude'];
        why =
            'دیدن تداوم روی روزها، حدس خوش‌بینانه را با واقعیت عوض می‌کند.';
      }
    } else if (areaId == 'time') {
      if (answerId == 'plan_day') {
        primary = 'timeblock';
        alts = ['pomodoro', 'eisenhower', 'gtd_next'];
        why =
            'تایم‌بلاک روز را به بازه‌های واقعی می‌شکند؛ پومودورو داخل بلوک‌ها کمک می‌کند.';
      } else if (answerId == 'flow') {
        primary = 'kanban';
        alts = ['eisenhower', 'gtd_next', 'timeblock'];
        why =
            'با چند کار موازی، کانبان با محدودیت «در حال» از گیر کردن جلوگیری می‌کند.';
      } else if (answerId == 'next') {
        primary = 'gtd_next';
        alts = ['two_minute', 'kanban', 'frog'];
        why =
            'پروژه مبهم با «اقدام فیزیکی بعدی» قفلش باز می‌شود.';
      } else {
        primary = 'eisenhower';
        alts = ['pareto', 'frog', 'timeblock'];
        why =
            'وقتی اولویت قاطی است، ماتریس اهمیت/فوریت مسیر را روشن می‌کند؛ پارتو روی اثر تمرکز می‌دهد.';
      }
    } else if (areaId == 'goal') {
      if (answerId == 'review') {
        primary = 'daily_review';
        alts = ['gratitude', 'frog', 'two_minute'];
        why =
            'مرور روزانه هدف را به قدم فردا وصل می‌کند بدون پیچیدگی.';
      } else if (answerId == 'align') {
        primary = 'hoshin';
        alts = ['okr_lite', 'smart_goal', 'wheel'];
        why =
            'هوشین ساده یک هدف بلند را با چند اقدام هم‌راستا می‌کند.';
      } else if (answerId == 'measure') {
        primary = 'okr_lite';
        alts = ['smart_goal', 'hoshin', 'pdca'];
        why =
            'OKR سبک هدف کیفی را به نتایج کلیدی قابل‌سنجش وصل می‌کند.';
      } else {
        primary = 'smart_goal';
        alts = ['okr_lite', 'daily_review', 'hoshin'];
        why =
            'قبل از مسیر بلند، SMART هدف را مشخص و زمان‌دار می‌کند.';
      }
    } else if (areaId == 'decision') {
      if (answerId == 'hard_first') {
        primary = 'frog';
        alts = ['eisenhower', 'pareto', 'pomodoro'];
        why =
            'انتخاب یک «قورباغه» روزانه مستقیم با تعویق کار سخت روبه‌رو می‌شود.';
      } else if (answerId == 'strategy') {
        primary = 'swot';
        alts = ['eisenhower', 'pareto', 'pdca'];
        why =
            'SWOT قوت/ضعف/فرصت/تهدید را برای یک موضوع مشخص شفاف می‌کند.';
      } else if (answerId == 'focus20') {
        primary = 'pareto';
        alts = ['eisenhower', 'frog', 'kanban'];
        why =
            'اصل ۸۰/۲۰ کمک می‌کند روی چند مورد پرتأثیر بمانی.';
      } else {
        primary = 'eisenhower';
        alts = ['pareto', 'swot', 'frog'];
        why =
            'ماتریس اهمیت/فوریت فوری‌های کم‌اهمیت را از مهم‌ها جدا می‌کند.';
      }
    } else if (areaId == 'self') {
      if (answerId == 'mood') {
        primary = 'mood_tracker';
        alts = ['gratitude', 'daily_review', 'cbt_journal'];
        why =
            'ثبت حال روزانه الگو را نشان می‌دهد؛ شکرگزاری و مرور مکمل ملایم‌اند.';
      } else if (answerId == 'meaning') {
        primary = 'ikigai';
        alts = ['wheel', 'hoshin', 'daily_review'];
        why =
            'ایکیگای چهار سؤال جهت را باز می‌کند؛ چرخ زندگی تعادل حوزه‌ها را می‌بیند.';
      } else if (answerId == 'thought') {
        primary = 'cbt_journal';
        alts = ['growth_mindset', 'daily_review', 'mood_tracker'];
        why =
            'ژورنال CBT فکر خودکار را از واقعیت جدا می‌کند؛ ذهن رشد قدم آزمایشی می‌سازد.';
      } else if (answerId == 'balance') {
        primary = 'wheel';
        alts = ['ikigai', 'daily_review', 'gratitude'];
        why =
            'چرخ زندگی امتیاز حوزه‌ها را می‌دهد تا یک قدم متعادل انتخاب کنی.';
      } else {
        primary = 'daily_review';
        alts = ['gratitude', 'mood_tracker', 'growth_mindset'];
        why =
            'مرور روزانه امن‌ترین شروع خودشناسی عملی است.';
      }
    } else {
      // unknown
      if (answerId == 'tired') {
        primary = 'two_minute';
        alts = ['gratitude', 'daily_review', 'pomodoro'];
        why =
            'با انرژی کم، ۲ دقیقه و شکرگزاری کوتاه فشار را کم می‌کنند.';
      } else if (answerId == 'overwhelm') {
        primary = 'daily_review';
        alts = ['eisenhower', 'gtd_next', 'two_minute'];
        why =
            'وقتی همه چیز قاطی است، مرور کوتاه + شفاف‌کردن اولویت نقطه امن است.';
      } else {
        primary = 'pomodoro';
        alts = ['two_minute', 'habit_tracker', 'kaizen'];
        why =
            'یک جلسه کوتاه پومودورو تجربه ملموس سریع می‌سازد.';
      }
    }

    final area = () {
      switch (areaId) {
        case 'focus':
          return GrowthNeedArea.focus;
        case 'habit':
          return GrowthNeedArea.habit;
        case 'time':
          return GrowthNeedArea.time;
        case 'goal':
          return GrowthNeedArea.goal;
        case 'decision':
          return GrowthNeedArea.decision;
        case 'self':
          return GrowthNeedArea.selfKnowledge;
        default:
          return GrowthNeedArea.unknown;
      }
    }();

    if (GrowthCatalog.byId(primary) == null) primary = 'pomodoro';
    alts = alts
        .where((id) => GrowthCatalog.byId(id) != null && id != primary)
        .toList();
    // حداکثر ۳ پیشنهاد جایگزین
    if (alts.length > 3) alts = alts.take(3).toList();

    return SensorResult(
      primaryProgramId: primary,
      alternatives: alts,
      why: why,
      area: area,
    );
  }
}
