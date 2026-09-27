import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:zuno/ui/player/player_controller.dart';

import '../utils/brand.dart';
import 'image_widget.dart';
import 'loader.dart';
import 'motion.dart';
import 'sleep_timer_bottom_sheet.dart';
import 'snackbar.dart';
import 'songinfo_bottom_sheet.dart';

/// Queue list: "Queue" header, compact rows, the playing song highlighted in
/// the accent colour with a play/pause button, drag handles to reorder and
/// swipe to remove.
class UpNextQueue extends StatelessWidget {
  const UpNextQueue(
      {super.key,
      this.onReorderEnd,
      this.onReorderStart,
      this.isQueueInSlidePanel = true});
  final void Function(int)? onReorderStart;
  final void Function(int)? onReorderEnd;
  final bool isQueueInSlidePanel;

  @override
  Widget build(BuildContext context) {
    final pc = Get.find<PlayerController>();
    return Container(
      decoration: BoxDecoration(
        color: isQueueInSlidePanel
            ? kSheetSurface
            : Theme.of(context).bottomSheetTheme.backgroundColor,
        borderRadius: isQueueInSlidePanel
            ? const BorderRadius.vertical(top: Radius.circular(16))
            : null,
      ),
      child: Obx(() {
        return ReorderableListView.builder(
          buildDefaultDragHandles: false,
          header: _QueueHeader(pc: pc, showHandle: isQueueInSlidePanel),
          footer: SizedBox(height: Get.mediaQuery.padding.bottom),
          scrollController: isQueueInSlidePanel ? pc.scrollController : null,
          onReorder: (int oldIndex, int newIndex) {
            if (pc.isShuffleModeEnabled.isTrue) {
              ScaffoldMessenger.of(Get.context!).showSnackBar(snackbar(
                  Get.context!, "queuerearrangingDeniedMsg".tr,
                  size: SanckBarSize.BIG));
              return;
            }
            pc.onReorder(oldIndex, newIndex);
          },
          onReorderStart: onReorderStart,
          onReorderEnd: onReorderEnd,
          itemCount: pc.currentQueue.length,
          padding: EdgeInsets.only(bottom: isQueueInSlidePanel ? 110 : 0),
          physics: const AlwaysScrollableScrollPhysics(),
          itemBuilder: (context, index) {
            final song = pc.currentQueue[index];
            return Material(
              key: Key('$index'),
              color: Colors.transparent,
              child: Dismissible(
                key: Key(song.id),
                direction: DismissDirection.horizontal,
                confirmDismiss: (direction) async =>
                    pc.currentSongIndex.value != index,
                onDismissed: (direction) => pc.removeFromQueue(song),
                background: Container(
                  color: kAccentDeep.withOpacity(0.6),
                  alignment: Alignment.centerLeft,
                  padding: const EdgeInsets.only(left: 20),
                  child: const Icon(Icons.delete_outline_rounded,
                      color: Colors.white),
                ),
                child: Obx(() => _QueueRow(
                      index: index,
                      isCurrent: pc.currentSongIndex.value == index,
                      pc: pc,
                    )),
              ),
            );
          },
        );
      }),
    );
  }
}

class _QueueHeader extends StatelessWidget {
  const _QueueHeader({required this.pc, required this.showHandle});
  final PlayerController pc;
  final bool showHandle;

  @override
  Widget build(BuildContext context) {
    final top = showHandle ? MediaQuery.of(context).padding.top : 0.0;
    return Padding(
      // clear the status bar when the sheet is fully open
      padding: EdgeInsets.fromLTRB(20, 10 + top, 10, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (showHandle)
            Center(
              child: Container(
                width: 36,
                height: 4,
                margin: const EdgeInsets.only(bottom: 18),
                decoration: BoxDecoration(
                    color: Colors.white24,
                    borderRadius: BorderRadius.circular(2)),
              ),
            ),
          // Title row: "Queue", song count pill, clear button
          Row(
            children: [
              Text("Queue", style: headerFont(size: 32, color: Colors.white)),
              const Spacer(),
              Obx(() => Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text("${pc.currentQueue.length} songs",
                        style: TextStyle(
                            color: Colors.white.withOpacity(0.75),
                            fontSize: 12,
                            fontWeight: FontWeight.w600)),
                  )),
              IconButton(
                tooltip: "Clear queue",
                visualDensity: VisualDensity.compact,
                icon: Icon(Icons.playlist_remove_rounded,
                    size: 22, color: Colors.white.withOpacity(0.7)),
                onPressed: pc.clearQueue,
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Source: small caps label, then the name
          Text("PLAYING FROM",
              style: TextStyle(
                  color: Colors.white.withOpacity(0.45),
                  fontSize: 10.5,
                  letterSpacing: 1.4,
                  fontWeight: FontWeight.w700)),
          const SizedBox(height: 4),
          Obx(() => Text(pc.playinfrom.value.nameString,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  letterSpacing: -0.2))),
          const SizedBox(height: 16),
          Container(
            height: 1,
            margin: const EdgeInsets.only(right: 10, bottom: 6),
            color: Colors.white.withOpacity(0.07),
          ),
        ],
      ),
    );
  }
}

class _QueueRow extends StatelessWidget {
  const _QueueRow(
      {required this.index, required this.isCurrent, required this.pc});
  final int index;
  final bool isCurrent;
  final PlayerController pc;

