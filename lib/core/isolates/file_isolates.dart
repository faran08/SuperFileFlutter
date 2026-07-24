import 'dart:io';
import 'dart:isolate';
import 'package:archive/archive_io.dart';
import 'package:path/path.dart' as p;
import '../models/file_item.dart';

class FileIsolates {
  /// Reads directory contents in a separate Isolate without blocking the main UI thread.
  static Future<List<FileItem>> readDirectory(String dirPath) async {
    return Isolate.run(() async {
      final dir = Directory(dirPath);
      if (!await dir.exists()) return <FileItem>[];

      final items = <FileItem>[];
      try {
        final entities = await dir.list(followLinks: false).toList();
        for (final entity in entities) {
          try {
            final stat = await entity.stat();
            items.add(FileItem.fromFileSystemEntity(entity, stat));
          } catch (_) {
            // Ignore unreadable/permission-denied files safely
          }
        }
      } catch (_) {
        // Return whatever was collected
      }
      return items;
    });
  }

  /// Calculates recursive directory size in a separate Isolate.
  static Future<int> calculateDirectorySize(String dirPath) async {
    return Isolate.run(() async {
      final dir = Directory(dirPath);
      if (!await dir.exists()) return 0;
      int totalSize = 0;
      try {
        await for (final entity in dir.list(recursive: true, followLinks: false)) {
          if (entity is File) {
            try {
              totalSize += await entity.length();
            } catch (_) {}
          }
        }
      } catch (_) {}
      return totalSize;
    });
  }

  /// Performs bulk copy operation with Isolates
  static Future<void> copyItems({
    required List<String> sourcePaths,
    required String targetDirectory,
    required Function(int bytesCopied, int totalBytes) onProgress,
  }) async {
    final receivePort = ReceivePort();
    
    await Isolate.spawn(_copyIsolateEntry, {
      'sendPort': receivePort.sendPort,
      'sourcePaths': sourcePaths,
      'targetDirectory': targetDirectory,
    });

    await for (final message in receivePort) {
      if (message is Map) {
        if (message['type'] == 'progress') {
          onProgress(message['copied'] as int, message['total'] as int);
        } else if (message['type'] == 'done') {
          receivePort.close();
          break;
        } else if (message['type'] == 'error') {
          receivePort.close();
          throw Exception(message['error']);
        }
      }
    }
  }

  static String _getUniqueDestinationPath(String targetDir, String srcPath) {
    final name = p.basename(srcPath);
    String dest = p.join(targetDir, name);

    if (File(dest).existsSync() || Directory(dest).existsSync()) {
      final ext = p.extension(name);
      final nameWithoutExt = p.basenameWithoutExtension(name);
      int counter = 1;
      dest = p.join(targetDir, '${nameWithoutExt}_copy$ext');
      while (File(dest).existsSync() || Directory(dest).existsSync()) {
        counter++;
        dest = p.join(targetDir, '${nameWithoutExt}_copy_$counter$ext');
      }
    }
    return dest;
  }

