import 'dart:ui';

import 'package:audio_video_progress_bar/audio_video_progress_bar.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:share_plus/share_plus.dart';

import '../../widgets/add_to_playlist.dart';
import '../../widgets/image_widget.dart';
import '../../widgets/loader.dart';
import '../../widgets/sleep_timer_bottom_sheet.dart';
import '../../widgets/songinfo_bottom_sheet.dart';
import '../player_controller.dart';
import 'backgroud_image.dart';
import 'lyrics_widget.dart';
import '../../utils/brand.dart';
import '../../widgets/motion.dart';

const _lyricsBlue = Color(0xFF4F7FA3);

/// Full-screen player (portrait, mobile): blurred cover background, large
/// cover, title row with like / add buttons, thin progress bar, round white
/// play button, extra actions row and a light-blue Lyrics card.
class ModernPlayer extends StatelessWidget {
  const ModernPlayer({super.key});

  @override
  Widget build(BuildContext context) {
    final pc = Get.find<PlayerController>();
    final media = MediaQuery.of(context);
    final size = media.size;
    // cover fills the width but leaves room for the controls below
    final artSize = (size.width - 48)
        .clamp(120.0, size.height - media.padding.vertical - 470);

    return Stack(
      children: [
        // Background: blurred cover + dark gradient for legibility
        BackgroudImage(
          key: Key("${pc.currentSong.value?.id}_background"),
          cacheHeight: 300,
        ),
        Positioned.fill(
          child: ClipRect(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 40, sigmaY: 40),
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.black.withOpacity(0.25),
                      Colors.black.withOpacity(0.45),
                      Colors.black.withOpacity(0.85),
                    ],
                    stops: const [0, 0.5, 1],
                  ),
                ),
              ),
            ),
          ),
        ),
        Padding(
          padding: EdgeInsets.only(
              top: media.padding.top + 6,
              bottom: media.padding.bottom + 12,
              left: 20,
              right: 20),
          child: Column(
            children: [
              _TopBar(pc: pc),
              const Spacer(),
              // Large cover; swipe to change song, long-press for options
              Obx(() {
                final song = pc.currentSong.value;
                if (song == null) return SizedBox(height: artSize);
                return GestureDetector(
                  onLongPress: () => _songMenu(pc),
                  onHorizontalDragEnd: (d) {
                    if ((d.primaryVelocity ?? 0) < 0) {
                      pc.next();
                    } else if ((d.primaryVelocity ?? 0) > 0) {
                      pc.prev();
                    }
                  },
                  // cover shrinks a little when paused; songs cross-fade
                  child: AnimatedScale(
                    scale: pc.buttonState.value == PlayButtonState.paused
                        ? 0.88
                        : 1.0,
                    duration: Motion.slow,
                    curve: Curves.easeOutBack,
                    child: AnimatedSwitcher(
                      duration: Motion.slow,
                      switchInCurve: Motion.curve,
                      transitionBuilder: (child, anim) => FadeTransition(
                        opacity: anim,
                        child: ScaleTransition(
                            scale: Tween(begin: 0.94, end: 1.0).animate(anim),
                            child: child),
                      ),
                      child: Container(
                        key: ValueKey(song.id),
                        decoration: const BoxDecoration(boxShadow: [
                          BoxShadow(
                              color: Colors.black45,
                              blurRadius: 30,
                              offset: Offset(0, 12))
                        ]),
                        child: ImageWidget(
                            size: artSize, song: song, isPlayerArtImage: true),
                      ),
                    ),
                  ),
                );
              }),
              const Spacer(),
              _TitleRow(pc: pc),
              const SizedBox(height: 14),
              _Progress(pc: pc),
              const SizedBox(height: 4),
              _Controls(pc: pc),
              const SizedBox(height: 8),
              _ExtraRow(pc: pc),
              const SizedBox(height: 12),
              _LyricsCard(pc: pc),
            ],
          ),
        ),
      ],
    );
  }
}

