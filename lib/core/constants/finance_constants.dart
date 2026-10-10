/// ثابت‌های ماژول مالی

const defaultExpenseCategories = [
  'خوراک و نوشیدنی',
  'سوپرمارکت',
  'رستوران و کافی‌شاپ',
  'حمل و نقل',
  'بنزین / شارژ خودرو',
  'تاکسی و اسنپ',
  'خرید کالا',
  'پوشاک',
  'قبوض (آب/برق/گاز)',
  'اینترنت و موبایل',
  'اجاره / مسکن',
  'خانه و تعمیرات',
  'سلامت و دارو',
  'بیمه',
  'آموزش',
  'فرزندان',
  'سرگرمی',
  'ورزش',
  'سفر',
  'هدیه و خیریه',
  'کارمزد بانکی',
  'سایر', // اگر سایر زدی در توضیحات بنویس چیست
];

const defaultIncomeCategories = [
  'حقوق',
  'درآمد ثابت',
  'آزاد / پروژه‌ای',
  'فروش',
  'سود سرمایه‌گذاری',
  'اجاره دریافتی',
  'یارانه / کمک‌هزینه',
  'هدیه',
  'سایر درآمد', // در توضیحات مشخص کن
];

const defaultSavingCategories = [
  'پس‌انداز ماهانه',
  'صندوق اضطراری',
  'سرمایه‌گذاری',
  'طلا / ارز',
  'سپرده بانکی',
  'بازنشستگی',
];

/// ساب‌تب‌های صفحه مالی
enum FinanceSubTab {
  overview,
  accounts,
  transactions,
  budget,
  debts,
  installments,
  goals,
}

extension FinanceSubTabX on FinanceSubTab {
  String get label {
    switch (this) {
      case FinanceSubTab.overview:
        return ''; // فقط آیکون
      case FinanceSubTab.accounts:
        return 'حساب‌ها';
      case FinanceSubTab.transactions:
        return 'تراکنش‌ها';
      case FinanceSubTab.budget:
        return 'بودجه';
      case FinanceSubTab.debts:
        return 'بدهی و طلب';
      case FinanceSubTab.installments:
        return 'اقساط';
      case FinanceSubTab.goals:
        return 'اهداف';
    }
  }

  String get iconName {
    switch (this) {
      case FinanceSubTab.overview:
        return 'dashboard';
      case FinanceSubTab.accounts:
        return 'account';
      case FinanceSubTab.transactions:
        return 'swap';
      case FinanceSubTab.budget:
        return 'budget';
      case FinanceSubTab.debts:
        return 'debt';
      case FinanceSubTab.installments:
        return 'installment';
      case FinanceSubTab.goals:
        return 'goal';
    }
  }
}