  @override
  Widget build(BuildContext context) {
    final song = pc.currentQueue[index];
    return PressScale(
      scale: 0.98,
      child: InkWell(
      onTap: () => pc.seekByIndex(index),
      onLongPress: () {
        showModalBottomSheet(
          constraints: const BoxConstraints(maxWidth: 500),
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(top: Radius.circular(10.0)),
          ),
          isScrollControlled: true,
          context: pc.homeScaffoldkey.currentState!.context,
          barrierColor: Colors.transparent.withAlpha(100),
          builder: (context) =>
              SongInfoBottomSheet(song, calledFromQueue: true),
        ).whenComplete(() => Get.delete<SongInfoController>());
      },
      child: Container(
        color: isCurrent ? Colors.white.withOpacity(0.05) : null,
        padding: const EdgeInsets.fromLTRB(20, 5, 6, 5),
        child: Row(
          children: [
            ImageWidget(size: 48, song: song),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      if (isCurrent) ...[
                        const Icon(Icons.graphic_eq_rounded,
                            size: 16, color: kAccent),
                        const SizedBox(width: 6),
                      ],
                      Flexible(
                        child: Text(song.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                                color: isCurrent ? kAccent : Colors.white,
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                                letterSpacing: -0.2)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 3),
                  Text(song.artist ?? "",
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                          color: Colors.white.withOpacity(0.55),
                          fontSize: 13)),
                ],
              ),
            ),
            if (isCurrent)
              _PlayPauseDot(pc: pc)
            else ...[
              if (GetPlatform.isDesktop)
                IconButton(
                  tooltip: "Remove",
                  icon: Icon(Icons.close_rounded,
                      size: 20, color: Colors.white.withOpacity(0.5)),
                  onPressed: () => pc.removeFromQueue(song),
                ),
              ReorderableDragStartListener(
                index: index,
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Icon(Icons.drag_handle_rounded,
                      color: Colors.white.withOpacity(0.55)),
                ),
              ),
            ],
          ],
        ),
      ),
    ));
  }
}

/// Small white play/pause circle for the playing row.
class _PlayPauseDot extends StatelessWidget {
  const _PlayPauseDot({required this.pc});
  final PlayerController pc;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 6),
      child: Obx(() {
        final state = pc.buttonState.value;
        return Material(
          color: Colors.white,
          shape: const CircleBorder(),
          child: InkWell(
            customBorder: const CircleBorder(),
            onTap: state == PlayButtonState.playing ? pc.pause : pc.play,
            child: SizedBox(
              width: 38,
              height: 38,
              child: Center(
                child: PopSwitcher(
                  child: state == PlayButtonState.loading
                      ? const LoadingIndicator(
                          key: ValueKey("l"),
                          dimension: 18,
                          strokeWidth: 2.5,
                          color: Colors.black)
                      : Icon(
                          state == PlayButtonState.playing
                              ? Icons.pause_rounded
                              : Icons.play_arrow_rounded,
                          key: ValueKey(state),
                          size: 24,
                          color: Colors.black),
                ),
              ),
            ),
          ),
        );
      }),
    );
  }
}

/// Bottom action tiles for the queue sheet: Shuffle, Repeat, Timer.
class QueueActionsBar extends StatelessWidget {
  const QueueActionsBar({super.key});

  @override
  Widget build(BuildContext context) {
    final pc = Get.find<PlayerController>();
    return Container(
      padding: EdgeInsets.fromLTRB(
          16, 12, 16, 12 + MediaQuery.of(context).padding.bottom),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.bottomCenter,
          end: Alignment.topCenter,
          colors: [kSheetSurface, kSheetSurface, kSheetSurface.withOpacity(0)],
          stops: const [0, 0.75, 1],
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: _ActionTile(
              icon: Icons.shuffle_rounded,
              label: "shuffle".tr.capitalizeFirst ?? "Shuffle",
              onTap: () {
                if (pc.isShuffleModeEnabled.isTrue) {
                  ScaffoldMessenger.of(context).showSnackBar(snackbar(
                      context, "queueShufflingDeniedMsg".tr,
                      size: SanckBarSize.BIG));
                  return;
                }
                pc.shuffleQueue();
              },
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Obx(() => _ActionTile(
                  icon: Icons.repeat_rounded,
                  label: "Repeat",
                  active: pc.isQueueLoopModeEnabled.isTrue,
                  onTap: pc.toggleQueueLoopMode,
                )),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Obx(() => _ActionTile(
                  icon: Icons.timer_outlined,
                  label: "Timer",
                  active: pc.isSleepTimerActive.isTrue,
                  onTap: () => showModalBottomSheet(
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
          ),
        ],
      ),
    );
  }
}

class _ActionTile extends StatelessWidget {
  const _ActionTile(
      {required this.icon,
      required this.label,
      required this.onTap,
      this.active = false});
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool active;

  @override
  Widget build(BuildContext context) {
    final color = active ? kAccent : Colors.white;
    return Material(
      color: active
          ? kAccent.withOpacity(0.14)
          : Colors.white.withOpacity(0.08),
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: onTap,
        child: SizedBox(
          height: 60,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 22, color: color),
              const SizedBox(height: 4),
              Text(label,
                  style: TextStyle(
                      color: color,
                      fontSize: 12.5,
                      fontWeight: FontWeight.w600)),
            ],
          ),
        ),
      ),
    );
  }
}
