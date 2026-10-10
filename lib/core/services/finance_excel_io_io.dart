import 'dart:io';
import 'dart:typed_data';

Future<void> writeBytesToPath(String path, Uint8List bytes) async {
  final file = File(path);
  await file.parent.create(recursive: true);
  await file.writeAsBytes(bytes, flush: true);
}

Future<Uint8List> readBytesFromPath(String path) async {
  return Uint8List.fromList(await File(path).readAsBytes());
}