  static Future<void> _copyIsolateEntry(Map<String, dynamic> args) async {
    final SendPort sendPort = args['sendPort'];
    final List<String> sourcePaths = List<String>.from(args['sourcePaths']);
    final String targetDirectory = args['targetDirectory'];

    try {
      int totalBytes = 0;
      int copiedBytes = 0;

      // First pass: calculate total bytes
      for (final src in sourcePaths) {
        final type = FileSystemEntity.typeSync(src);
        if (type == FileSystemEntityType.file) {
          totalBytes += File(src).lengthSync();
        } else if (type == FileSystemEntityType.directory) {
          final dir = Directory(src);
          for (final entity in dir.listSync(recursive: true)) {
            if (entity is File) {
              totalBytes += entity.lengthSync();
            }
          }
        }
      }

      sendPort.send({'type': 'progress', 'copied': 0, 'total': totalBytes});

      // Second pass: copy with unique target paths
      for (final src in sourcePaths) {
        final dest = _getUniqueDestinationPath(targetDirectory, src);
        final type = FileSystemEntity.typeSync(src);

        if (type == FileSystemEntityType.file) {
          copiedBytes += await _copyFileWithProgress(src, dest, (c) {
            sendPort.send({'type': 'progress', 'copied': copiedBytes + c, 'total': totalBytes});
          });
        } else if (type == FileSystemEntityType.directory) {
          final srcDir = Directory(src);
          final entities = srcDir.listSync(recursive: true);
          
          Directory(dest).createSync(recursive: true);

          for (final entity in entities) {
            final rel = p.relative(entity.path, from: src);
            final targetPath = p.join(dest, rel);

            if (entity is Directory) {
              Directory(targetPath).createSync(recursive: true);
            } else if (entity is File) {
              copiedBytes += await _copyFileWithProgress(entity.path, targetPath, (c) {
                sendPort.send({'type': 'progress', 'copied': copiedBytes + c, 'total': totalBytes});
              });
            }
          }
        }
      }

      sendPort.send({'type': 'done'});
    } catch (e) {
      sendPort.send({'type': 'error', 'error': e.toString()});
    }
  }

  static Future<int> _copyFileWithProgress(
    String src,
    String dest,
    Function(int currentFileCopied) onChunk,
  ) async {
    final srcFile = File(src);
    if (!srcFile.existsSync()) return 0;

    final length = srcFile.lengthSync();
    File(dest).parent.createSync(recursive: true);
    srcFile.copySync(dest);
    onChunk(length);
    return length;
  }

  /// Delete items asynchronously
  static Future<void> deleteItems(List<String> paths) async {
    return Isolate.run(() async {
      for (final path in paths) {
        final type = FileSystemEntity.typeSync(path);
        if (type == FileSystemEntityType.file) {
          await File(path).delete();
        } else if (type == FileSystemEntityType.directory) {
          await Directory(path).delete(recursive: true);
        }
      }
    });
  }

  /// Compress files/folders into a ZIP archive asynchronously
  static Future<String> compressToZip({
    required List<String> sourcePaths,
    required String targetZipPath,
  }) async {
    return Isolate.run(() async {
      final archive = Archive();
      for (final src in sourcePaths) {
        final type = FileSystemEntity.typeSync(src);
        if (type == FileSystemEntityType.file) {
          final file = File(src);
          if (file.existsSync()) {
            final bytes = file.readAsBytesSync();
            archive.addFile(ArchiveFile(p.basename(src), bytes.length, bytes));
          }
        } else if (type == FileSystemEntityType.directory) {
          final dir = Directory(src);
          if (dir.existsSync()) {
            final baseName = p.basename(src);
            final entities = dir.listSync(recursive: true);
            for (final entity in entities) {
              if (entity is File) {
                final bytes = entity.readAsBytesSync();
                final relPath = p.join(baseName, p.relative(entity.path, from: src));
                archive.addFile(ArchiveFile(relPath, bytes.length, bytes));
              }
            }
          }
        }
      }

      final zipData = ZipEncoder().encode(archive);
      File(targetZipPath).writeAsBytesSync(zipData);
      return targetZipPath;
    });
  }

  /// Extract a ZIP archive into target directory asynchronously
  static Future<void> extractZip({
    required String zipPath,
    required String targetDir,
  }) async {
    return Isolate.run(() async {
      final bytes = await File(zipPath).readAsBytes();
      final archive = ZipDecoder().decodeBytes(bytes);

      for (final file in archive) {
        final filename = file.name;
        final destPath = p.join(targetDir, filename);
        if (file.isFile) {
          final data = file.content as List<int>;
          File(destPath)
            ..createSync(recursive: true)
            ..writeAsBytesSync(data);
        } else {
          Directory(destPath).createSync(recursive: true);
        }
      }
    });
  }
}
