import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:zuno/models/movie.dart';
import 'package:zuno/ui/widgets/tv_focus_wrapper.dart';

class MovieBanner extends StatelessWidget {
  final Movie movie;
  final VoidCallback? onTap;
  final VoidCallback? onPlayTap;

  const MovieBanner({
    super.key,
    required this.movie,
    this.onTap,
    this.onPlayTap,
  });

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final bannerHeight = screenWidth > 800 ? 450.0 : 300.0;

    return TVFocusWrapper(
      onTap: onTap,
      borderRadius: BorderRadius.circular(0),
      scaleFactor: 1.0,
      child: SizedBox(
        height: bannerHeight,
        width: double.infinity,
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Backdrop image
            if (movie.backdropUrl.isNotEmpty)
              CachedNetworkImage(
                imageUrl: movie.backdropUrl,
                fit: BoxFit.cover,
                placeholder: (_, __) => Container(color: Colors.black),
                errorWidget: (_, __, ___) => Container(
                  color: Colors.grey[900],
                  child: const Center(
                    child: Icon(Icons.movie, color: Colors.white24, size: 80),
                  ),
                ),
              )
            else
              Container(color: Colors.grey[900]),

            // Gradient overlays
            // Bottom gradient
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.transparent,
                      Colors.transparent,
                      Colors.black.withValues(alpha: 0.7),
                      Colors.black.withValues(alpha: 0.95),
                    ],
                    stops: const [0.0, 0.3, 0.7, 1.0],
                  ),
                ),
              ),
            ),
            // Left gradient for text readability
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                    colors: [
                      Colors.black.withValues(alpha: 0.6),
                      Colors.transparent,
                    ],
                    stops: const [0.0, 0.6],
                  ),
                ),
              ),
            ),

            // Content
            Positioned(
              bottom: 24,
              left: 24,
              right: 24,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Title
                  Text(
                    movie.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      letterSpacing: -0.5,
                      height: 1.2,
                      shadows: [
                        Shadow(
                          blurRadius: 10,
                          color: Colors.black,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),

                  // Meta row
                  Row(
                    children: [
                      if (movie.voteAverage > 0) ...[
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: const Color(0xFF21D07A),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.star,
                                  color: Colors.white, size: 14),
                              const SizedBox(width: 3),
                              Text(
                                movie.ratingText,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                      ],
                      if (movie.year.isNotEmpty)
                        Text(
                          movie.year,
                          style: TextStyle(
                            color: Colors.grey[300],
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 10),

                  // Overview
                  if (movie.overview != null && movie.overview!.isNotEmpty)
                    Text(
                      movie.overview!,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: Colors.grey[300],
                        fontSize: 13,
                        height: 1.4,
                      ),
                    ),
                  const SizedBox(height: 16),

                  // Action buttons
                  Row(
                    children: [
                      TVFocusWrapper(
                        onTap: onPlayTap ?? onTap,
                        borderRadius: BorderRadius.circular(8),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 20, vertical: 10),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.play_arrow,
                                  color: Colors.black, size: 22),
                              SizedBox(width: 6),
                              Text(
                                'Watch Now',
                                style: TextStyle(
                                  color: Colors.black,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      TVFocusWrapper(
                        onTap: onTap,
                        borderRadius: BorderRadius.circular(8),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 20, vertical: 10),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.white30),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.info_outline,
                                  color: Colors.white, size: 20),
                              SizedBox(width: 6),
                              Text(
                                'More Info',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
