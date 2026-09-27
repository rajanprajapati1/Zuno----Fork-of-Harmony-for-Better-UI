import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:zuno/models/movie.dart';
import 'package:zuno/ui/widgets/tv_focus_wrapper.dart';

class MovieCard extends StatelessWidget {
  final Movie movie;
  final VoidCallback? onTap;
  final double width;
  final bool showTitle;

  const MovieCard({
    super.key,
    required this.movie,
    this.onTap,
    this.width = 140,
    this.showTitle = true,
  });

  @override
  Widget build(BuildContext context) {
    return TVFocusWrapper(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      scaleFactor: 1.08,
      child: SizedBox(
        width: width,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Poster
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: AspectRatio(
                aspectRatio: 2 / 3,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    movie.posterUrl.isNotEmpty
                        ? CachedNetworkImage(
                            imageUrl: movie.posterUrlSmall,
                            fit: BoxFit.cover,
                            placeholder: (_, __) => Container(
                              color: Colors.grey[900],
                              child: const Center(
                                child: Icon(Icons.movie,
                                    color: Colors.white38, size: 40),
                              ),
                            ),
                            errorWidget: (_, __, ___) => Container(
                              color: Colors.grey[900],
                              child: const Center(
                                child: Icon(Icons.broken_image,
                                    color: Colors.white38, size: 40),
                              ),
                            ),
                          )
                        : Container(
                            color: Colors.grey[900],
                            child: const Center(
                              child: Icon(Icons.movie,
                                  color: Colors.white38, size: 40),
                            ),
                          ),
                    // Rating badge
                    if (movie.voteAverage > 0)
                      Positioned(
                        top: 8,
                        right: 8,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 3),
                          decoration: BoxDecoration(
                            color: _ratingColor(movie.voteAverage),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.star,
                                  color: Colors.white, size: 12),
                              const SizedBox(width: 2),
                              Text(
                                movie.ratingText,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
            // Title & Year
            if (showTitle) ...[
              const SizedBox(height: 8),
              Text(
                movie.title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
              if (movie.year.isNotEmpty)
                Text(
                  movie.year,
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.grey[500],
                  ),
                ),
            ],
          ],
        ),
      ),
    );
  }

  Color _ratingColor(double rating) {
    if (rating >= 7.5) return const Color(0xFF21D07A);
    if (rating >= 5.0) return const Color(0xFFD2D531);
    return const Color(0xFFDB2360);
  }
}
