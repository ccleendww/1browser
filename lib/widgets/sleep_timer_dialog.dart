import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/sleep_timer_service.dart';

/// 睡眠定时器设置对话框
class SleepTimerDialog extends StatefulWidget {
  const SleepTimerDialog({super.key});

  @override
  State<SleepTimerDialog> createState() => _SleepTimerDialogState();
}

class _SleepTimerDialogState extends State<SleepTimerDialog> {
  int _customMinutes = 30;
  TimerEndAction _endAction = TimerEndAction.pause;

  @override
  Widget build(BuildContext context) {
    final timerService = context.watch<SleepTimerService>();

    return Dialog(
      backgroundColor: const Color(0xFF1E1E1E),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  '定时关闭',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (timerService.isActive)
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.deepPurpleAccent.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      timerService.formattedRemaining,
                      style: const TextStyle(
                        color: Colors.deepPurpleAccent,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 20),

            // 预设时间
            const Text(
              '预设时间',
              style: TextStyle(color: Colors.white70, fontSize: 14),
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: SleepTimerService.presetMinutes.map((minutes) {
                final isActive = timerService.isActive &&
                    timerService.remainingDuration?.inMinutes == minutes;
                return GestureDetector(
                  onTap: () {
                    timerService.setTimer(minutes, endAction: _endAction);
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: isActive
                          ? Colors.deepPurpleAccent
                          : Colors.white10,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      _formatPreset(minutes),
                      style: TextStyle(
                        color: isActive ? Colors.white : Colors.white70,
                        fontWeight:
                            isActive ? FontWeight.w600 : FontWeight.normal,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 20),

            // 自定义时间
            const Text(
              '自定义时间',
              style: TextStyle(color: Colors.white70, fontSize: 14),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: Slider(
                    value: _customMinutes.toDouble(),
                    min: 1,
                    max: 180,
                    divisions: 179,
                    label: '$_customMinutes 分钟',
                    onChanged: (value) {
                      setState(() {
                        _customMinutes = value.round();
                      });
                    },
                  ),
                ),
                SizedBox(
                  width: 80,
                  child: Text(
                    '$_customMinutes 分钟',
                    style: const TextStyle(color: Colors.white),
                    textAlign: TextAlign.right,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {
                  timerService.setTimer(_customMinutes, endAction: _endAction);
                },
                icon: const Icon(Icons.timer),
                label: Text('设置 $_customMinutes 分钟后关闭'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.deepPurpleAccent,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),

            // 结束行为
            const Text(
              '定时结束时',
              style: TextStyle(color: Colors.white70, fontSize: 14),
            ),
            const SizedBox(height: 10),
            Column(
              children: [
                _buildEndActionOption(
                  TimerEndAction.pause,
                  '暂停播放',
                  '⏸️',
                ),
                _buildEndActionOption(
                  TimerEndAction.stop,
                  '停止播放',
                  '⏹️',
                ),
              ],
            ),
            const SizedBox(height: 20),

            // 取消按钮
            if (timerService.isActive)
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () {
                    timerService.cancelTimer();
                  },
                  icon: const Icon(Icons.cancel_outlined),
                  label: const Text('取消定时器'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.redAccent,
                    side: const BorderSide(color: Colors.redAccent),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildEndActionOption(
    TimerEndAction action,
    String label,
    String icon,
  ) {
    final isSelected = _endAction == action;
    return GestureDetector(
      onTap: () {
        setState(() {
          _endAction = action;
        });
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected
              ? Colors.deepPurpleAccent.withOpacity(0.2)
              : Colors.white10,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? Colors.deepPurpleAccent : Colors.transparent,
            width: 1,
          ),
        ),
        child: Row(
          children: [
            Text(icon, style: const TextStyle(fontSize: 20)),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  color: isSelected ? Colors.white : Colors.white70,
                  fontWeight:
                      isSelected ? FontWeight.w600 : FontWeight.normal,
                ),
              ),
            ),
            if (isSelected)
              const Icon(Icons.check_circle,
                  color: Colors.deepPurpleAccent, size: 20),
          ],
        ),
      ),
    );
  }

  String _formatPreset(int minutes) {
    if (minutes < 60) return '$minutes 分钟';
    final hours = minutes ~/ 60;
    final mins = minutes % 60;
    if (mins == 0) return '$hours 小时';
    return '$hours小时$mins分';
  }
}
