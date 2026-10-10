/// Stub برای وب – path_provider روی وب پشتیبانی کامل ندارد
/// فقط path برمی‌گرداند؛ Directory اینجا تعریف نمی‌شود

class AppDocumentsDir {
  final String path;
  AppDocumentsDir(this.path);
}

Future<AppDocumentsDir> getApplicationDocumentsDirectory() async {
  return AppDocumentsDir('/web_stub');
}
