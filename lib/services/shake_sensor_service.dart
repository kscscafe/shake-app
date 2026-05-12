import 'dart:async';
import 'dart:math' as math;

import 'package:sensors_plus/sensors_plus.dart';

/// 加速度センサーで [duration] 秒間サンプリングし、各秒のピーク |a| のうち
/// 上位 [topSeconds] 秒分の平均を m/s² で返す。
///
/// 重力を含まない userAccelerometer を使うため、静止時は 0 付近・振ると大きく増える。
class ShakeSensorService {
  StreamSubscription<UserAccelerometerEvent>? _sub;

  Future<double> measure({
    Duration duration = const Duration(seconds: 10),
    int topSeconds = 5,
  }) async {
    final totalSeconds = duration.inSeconds;
    final perSecondPeak = List<double>.filled(totalSeconds, 0.0);
    final start = DateTime.now();
    final completer = Completer<double>();

    _sub = userAccelerometerEventStream(
      samplingPeriod: const Duration(milliseconds: 20),
    ).listen((event) {
      final magnitude = math.sqrt(
        event.x * event.x + event.y * event.y + event.z * event.z,
      );
      final elapsedMs = DateTime.now().difference(start).inMilliseconds;
      final idx = elapsedMs ~/ 1000;
      if (idx < 0 || idx >= totalSeconds) return;
      if (magnitude > perSecondPeak[idx]) {
        perSecondPeak[idx] = magnitude;
      }
    });

    Timer(duration, () async {
      await _sub?.cancel();
      _sub = null;

      final sorted = [...perSecondPeak]..sort((a, b) => b.compareTo(a));
      final top = sorted.take(topSeconds).toList();
      final avg = top.isEmpty
          ? 0.0
          : top.reduce((a, b) => a + b) / top.length;
      if (!completer.isCompleted) completer.complete(avg);
    });

    return completer.future;
  }

  Future<void> dispose() async {
    await _sub?.cancel();
    _sub = null;
  }
}
