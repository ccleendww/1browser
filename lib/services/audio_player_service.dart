import 'package:flutter/foundation.dart';
import 'package:just_audio/just_audio.dart';
import 'package:audio_session/audio_session.dart';
import '../models/audio_file.dart';

/// 播放模式
enum PlayMode {
  /// 列表循环
  listLoop,

  /// 单曲循环
  singleLoop,

  /// 随机播放
  shuffle,

  /// 顺序播放
  sequence,
}

/// 音频播放服务
class AudioPlayerService extends ChangeNotifier {
  final AudioPlayer _player = AudioPlayer();
  final List<AudioFile> _playlist = [];
  int _currentIndex = -1;
  PlayMode _playMode = PlayMode.sequence;
  bool _isInitialized = false;

  /// 播放列表
  List<AudioFile> get playlist => List.unmodifiable(_playlist);

  /// 当前播放索引
  int get currentIndex => _currentIndex;

  /// 当前播放的音频文件
  AudioFile? get currentAudio =>
      _currentIndex >= 0 && _currentIndex < _playlist.length
          ? _playlist[_currentIndex]
          : null;

  /// 是否正在播放
  bool get isPlaying => _player.playing;

  /// 播放状态
  ProcessingState get processingState => _player.processingState;

  /// 当前播放位置
  Duration get position => _player.position;

  /// 总时长
  Duration get duration => _player.duration ?? Duration.zero;

  /// 播放模式
  PlayMode get playMode => _playMode;

  /// 是否有上一首
  bool get hasPrevious => _playlist.isNotEmpty && _currentIndex > 0;

  /// 是否有下一首
  bool get hasNext =>
      _playlist.isNotEmpty && _currentIndex < _playlist.length - 1;

  /// 播放位置流
  Stream<Duration> get positionStream => _player.positionStream;

  /// 播放状态流
  Stream<bool> get playingStream => _player.playingStream;

  /// 时长流
  Stream<Duration?> get durationStream => _player.durationStream;

  AudioPlayerService() {
    _init();
  }

  Future<void> _init() async {
    // 配置音频会话
    final session = await AudioSession.instance;
    await session.configure(const AudioSessionConfiguration.music());

    // 监听播放完成事件
    _player.processingStateStream.listen((state) {
      if (state == ProcessingState.completed) {
        _onPlaybackCompleted();
      }
      notifyListeners();
    });

    // 监听播放状态变化
    _player.playingStream.listen((_) {
      notifyListeners();
    });

    // 监听位置变化（用于 UI 更新）
    _player.positionStream.listen((_) {
      // 不每次都通知，避免性能问题，UI 层使用 StreamBuilder 监听
    });

    _isInitialized = true;
    notifyListeners();
  }

  /// 设置播放列表
  Future<void> setPlaylist(List<AudioFile> files, {int initialIndex = 0}) async {
    _playlist.clear();
    _playlist.addAll(files);

    if (files.isEmpty) {
      _currentIndex = -1;
      await _player.stop();
      notifyListeners();
      return;
    }

    final index = initialIndex.clamp(0, files.length - 1);
    await _playAtIndex(index);
  }

  /// 播放指定索引的音频
  Future<void> _playAtIndex(int index) async {
    if (index < 0 || index >= _playlist.length) return;

    _currentIndex = index;
    final audio = _playlist[index];

    try {
      await _player.setFilePath(audio.path);
      await _player.play();
    } catch (e) {
      debugPrint('播放失败: $e');
    }

    notifyListeners();
  }

  /// 播放指定索引
  Future<void> playAt(int index) async {
    if (index >= 0 && index < _playlist.length) {
      await _playAtIndex(index);
    }
  }

  /// 播放/暂停
  Future<void> togglePlay() async {
    if (_player.playing) {
      await _player.pause();
    } else {
      if (_currentIndex < 0 && _playlist.isNotEmpty) {
        await _playAtIndex(0);
      } else {
        await _player.play();
      }
    }
  }

  /// 暂停
  Future<void> pause() async {
    await _player.pause();
  }

  /// 停止
  Future<void> stop() async {
    await _player.stop();
  }

  /// 上一首
  Future<void> previous() async {
    if (_playlist.isEmpty) return;

    int newIndex;
    switch (_playMode) {
      case PlayMode.shuffle:
        newIndex = _getRandomIndex();
        break;
      case PlayMode.singleLoop:
      case PlayMode.listLoop:
      case PlayMode.sequence:
        newIndex = _currentIndex - 1;
        if (newIndex < 0) {
          if (_playMode == PlayMode.listLoop) {
            newIndex = _playlist.length - 1;
          } else {
            newIndex = 0;
          }
        }
        break;
    }

    await _playAtIndex(newIndex);
  }

  /// 下一首
  Future<void> next() async {
    if (_playlist.isEmpty) return;

    int newIndex;
    switch (_playMode) {
      case PlayMode.shuffle:
        newIndex = _getRandomIndex();
        break;
      case PlayMode.singleLoop:
      case PlayMode.listLoop:
      case PlayMode.sequence:
        newIndex = _currentIndex + 1;
        if (newIndex >= _playlist.length) {
          if (_playMode == PlayMode.listLoop) {
            newIndex = 0;
          } else {
            newIndex = _playlist.length - 1;
            await _player.pause();
            notifyListeners();
            return;
          }
        }
        break;
    }

    await _playAtIndex(newIndex);
  }

  /// 播放完成回调
  void _onPlaybackCompleted() {
    if (_playlist.isEmpty) return;

    switch (_playMode) {
      case PlayMode.singleLoop:
        // 单曲循环：重新播放当前曲目
        _player.seek(Duration.zero).then((_) => _player.play());
        break;
      case PlayMode.listLoop:
      case PlayMode.shuffle:
        next();
        break;
      case PlayMode.sequence:
        if (_currentIndex < _playlist.length - 1) {
          next();
        }
        break;
    }
  }

  /// 获取随机索引（避免与当前相同）
  int _getRandomIndex() {
    if (_playlist.length <= 1) return 0;
    int newIndex;
    do {
      newIndex = DateTime.now().millisecondsSinceEpoch % _playlist.length;
    } while (newIndex == _currentIndex);
    return newIndex;
  }

  /// 跳转到指定位置
  Future<void> seek(Duration position) async {
    await _player.seek(position);
  }

  /// 切换播放模式
  void togglePlayMode() {
    final modes = PlayMode.values;
    final currentIndex = modes.indexOf(_playMode);
    _playMode = modes[(currentIndex + 1) % modes.length];
    notifyListeners();
  }

  /// 获取播放模式名称
  String get playModeName {
    switch (_playMode) {
      case PlayMode.sequence:
        return '顺序播放';
      case PlayMode.listLoop:
        return '列表循环';
      case PlayMode.singleLoop:
        return '单曲循环';
      case PlayMode.shuffle:
        return '随机播放';
    }
  }

  /// 获取播放模式图标
  String get playModeIcon {
    switch (_playMode) {
      case PlayMode.sequence:
        return '🔁';
      case PlayMode.listLoop:
        return '🔄';
      case PlayMode.singleLoop:
        return '🔂';
      case PlayMode.shuffle:
        return '🔀';
    }
  }

  @override
  void dispose() {
    _player.dispose();
    super.dispose();
  }
}