void _songMenu(PlayerController pc) {
  final song = pc.currentSong.value;
  if (song == null) return;
  showModalBottomSheet(
    constraints: const BoxConstraints(maxWidth: 500),
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(10.0)),
    ),
    isScrollControlled: true,
    context: pc.homeScaffoldkey.currentState!.context,
    barrierColor: Colors.transparent.withAlpha(100),
    builder: (context) => SongInfoBottomSheet(song, calledFromPlayer: true),
  ).whenComplete(() => Get.delete<SongInfoController>());
}

class _TopBar extends StatelessWidget {
  const _TopBar({required this.pc});
  final PlayerController pc;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        IconButton(
          tooltip: "Minimize",
          icon: const Icon(Icons.keyboard_arrow_down_rounded,
              size: 32, color: Colors.white),
          onPressed: pc.playerPanelController.close,
        ),
        Expanded(
          child: Obx(() => Column(
                children: [
                  Text(pc.playinfrom.value.typeString.toUpperCase(),
                      maxLines: 1,
                      style: TextStyle(
                          color: Colors.white.withOpacity(0.7),
                          fontSize: 10.5,
                          letterSpacing: 1.2,
                          fontWeight: FontWeight.w600)),
                  const SizedBox(height: 2),
                  Text(pc.playinfrom.value.nameString,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 13.5,
                          fontWeight: FontWeight.w700)),
                ],
              )),
        ),
        IconButton(
          tooltip: "More",
          icon: const Icon(Icons.more_horiz_rounded,
              size: 28, color: Colors.white),
          onPressed: () => _songMenu(pc),
        ),
      ],
    );
  }
}

class _TitleRow extends StatelessWidget {
  const _TitleRow({required this.pc});
  final PlayerController pc;

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final song = pc.currentSong.value;
      return Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(song?.title ?? "",
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.5)),
                const SizedBox(height: 3),
                Text(song?.artist ?? "",
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                        color: Colors.white.withOpacity(0.7),
                        fontSize: 15,
                        fontWeight: FontWeight.w500)),
              ],
            ),
          ),
          IconButton(
            tooltip: "favorites".tr,
            onPressed: pc.toggleFavourite,
            icon: PopSwitcher(
              child: Icon(
                  pc.isCurrentSongFav.isTrue
                      ? Icons.favorite_rounded
                      : Icons.favorite_border_rounded,
                  key: ValueKey(pc.isCurrentSongFav.isTrue),
                  size: 28,
                  color: pc.isCurrentSongFav.isTrue ? kAccent : Colors.white),
            ),
          ),
          IconButton(
            tooltip: "addToPlaylist".tr,
            onPressed: song == null
                ? null
                : () => showDialog(
                      context: context,
                      builder: (context) => AddToPlaylist([song]),
                    ).whenComplete(
                        () => Get.delete<AddToPlaylistController>()),
            icon: const Icon(Icons.add_circle_outline_rounded,
                size: 28, color: Colors.white),
          ),
        ],
      );
    });
  }
}

class _Progress extends StatelessWidget {
  const _Progress({required this.pc});
  final PlayerController pc;

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final s = pc.progressBarStatus.value;
      return ProgressBar(
        progress: s.current,
        total: s.total,
        buffered: s.buffered,
        onSeek: pc.seek,
        barHeight: 3.5,
        thumbRadius: 6,
        thumbGlowRadius: 14,
        baseBarColor: Colors.white.withOpacity(0.22),
        bufferedBarColor: Colors.white.withOpacity(0.35),
        progressBarColor: Colors.white,
        thumbColor: Colors.white,
        timeLabelPadding: 6,
        timeLabelTextStyle: TextStyle(
            color: Colors.white.withOpacity(0.7),
            fontSize: 12,
            fontFeatures: const [FontFeature.tabularFigures()]),
      );
    });
  }
}

