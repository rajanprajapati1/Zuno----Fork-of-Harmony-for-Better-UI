import 'package:flutter/gestures.dart' show kSecondaryMouseButton;
import 'package:flutter/material.dart';
import '../utils/brand.dart';
import 'package:get/get.dart';

import 'package:zuno/models/quick_picks.dart';
import '../player/player_controller.dart';
import 'image_widget.dart';
import 'now_playing_overlay.dart';
import 'songinfo_bottom_sheet.dart';

class QuickPicksWidget extends StatelessWidget {
  const QuickPicksWidget(
      {super.key, required this.content, this.scrollController});
  final QuickPicks content;
  final ScrollController? scrollController;

  @override
  Widget build(BuildContext context) {
    final PlayerController playerController = Get.find<PlayerController>();
    return SizedBox(
      height: 280,
      width: double.infinity,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          Align(
              alignment: Alignment.centerLeft,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: Text(
                  content.title.toLowerCase().removeAllWhitespace.tr,
                  style: sectionFont(
                size: 22,
                color: Theme.of(context).textTheme.titleLarge?.color),
                ),
              )),
          const SizedBox(height: 10),
          Expanded(
            child: GridView.builder(
                controller: scrollController,
                physics: const BouncingScrollPhysics(),
                scrollDirection: Axis.horizontal,
                itemCount: content.songList.length,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 4,
                  childAspectRatio: .15 / 1, // Adjusted for removed margins
                  crossAxisSpacing: 6, // Match standard vertical gap
                  mainAxisSpacing: 10, // Match album horizontal gap
                ),
                itemBuilder: (_, item) {
                  return Listener(
                    onPointerDown: (PointerDownEvent event) {
                      if (event.buttons == kSecondaryMouseButton) {
                        //show songinfobotomsheet
                        showModalBottomSheet(
                          constraints: const BoxConstraints(maxWidth: 500),
                          shape: const RoundedRectangleBorder(
                            borderRadius: BorderRadius.vertical(
                                top: Radius.circular(10.0)),
                          ),
                          isScrollControlled: true,
                          context: playerController
                              .homeScaffoldkey.currentState!.context,
                          barrierColor: Colors.transparent.withAlpha(100),
                          builder: (context) => SongInfoBottomSheet(
                            content.songList[item],
                          ),
                        ).whenComplete(() => Get.delete<SongInfoController>());
                      }
                    },
                    child: Material(
                      type: MaterialType.transparency,
                      child: InkWell(
                        onTap: () {
                          playerController
                              .pushSongToQueue(content.songList[item]);
                        },
                        onLongPress: () {
                          showModalBottomSheet(
                            constraints: const BoxConstraints(maxWidth: 500),
                            shape: const RoundedRectangleBorder(
                              borderRadius: BorderRadius.vertical(
                                  top: Radius.circular(10.0)),
                            ),
                            isScrollControlled: true,
                            context: playerController
                                .homeScaffoldkey.currentState!.context,
                            barrierColor: Colors.transparent.withAlpha(100),
                            builder: (context) =>
                                SongInfoBottomSheet(content.songList[item]),
                          ).whenComplete(
                              () => Get.delete<SongInfoController>());
                        },
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 4, vertical: 4),
                          child: Row(
                            children: [
                              Stack(children: [
                                ImageWidget(
                                  song: content.songList[item],
                                  size: 50,
                                ),
                                NowPlayingOverlay(
                                    songId: content.songList[item].id,
                                    size: 50),
                              ]),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      content.songList[item].title,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: Theme.of(context)
                                          .textTheme
                                          .titleMedium
                                          ?.copyWith(
                                            fontWeight: FontWeight.w500,
                                            fontSize: 15,
                                          ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      "${content.songList[item].artist}",
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: Theme.of(context)
                                          .textTheme
                                          .titleSmall
                                          ?.copyWith(
                                            fontSize: 13,
                                            color: Colors.grey[500],
                                          ),
                                    ),
                                  ],
                                ),
                              ),
                              if (GetPlatform.isDesktop)
                                IconButton(
                                    splashRadius: 18,
                                    onPressed: () {
                                      showModalBottomSheet(
                                        constraints:
                                            const BoxConstraints(maxWidth: 500),
                                        shape: const RoundedRectangleBorder(
                                          borderRadius: BorderRadius.vertical(
                                              top: Radius.circular(10.0)),
                                        ),
                                        isScrollControlled: true,
                                        context: playerController
                                            .homeScaffoldkey
                                            .currentState!
                                            .context,
                                        barrierColor:
                                            Colors.transparent.withAlpha(100),
                                        builder: (context) =>
                                            SongInfoBottomSheet(
                                                content.songList[item]),
                                      ).whenComplete(() =>
                                          Get.delete<SongInfoController>());
                                    },
                                    icon: const Icon(Icons.more_vert, size: 18))
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                }),
          ),
          const SizedBox(height: 16) // Half of 32
        ],
      ),
    );
  }
}
