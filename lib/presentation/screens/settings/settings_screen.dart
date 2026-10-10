import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/constants/app_constants.dart';
import '../../widgets/nozhin_logo.dart';
import '../../../core/widgets/app_card.dart';
import '../../providers/theme_provider.dart';
import '../../../core/security/secure_storage_service.dart';
import '../../../core/security/biometric_service.dart';
import '../lock_screen.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import '../../../core/services/backup_service.dart';
import '../../../core/services/finance_excel_service.dart';
import 'package:flutter/services.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  late final TextEditingController _nameController;

  @override
  void initState() {
    super.initState();
    final name = ref.read(themeProvider).userName;
    _nameController = TextEditingController(text: name);
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final themeState = ref.watch(themeProvider);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text(AppStrings.settings),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(14, 14, 14, 40),
        children: [
          // Profile
          _SettingsGroup(
            title: AppStrings.profile,
            icon: Icons.person_outline_rounded,
            children: [
              TextField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: AppStrings.yourName,
                  hintText: 'مثلاً: علی',
                ),
                onChanged: (v) {
                  ref.read(themeProvider.notifier).setUserName(v);
                },
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Appearance
          _SettingsGroup(
            title: 'ظاهر',
            icon: Icons.palette_outlined,
            children: [
              Text(AppStrings.theme, style: theme.textTheme.bodyMedium),
              const SizedBox(height: 10),
              Row(
                children: [
                  _ThemeChip(
                    label: AppStrings.themeLight,
                    selected: themeState.themeMode == ThemeMode.light,
                    onTap: () => ref.read(themeProvider.notifier).setThemeMode(ThemeMode.light),
                  ),
                  const SizedBox(width: 8),
                  _ThemeChip(
                    label: AppStrings.themeDark,
                    selected: themeState.themeMode == ThemeMode.dark,
                    onTap: () => ref.read(themeProvider.notifier).setThemeMode(ThemeMode.dark),
                  ),
                  const SizedBox(width: 8),
                  _ThemeChip(
                    label: AppStrings.themeSystem,
                    selected: themeState.themeMode == ThemeMode.system,
                    onTap: () => ref.read(themeProvider.notifier).setThemeMode(ThemeMode.system),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              Text(AppStrings.fontSize, style: theme.textTheme.bodyMedium),
              const SizedBox(height: 10),
              Row(
                children: [
                  _ThemeChip(
                    label: AppStrings.fontSmall,
                    selected: themeState.fontSize == AppFontSize.small,
                    onTap: () => ref.read(themeProvider.notifier).setFontSize(AppFontSize.small),
                  ),
                  const SizedBox(width: 8),
                  _ThemeChip(
                    label: AppStrings.fontMedium,
                    selected: themeState.fontSize == AppFontSize.medium,
                    onTap: () => ref.read(themeProvider.notifier).setFontSize(AppFontSize.medium),
                  ),
                  const SizedBox(width: 8),
                  _ThemeChip(
                    label: AppStrings.fontLarge,
                    selected: themeState.fontSize == AppFontSize.large,
                    onTap: () => ref.read(themeProvider.notifier).setFontSize(AppFontSize.large),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              Text('نوع فونت', style: theme.textTheme.bodyMedium),
              const SizedBox(height: 10),
              Row(
                children: [
                  _ThemeChip(
                    label: 'وزیرمتن',
                    selected: themeState.fontFamily == 'Vazirmatn',
                    onTap: () => ref
                        .read(themeProvider.notifier)
                        .setFontFamily('Vazirmatn'),
                  ),

                ],
              ),
              const SizedBox(height: 6),
              Text(
                'فونت‌ها از پوشه assets/fonts بارگذاری می‌شوند (آفلاین).',
                style: theme.textTheme.labelSmall?.copyWith(
                  color: theme.colorScheme.onSurface.withOpacity(0.5),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Data
          _SettingsGroup(
            title: AppStrings.data,
            icon: Icons.storage_outlined,
            children: [
              _SettingsAction(
                icon: Icons.download_rounded,
                label: AppStrings.exportData,
                onTap: () => _exportBackup(context),
              ),
              _SettingsAction(
                icon: Icons.upload_rounded,
                label: AppStrings.importData,
                onTap: () => _importBackup(context),
              ),
              _SettingsAction(
                icon: Icons.delete_forever_rounded,
                label: AppStrings.clearAllData,
                isDanger: true,
                onTap: () => _clearAll(context),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // اکسل مالی
          _SettingsGroup(
            title: 'اکسل مالی',
            icon: Icons.table_chart_outlined,
            children: [
              Text(
                'خروجی چندشیتی استاندارد (حساب‌ها، دفترروزنامه، بدهی، اقساط، بودجه، اهداف، قصد خرید، خلاصه). واحد: تومان.',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurface.withOpacity(0.55),
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 10),
              _SettingsAction(
                icon: Icons.file_download_outlined,
                label: 'خروجی اکسل مالی (.xlsx)',
                onTap: () => _exportFinanceExcel(context),
              ),
              _SettingsAction(
                icon: Icons.file_upload_outlined,
                label: 'ورود از اکسل (ادغام با داده فعلی)',
                onTap: () => _importFinanceExcel(context, merge: true),
              ),
              _SettingsAction(
                icon: Icons.sync_problem_rounded,
                label: 'ورود از اکسل (جایگزینی کامل مالی)',
                onTap: () => _importFinanceExcel(context, merge: false),
              ),
            ],
          ),
          const SizedBox(height: 14),


          // امنیت
          _SettingsGroup(
            title: 'امنیت',
            icon: Icons.lock_outline_rounded,
            children: [
              FutureBuilder<bool>(
                future: SecureStorageService.instance.getAppLockEnabled(),
                builder: (context, snap) {
                  final enabled = snap.data ?? false;
                  return SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('قفل برنامه با PIN'),
                    subtitle: Text(
                      enabled
                          ? 'فعال — هنگام ورود رمز می‌خواهد'
                          : 'غیرفعال',
                    ),
                    value: enabled,
                    activeThumbColor: AppColors.brand3,
                    onChanged: (v) async {
                      if (v) {
                        final pin = await _askNewPin(context);
                        if (pin == null) return;
                        await SecureStorageService.instance
                            .saveAppLockPinHash(LockScreen.hashPin(pin));
                        await SecureStorageService.instance
                            .saveAppLockEnabled(true);
                      } else {
                        await SecureStorageService.instance
                            .saveAppLockEnabled(false);
                      }
                      if (context.mounted) setState(() {});
                    },
                  );
                },
              ),

              FutureBuilder<bool>(
                future: SecureStorageService.instance.getAppLockEnabled(),
                builder: (context, snap) {
                  final pinOn = snap.data ?? false;
                  return FutureBuilder<bool>(
                    future: SecureStorageService.instance
                        .getBiometricLockEnabled(),
                    builder: (context, bioSnap) {
                      final bioOn = bioSnap.data ?? false;
                      return SwitchListTile(
                        contentPadding: EdgeInsets.zero,
                        title: const Text('باز شدن با اثر انگشت / چهره'),
                        subtitle: Text(
                          kIsWeb
                              ? 'روی وب در دسترس نیست — فقط اندروید و iOS'
                              : (!pinOn
                                  ? 'اول قفل با PIN را فعال کن'
                                  : (bioOn
                                      ? 'فعال — ورود با اثرانگشت'
                                      : 'اگر حسگر در دسترس نبود، به تنظیمات دسترسی‌ها می‌روی')),
                        ),
                        value: bioOn && pinOn && !kIsWeb,
                        activeThumbColor: AppColors.brand3,
                        onChanged: (kIsWeb || !pinOn)
                            ? null
                            : (v) async {
                                if (v) {
                                  final ok = await BiometricService.instance
                                      .authenticate(
                                    reason:
                                        'برای فعال‌سازی اثرانگشت یک‌بار تأیید کن',
                                    biometricOnly: false,
                                  );
                                  if (!ok) {
                                    if (context.mounted) {
                                      final go = await showDialog<bool>(
                                        context: context,
                                        builder: (ctx) => AlertDialog(
                                          title: const Text('اثرانگشت فعال نشد'),
                                          content: const Text(
                                            'یا اثرانگشت روی گوشی ثبت نشده، یا دسترسی برنامه محدود است.\n\nمی‌خوای به تنظیمات دسترسی‌های هاوژین بروی؟',
                                          ),
                                          actions: [
                                            TextButton(
                                              onPressed: () =>
                                                  Navigator.pop(ctx, false),
                                              child: const Text('بعداً'),
                                            ),
                                            FilledButton(
                                              onPressed: () =>
                                                  Navigator.pop(ctx, true),
                                              child: const Text('باز کردن تنظیمات'),
                                            ),
                                          ],
                                        ),
                                      );
                                      if (go == true) {
                                        await BiometricService.instance
                                            .openSystemAppSettings();
                                      }
                                    }
                                    return;
                                  }
                                }
                                await SecureStorageService.instance
                                    .saveBiometricLockEnabled(v);
                                if (context.mounted) setState(() {});
                              },
                      );
                    },
                  );
                },
              ),
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('دسترسی‌های برنامه (سیستم)'),
                subtitle: const Text('برای اثرانگشت و سایر مجوزها'),
                leading: const Icon(Icons.app_settings_alt_rounded),
                onTap: () async {
                  final ok =
                      await BiometricService.instance.openSystemAppSettings();
                  if (!ok && context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                      content: Text('نتوانست تنظیمات سیستم را باز کند'),
                      behavior: SnackBarBehavior.fixed,
                    ));
                  }
                },
              ),
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('تغییر PIN'),
                leading: const Icon(Icons.password_rounded),
                onTap: () async {
                  final pin = await _askNewPin(context);
                  if (pin == null) return;
                  await SecureStorageService.instance
                      .saveAppLockPinHash(LockScreen.hashPin(pin));
                  await SecureStorageService.instance.saveAppLockEnabled(true);
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                      content: Text('PIN ذخیره شد'),
                      behavior: SnackBarBehavior.fixed,
                    ));
                    setState(() {});
                  }
                },
              ),
            ],
          ),
          const SizedBox(height: 14),

          // درباره ما
          _SettingsGroup(
            title: AppStrings.about,
            icon: Icons.info_outline_rounded,
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.fromLTRB(16, 18, 16, 16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topRight,
                    end: Alignment.bottomLeft,
                    colors: [
                      AppColors.brand3.withOpacity(0.16),
                      AppColors.brand2.withOpacity(0.08),
                      theme.colorScheme.surfaceContainerHighest,
                    ],
                  ),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: AppColors.brand3.withOpacity(0.25),
                  ),
                ),
                child: Column(
                  children: [
                    const HawzhinLogo(
                      size: 72,
                      variant: HawzhinLogoVariant.bookLeaf,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      AppConstants.appName,
                      style: theme.textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1.5,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      AppConstants.appNameEn,
                      style: theme.textTheme.labelLarge?.copyWith(
                        color: AppColors.brand3,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 2,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.brand3.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        'نسخه ${AppConstants.appVersion}  ·  بیلد ${AppConstants.appBuild}',
                        style: theme.textTheme.labelSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: AppColors.brand3,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      AppConstants.appTagline,
                      textAlign: TextAlign.center,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      AppConstants.aboutBlurb,
                      textAlign: TextAlign.center,
                      style: theme.textTheme.bodySmall?.copyWith(
                        height: 1.55,
                        color: theme.colorScheme.onSurface.withOpacity(0.72),
                      ),
                    ),
                    const SizedBox(height: 18),
                    // سازنده
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.surface.withOpacity(0.85),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: theme.colorScheme.outline),
                      ),
                      child: Column(
                        children: [
                          Row(
                            children: [
                              Container(
                                width: 44,
                                height: 44,
                                decoration: BoxDecoration(
                                  gradient: AppColors.primaryGradient,
                                  borderRadius: BorderRadius.circular(14),
                                ),
                                child: const Icon(Icons.person_rounded,
                                    color: Colors.white, size: 24),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'سازنده',
                                      style: theme.textTheme.labelSmall
                                          ?.copyWith(
                                        color: theme.colorScheme.onSurface
                                            .withOpacity(0.55),
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    Text(
                                      AppConstants.developerName,
                                      style: theme.textTheme.titleMedium
                                          ?.copyWith(
                                        fontWeight: FontWeight.w900,
                                      ),
                                    ),
                                    Text(
                                      AppConstants.developerNameEn,
                                      style: theme.textTheme.labelMedium
                                          ?.copyWith(
                                        color: AppColors.brand3,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'هر نقد، پیشنهاد، گزارش باگ یا ایده برای هاوژین را به این ایمیل بفرستید. پیام‌ها خوانده می‌شوند.',
                            textAlign: TextAlign.center,
                            style: theme.textTheme.bodySmall?.copyWith(
                              height: 1.5,
                              color: theme.colorScheme.onSurface
                                  .withOpacity(0.7),
                            ),
                          ),
                          const SizedBox(height: 12),
                          SizedBox(
                            width: double.infinity,
                            child: FilledButton.icon(
                              onPressed: () async {
                                final uri = Uri(
                                  scheme: 'mailto',
                                  path: AppConstants.supportEmail,
                                  queryParameters: {
                                    'subject':
                                        'هاوژین — بازخورد / باگ / پیشنهاد',
                                  },
                                );
                                try {
                                  final ok = await launchUrl(uri);
                                  if (!ok && context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(
                                            'ایمیل: ${AppConstants.supportEmail}'),
                                        behavior: SnackBarBehavior.floating,
                                      ),
                                    );
                                  }
                                } catch (_) {
                                  if (context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(
                                            'ایمیل: ${AppConstants.supportEmail}'),
                                        behavior: SnackBarBehavior.floating,
                                      ),
                                    );
                                  }
                                }
                              },
                              style: FilledButton.styleFrom(
                                backgroundColor: AppColors.brand3,
                                padding:
                                    const EdgeInsets.symmetric(vertical: 12),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              icon: const Icon(Icons.mail_outline_rounded),
                              label: Text(
                                AppConstants.supportEmail,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'ساخته‌شده با دقت برای کاربران فارسی‌زبان · کاملاً آفلاین',
                      textAlign: TextAlign.center,
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: theme.colorScheme.onSurface.withOpacity(0.45),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<String?> _askNewPin(BuildContext context) async {
    final c1 = TextEditingController();
    final c2 = TextEditingController();
    var show1 = false;
    var show2 = false;
    return showDialog<String>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setLocal) => AlertDialog(
          title: const Text('تنظیم PIN'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: c1,
                keyboardType: TextInputType.number,
                obscureText: !show1,
                maxLength: 6,
                decoration: InputDecoration(
                  labelText: 'PIN (۴ تا ۶ رقم)',
                  suffixIcon: IconButton(
                    icon: Icon(
                      show1
                          ? Icons.visibility_off_outlined
                          : Icons.visibility_outlined,
                    ),
                    onPressed: () => setLocal(() => show1 = !show1),
                  ),
                ),
              ),
              TextField(
                controller: c2,
                keyboardType: TextInputType.number,
                obscureText: !show2,
                maxLength: 6,
                decoration: InputDecoration(
                  labelText: 'تکرار PIN',
                  suffixIcon: IconButton(
                    icon: Icon(
                      show2
                          ? Icons.visibility_off_outlined
                          : Icons.visibility_outlined,
                    ),
                    onPressed: () => setLocal(() => show2 = !show2),
                  ),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('لغو')),
            TextButton(
              onPressed: () {
                final a = c1.text.trim();
                final b = c2.text.trim();
                if (a.length < 4 || a.length > 6) {
                  ScaffoldMessenger.of(ctx).showSnackBar(const SnackBar(
                    content: Text('۴ تا ۶ رقم لازم است'),
                    behavior: SnackBarBehavior.fixed,
                  ));
                  return;
                }
                if (a != b) {
                  ScaffoldMessenger.of(ctx).showSnackBar(const SnackBar(
                    content: Text('PIN یکسان نیست'),
                    behavior: SnackBarBehavior.fixed,
                  ));
                  return;
                }
                Navigator.pop(ctx, a);
              },
              child: const Text('ذخیره'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _exportFinanceExcel(BuildContext context) async {
    try {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('در حال ساخت فایل اکسل…'),
        behavior: SnackBarBehavior.fixed,
        duration: Duration(seconds: 2),
      ));
      final path = await FinanceExcelService.instance.exportToFile();
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('اکسل مالی آماده شد\n$path'),
        behavior: SnackBarBehavior.fixed,
        duration: const Duration(seconds: 4),
      ));
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('خطا در خروجی اکسل: $e'),
        behavior: SnackBarBehavior.fixed,
      ));
    }
  }

  Future<void> _importFinanceExcel(
    BuildContext context, {
    required bool merge,
  }) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(merge ? 'ورود اکسل (ادغام)' : 'ورود اکسل (جایگزینی)'),
        content: Text(
          merge
              ? 'رکوردهای هم‌شناسه به‌روز می‌شوند و بقیه اضافه می‌شوند. یادداشت‌ها دست نمی‌خورند.'
              : 'داده‌های مالی فعلی با محتوای فایل جایگزین می‌شوند. این کار برگشت‌ناپذیر است.',
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('لغو')),
          TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('ادامه')),
        ],
      ),
    );
    if (confirm != true) return;
    final result =
        await FinanceExcelService.instance.importFromPicker(merge: merge);
    if (!context.mounted) return;
    if (result.cancelled) return;
    if (!result.success) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('خطا: ${result.error}'),
        behavior: SnackBarBehavior.fixed,
      ));
      return;
    }
    final summary = result.counts.entries
        .where((e) => e.value > 0)
        .map((e) => '${e.key}: ${e.value}')
        .join(' · ');
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(
        summary.isEmpty
            ? 'فایلی با دادهٔ قابل‌ورود پیدا نشد'
            : 'ورود انجام شد — $summary\nبرای دیدن تغییرات یک‌بار تب مالی را تازه کن یا برنامه را باز/بسته کن',
      ),
      behavior: SnackBarBehavior.fixed,
      duration: const Duration(seconds: 5),
    ));
  }

  Future<void> _exportBackup(BuildContext context) async {
    final usePin = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('پشتیبان‌گیری'),
        content: const Text(
          'می‌خواهی بک‌آپ با PIN رمزگذاری شود؟\n(بدون PIN هم رمز کارت در فایل نمی‌آید)',
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('بدون رمز')),
          TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('با PIN')),
        ],
      ),
    );
    if (usePin == null) return;
    String? pin;
    if (usePin) {
      pin = await _askNewPin(context);
      if (pin == null) return;
    }
    try {
      final json = await BackupService.instance.exportJsonString(pin: pin);
      await Clipboard.setData(ClipboardData(text: json));
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('بک‌آپ در کلیپ‌بورد کپی شد — در فایل متنی ذخیره کن'),
        behavior: SnackBarBehavior.fixed,
        duration: Duration(seconds: 3),
      ));
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('خطا: $e'),
        behavior: SnackBarBehavior.fixed,
      ));
    }
  }

  Future<void> _importBackup(BuildContext context) async {
    final ctrl = TextEditingController();
    final pinCtrl = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('بازیابی بک‌آپ'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'محتوای JSON بک‌آپ را بچسبان. داده‌های فعلی جایگزین می‌شوند.',
              ),
              const SizedBox(height: 12),
              TextField(
                controller: ctrl,
                maxLines: 6,
                decoration: const InputDecoration(
                  labelText: 'JSON',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: pinCtrl,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'PIN (اگر بک‌آپ رمز داشت)',
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('لغو')),
          TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('بازیابی')),
        ],
      ),
    );
    if (ok != true) return;
    try {
      final pin = pinCtrl.text.trim();
      await BackupService.instance.importJsonString(
        ctrl.text.trim(),
        pin: pin.isEmpty ? null : pin,
      );
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('بازیابی انجام شد — برنامه را یک‌بار ریستارت کن'),
        behavior: SnackBarBehavior.fixed,
      ));
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('خطا: $e'),
        behavior: SnackBarBehavior.fixed,
      ));
    }
  }

  Future<void> _clearAll(BuildContext context) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('پاک‌سازی همه داده‌ها'),
        content: const Text('این کار برگشت‌ناپذیر است. مطمئنی؟'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('لغو')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('پاک کن', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    if (ok != true) return;
    try {
      await BackupService.instance.importJsonString(
        '{"_meta":{"app":"hawzhin","version":"1.0.0"},"notes":[],"accounts":[],"transactions":[],"debts":[],"installments":[],"fin_goals":[],"budgets":[],"info_items":[],"sticker_surfaces":[],"sticker_active_id":[],"habits":[],"eisen":[],"program_data":[],"emergency":[]}',
      );
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('همه داده‌ها پاک شد'),
        behavior: SnackBarBehavior.fixed,
      ));
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('خطا: $e'),
        behavior: SnackBarBehavior.fixed,
      ));
    }
  }


}

