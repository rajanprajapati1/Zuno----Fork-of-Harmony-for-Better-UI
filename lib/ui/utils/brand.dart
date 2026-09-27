import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Zuno accent: warm pastel coral taken from the logo's orange. Used for
/// play buttons, the playing song, and active toggles.
const kAccent = Color(0xFFFF6F61);

/// Darker end for accent gradients.
const kAccentDeep = Color(0xFFD9433F);

/// Surface for sheets such as the queue.
const kSheetSurface = Color(0xFF1B1B1E);

/// Page-header font (condensed, bold) used for the big titles at the top of
/// screens: Home, Search, Library, Favourites, Settings, playlist, artist,
/// queue. Not used for section headings or list text.
TextStyle headerFont({double size = 40, Color? color}) => GoogleFonts.anton(
    fontSize: size, height: 1.05, letterSpacing: -0.3, color: color);

/// Section-heading font ("Recently played", "Quick Picks", "Popular", ...).
TextStyle sectionFont({double size = 22, Color? color}) =>
    GoogleFonts.plusJakartaSans(
        fontSize: size,
        height: 1.15,
        fontWeight: FontWeight.w800,
        letterSpacing: -0.6,
        color: color);
