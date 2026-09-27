import 'package:flutter/material.dart';
import 'package:zuno/ui/utils/brand.dart';
import 'package:zuno/ui/widgets/motion.dart';
import 'package:get/get.dart';

import 'components/search_item.dart';
import 'package:zuno/ui/screens/Settings/settings_screen_controller.dart';
import '../../widgets/modified_text_field.dart';
import 'package:zuno/ui/navigator.dart';
import 'search_screen_controller.dart';
import '../../widgets/page_title.dart';

class SearchScreen extends StatelessWidget {
  const SearchScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final searchScreenController = Get.put(SearchScreenController());
    final settingsScreenController = Get.find<SettingsScreenController>();
    final topPadding = context.isLandscape ? 50.0 : 80.0;
    return Scaffold(
      resizeToAvoidBottomInset: false,
      body: Obx(
        () => Row(
          children: [
            settingsScreenController.isBottomNavBarEnabled.isFalse
                ? Container(
                    width: 60,
                    color:
                        Theme.of(context).navigationRailTheme.backgroundColor,
                    child: Column(
                      children: [
                        Padding(
                          padding: EdgeInsets.only(top: topPadding),
                          child: IconButton(
                            icon: Icon(
                              Icons.arrow_back_ios_new,
                              color: Theme.of(context)
                                  .textTheme
                                  .titleMedium!
                                  .color,
                            ),
                            onPressed: () {
                              Get.nestedKey(ScreenNavigationSetup.id)!
                                  .currentState!
                                  .pop();
                            },
                          ),
                        ),
                      ],
                    ),
                  )
                : const SizedBox.shrink(),
            Expanded(
              child: Padding(
                padding: EdgeInsets.only(
                    top: settingsScreenController.isBottomNavBarEnabled.isTrue
                        ? 0
                        : topPadding,
                    left: settingsScreenController.isBottomNavBarEnabled.isTrue
                        ? 0
                        : 5),
                child: Column(
                  children: [
                    settingsScreenController.isBottomNavBarEnabled.isTrue
                        ? PageTitle("search".tr)
                        : Align(
                            alignment: Alignment.centerLeft,
                            child: Text(
                              "search".tr,
                              style: Theme.of(context).textTheme.titleLarge,
                            ),
                          ),
                    const SizedBox(
                      height: 14,
                    ),
                    ModifiedTextField(
                      textCapitalization: TextCapitalization.sentences,
                      controller: searchScreenController.textInputController,
                      textInputAction: TextInputAction.search,
                      onChanged: searchScreenController.onChanged,
                      onSubmitted: (val) {
                        if (val.contains("https://")) {
                          searchScreenController.filterLinks(Uri.parse(val));
                          searchScreenController.reset();
                          return;
                        }
                        Get.toNamed(ScreenNavigationSetup.searchResultScreen,
                            id: ScreenNavigationSetup.id, arguments: val);
                        searchScreenController.addToHistryQueryList(val);
                      },
                      autofocus: settingsScreenController
                          .isBottomNavBarEnabled.isFalse,
                      cursorColor: Theme.of(context).textTheme.bodySmall!.color,
                      // Filled search box with a search icon (no underline)
                      decoration: InputDecoration(
                          isDense: true,
                          filled: true,
                          fillColor: Colors.white.withOpacity(0.09),
                          contentPadding:
                              const EdgeInsets.symmetric(vertical: 14),
                          border: const OutlineInputBorder(
                              borderSide: BorderSide.none,
                              borderRadius:
                                  BorderRadius.all(Radius.circular(2))),
                          enabledBorder: const OutlineInputBorder(
                              borderSide: BorderSide.none,
                              borderRadius:
                                  BorderRadius.all(Radius.circular(2))),
                          focusedBorder: OutlineInputBorder(
                              borderSide: BorderSide(
                                  color: Colors.white.withOpacity(0.35)),
                              borderRadius:
                                  const BorderRadius.all(Radius.circular(2))),
                          hintText: "searchDes".tr,
                          hintStyle: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w500,
                              color: Colors.white.withOpacity(0.45)),
                          prefixIcon: Icon(Icons.search_rounded,
                              color: Colors.white.withOpacity(0.7)),
                          suffixIcon: IconButton(
                            onPressed: searchScreenController.reset,
                            icon: Icon(Icons.close_rounded,
                                color: Colors.white.withOpacity(0.6)),
                            splashRadius: 16,
                            iconSize: 20,
                          )),
                    ),
                    Expanded(
                      child: Obx(() {
                        final isEmpty = searchScreenController
                                .suggestionList.isEmpty ||
                            searchScreenController.textInputController.text ==
                                "";
                        final list = isEmpty
                            ? searchScreenController.historyQuerylist.toList()
                            : searchScreenController.suggestionList.toList();
                        return ListView(
                            padding: const EdgeInsets.only(top: 5, bottom: 400),
                            physics: const BouncingScrollPhysics(
                                parent: AlwaysScrollableScrollPhysics()),
                            children: searchScreenController.urlPasted.isTrue
                                ? [
                                    InkWell(
                                      onTap: () {
                                        searchScreenController.filterLinks(
                                            Uri.parse(searchScreenController
                                                .textInputController.text));
                                        searchScreenController.reset();
                                      },
                                      child: Padding(
                                        padding: const EdgeInsets.symmetric(
                                            vertical: 10.0),
                                        child: SizedBox(
                                          width: double.maxFinite,
                                          height: 60,
                                          child: Center(
                                              child: Text(
                                            "urlSearchDes".tr,
                                            style: Theme.of(context)
                                                .textTheme
                                                .titleMedium,
                                          )),
                                        ),
                                      ),
                                    )
                                  ]
                                : [
                                    ...list.map((item) => SearchItem(
                                        queryString: item,
                                        isHistoryString: isEmpty)),
                                    if (isEmpty) const _BrowseGrid(),
                                  ]);
                      }),
                    )
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// "Browse all" genre tiles shown under the search box when it is empty.
class _BrowseGrid extends StatelessWidget {
  const _BrowseGrid();

  static const _genres = <(String, Color, IconData)>[
    ('Bollywood', Color(0xFFD9433F), Icons.movie_filter_rounded),
    ('Pop', Color(0xFFE13300), Icons.star_rounded),
    ('Hip Hop', Color(0xFFBA5D07), Icons.mic_external_on_rounded),
    ('Indie', Color(0xFF8D67AB), Icons.eco_rounded),
    ('Punjabi', Color(0xFF1E3264), Icons.celebration_rounded),
    ('Lofi', Color(0xFF477D95), Icons.nightlight_round),
    ('Romance', Color(0xFFE8115B), Icons.favorite_rounded),
    ('Devotional', Color(0xFFE91429), Icons.self_improvement_rounded),
    ('Party', Color(0xFF7B3FE4), Icons.nightlife_rounded),
    ('Chill', Color(0xFF509BF5), Icons.spa_rounded),
    ('Workout', Color(0xFF777777), Icons.fitness_center_rounded),
    ('Sad', Color(0xFFAF2896), Icons.water_drop_rounded),
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 18, bottom: 14, left: 2),
          child: Text("Browse all",
              style: sectionFont(
                  size: 20,
                  color: Theme.of(context).textTheme.titleMedium?.color)),
        ),
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          padding: EdgeInsets.zero,
          mainAxisSpacing: 10,
          crossAxisSpacing: 10,
          childAspectRatio: 1.75,
          children: [
            for (final (i, (name, color, icon)) in _genres.indexed)
              PressScale(child: Material(
                color: color,
                clipBehavior: Clip.hardEdge,
                borderRadius: BorderRadius.circular(2),
                child: InkWell(
                  onTap: () => Get.toNamed(
                      ScreenNavigationSetup.searchResultScreen,
                      id: ScreenNavigationSetup.id,
                      arguments: "$name songs"),
                  child: Stack(
                    children: [
                      // soft shading for depth
                      Positioned.fill(
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [
                                Colors.white.withOpacity(0.06),
                                Colors.black.withOpacity(0.22),
                              ],
                            ),
                          ),
                        ),
                      ),
                      // tilted icon peeking from the corner
                      Positioned(
                        right: -10,
                        bottom: -8,
                        child: Transform.rotate(
                          angle: 0.42,
                          child: Icon(icon,
                              size: 64,
                              color: Colors.white.withOpacity(0.28)),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(12),
                        child: Text(
                          name,
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 16.5,
                              fontWeight: FontWeight.w800,
                              letterSpacing: -0.3),
                        ),
                      ),
                    ],
                  ),
                ),
              )).appear(index: i),
          ],
        ),
      ],
    );
  }
}