class _Controls extends StatelessWidget {
  const _Controls({required this.pc});
  final PlayerController pc;

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final state = pc.buttonState.value;
      final isLast = pc.currentQueue.isEmpty ||
          (!(pc.isShuffleModeEnabled.isTrue ||
                  pc.isQueueLoopModeEnabled.isTrue) &&
              pc.currentQueue.last.id == pc.currentSong.value?.id);
      return Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _ModeButton(
            icon: Icons.shuffle_rounded,
            active: pc.isShuffleModeEnabled.isTrue,
            onTap: pc.toggleShuffleMode,
          ),
          IconButton(
            iconSize: 40,
            onPressed: pc.prev,
            icon: const Icon(Icons.skip_previous_rounded, color: Colors.white),
          ),
          PressScale(
            scale: 0.9,
            child: Material(
            color: Colors.white,
            shape: const CircleBorder(),
            child: InkWell(
              customBorder: const CircleBorder(),
              onTap: state == PlayButtonState.loading
                  ? null
                  : state == PlayButtonState.playing
                      ? pc.pause
                      : pc.play,
              child: SizedBox(
                width: 68,
                height: 68,
                child: Center(
                  child: PopSwitcher(
                    child: state == PlayButtonState.loading
                        ? const LoadingIndicator(
                            key: ValueKey('loading'),
                            dimension: 28,
                            strokeWidth: 3,
                            color: Colors.black)
                        : Icon(
                            state == PlayButtonState.playing
                                ? Icons.pause_rounded
                                : Icons.play_arrow_rounded,
                            key: ValueKey(state),
                            size: 40,
                            color: Colors.black),
                  ),
                ),
              ),
            ),
          )),
          IconButton(
            iconSize: 40,
            onPressed: isLast ? null : pc.next,
            icon: Icon(Icons.skip_next_rounded,
                color: isLast ? Colors.white30 : Colors.white),
          ),
          _ModeButton(
            icon: Icons.repeat_rounded,
            active: pc.isLoopModeEnabled.isTrue,
            onTap: pc.toggleLoopMode,
          ),
        ],
      );
    });
  }
}

/// Shuffle / repeat toggle: green with a dot when active.
class _ModeButton extends StatelessWidget {
  const _ModeButton(
      {required this.icon, required this.active, required this.onTap});
  final IconData icon;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkResponse(
      onTap: onTap,
      radius: 26,
      child: SizedBox(
        width: 44,
        height: 48,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 26, color: active ? kAccent : Colors.white),
            const SizedBox(height: 3),
            Container(
              width: 4,
              height: 4,
              decoration: BoxDecoration(
                  color: active ? kAccent : Colors.transparent,
                  shape: BoxShape.circle),
            ),
          ],
        ),
      ),
    );
  }
}

class _ExtraRow extends StatelessWidget {
  const _ExtraRow({required this.pc});
  final PlayerController pc;

  @override
  Widget build(BuildContext context) {
    final c = Colors.white.withOpacity(0.85);
    return Row(
      children: [
        Obx(() => IconButton(
              tooltip: "Sleep timer",
              icon: Icon(Icons.bedtime_outlined,
                  size: 23,
                  color: pc.isSleepTimerActive.isTrue ? kAccent : c),
              onPressed: () => showModalBottomSheet(
                constraints: const BoxConstraints(maxWidth: 500),
                shape: const RoundedRectangleBorder(
                  borderRadius:
                      BorderRadius.vertical(top: Radius.circular(10.0)),
                ),
                isScrollControlled: true,
                context: pc.homeScaffoldkey.currentState!.context,
                barrierColor: Colors.transparent.withAlpha(100),
                builder: (context) => const SleepTimerBottomSheet(),
              ),
            )),
        const Spacer(),
        IconButton(
          tooltip: "share".tr,
          icon: Icon(Icons.ios_share_rounded, size: 22, color: c),
          onPressed: () {
            final id = pc.currentSong.value?.id;
            if (id != null) Share.share("https://youtube.com/watch?v=$id");
          },
        ),
        IconButton(
          tooltip: "Queue",
          icon: Icon(Icons.queue_music_rounded, size: 25, color: c),
          onPressed: () => pc.queuePanelController.open(),
        ),
      ],
    );
  }
}

