class Movie {
  final int id;
  final String title;
  final String? overview;
  final String? posterPath;
  final String? backdropPath;
  final String? releaseDate;
  final double voteAverage;
  final int voteCount;
  final List<int> genreIds;
  final String originalLanguage;

  Movie({
    required this.id,
    required this.title,
    this.overview,
    this.posterPath,
    this.backdropPath,
    this.releaseDate,
    this.voteAverage = 0.0,
    this.voteCount = 0,
    this.genreIds = const [],
    this.originalLanguage = '',
  });

  factory Movie.fromJson(Map<String, dynamic> json) {
    return Movie(
      id: json['id'] ?? 0,
      title: json['title'] ?? json['original_title'] ?? '',
      overview: json['overview'],
      posterPath: json['poster_path'],
      backdropPath: json['backdrop_path'],
      releaseDate: json['release_date'],
      voteAverage: (json['vote_average'] ?? 0).toDouble(),
      voteCount: json['vote_count'] ?? 0,
      genreIds: (json['genre_ids'] as List?)?.cast<int>() ?? [],
      originalLanguage: json['original_language'] ?? '',
    );
  }

  String get posterUrl =>
      posterPath != null ? 'https://image.tmdb.org/t/p/w500$posterPath' : '';

  String get backdropUrl => backdropPath != null
      ? 'https://image.tmdb.org/t/p/w1280$backdropPath'
      : '';

  String get posterUrlSmall =>
      posterPath != null ? 'https://image.tmdb.org/t/p/w342$posterPath' : '';

  String get year => (releaseDate != null && releaseDate!.length >= 4)
      ? releaseDate!.substring(0, 4)
      : '';

  String get ratingText =>
      voteAverage > 0 ? voteAverage.toStringAsFixed(1) : 'N/A';
}

class MovieDetail {
  final Movie movie;
  final int? runtime;
  final List<Genre> genres;
  final List<CastMember> cast;
  final List<MovieTrailer> trailers;
  final List<Movie> similar;
  final String? tagline;
  final String? imdbId;

  MovieDetail({
    required this.movie,
    this.runtime,
    this.genres = const [],
    this.cast = const [],
    this.trailers = const [],
    this.similar = const [],
    this.tagline,
    this.imdbId,
  });

  String get runtimeText {
    if (runtime == null || runtime == 0) return '';
    final hours = runtime! ~/ 60;
    final mins = runtime! % 60;
    if (hours > 0) return '${hours}h ${mins}m';
    return '${mins}m';
  }

  MovieTrailer? get mainTrailer {
    // Prefer official YouTube trailers
    try {
      return trailers.firstWhere(
        (t) => t.site == 'YouTube' && t.type == 'Trailer',
      );
    } catch (_) {
      return trailers.isNotEmpty ? trailers.first : null;
    }
  }
}

class Genre {
  final int id;
  final String name;

  Genre({required this.id, required this.name});

  factory Genre.fromJson(Map<String, dynamic> json) {
    return Genre(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
    );
  }
}

class CastMember {
  final int id;
  final String name;
  final String? character;
  final String? profilePath;

  CastMember({
    required this.id,
    required this.name,
    this.character,
    this.profilePath,
  });

  factory CastMember.fromJson(Map<String, dynamic> json) {
    return CastMember(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      character: json['character'],
      profilePath: json['profile_path'],
    );
  }

  String get profileUrl =>
      profilePath != null ? 'https://image.tmdb.org/t/p/w185$profilePath' : '';
}

class MovieTrailer {
  final String key;
  final String name;
  final String site;
  final String type;

  MovieTrailer({
    required this.key,
    required this.name,
    required this.site,
    required this.type,
  });

  factory MovieTrailer.fromJson(Map<String, dynamic> json) {
    return MovieTrailer(
      key: json['key'] ?? '',
      name: json['name'] ?? '',
      site: json['site'] ?? '',
      type: json['type'] ?? '',
    );
  }

  String get youtubeUrl => 'https://www.youtube.com/watch?v=$key';
}
