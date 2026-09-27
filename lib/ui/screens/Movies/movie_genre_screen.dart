import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:zuno/models/movie.dart';
import 'package:zuno/services/tmdb_service.dart';
import 'package:zuno/ui/screens/Movies/movie_detail_screen.dart';
import 'package:zuno/ui/widgets/movie_card.dart';
import 'package:zuno/ui/widgets/tv_focus_wrapper.dart';

class MovieGenreScreen extends StatefulWidget {
  const MovieGenreScreen({super.key});

  @override
  State<MovieGenreScreen> createState() => _MovieGenreScreenState();
}

class _MovieGenreScreenState extends State<MovieGenreScreen> {
  final TmdbService _tmdbService = Get.find<TmdbService>();
  List<Genre> _genres = [];
  Genre? _selectedGenre;
  List<Movie> _movies = [];
  bool _isLoadingGenres = true;
  bool _isLoadingMovies = false;

  @override
  void initState() {
    super.initState();
    _loadGenres();
  }

  Future<void> _loadGenres() async {
    try {
      final genres = await _tmdbService.getGenres();
      setState(() {
        _genres = genres;
        _isLoadingGenres = false;
      });
    } catch (e) {
      setState(() => _isLoadingGenres = false);
    }
  }

  Future<void> _selectGenre(Genre genre) async {
    setState(() {
      _selectedGenre = genre;
      _isLoadingMovies = true;
    });
    try {
      final movies = await _tmdbService.getMoviesByGenre(genre.id);
      setState(() {
        _movies = movies;
        _isLoadingMovies = false;
      });
    } catch (e) {
      setState(() => _isLoadingMovies = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Title
            const Padding(
              padding: EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Text(
                'Browse by Genre',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),

            // Genre chips
            if (_isLoadingGenres)
              const Padding(
                padding: EdgeInsets.all(20),
                child: Center(
                  child: CircularProgressIndicator(color: Color(0xFFE50914)),
                ),
              )
            else
              SizedBox(
                height: 50,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  itemCount: _genres.length,
                  itemBuilder: (context, index) {
                    final genre = _genres[index];
                    final isSelected = _selectedGenre?.id == genre.id;
                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: TVFocusWrapper(
                        onTap: () => _selectGenre(genre),
                        borderRadius: BorderRadius.circular(20),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 10),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? const Color(0xFFE50914)
                                : Colors.grey[850],
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: isSelected
                                  ? const Color(0xFFE50914)
                                  : Colors.grey[700]!,
                            ),
                          ),
                          child: Center(
                            child: Text(
                              genre.name,
                              style: TextStyle(
                                color: isSelected
                                    ? Colors.white
                                    : Colors.grey[300],
                                fontWeight: isSelected
                                    ? FontWeight.bold
                                    : FontWeight.normal,
                                fontSize: 13,
                              ),
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            const SizedBox(height: 12),

            // Movie grid
            Expanded(
              child: _selectedGenre == null
                  ? Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.category,
                              color: Colors.grey[700], size: 60),
                          const SizedBox(height: 12),
                          Text('Select a genre to browse',
                              style: TextStyle(
                                  color: Colors.grey[600], fontSize: 16)),
                        ],
                      ),
                    )
                  : _isLoadingMovies
                      ? const Center(
                          child: CircularProgressIndicator(
                              color: Color(0xFFE50914)),
                        )
                      : _movies.isEmpty
                          ? Center(
                              child: Text('No movies found',
                                  style: TextStyle(
                                      color: Colors.grey[600], fontSize: 16)),
                            )
                          : GridView.builder(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 8),
                              gridDelegate:
                                  const SliverGridDelegateWithMaxCrossAxisExtent(
                                maxCrossAxisExtent: 160,
                                childAspectRatio: 0.55,
                                crossAxisSpacing: 12,
                                mainAxisSpacing: 12,
                              ),
                              itemCount: _movies.length,
                              itemBuilder: (context, index) {
                                return MovieCard(
                                  movie: _movies[index],
                                  width: double.infinity,
                                  onTap: () {
                                    Navigator.of(context).push(
                                      MaterialPageRoute(
                                        builder: (_) => MovieDetailScreen(
                                            movieId: _movies[index].id),
                                      ),
                                    );
                                  },
                                );
                              },
                            ),
            ),
          ],
        ),
      ),
    );
  }
}
