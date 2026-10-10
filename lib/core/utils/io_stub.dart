/// Stub برای وب – جایگزین dart:io

class FileSystemEntity {
  final String path;
  FileSystemEntity(this.path);
}

class Directory extends FileSystemEntity {
  Directory(super.path);

  Future<bool> exists() async => false;
  Future<Directory> create({bool recursive = false}) async => this;
  Stream<FileSystemEntity> list({bool recursive = false}) =>
      const Stream.empty();
}

class File extends FileSystemEntity {
  File(super.path);

  Future<bool> exists() async => false;
  Future<File> writeAsString(String contents) async => this;
  Future<String> readAsString() async => '';
  Future<FileSystemEntity> delete() async => this;
}
