import 'dart:io';
import 'package:path/path.dart' as p;

enum FileSortMode { name, size, date, type }

class FileItem {
  final String path;
  final String name;
  final bool isDirectory;
  final int size;
  final DateTime modified;
  final String extension;
  final bool isHidden;
  final String permissions;

  const FileItem({
    required this.path,
    required this.name,
    required this.isDirectory,
    required this.size,
    required this.modified,
    required this.extension,
    required this.isHidden,
    required this.permissions,
  });

  factory FileItem.fromFileSystemEntity(FileSystemEntity entity, FileStat stat) {
    final name = p.basename(entity.path);
    final isDir = entity is Directory;
    final ext = isDir ? '' : p.extension(name).replaceAll('.', '').toLowerCase();
    final isHidden = name.startsWith('.');

    return FileItem(
      path: entity.path,
      name: name,
      isDirectory: isDir,
      size: stat.size,
      modified: stat.modified,
      extension: ext,
      isHidden: isHidden,
      permissions: stat.modeString(),
    );
  }
}
