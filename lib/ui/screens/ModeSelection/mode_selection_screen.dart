import 'package:flutter/material.dart';
import 'package:zuno/services/session_guard.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:get/get.dart';
import 'package:hive/hive.dart';

import '../../utils/brand.dart';
import '../../widgets/motion.dart';

class _Mode {
  final String id;
  final String label;
  final String chip;
  final String image;
  final IconData icon;
  final Color accent;

  const _Mode({
    required this.id,
    required this.label,
    required this.chip,
    required this.image,
    required this.icon,
    required this.accent,
  });
}

const _modes = [
  _Mode(
    id: 'music',
    label: 'Music',
    chip: 'Songs, albums & lyrics',
    image: 'assets/onboarding/music.jpg',
    icon: Icons.music_note_rounded,
    accent: kAccent,
  ),
  _Mode(
    id: 'movies',
    label: 'Movies',
    chip: 'Films, series & live TV',
    image: 'assets/onboarding/movies.jpg',
    icon: Icons.movie_rounded,
    accent: Color(0xFFE50914),
  ),
];

/// Pick Movies or Music: two tall photo cards with a big label in the middle,
/// round icon buttons in the corners and a glass chip at the bottom.
class ModeSelectionScreen extends StatefulWidget {
  const ModeSelectionScreen({super.key});

  @override
  State<ModeSelectionScreen> createState() => _ModeSelectionScreenState();
}

class _ModeSelectionScreenState extends State<ModeSelectionScreen> {
  int? _selected;

  Future<void> _pick(int i) async {
    if (_selected != null) return;
    setState(() => _selected = i);
    await Future.delayed(const Duration(milliseconds: 420));
    await Hive.box('AppPrefs').put('appMode', _modes[i].id);
    Get.offAllNamed('/');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0E0B0B),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 18, 16, 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.only(left: 4),
                child: Row(
                  children: [
                    Expanded(
                      child: Text('Pick your vibe',
                          style: headerFont(size: 40, color: Colors.white)),
                    ),
                    TextButton.icon(
                      onPressed: SessionGuard.confirmLogout,
                      style: TextButton.styleFrom(
                          foregroundColor: Colors.white70),
                      icon: const Icon(Icons.logout_rounded, size: 18),
                      label: const Text('Log out'),
                    ),
                  ],
                ),
              ).appear(),
              Padding(
                padding: const EdgeInsets.fromLTRB(4, 4, 4, 18),
                child: Text('You can switch anytime from Settings.',
                    style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.55),
                        fontSize: 14.5)),
              ).appear(index: 1),
              for (var i = 0; i < _modes.length; i++) ...[
                if (i > 0) const SizedBox(height: 14),
                Expanded(
                  child: _ModeCard(
                    mode: _modes[i],
                    selected: _selected == i,
                    dimmed: _selected != null && _selected != i,
                    onTap: () => _pick(i),
                  ).appear(index: 2 + i),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _ModeCard extends StatelessWidget {
  const _ModeCard({
    required this.mode,
    required this.selected,
    required this.dimmed,
    required this.onTap,
  });
  final _Mode mode;
  final bool selected;
  final bool dimmed;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return AnimatedOpacity(
      duration: Motion.medium,
      opacity: dimmed ? 0.35 : 1,
      child: AnimatedScale(
        duration: Motion.slow,
        curve: Curves.easeOutBack,
        scale: selected ? 1.03 : 1,
        child: PressScale(
          child: GestureDetector(
            onTap: onTap,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(26),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Image.asset(mode.image, fit: BoxFit.cover)
                      .animate(onPlay: (c) => c.repeat(reverse: true))
                      .scaleXY(
                          begin: 1,
                          end: 1.07,
                          duration: const Duration(seconds: 12),
                          curve: Curves.easeInOut),
                  DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.black.withValues(alpha: 0.15),
                          Colors.black.withValues(alpha: 0.25),
                          Colors.black.withValues(alpha: 0.6),
                        ],
                      ),
                    ),
                  ),
                  // selected ring
                  AnimatedContainer(
                    duration: Motion.medium,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(26),
                      border: Border.all(
                          color: selected ? mode.accent : Colors.transparent,
                          width: 3),
                    ),
                  ),
                  Positioned(
                    top: 14,
                    left: 14,
                    child: _RoundBadge(
                        child: Icon(mode.icon, size: 18, color: Colors.white)),
                  ),
                  Positioned(
                    top: 14,
                    right: 14,
                    child: _RoundBadge(
                      child: Icon(
                          selected
                              ? Icons.check_rounded
                              : Icons.arrow_outward_rounded,
                          size: 18,
                          color: selected ? mode.accent : Colors.white),
                    ),
                  ),
                  Center(
                    child: Text(mode.label,
                        style: headerFont(size: 64, color: Colors.white)
                            .copyWith(shadows: const [
                          Shadow(color: Colors.black54, blurRadius: 24)
                        ])),
                  ),
                  Positioned(
                    bottom: 16,
                    left: 0,
                    right: 0,
                    child: Center(
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.55),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.play_arrow_rounded,
                                size: 15, color: mode.accent),
                            const SizedBox(width: 5),
                            Text(mode.chip,
                                style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 12.5,
                                    fontWeight: FontWeight.w600)),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _RoundBadge extends StatelessWidget {
  const _RoundBadge({required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 38,
      height: 38,
      decoration: const BoxDecoration(
          color: Color(0xE6000000), shape: BoxShape.circle),
      child: Center(child: child),
    );
  }
}
