import 'dart:io';
import '../models/audio_file.dart';

/// 音频文件扫描服务
class AudioScannerService {
  /// 支持的音频扩展名
  static const Set<String> _supportedExtensions = {
    '.mp3',
    '.wav',
    '.flac',
    '.aac',
    '.m4a',
    '.ogg',
    '.wma',
    '.opus',
    '.amr',
  };

  /// 检查文件是否为支持的音频格式
  static bool isAudioFile(String path) {
    final ext = path.toLowerCase();
    return _supportedExtensions.any((e) => ext.endsWith(e));
  }

  /// 扫描指定目录下的所有音频文件
  ///
  /// [directoryPath] 目录路径
  /// [recursive] 是否递归子目录，默认 true
  /// 返回按文件名排序的音频文件列表
  static Future<List<AudioFile>> scanDirectory(
    String directoryPath, {
    bool recursive = true,
  }) async {
    final directory = Directory(directoryPath);
    if (!await directory.exists()) {
      return [];
    }

    final List<AudioFile> audioFiles = [];

    try {
      await for (final entity in directory.list(
        recursive: recursive,
        followLinks: false,
      )) {
        if (entity is File && isAudioFile(entity.path)) {
          try {
            audioFiles.add(AudioFile.fromFile(entity));
          } catch (_) {
            // 跳过无法读取的文件
          }
        }
      }
    } catch (_) {
      // 目录访问出错
    }

    // 按文件名排序
    audioFiles.sort((a, b) => a.displayName.compareTo(b.displayName));

    return audioFiles;
  }

  /// 获取文件夹名称
  static String getFolderName(String directoryPath) {
    final dir = Directory(directoryPath);
    return dir.uri.pathSegments.where((s) => s.isNotEmpty).last;
  }
}
