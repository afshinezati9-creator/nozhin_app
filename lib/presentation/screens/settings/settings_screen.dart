import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/widgets/app_card.dart';
import '../../providers/theme_provider.dart';
import '../../../core/security/secure_storage_service.dart';
import '../../../core/security/biometric_service.dart';
import '../lock_screen.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import '../../../core/services/backup_service.dart';
import '../../../core/services/debug_log_service.dart';
import '../../../core/services/debug_export.dart';
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
                  const SizedBox(width: 8),
                  _ThemeChip(
                    label: 'Inter',
                    selected: themeState.fontFamily == 'Inter',
                    onTap: () =>
                        ref.read(themeProvider.notifier).setFontFamily('Inter'),
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
                future: Future.wait([
                  SecureStorageService.instance.getAppLockEnabled(),
                  SecureStorageService.instance.getBiometricLockEnabled(),
                  BiometricService.instance.canCheck,
                ]).then((v) => v[0] && v[2]),
                builder: (context, snap) {
                  final pinOnAndDevice = snap.data ?? false;
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
                              : (!pinOnAndDevice
                                  ? 'اول قفل PIN را فعال کن؛ دستگاه باید حسگر داشته باشد'
                                  : (bioOn
                                      ? 'فعال — هنگام ورود می‌توانی بیومتریک بزنی'
                                      : 'در صورت وجود حسگر روی دستگاه')),
                        ),
                        value: bioOn && pinOnAndDevice && !kIsWeb,
                        activeThumbColor: AppColors.brand3,
                        onChanged: (kIsWeb || !pinOnAndDevice)
                            ? null
                            : (v) async {
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


          // دیباگ موقت — قبل از انتشار عمومی حذف شود
          _SettingsGroup(
            title: 'دیباگ (موقت)',
            icon: Icons.bug_report_rounded,
            children: [
              Text(
                'برای تست اندروید و رفع باگ. قبل از انتشار عمومی این بخش را حذف می‌کنیم.',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurface.withOpacity(0.6),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'تعداد لاگ در حافظه: ${DebugLogService.instance.count}',
                style: theme.textTheme.labelMedium,
              ),
              const SizedBox(height: 8),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.file_download_rounded),
                title: const Text('خروجی فایل لاگ'),
                subtitle: const Text('تاریخ، ساعت، سطح، علت — برای ارسال به توسعه‌دهنده'),
                onTap: () async {
                  DebugLogService.instance.event('کاربر خروجی دیباگ گرفت', tag: 'debug');
                  final r = await DebugExport.export();
                  if (!context.mounted) return;
                  await showDialog<void>(
                    context: context,
                    builder: (ctx) => AlertDialog(
                      title: const Text('گزارش دیباگ'),
                      content: SingleChildScrollView(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              r.pathOrHint,
                              style: const TextStyle(fontWeight: FontWeight.w700),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              r.textPreview.length > 4000
                                  ? '${r.textPreview.substring(0, 4000)}\n\n… (ادامه در فایل/کلیپ‌بورد)'
                                  : r.textPreview,
                              style: const TextStyle(
                                fontFamily: 'monospace',
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ),
                      ),
                      actions: [
                        TextButton(
                          onPressed: () async {
                            await Clipboard.setData(
                                ClipboardData(text: r.textPreview));
                            if (ctx.mounted) Navigator.pop(ctx);
                          },
                          child: const Text('کپی کامل'),
                        ),
                        FilledButton(
                          onPressed: () => Navigator.pop(ctx),
                          child: const Text('باشه'),
                        ),
                      ],
                    ),
                  );
                  setState(() {});
                },
              ),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.delete_outline_rounded),
                title: const Text('پاک کردن لاگ‌های حافظه'),
                onTap: () {
                  DebugLogService.instance.clear();
                  DebugLogService.instance.info('لاگ‌ها پاک شد', tag: 'debug');
                  setState(() {});
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('لاگ‌ها پاک شد'),
                      behavior: SnackBarBehavior.fixed,
                    ),
                  );
                },
              ),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.note_add_outlined),
                title: const Text('ثبت یادداشت دستی در لاگ'),
                onTap: () async {
                  final c = TextEditingController();
                  final ok = await showDialog<bool>(
                    context: context,
                    builder: (ctx) => AlertDialog(
                      title: const Text('یادداشت دیباگ'),
                      content: TextField(
                        controller: c,
                        maxLines: 3,
                        decoration: const InputDecoration(
                          hintText: 'چه مشکلی دیدی؟ در کدام صفحه؟',
                        ),
                      ),
                      actions: [
                        TextButton(
                            onPressed: () => Navigator.pop(ctx, false),
                            child: const Text('لغو')),
                        FilledButton(
                            onPressed: () => Navigator.pop(ctx, true),
                            child: const Text('ثبت')),
                      ],
                    ),
                  );
                  if (ok == true && c.text.trim().isNotEmpty) {
                    DebugLogService.instance.warn(
                      'یادداشت کاربر',
                      cause: c.text.trim(),
                      tag: 'user',
                    );
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('در لاگ ثبت شد'),
                          behavior: SnackBarBehavior.fixed,
                        ),
                      );
                      setState(() {});
                    }
                  }
                },
              ),
            ],
          ),
          const SizedBox(height: 14),

          // About
          _SettingsGroup(
            title: AppStrings.about,
            icon: Icons.info_outline_rounded,
            children: [
              Center(
                child: Column(
                  children: [
                    Container(
                      width: 64,
                      height: 64,
                      decoration: BoxDecoration(
                        gradient: AppColors.primaryGradient,
                        borderRadius: BorderRadius.circular(18),
                      ),
                      child: const Center(
                        child: Text(
                          'ن',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w900,
                            fontSize: 28,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      AppConstants.appName,
                      style: theme.textTheme.headlineMedium?.copyWith(
                        letterSpacing: 2,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'نسخه ${AppConstants.appVersion} · ${AppConstants.appTagline}',
                      style: theme.textTheme.bodySmall,
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

              const Divider(),
              ListTile(
                leading: const Icon(Icons.spa_rounded),
                title: const Text('توسعه فردی (آفلاین)'),
                subtitle: const Text(
                  'مسیرها، اجراها و ارزیابی‌ها فقط روی همین دستگاه ذخیره می‌شوند. نیاز به اینترنت نیست.',
                ),
              ),
          ],
        ),
      ),
    );
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
        '{"_meta":{"app":"nozhin","version":"1.0.0"},"notes":[],"accounts":[],"transactions":[],"debts":[],"installments":[],"fin_goals":[],"budgets":[],"info_items":[],"sticker_surfaces":[],"sticker_active_id":[],"habits":[],"eisen":[],"program_data":[],"emergency":[]}',
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
