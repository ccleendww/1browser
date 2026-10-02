import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/audio_file.dart';
import '../services/audio_player_service.dart';

/// 音频文件列表组件
class AudioList extends StatelessWidget {
  final List<AudioFile> audioFiles;
  final String? folderName;

  const AudioList({
    super.key,
    required this.audioFiles,
    this.folderName,
  });

  @override
  Widget build(BuildContext context) {
    final playerService = context.watch<AudioPlayerService>();

    if (audioFiles.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.folder_outlined,
              size: 80,
              color: Colors.white30,
            ),
            const SizedBox(height: 16),
            const Text(
              '没有找到音频文件',
              style: TextStyle(color: Colors.white54, fontSize: 16),
            ),
            const SizedBox(height: 8),
            const Text(
              '请选择包含音频的文件夹',
              style: TextStyle(color: Colors.white38, fontSize: 14),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: EdgeInsets.only(
        top: 8,
        bottom: playerService.currentAudio != null ? 100 : 16,
      ),
      itemCount: audioFiles.length,
      itemBuilder: (context, index) {
        final audio = audioFiles[index];
        final isPlaying = playerService.currentIndex == index &&
            playerService.isPlaying;
        final isCurrent = playerService.currentIndex == index;

        return _AudioListItem(
          audio: audio,
          index: index,
          isPlaying: isPlaying,
          isCurrent: isCurrent,
          onTap: () {
            if (isCurrent) {
              playerService.togglePlay();
            } else {
              playerService.playAt(index);
            }
          },
        );
      },
    );
  }
}

class _AudioListItem extends StatelessWidget {
  final AudioFile audio;
  final int index;
  final bool isPlaying;
  final bool isCurrent;
  final VoidCallback onTap;

  const _AudioListItem({
    required this.audio,
    required this.index,
    required this.isPlaying,
    required this.isCurrent,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: isCurrent
            ? Colors.deepPurpleAccent.withOpacity(0.15)
            : Colors.transparent,
        borderRadius: BorderRadius.circular(10),
      ),
      child: ListTile(
        onTap: onTap,
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        leading: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: isCurrent
                ? Colors.deepPurpleAccent.withOpacity(0.3)
                : Colors.white10,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Center(
            child: isPlaying
                ? const _PlayingAnimation()
                : Text(
                    '${index + 1}',
                    style: TextStyle(
                      color: isCurrent ? Colors.deepPurpleAccent : Colors.white54,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
          ),
        ),
        title: Text(
          audio.displayName,
          style: TextStyle(
            color: isCurrent ? Colors.deepPurpleAccent : Colors.white,
            fontWeight: isCurrent ? FontWeight.w600 : FontWeight.normal,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Text(
            audio.formattedSize,
            style: const TextStyle(color: Colors.white38, fontSize: 12),
          ),
        ),
        trailing: Icon(
          isCurrent
              ? (isPlaying ? Icons.pause : Icons.play_arrow)
              : Icons.play_arrow,
          color: isCurrent ? Colors.deepPurpleAccent : Colors.white38,
          size: 28,
        ),
      ),
    );
  }
}

/// 播放中动画效果
class _PlayingAnimation extends StatefulWidget {
  const _PlayingAnimation();

  @override
  State<_PlayingAnimation> createState() => _PlayingAnimationState();
}

class _PlayingAnimationState extends State<_PlayingAnimation>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Row(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            _buildBar(0, 0.3),
            const SizedBox(width: 2),
            _buildBar(1, 0.6),
            const SizedBox(width: 2),
            _buildBar(2, 0.4),
          ],
        );
      },
    );
  }

  Widget _buildBar(int index, double baseHeight) {
    final animationValue = _controller.value;
    final height = 8 + (baseHeight + animationValue * 0.5) * 16;
    return Container(
      width: 3,
      height: height,
      decoration: BoxDecoration(
        color: Colors.deepPurpleAccent,
        borderRadius: BorderRadius.circular(1.5),
      ),
    );
  }
}
