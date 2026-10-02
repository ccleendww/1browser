import 'dart:async';
import 'package:flutter/foundation.dart';

/// 定时结束行为
enum TimerEndAction {
  /// 暂停播放
  pause,

  /// 停止播放
  stop,

  /// 退出应用（仅提示，实际由系统决定）
  exitApp,
}

/// 睡眠定时器服务
class SleepTimerService extends ChangeNotifier {
  Timer? _timer;
  Duration? _remainingDuration;
  DateTime? _endTime;
  TimerEndAction _endAction = TimerEndAction.pause;
  bool _isActive = false;

  /// 是否激活
  bool get isActive => _isActive;

  /// 剩余时间
  Duration? get remainingDuration => _remainingDuration;

  /// 结束时间
  DateTime? get endTime => _endTime;

  /// 结束行为
  TimerEndAction get endAction => _endAction;

  /// 格式化的剩余时间
  String get formattedRemaining {
    if (_remainingDuration == null) return '未设置';
    final duration = _remainingDuration!;
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    final seconds = duration.inSeconds.remainder(60);
    if (hours > 0) {
      return '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
    }
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  /// 预设时间选项（分钟）
  static const List<int> presetMinutes = [5, 10, 15, 30, 45, 60, 90, 120];

  /// 回调：定时结束时调用
  VoidCallback? onTimerEnd;

  SleepTimerService();

  /// 设置定时器
  ///
  /// [minutes] 分钟数
  /// [endAction] 结束行为
  void setTimer(int minutes, {TimerEndAction endAction = TimerEndAction.pause}) {
    cancelTimer();

    _endAction = endAction;
    _remainingDuration = Duration(minutes: minutes);
    _endTime = DateTime.now().add(_remainingDuration!);
    _isActive = true;

    _startTick();
    notifyListeners();
  }

  /// 启动计时器
  void _startTick() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_remainingDuration == null) return;

      _remainingDuration = _remainingDuration! - const Duration(seconds: 1);

      if (_remainingDuration!.inSeconds <= 0) {
        _remainingDuration = Duration.zero;
        cancelTimer();
        _triggerEndAction();
      }

      notifyListeners();
    });
  }

  /// 触发结束行为
  void _triggerEndAction() {
    onTimerEnd?.call();
  }

  /// 取消定时器
  void cancelTimer() {
    _timer?.cancel();
    _timer = null;
    _isActive = false;
    _remainingDuration = null;
    _endTime = null;
    notifyListeners();
  }

  /// 增加时间
  void addTime(int minutes) {
    if (!_isActive || _remainingDuration == null) return;

    _remainingDuration = _remainingDuration! + Duration(minutes: minutes);
    _endTime = DateTime.now().add(_remainingDuration!);
    notifyListeners();
  }

  /// 减少时间
  void reduceTime(int minutes) {
    if (!_isActive || _remainingDuration == null) return;

    final newDuration = _remainingDuration! - Duration(minutes: minutes);
    if (newDuration.inSeconds <= 0) {
      cancelTimer();
      _triggerEndAction();
    } else {
      _remainingDuration = newDuration;
      _endTime = DateTime.now().add(_remainingDuration!);
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}
