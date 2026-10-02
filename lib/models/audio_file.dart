import 'dart:io';

/// 音频文件模型
class AudioFile {
  /// 文件路径
  final String path;

  /// 文件名（含扩展名）
  final String fileName;

  /// 显示名称（不含扩展名）
  final String displayName;

  /// 文件大小（字节）
  final int size;

  /// 文件修改时间
  final DateTime modified;

  AudioFile({
    required this.path,
    required this.fileName,
    required this.displayName,
    required this.size,
    required this.modified,
  });

  /// 从 File 对象创建
  factory AudioFile.fromFile(File file) {
    final stat = file.statSync();
    final fileName = file.uri.pathSegments.last;
    final displayName = fileName.replaceAll(RegExp(r'\.[^.]+$'), '');
    return AudioFile(
      path: file.path,
      fileName: fileName,
      displayName: displayName,
      size: stat.size,
      modified: stat.modified,
    );
  }

  /// 格式化文件大小
  String get formattedSize {
    if (size < 1024) return '$size B';
    if (size < 1024 * 1024) return '${(size / 1024).toStringAsFixed(1)} KB';
    return '${(size / (1024 * 1024)).toStringAsFixed(1)} MB';
  }
}
