import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:zuno/models/tv_show.dart';
import 'package:zuno/services/tmdb_service.dart';
import 'package:zuno/ui/screens/Movies/tv_show_detail_screen.dart';
import 'package:zuno/ui/widgets/tv_focus_wrapper.dart';

class TvShowDiscoverScreen extends StatefulWidget {
  const TvShowDiscoverScreen({super.key});

  @override
  State<TvShowDiscoverScreen> createState() => _TvShowDiscoverScreenState();
}

class _TvShowDiscoverScreenState extends State<TvShowDiscoverScreen> {
  final TmdbService _tmdbService = Get.find<TmdbService>();
  List<TvShow> _trending = [];
  List<TvShow> _popular = [];
  List<TvShow> _topRated = [];
  List<TvShow> _indian = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadContent();
  }

  Future<void> _loadContent() async {
    try {
      final results = await Future.wait([
        _tmdbService.getTrendingTv(),
        _tmdbService.getPopularTv(),
        _tmdbService.getTopRatedTv(),
        _tmdbService.discoverTvShows(),
      ]);
      setState(() {
        _trending = results[0];
        _popular = results[1];
        _topRated = results[2];
        _indian = results[3];
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(
          child: CircularProgressIndicator(color: Color(0xFFE50914)));
    }

    return RefreshIndicator(
      color: const Color(0xFFE50914),
      onRefresh: () async {
        setState(() => _isLoading = true);
        await _loadContent();
      },
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          // Hero banner
          if (_trending.isNotEmpty) _buildHeroBanner(_trending.first),
          const SizedBox(height: 16),
          _buildShowRow('🔥 Trending Shows', _trending),
          _buildShowRow('🇮🇳 Indian Shows', _indian),
          _buildShowRow('⭐ Popular', _popular),
          _buildShowRow('🏆 Top Rated', _topRated),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildHeroBanner(TvShow show) {
    final bannerHeight =
        MediaQuery.of(context).size.width > 800 ? 400.0 : 280.0;
    return GestureDetector(
      onTap: () => _openDetail(show),
      child: SizedBox(
        height: bannerHeight,
        width: double.infinity,
        child: Stack(
          fit: StackFit.expand,
          children: [
            if (show.backdropUrl.isNotEmpty)
              CachedNetworkImage(imageUrl: show.backdropUrl, fit: BoxFit.cover),
            DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    Colors.transparent,
                    Colors.black.withValues(alpha: 0.8),
                    Colors.black
                  ],
                  stops: const [0.0, 0.3, 0.7, 1.0],
                ),
              ),
            ),
            Positioned(
              bottom: 24,
              left: 24,
              right: 24,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(show.name,
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 26,
                          fontWeight: FontWeight.bold),
                      maxLines: 2),
                  const SizedBox(height: 8),
                  if (show.overview != null)
                    Text(show.overview!,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style:
                            TextStyle(color: Colors.grey[300], fontSize: 13)),
                  const SizedBox(height: 12),
                  TVFocusWrapper(
                    onTap: () => _openDetail(show),
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 10),
                      decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(8)),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.play_arrow, color: Colors.black, size: 22),
                          SizedBox(width: 6),
                          Text('Watch Now',
                              style: TextStyle(
                                  color: Colors.black,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14)),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildShowRow(String title, List<TvShow> shows) {
    if (shows.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Text(title,
              style:
                  const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        ),
        SizedBox(
          height: 260,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            itemCount: shows.length,
            itemBuilder: (context, index) {
              final show = shows[index];
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 6),
                child: TVFocusWrapper(
                  onTap: () => _openDetail(show),
                  borderRadius: BorderRadius.circular(12),
                  scaleFactor: 1.08,
                  child: SizedBox(
                    width: 140,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: AspectRatio(
                            aspectRatio: 2 / 3,
                            child: show.posterUrl.isNotEmpty
                                ? CachedNetworkImage(
                                    imageUrl: show.posterUrlSmall,
                                    fit: BoxFit.cover)
                                : Container(
                                    color: Colors.grey[900],
                                    child: const Icon(Icons.tv,
                                        color: Colors.white38, size: 40)),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(show.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                                fontSize: 13, fontWeight: FontWeight.w600)),
                        if (show.year.isNotEmpty)
                          Text(show.year,
                              style: TextStyle(
                                  fontSize: 11, color: Colors.grey[500])),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 8),
      ],
    );
  }

  void _openDetail(TvShow show) {
    Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => TvShowDetailScreen(tvId: show.id),
    ));
  }
}
