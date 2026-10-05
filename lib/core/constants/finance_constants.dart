/// ثابت‌های ماژول مالی

const defaultExpenseCategories = [
  'خوراک و نوشیدنی',
  'حمل و نقل',
  'خرید',
  'قبوض',
  'سلامت',
  'سرگرمی',
  'پوشاک',
  'آموزش',
  'خانه',
  'سایر',
];

const defaultIncomeCategories = [
  'حقوق',
  'درآمد ثابت',
  'آزاد / پروژه‌ای',
  'سرمایه',
  'هدیه',
  'سایر درآمد',
];

const defaultSavingCategories = [
  'پس‌انداز',
  'صندوق اضطراری',
  'سرمایه‌گذاری',
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
        return 'خلاصه';
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
