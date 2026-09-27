import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:zuno/models/movie.dart';
import 'package:zuno/ui/screens/Movies/movie_home_controller.dart';
import 'package:zuno/ui/screens/Movies/movie_detail_screen.dart';
import 'package:zuno/ui/widgets/movie_banner.dart';
import 'package:zuno/ui/widgets/movie_card.dart';

class MovieDiscoverScreen extends StatelessWidget {
  const MovieDiscoverScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<MovieHomeController>();

    return Obx(() {
      if (controller.isLoading.isTrue) {
        return const Center(
          child: CircularProgressIndicator(color: Color(0xFFE50914)),
        );
      }

      return RefreshIndicator(
        color: const Color(0xFFE50914),
        onRefresh: controller.refresh,
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            // Hero Banner
            if (controller.bannerMovie != null)
              MovieBanner(
                movie: controller.bannerMovie!,
                onTap: () => _openDetail(context, controller.bannerMovie!),
                onPlayTap: () => _openDetail(context, controller.bannerMovie!),
              ),

            const SizedBox(height: 20),

            // Trending Now
            _buildMovieRow(
              context,
              title: '🔥 Trending Now',
              movies: controller.trendingMovies,
            ),

            // Popular
            _buildMovieRow(
              context,
              title: '⭐ Popular',
              movies: controller.popularMovies,
            ),

            // Now Playing
            _buildMovieRow(
              context,
              title: '🎬 Now Playing',
              movies: controller.nowPlayingMovies,
            ),

            // Top Rated
            _buildMovieRow(
              context,
              title: '🏆 Top Rated',
              movies: controller.topRatedMovies,
            ),

            // Upcoming
            _buildMovieRow(
              context,
              title: '📅 Coming Soon',
              movies: controller.upcomingMovies,
            ),

            const SizedBox(height: 40),
          ],
        ),
      );
    });
  }

  Widget _buildMovieRow(BuildContext context,
      {required String title, required List<Movie> movies}) {
    if (movies.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Text(
            title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              letterSpacing: -0.3,
            ),
          ),
        ),
        SizedBox(
          height: 260,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            itemCount: movies.length,
            itemBuilder: (context, index) {
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 6),
                child: MovieCard(
                  movie: movies[index],
                  onTap: () => _openDetail(context, movies[index]),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 8),
      ],
    );
  }

  void _openDetail(BuildContext context, Movie movie) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => MovieDetailScreen(movieId: movie.id),
      ),
    );
  }
}
