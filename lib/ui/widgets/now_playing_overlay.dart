import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../player/player_controller.dart';
import '../utils/brand.dart';

/// Overlay for a song cover: a spinner while this song is loading, a coral
/// sound-wave while it plays, nothing otherwise. Place it in a Stack over
/// the cover.
class NowPlayingOverlay extends StatelessWidget {
  const NowPlayingOverlay(
      {super.key, required this.songId, required this.size});
  final String songId;
  final double size;

  @override
  Widget build(BuildContext context) {
    final pc = Get.find<PlayerController>();
    return Obx(() {
      if (pc.currentSong.value?.id != songId) return const SizedBox.shrink();
      final loading = pc.buttonState.value == PlayButtonState.loading;
      return Container(
        width: size,
        height: size,
        color: Colors.black.withOpacity(0.5),
        alignment: Alignment.center,
        child: loading
            ? SizedBox.square(
                dimension: (size * 0.36).clamp(16.0, 34.0),
                child: const CircularProgressIndicator(
                    strokeWidth: 2.5, color: Colors.white),
              )
            : Icon(Icons.graphic_eq_rounded,
                size: (size * 0.4).clamp(18.0, 40.0), color: kAccent),
      );
    });
  }
}
