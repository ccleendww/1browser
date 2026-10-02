import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:file_picker/file_picker.dart';
import '../models/audio_file.dart';
import '../services/audio_scanner_service.dart';
import '../services/audio_player_service.dart';
import '../services/sleep_timer_service.dart';
import '../widgets/audio_list.dart';
import '../widgets/player_bar.dart';
import '../widgets/sleep_timer_dialog.dart';

/// 主页
class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  List<AudioFile> _audioFiles = [];
  String? _folderPath;
  String? _folderName;
  bool _isScanning = false;
  bool _isRecursive = true;

  @override
  void initState() {
    super.initState();
    // 关联定时器结束时的行为
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final timerService = context.read<SleepTimerService>();
      final playerService = context.read<AudioPlayerService>();
      timerService.onTimerEnd = () {
        playerService.pause();
      };
    });
  }

  /// 选择文件夹
  Future<void> _pickFolder() async {
    try {
      String? selectedDirectory = await FilePicker.platform.getDirectoryPath();

      if (selectedDirectory == null) return;

      setState(() {
        _folderPath = selectedDirectory;
        _folderName = AudioScannerService.getFolderName(selectedDirectory);
        _isScanning = true;
        _audioFiles = [];
      });

      // 扫描音频文件
      final files = await AudioScannerService.scanDirectory(
        selectedDirectory,
        recursive: _isRecursive,
      );

      setState(() {
        _audioFiles = files;
        _isScanning = false;
      });

      // 设置播放列表
      if (mounted && files.isNotEmpty) {
        final playerService = context.read<AudioPlayerService>();
        await playerService.setPlaylist(files);
      }

      if (mounted && files.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('该文件夹中没有找到音频文件'),
            backgroundColor: Colors.deepOrange,
          ),
        );
      }
    } catch (e) {
      setState(() {
        _isScanning = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('选择文件夹失败: $e')),
        );
      }
    }
  }

  /// 重新扫描
  Future<void> _rescan() async {
    if (_folderPath == null) return;

    setState(() {
      _isScanning = true;
    });

    final files = await AudioScannerService.scanDirectory(
      _folderPath!,
      recursive: _isRecursive,
    );

    setState(() {
      _audioFiles = files;
      _isScanning = false;
    });

    if (mounted && files.isNotEmpty) {
      final playerService = context.read<AudioPlayerService>();
      await playerService.setPlaylist(files);
    }
  }

  /// 显示定时器对话框
  void _showSleepTimer() {
    showDialog(
      context: context,
      builder: (context) => const SleepTimerDialog(),
    );
  }

  /// 切换递归扫描
  void _toggleRecursive(bool value) {
    setState(() {
      _isRecursive = value;
    });
    // 如果已有文件夹，重新扫描
    if (_folderPath != null) {
      _rescan();
    }
  }

  @override
  Widget build(BuildContext context) {
    final playerService = context.watch<AudioPlayerService>();
    final timerService = context.watch<SleepTimerService>();
    final isTablet = MediaQuery.of(context).size.shortestSide >= 600;

    return Scaffold(
      appBar: AppBar(
        title: Text(_folderName ?? '音乐播放器'),
        actions: [
          // 定时器按钮
          IconButton(
            onPressed: _showSleepTimer,
            icon: Stack(
              children: [
                const Icon(Icons.timer_outlined),
                if (timerService.isActive)
                  Positioned(
                    right: 0,
                    top: 0,
                    child: Container(
                      padding: const EdgeInsets.all(2),
                      decoration: const BoxDecoration(
                        color: Colors.deepPurpleAccent,
                        shape: BoxShape.circle,
                      ),
                      constraints: const BoxConstraints(
                        minWidth: 8,
                        minHeight: 8,
                      ),
                    ),
                  ),
              ],
            ),
            tooltip: '定时关闭',
          ),
          // 播放模式
          if (_audioFiles.isNotEmpty)
            IconButton(
              onPressed: () {
                playerService.togglePlayMode();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('${playerService.playModeIcon} ${playerService.playModeName}'),
                    duration: const Duration(seconds: 1),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              },
              icon: Text(
                playerService.playModeIcon,
                style: const TextStyle(fontSize: 22),
              ),
              tooltip: playerService.playModeName,
            ),
          // 递归扫描开关
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert),
            onSelected: (value) {
              if (value == 'rescan') {
                _rescan();
              }
            },
            itemBuilder: (context) => [
              PopupMenuItem(
                enabled: _folderPath != null,
                child: StatefulBuilder(
                  builder: (context, setState) {
                    return Row(
                      children: [
                        const Text('包含子文件夹'),
                        const Spacer(),
                        Switch(
                          value: _isRecursive,
                          onChanged: (value) {
                            Navigator.pop(context);
                            _toggleRecursive(value);
                          },
                          activeColor: Colors.deepPurpleAccent,
                        ),
                      ],
                    );
                  },
                ),
              ),
              if (_folderPath != null)
                const PopupMenuItem(
                  value: 'rescan',
                  child: Row(
                    children: [
                      Icon(Icons.refresh, color: Colors.white70),
                      SizedBox(width: 12),
                      Text('重新扫描'),
                    ],
                  ),
                ),
            ],
          ),
        ],
      ),
      body: _buildBody(isTablet),
      bottomNavigationBar: const PlayerBar(),
      floatingActionButton: _folderPath == null
          ? FloatingActionButton.extended(
              onPressed: _pickFolder,
              backgroundColor: Colors.deepPurpleAccent,
              icon: const Icon(Icons.folder_open),
              label: const Text('选择文件夹'),
            )
          : FloatingActionButton(
              onPressed: _pickFolder,
              backgroundColor: Colors.deepPurpleAccent,
              child: const Icon(Icons.folder_open),
              tooltip: '更换文件夹',
            ),
    );
  }

  Widget _buildBody(bool isTablet) {
    if (_folderPath == null && !_isScanning) {
      return _buildEmptyState();
    }

    if (_isScanning) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(color: Colors.deepPurpleAccent),
            SizedBox(height: 16),
            Text(
              '正在扫描音频文件...',
              style: TextStyle(color: Colors.white70),
            ),
          ],
        ),
      );
    }

    // 平板布局：左右分栏
    if (isTablet) {
      return _buildTabletLayout();
    }

    // 手机布局：列表
    return AudioList(audioFiles: _audioFiles, folderName: _folderName);
  }

  Widget _buildTabletLayout() {
    return Row(
      children: [
        // 左侧：播放列表
        Expanded(
          flex: 5,
          child: AudioList(audioFiles: _audioFiles, folderName: _folderName),
        ),
        // 右侧：当前播放详情
        Expanded(
          flex: 4,
          child: _buildNowPlayingPanel(),
        ),
      ],
    );
  }

  Widget _buildNowPlayingPanel() {
    final playerService = context.watch<AudioPlayerService>();

    return Container(
      margin: const EdgeInsets.fromLTRB(0, 8, 8, 8),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E1E),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // 封面
          Container(
            width: 180,
            height: 180,
            decoration: BoxDecoration(
              color: Colors.deepPurpleAccent.withOpacity(0.2),
              borderRadius: BorderRadius.circular(24),
            ),
            child: const Icon(
              Icons.music_note,
              color: Colors.deepPurpleAccent,
              size: 80,
            ),
          ),
          const SizedBox(height: 24),
          // 歌曲名
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Text(
              playerService.currentAudio?.displayName ?? '未播放',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _folderName ?? '',
            style: const TextStyle(color: Colors.white54, fontSize: 14),
          ),
          const SizedBox(height: 32),
          // 进度条
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: StreamBuilder<Duration>(
              stream: playerService.positionStream,
              initialData: Duration.zero,
              builder: (context, snapshot) {
                final position = snapshot.data ?? Duration.zero;
                final duration = playerService.duration;
                return Column(
                  children: [
                    Slider(
                      value: duration.inMilliseconds > 0
                          ? position.inMilliseconds / duration.inMilliseconds
                          : 0.0,
                      onChanged: (value) {
                        final newPos = Duration(
                          milliseconds: (value * duration.inMilliseconds).toInt(),
                        );
                        playerService.seek(newPos);
                      },
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          _formatDuration(position),
                          style: const TextStyle(
                            color: Colors.white54,
                            fontSize: 12,
                          ),
                        ),
                        Text(
                          _formatDuration(duration),
                          style: const TextStyle(
                            color: Colors.white54,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ],
                );
              },
            ),
          ),
          const SizedBox(height: 24),
          // 控制按钮
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton(
                onPressed: playerService.hasPrevious
                    ? () => playerService.previous()
                    : null,
                icon: const Icon(Icons.skip_previous),
                color: Colors.white,
                iconSize: 36,
              ),
              const SizedBox(width: 24),
              IconButton(
                onPressed: () => playerService.togglePlay(),
                icon: Icon(
                  playerService.isPlaying
                      ? Icons.pause_circle_filled
                      : Icons.play_circle_filled,
                  color: Colors.deepPurpleAccent,
                  size: 64,
                ),
              ),
              const SizedBox(width: 24),
              IconButton(
                onPressed:
                    playerService.hasNext ? () => playerService.next() : null,
                icon: const Icon(Icons.skip_next),
                color: Colors.white,
                iconSize: 36,
              ),
            ],
          ),
          const SizedBox(height: 24),
          // 播放模式
          TextButton.icon(
            onPressed: () {
              playerService.togglePlayMode();
            },
            icon: Text(
              playerService.playModeIcon,
              style: const TextStyle(fontSize: 18),
            ),
            label: Text(
              playerService.playModeName,
              style: const TextStyle(color: Colors.white70),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                color: Colors.deepPurpleAccent.withOpacity(0.1),
                borderRadius: BorderRadius.circular(30),
              ),
              child: const Icon(
                Icons.library_music_outlined,
                size: 60,
                color: Colors.deepPurpleAccent,
              ),
            ),
            const SizedBox(height: 32),
            const Text(
              '欢迎使用音乐播放器',
              style: TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              '选择一个文件夹，开始播放您喜欢的音乐',
              style: TextStyle(color: Colors.white54, fontSize: 15),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 40),
            ElevatedButton.icon(
              onPressed: _pickFolder,
              icon: const Icon(Icons.folder_open),
              label: const Text('选择文件夹'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.deepPurpleAccent,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 32,
                  vertical: 16,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                textStyle: const TextStyle(fontSize: 16),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              '支持 MP3、WAV、FLAC、M4A、AAC、OGG 等格式',
              style: TextStyle(color: Colors.white38, fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDuration(Duration duration) {
    final minutes = duration.inMinutes.remainder(60);
    final seconds = duration.inSeconds.remainder(60);
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }
}
