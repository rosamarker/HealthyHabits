import 'package:flutter/material.dart';
import 'package:stop_watch_timer/stop_watch_timer.dart';

/// Minimal UI wrapper around [StopWatchTimer] used for timed exercises.
class StopwatchWidget extends StatelessWidget {
  final StopWatchTimer stopWatchTimer;

  const StopwatchWidget({
    super.key,
    required this.stopWatchTimer,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: StreamBuilder<int>(
            stream: stopWatchTimer.rawTime,
            initialData: stopWatchTimer.rawTime.value,
            builder: (context, snap) {
              final value = snap.data ?? 0;
              final display = StopWatchTimer.getDisplayTime(
                value,
                milliSecond: false,
                hours: false,
              );
              return Text(
                display,
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
              );
            },
          ),
        ),
        IconButton(
          tooltip: 'Start',
          icon: const Icon(Icons.play_arrow),
          onPressed: () => stopWatchTimer.onStartTimer(),
        ),
        IconButton(
          tooltip: 'Pause',
          icon: const Icon(Icons.pause),
          onPressed: () => stopWatchTimer.onStopTimer(),
        ),
        IconButton(
          tooltip: 'Reset',
          icon: const Icon(Icons.replay),
          onPressed: () => stopWatchTimer.onResetTimer(),
        ),
      ],
    );
  }
}
