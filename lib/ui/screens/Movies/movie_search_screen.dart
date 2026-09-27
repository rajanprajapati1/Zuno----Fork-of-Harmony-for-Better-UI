import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:zuno/models/movie.dart';
import 'package:zuno/models/tv_show.dart';
import 'package:zuno/services/tmdb_service.dart';
import 'package:zuno/ui/screens/Movies/movie_detail_screen.dart';
import 'package:zuno/ui/screens/Movies/tv_show_detail_screen.dart';
import 'package:zuno/ui/widgets/tv_focus_wrapper.dart';

/// Combined search for Movies and TV Shows
class MovieSearchScreen extends StatefulWidget {
  const MovieSearchScreen({super.key});

  @override
  State<MovieSearchScreen> createState() => _MovieSearchScreenState();
}

class _MovieSearchScreenState extends State<MovieSearchScreen>
    with SingleTickerProviderStateMixin {
  final TmdbService _tmdbService = Get.find<TmdbService>();
  final TextEditingController _searchController = TextEditingController();
  late final TabController _tabController;

  final List<Movie> _movieResults = [];
  final List<TvShow> _tvResults = [];
  bool _isLoading = false;
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _searchController.dispose();
    _tabController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  void _onSearchChanged(String query) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () {
      if (query.trim().isNotEmpty) {
        _search(query.trim());
      } else {
        setState(() {
          _movieResults.clear();
          _tvResults.clear();
        });
      }
    });
  }

  Future<void> _search(String query) async {
    setState(() => _isLoading = true);
    try {
      final results = await Future.wait([
        _tmdbService.searchMovies(query),
        _tmdbService.searchTvShows(query),
      ]);
      setState(() {
        _movieResults
          ..clear()
          ..addAll(results[0] as List<Movie>);
        _tvResults
          ..clear()
          ..addAll(results[1] as List<TvShow>);
      });
    } catch (e) {
      // ignore
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Column(
          children: [
            // Search bar
            Padding(
              padding: const EdgeInsets.all(16),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.grey[900],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: TextField(
                  controller: _searchController,
                  onChanged: _onSearchChanged,
                  autofocus: true,
                  style: const TextStyle(color: Colors.white, fontSize: 16),
                  decoration: InputDecoration(
                    hintText: 'Search movies & TV shows...',
                    hintStyle: TextStyle(color: Colors.grey[600]),
                    prefixIcon:
                        Icon(Icons.search, color: Colors.grey[500], size: 22),
                    suffixIcon: _searchController.text.isNotEmpty
                        ? TVFocusWrapper(
                            onTap: () {
                              _searchController.clear();
                              setState(() {
                                _movieResults.clear();
                                _tvResults.clear();
                              });
                            },
                            child: Icon(Icons.clear,
                                color: Colors.grey[500], size: 20),
                          )
                        : null,
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 14),
                  ),
                ),
              ),
            ),

            // Tabs
            if (_movieResults.isNotEmpty || _tvResults.isNotEmpty)
              TabBar(
                controller: _tabController,
                indicatorColor: const Color(0xFFE50914),
                labelColor: Colors.white,
                unselectedLabelColor: Colors.grey[600],
                tabs: [
                  Tab(text: 'Movies (${_movieResults.length})'),
                  Tab(text: 'TV Shows (${_tvResults.length})'),
                ],
              ),

            // Results
            Expanded(
              child: _isLoading
                  ? const Center(
                      child:
                          CircularProgressIndicator(color: Color(0xFFE50914)))
                  : (_movieResults.isEmpty && _tvResults.isEmpty)
                      ? Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.movie_filter,
                                  color: Colors.grey[700], size: 60),
                              const SizedBox(height: 12),
                              Text(
                                _searchController.text.isEmpty
                                    ? 'Search for movies & TV shows'
                                    : 'No results found',
                                style: TextStyle(
                                    color: Colors.grey[600], fontSize: 16),
                              ),
                            ],
                          ),
                        )
                      : TabBarView(
                          controller: _tabController,
                          children: [
                            _buildMovieGrid(),
                            _buildTvGrid(),
                          ],
                        ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMovieGrid() {
    if (_movieResults.isEmpty) {
      return Center(
          child: Text('No movies found',
              style: TextStyle(color: Colors.grey[600])));
    }
    return GridView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: 160,
        childAspectRatio: 0.55,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemCount: _movieResults.length,
      itemBuilder: (context, index) {
        final movie = _movieResults[index];
        return TVFocusWrapper(
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute(
                builder: (_) => MovieDetailScreen(movieId: movie.id)),
          ),
          borderRadius: BorderRadius.circular(12),
          scaleFactor: 1.08,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: movie.posterUrl.isNotEmpty
                      ? CachedNetworkImage(
                          imageUrl: movie.posterUrlSmall,
                          fit: BoxFit.cover,
                          width: double.infinity)
                      : Container(
                          color: Colors.grey[900],
                          child: const Icon(Icons.movie,
                              color: Colors.white38, size: 40)),
                ),
              ),
              const SizedBox(height: 6),
              Text(movie.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                      fontSize: 12, fontWeight: FontWeight.w600)),
              if (movie.year.isNotEmpty)
                Text(movie.year,
                    style: TextStyle(fontSize: 10, color: Colors.grey[500])),
            ],
          ),
        );
      },
    );
  }

  Widget _buildTvGrid() {
    if (_tvResults.isEmpty) {
      return Center(
          child: Text('No TV shows found',
              style: TextStyle(color: Colors.grey[600])));
    }
    return GridView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: 160,
        childAspectRatio: 0.55,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemCount: _tvResults.length,
      itemBuilder: (context, index) {
        final show = _tvResults[index];
        return TVFocusWrapper(
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute(
                builder: (_) => TvShowDetailScreen(tvId: show.id)),
          ),
          borderRadius: BorderRadius.circular(12),
          scaleFactor: 1.08,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: show.posterUrl.isNotEmpty
                      ? CachedNetworkImage(
                          imageUrl: show.posterUrlSmall,
                          fit: BoxFit.cover,
                          width: double.infinity)
                      : Container(
                          color: Colors.grey[900],
                          child: const Icon(Icons.tv,
                              color: Colors.white38, size: 40)),
                ),
              ),
              const SizedBox(height: 6),
              Text(show.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                      fontSize: 12, fontWeight: FontWeight.w600)),
              if (show.year.isNotEmpty)
                Text(show.year,
                    style: TextStyle(fontSize: 10, color: Colors.grey[500])),
            ],
          ),
        );
      },
    );
  }
}
