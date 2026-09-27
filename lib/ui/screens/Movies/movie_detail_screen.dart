import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:zuno/models/movie.dart';
import 'package:zuno/services/tmdb_service.dart';
import 'package:zuno/ui/screens/Movies/video_player_screen.dart';
import 'package:zuno/ui/widgets/movie_card.dart';
import 'package:zuno/ui/widgets/tv_focus_wrapper.dart';

class MovieDetailScreen extends StatefulWidget {
  final int movieId;
  const MovieDetailScreen({super.key, required this.movieId});

  @override
  State<MovieDetailScreen> createState() => _MovieDetailScreenState();
}

class _MovieDetailScreenState extends State<MovieDetailScreen> {
  final TmdbService _tmdbService = Get.find<TmdbService>();
  MovieDetail? _detail;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadDetails();
  }

  Future<void> _loadDetails() async {
    try {
      final detail = await _tmdbService.getMovieDetails(widget.movieId);
      setState(() {
        _detail = detail;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: Color(0xFFE50914)),
            )
          : _detail == null
              ? const Center(
                  child: Text('Failed to load movie',
                      style: TextStyle(color: Colors.white)),
                )
              : _buildContent(context),
    );
  }

  Widget _buildContent(BuildContext context) {
    final detail = _detail!;
    final movie = detail.movie;

    return CustomScrollView(
      slivers: [
        // Backdrop with back button
        SliverAppBar(
          expandedHeight: 300,
          pinned: true,
          backgroundColor: Colors.black,
          leading: TVFocusWrapper(
            onTap: () => Navigator.pop(context),
            borderRadius: BorderRadius.circular(20),
            child: Container(
              margin: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.black54,
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Icon(Icons.arrow_back, color: Colors.white),
            ),
          ),
          flexibleSpace: FlexibleSpaceBar(
            background: Stack(
              fit: StackFit.expand,
              children: [
                if (movie.backdropUrl.isNotEmpty)
                  CachedNetworkImage(
                    imageUrl: movie.backdropUrl,
                    fit: BoxFit.cover,
                  ),
                // Bottom gradient
                DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.transparent,
                        Colors.black.withValues(alpha: 0.8),
                        Colors.black,
                      ],
                      stops: const [0.3, 0.8, 1.0],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),

        // Content
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Title
                Text(
                  movie.title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    height: 1.2,
                  ),
                ),
                const SizedBox(height: 8),

                // Tagline
                if (detail.tagline != null && detail.tagline!.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Text(
                      detail.tagline!,
                      style: TextStyle(
                        color: Colors.grey[400],
                        fontSize: 15,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ),

                // Meta row
                Wrap(
                  spacing: 12,
                  runSpacing: 8,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    if (movie.voteAverage > 0)
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
                            Text(movie.ratingText,
                                style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13)),
                          ],
                        ),
                      ),
                    if (movie.year.isNotEmpty)
                      Text(movie.year,
                          style:
                              TextStyle(color: Colors.grey[400], fontSize: 14)),
                    if (detail.runtimeText.isNotEmpty)
                      Text(detail.runtimeText,
                          style:
                              TextStyle(color: Colors.grey[400], fontSize: 14)),
                  ],
                ),
                const SizedBox(height: 12),

                // Genres
                if (detail.genres.isNotEmpty)
                  Wrap(
                    spacing: 8,
                    runSpacing: 6,
                    children: detail.genres.map((g) {
                      return Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey[700]!),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(g.name,
                            style: const TextStyle(
                                color: Colors.white, fontSize: 12)),
                      );
                    }).toList(),
                  ),
                const SizedBox(height: 20),

                // Play Movie button
                TVFocusWrapper(
                  onTap: () => _playMovie(movie.title, widget.movieId),
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE50914),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.play_arrow, color: Colors.white, size: 24),
                        SizedBox(width: 8),
                        Text('Play',
                            style: TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 10),

                // Watch Trailer button
                if (detail.mainTrailer != null)
                  TVFocusWrapper(
                    onTap: () => _launchTrailer(detail.mainTrailer!),
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        color: Colors.transparent,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.grey[600]!),
                      ),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.play_circle_outline,
                              color: Colors.white, size: 22),
                          SizedBox(width: 8),
                          Text('Watch Trailer',
                              style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500)),
                        ],
                      ),
                    ),
                  ),
                const SizedBox(height: 20),

                // Overview
                if (movie.overview != null && movie.overview!.isNotEmpty) ...[
                  const Text('Overview',
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Text(
                    movie.overview!,
                    style: TextStyle(
                      color: Colors.grey[300],
                      fontSize: 14,
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 24),
                ],

                // Cast
                if (detail.cast.isNotEmpty) ...[
                  const Text('Cast',
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),
                  SizedBox(
                    height: 140,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: detail.cast.length,
                      itemBuilder: (context, index) {
                        final actor = detail.cast[index];
                        return Padding(
                          padding: const EdgeInsets.only(right: 12),
                          child: SizedBox(
                            width: 80,
                            child: Column(
                              children: [
                                CircleAvatar(
                                  radius: 35,
                                  backgroundColor: Colors.grey[800],
                                  backgroundImage: actor.profileUrl.isNotEmpty
                                      ? CachedNetworkImageProvider(
                                          actor.profileUrl)
                                      : null,
                                  child: actor.profileUrl.isEmpty
                                      ? const Icon(Icons.person,
                                          color: Colors.white54, size: 30)
                                      : null,
                                ),
                                const SizedBox(height: 6),
                                Text(actor.name,
                                    textAlign: TextAlign.center,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                        color: Colors.white, fontSize: 11)),
                                if (actor.character != null)
                                  Text(actor.character!,
                                      textAlign: TextAlign.center,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                          color: Colors.grey[500],
                                          fontSize: 10)),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 16),
                ],

                // Similar Movies
                if (detail.similar.isNotEmpty) ...[
                  const Text('Similar Movies',
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),
                  SizedBox(
                    height: 260,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: detail.similar.length,
                      itemBuilder: (context, index) {
                        return Padding(
                          padding: const EdgeInsets.only(right: 10),
                          child: MovieCard(
                            movie: detail.similar[index],
                            onTap: () {
                              Navigator.pushReplacement(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => MovieDetailScreen(
                                      movieId: detail.similar[index].id),
                                ),
                              );
                            },
                          ),
                        );
                      },
                    ),
                  ),
                ],

                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ],
    );
  }

  void _playMovie(String title, int tmdbId) {
    Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => VideoPlayerScreen.movie(
        title: title,
        tmdbId: tmdbId,
      ),
    ));
  }

  Future<void> _launchTrailer(MovieTrailer trailer) async {
    final uri = Uri.parse(trailer.youtubeUrl);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }
}
