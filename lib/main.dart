import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'core/theme/app_theme.dart';
import 'core/constants/app_constants.dart';
import 'core/services/local_database.dart';
import 'presentation/providers/theme_provider.dart';
import 'presentation/screens/splash_screen.dart';
import 'core/services/debug_log_service.dart';

class AppScrollBehavior extends MaterialScrollBehavior {
  @override
  Set<PointerDeviceKind> get dragDevices => {
        PointerDeviceKind.touch,
        PointerDeviceKind.mouse,
        PointerDeviceKind.trackpad,
        PointerDeviceKind.stylus,
      };
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  DebugLogService.instance.installGlobalHandlers();
  DebugLogService.instance.info('main() شروع', tag: 'boot');

  try {
    final sw = Stopwatch()..start();
    await LocalDatabase.instance.init();
    sw.stop();
    DebugLogService.instance.perf('LocalDatabase.init', duration: sw.elapsed, tag: 'boot');
  } catch (e, st) {
    DebugLogService.instance.error('LocalDatabase init', error: e, stack: st, tag: 'boot');
    debugPrint('LocalDatabase init skipped: $e');
  }

  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(statusBarColor: Colors.transparent),
  );

  runApp(const ProviderScope(child: NozhinApp()));
}

class NozhinApp extends ConsumerWidget {
  const NozhinApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeState = ref.watch(themeProvider);

    return MaterialApp(
      scrollBehavior: AppScrollBehavior(),
      title: AppConstants.appName,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(
        fontSizeFactor: themeState.fontSizeFactor,
        fontFamily: themeState.fontFamily,
      ),
      darkTheme: AppTheme.dark(
        fontSizeFactor: themeState.fontSizeFactor,
        fontFamily: themeState.fontFamily,
      ),
      themeMode: themeState.themeMode,
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        FlutterQuillLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('fa'),
        Locale('en'),
      ],
      builder: (context, child) {
        return Directionality(
          textDirection: TextDirection.rtl,
          child: child!,
        );
      },
      navigatorObservers: [DebugNavigatorObserver()],
      home: const SplashScreen(),
    );
  }
}