class _SettingsGroup extends StatelessWidget {
  final String title;
  final IconData icon;
  final List<Widget> children;

  const _SettingsGroup({
    required this.title,
    required this.icon,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 18, color: AppColors.brand3),
              const SizedBox(width: 8),
              Text(title, style: theme.textTheme.titleLarge),
            ],
          ),
          const SizedBox(height: 14),
          ...children,
        ],
      ),
    );
  }
}

class _ThemeChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _ThemeChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          gradient: selected ? AppColors.primaryGradient : null,
          color: selected ? null : Theme.of(context).colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(10),
          border: selected ? null : Border.all(color: Theme.of(context).colorScheme.outline),
        ),
        child: Text(
          label,
          style: Theme.of(context).textTheme.labelMedium?.copyWith(
                color: selected ? Colors.white : null,
                fontWeight: FontWeight.w700,
              ),
        ),
      ),
    );
  }
}

class _SettingsAction extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool isDanger;

  const _SettingsAction({
    required this.icon,
    required this.label,
    required this.onTap,
    this.isDanger = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = isDanger ? AppColors.danger : theme.colorScheme.onSurface;

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(AppRadius.sm),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppRadius.sm),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(AppRadius.sm),
              border: Border.all(color: theme.colorScheme.outline),
            ),
            child: Row(
              children: [
                Icon(icon, size: 18, color: color),
                const SizedBox(width: 12),
                Text(
                  label,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: color,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
