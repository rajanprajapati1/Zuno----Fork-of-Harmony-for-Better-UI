import 'package:dio/dio.dart';
import 'package:zuno/models/movie.dart';
import 'package:zuno/models/tv_show.dart';

class TmdbService {
  static const String _baseUrl = 'https://api.themoviedb.org/3';
  static const String _bearerToken =
      'eyJhbGciOiJIUzI1NiJ9.eyJhdWQiOiIwMTFmMGY4MjYxMTAzMDk1MTRiM2U5MjMxODY3NjE0ZSIsInN1YiI6IjY0ZDM1ZDZhMDM3MjY0MDBmZmZjN2M3ZCIsInNjb3BlcyI6WyJhcGlfcmVhZCJdLCJ2ZXJzaW9uIjoxfQ.TpzrrzlL_IEwa7uovSoSWI_8fwByw8FbP0aCbMk_2Y0';

  late final Dio _dio;

  TmdbService() {
    _dio = Dio(BaseOptions(
      baseUrl: _baseUrl,
      headers: {
        'Authorization': 'Bearer $_bearerToken',
        'Content-Type': 'application/json',
      },
    ));
  }

  // ==================== MOVIES ====================

  Future<List<Movie>> discoverMovies({int page = 1}) async {
    final response = await _dio.get('/discover/movie', queryParameters: {
      'language': 'en-US',
      'region': 'IN',
      'with_original_language': 'hi',
      'sort_by': 'popularity.desc',
      'page': page,
    });
    return _parseMovieList(response.data);
  }

  Future<List<Movie>> getTrending({String timeWindow = 'week'}) async {
    final response =
        await _dio.get('/trending/movie/$timeWindow', queryParameters: {
      'language': 'en-US',
    });
    return _parseMovieList(response.data);
  }

  Future<List<Movie>> getTopRated({int page = 1}) async {
    final response = await _dio.get('/movie/top_rated', queryParameters: {
      'language': 'en-US',
      'region': 'IN',
      'page': page,
    });
    return _parseMovieList(response.data);
  }

  Future<List<Movie>> getNowPlaying({int page = 1}) async {
    final response = await _dio.get('/movie/now_playing', queryParameters: {
      'language': 'en-US',
      'region': 'IN',
      'page': page,
    });
    return _parseMovieList(response.data);
  }

  Future<List<Movie>> getUpcoming({int page = 1}) async {
    final response = await _dio.get('/movie/upcoming', queryParameters: {
      'language': 'en-US',
      'region': 'IN',
      'page': page,
    });
    return _parseMovieList(response.data);
  }

  Future<List<Movie>> getPopular({int page = 1}) async {
    final response = await _dio.get('/movie/popular', queryParameters: {
      'language': 'en-US',
      'region': 'IN',
      'page': page,
    });
    return _parseMovieList(response.data);
  }

  Future<List<Movie>> searchMovies(String query, {int page = 1}) async {
    final response = await _dio.get('/search/movie', queryParameters: {
      'query': query,
      'language': 'en-US',
      'page': page,
      'include_adult': false,
    });
    return _parseMovieList(response.data);
  }

  Future<MovieDetail> getMovieDetails(int movieId) async {
    final response = await _dio.get('/movie/$movieId', queryParameters: {
      'language': 'en-US',
      'append_to_response': 'credits,videos,similar,external_ids',
    });

    final data = response.data;
    final movie = Movie.fromJson(data);

    final genres =
        (data['genres'] as List?)?.map((g) => Genre.fromJson(g)).toList() ?? [];

    final cast = (data['credits']?['cast'] as List?)
            ?.take(20)
            .map((c) => CastMember.fromJson(c))
            .toList() ??
        [];

    final trailers = (data['videos']?['results'] as List?)
            ?.map((v) => MovieTrailer.fromJson(v))
            .toList() ??
        [];

    final similar = (data['similar']?['results'] as List?)
            ?.map((m) => Movie.fromJson(m))
            .toList() ??
        [];

    return MovieDetail(
      movie: movie,
      runtime: data['runtime'],
      genres: genres,
      cast: cast,
      trailers: trailers,
      similar: similar,
      tagline: data['tagline'],
      imdbId: data['imdb_id'] ?? data['external_ids']?['imdb_id'],
    );
  }