/// Light-blue "Lyrics" card; tapping opens the full lyrics sheet.
class _LyricsCard extends StatelessWidget {
  const _LyricsCard({required this.pc});
  final PlayerController pc;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: _lyricsBlue,
      borderRadius: BorderRadius.circular(10),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => openLyricsSheet(context, pc),
        child: SizedBox(
          height: 56,
          child: Row(
            children: [
              const SizedBox(width: 16),
              const Icon(Icons.lyrics_outlined, color: Colors.white, size: 22),
              const SizedBox(width: 10),
              const Expanded(
                child: Text("Lyrics",
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w800)),
              ),
              Container(
                width: 34,
                height: 34,
                margin: const EdgeInsets.only(right: 12),
                decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.2),
                    shape: BoxShape.circle),
                child: const Icon(Icons.open_in_full_rounded,
                    size: 18, color: Colors.white),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Full-height lyrics sheet on the light-blue background, with a
/// synced / plain switch and a close button.
void openLyricsSheet(BuildContext context, PlayerController pc) {
  // showLyrics() toggles the flag and fetches lyrics when turning on
  if (pc.showLyricsflag.isFalse) pc.showLyrics();
  showModalBottomSheet(
    context: pc.homeScaffoldkey.currentState!.context,
    isScrollControlled: true,
    backgroundColor: _lyricsBlue,
    shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
    builder: (ctx) => SizedBox(
      height: MediaQuery.of(ctx).size.height * 0.92,
      child: Column(
        children: [
          const SizedBox(height: 10),
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
                color: Colors.white54, borderRadius: BorderRadius.circular(2)),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 8, 4),
            child: Row(
              children: [
                Expanded(
                  child: Obx(() => Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(pc.currentSong.value?.title ?? "",
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 18,
                                  fontWeight: FontWeight.w800)),
                          Text(pc.currentSong.value?.artist ?? "",
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                  color: Colors.white.withOpacity(0.75),
                                  fontSize: 14)),
                        ],
                      )),
                ),
                IconButton(
                  tooltip: "Close",
                  icon: const Icon(Icons.close_rounded, color: Colors.white),
                  onPressed: () => Navigator.of(ctx).pop(),
                ),
              ],
            ),
          ),
          // synced / plain switch
          Obx(() => Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  children: [
                    for (final (i, label) in [(0, 'synced'.tr), (1, 'plain'.tr)])
                      Padding(
                        padding: const EdgeInsets.only(right: 8, top: 6),
                        child: ChoiceChip(
                          label: Text(label),
                          selected: pc.lyricsMode.value == i,
                          showCheckmark: false,
                          onSelected: (_) => pc.changeLyricsMode(i),
                          color: WidgetStateProperty.resolveWith((states) =>
                              states.contains(WidgetState.selected)
                                  ? Colors.white
                                  : Colors.white.withOpacity(0.18)),
                          side: BorderSide.none,
                          labelStyle: TextStyle(
                              fontWeight: FontWeight.w700,
                              color: pc.lyricsMode.value == i
                                  ? Colors.black
                                  : Colors.white),
                        ),
                      ),
                  ],
                ),
              )),
          const Expanded(
            child: LyricsWidget(
                padding: EdgeInsets.symmetric(horizontal: 24, vertical: 40)),
          ),
        ],
      ),
    ),
  ).whenComplete(() {
    // hide the lyrics overlay used by other player layouts
    pc.showLyricsflag.value = false;
  });
}
