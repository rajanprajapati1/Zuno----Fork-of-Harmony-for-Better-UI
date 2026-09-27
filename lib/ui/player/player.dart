
import 'package:get/get.dart';
import 'package:flutter/material.dart';

import 'package:zuno/ui/player/components/gesture_player.dart';
import 'package:zuno/ui/player/components/standard_player.dart';
import 'package:zuno/ui/screens/Settings/settings_screen_controller.dart';
import '../../utils/helper.dart';
import '../widgets/up_next_queue.dart';
import 'package:zuno/ui/player/player_controller.dart';
import '../widgets/sliding_up_panel.dart';

/// Player screen
/// Contains the player ui
///
/// Player ui can be standard player or gesture player
class Player extends StatelessWidget {
  const Player({super.key});

  @override
  Widget build(BuildContext context) {
    printINFO("player");
    final size = MediaQuery.of(context).size;
    final PlayerController playerController = Get.find<PlayerController>();
    final settingsScreenController = Get.find<SettingsScreenController>();
    return Scaffold(
      /// SlidingUpPanel is used to create a panel that can slide up and down
      /// It is used to show the current queue panel in mobile
      body: Obx(
        () => SlidingUpPanel(
          boxShadow: const [],
          color: Colors.transparent,
          // the modern phone layout opens the queue from its own button
          minHeight: settingsScreenController.playerUi.value == 0 &&
                  !(GetPlatform.isMobile && !context.isLandscape)
              ? 65 + Get.mediaQuery.padding.bottom
              : 0,
          maxHeight: size.height,
          isDraggable: !GetPlatform.isDesktop,
          controller: GetPlatform.isDesktop
              ? null
              : playerController.queuePanelController,

          /// this is the header of the collapsed panel
          /// contains the button ^ to open the queue panel
          collapsed: InkWell(
            onTap: () {
              /// queue open in end drawer in desktop
              if (GetPlatform.isDesktop) {
                playerController.homeScaffoldkey.currentState!.openEndDrawer();
              } else {
                playerController.queuePanelController.open();
              }
            },
            child: Container(
                color: Theme.of(context).primaryColor,
                child: Column(
                  children: [
                    SizedBox(
                      height: 65,
                      child: Center(
                          child: Icon(
                        color: Theme.of(context).textTheme.titleMedium!.color,
                        Icons.keyboard_arrow_up,
                        size: 40,
                      )),
                    ),
                  ],
                )),
          ),

          /// Panel for queue
          panelBuilder: (ScrollController sc, onReorderStart, onReorderEnd) {
            playerController.scrollController = sc;
            return Stack(
              children: [
                /// Stack first child
                /// UpNextQueue widget contains list of songs in queue
                UpNextQueue(
                  onReorderEnd: onReorderEnd,
                  onReorderStart: onReorderStart,
                ),

                /// Stack second child
                /// Shuffle / Repeat / Timer tiles pinned to the bottom
                const Align(
                  alignment: Alignment.bottomCenter,
                  child: QueueActionsBar(),
                ),
              ],
            );
          },

          /// show player ui based on selected player ui in settings
          /// Gesture player is only applicable for mobile
          body: settingsScreenController.playerUi.value == 0
              ? const StandardPlayer()
              : const GesturePlayer(),
        ),
      ),
    );
  }
}