  Future<List<Genre>> getGenres() async {
    final response = await _dio.get('/genre/movie/list', queryParameters: {
      'language': 'en',
    });
    return (response.data['genres'] as List)
        .map((g) => Genre.fromJson(g))
        .toList();
  }

  Future<List<Movie>> getMoviesByGenre(int genreId, {int page = 1}) async {
    final response = await _dio.get('/discover/movie', queryParameters: {
      'language': 'en-US',
      'with_genres': genreId,
      'sort_by': 'popularity.desc',
      'page': page,
    });
    return _parseMovieList(response.data);
  }

  // ==================== TV SHOWS ====================

  Future<List<TvShow>> discoverTvShows({int page = 1}) async {
    final response = await _dio.get('/discover/tv', queryParameters: {
      'language': 'en-US',
      'region': 'IN',
      'with_original_language': 'hi',
      'sort_by': 'popularity.desc',
      'page': page,
    });
    return _parseTvList(response.data);
  }

  Future<List<TvShow>> getTrendingTv({String timeWindow = 'week'}) async {
    final response =
        await _dio.get('/trending/tv/$timeWindow', queryParameters: {
      'language': 'en-US',
    });
    return _parseTvList(response.data);
  }

  Future<List<TvShow>> getPopularTv({int page = 1}) async {
    final response = await _dio.get('/tv/popular', queryParameters: {
      'language': 'en-US',
      'page': page,
    });
    return _parseTvList(response.data);
  }

  Future<List<TvShow>> getTopRatedTv({int page = 1}) async {
    final response = await _dio.get('/tv/top_rated', queryParameters: {
      'language': 'en-US',
      'page': page,
    });
    return _parseTvList(response.data);
  }

  Future<List<TvShow>> searchTvShows(String query, {int page = 1}) async {
    final response = await _dio.get('/search/tv', queryParameters: {
      'query': query,
      'language': 'en-US',
      'page': page,
    });
    return _parseTvList(response.data);
  }

  Future<TvShowDetail> getTvShowDetails(int tvId) async {
    final response = await _dio.get('/tv/$tvId', queryParameters: {
      'language': 'en-US',
      'append_to_response': 'credits,videos,similar,external_ids',
    });

    final data = response.data;
    final show = TvShow.fromJson(data);

    final seasons = (data['seasons'] as List?)
            ?.map((s) => Season.fromJson(s))
            .where((s) => s.seasonNumber > 0)
            .toList() ??
        [];

    final genres =
        (data['genres'] as List?)?.map((g) => Genre.fromJson(g)).toList() ?? [];

    final cast = (data['credits']?['cast'] as List?)
            ?.take(20)
            .map((c) => CastMember.fromJson(c))
            .toList() ??
        [];

    final trailers = (data['videos']?['results'] as List?)
            ?.map((v) => MovieTrailer.fromJson(v))
            .toList() ??
        [];

    final similar = (data['similar']?['results'] as List?)
            ?.map((m) => TvShow.fromJson(m))
            .toList() ??
        [];

    return TvShowDetail(
      show: show,
      numberOfSeasons: data['number_of_seasons'],
      numberOfEpisodes: data['number_of_episodes'],
      seasons: seasons,
      genres: genres,
      cast: cast,
      trailers: trailers,
      similar: similar,
      tagline: data['tagline'],
      imdbId: data['external_ids']?['imdb_id'],
    );
  }

  Future<List<Episode>> getSeasonEpisodes(int tvId, int seasonNumber) async {
    final response =
        await _dio.get('/tv/$tvId/season/$seasonNumber', queryParameters: {
      'language': 'en-US',
    });
    return (response.data['episodes'] as List?)
            ?.map((e) => Episode.fromJson(e))
            .toList() ??
        [];
  }

  // ==================== HELPERS ====================

  List<Movie> _parseMovieList(Map<String, dynamic> data) {
    return (data['results'] as List?)?.map((m) => Movie.fromJson(m)).toList() ??
        [];
  }

  List<TvShow> _parseTvList(Map<String, dynamic> data) {
    return (data['results'] as List?)
            ?.map((m) => TvShow.fromJson(m))
            .toList() ??
        [];
  }
}
