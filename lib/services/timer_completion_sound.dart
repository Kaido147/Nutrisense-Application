import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';

class TimerCompletionSound {
  const TimerCompletionSound._();

  static Future<void> play() async {
    try {
      final player = AudioPlayer();
      await player.setReleaseMode(ReleaseMode.release);
      await player.play(AssetSource('sounds/timer_complete.wav'));
    } catch (error, stackTrace) {
      debugPrint('Timer completion sound failed: $error');
      debugPrintStack(stackTrace: stackTrace);
    }
  }
}
