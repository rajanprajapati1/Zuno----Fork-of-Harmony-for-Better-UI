class TvShow {
  final int id;
  final String name;
  final String? overview;
  final String? posterPath;
  final String? backdropPath;
  final String? firstAirDate;
  final double voteAverage;
  final int voteCount;
  final List<int> genreIds;
  final String originalLanguage;

  TvShow({
    required this.id,
    required this.name,
    this.overview,
    this.posterPath,
    this.backdropPath,
    this.firstAirDate,
    this.voteAverage = 0.0,
    this.voteCount = 0,
    this.genreIds = const [],
    this.originalLanguage = '',
  });

  factory TvShow.fromJson(Map<String, dynamic> json) {
    return TvShow(
      id: json['id'] ?? 0,
      name: json['name'] ?? json['original_name'] ?? '',
      overview: json['overview'],
      posterPath: json['poster_path'],
      backdropPath: json['backdrop_path'],
      firstAirDate: json['first_air_date'],
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

  String get year => (firstAirDate != null && firstAirDate!.length >= 4)
      ? firstAirDate!.substring(0, 4)
      : '';

  String get ratingText =>
      voteAverage > 0 ? voteAverage.toStringAsFixed(1) : 'N/A';
}

class TvShowDetail {
  final TvShow show;
  final int? numberOfSeasons;
  final int? numberOfEpisodes;
  final List<Season> seasons;
  final List<dynamic> genres;
  final List<dynamic> cast;
  final List<dynamic> trailers;
  final List<TvShow> similar;
  final String? tagline;
  final String? imdbId;

  TvShowDetail({
    required this.show,
    this.numberOfSeasons,
    this.numberOfEpisodes,
    this.seasons = const [],
    this.genres = const [],
    this.cast = const [],
    this.trailers = const [],
    this.similar = const [],
    this.tagline,
    this.imdbId,
  });
}

class Season {
  final int id;
  final int seasonNumber;
  final String? name;
  final String? overview;
  final String? posterPath;
  final int episodeCount;
  final String? airDate;

  Season({
    required this.id,
    required this.seasonNumber,
    this.name,
    this.overview,
    this.posterPath,
    this.episodeCount = 0,
    this.airDate,
  });

  factory Season.fromJson(Map<String, dynamic> json) {
    return Season(
      id: json['id'] ?? 0,
      seasonNumber: json['season_number'] ?? 0,
      name: json['name'],
      overview: json['overview'],
      posterPath: json['poster_path'],
      episodeCount: json['episode_count'] ?? 0,
      airDate: json['air_date'],
    );
  }

  String get posterUrl =>
      posterPath != null ? 'https://image.tmdb.org/t/p/w342$posterPath' : '';
}

class Episode {
  final int id;
  final int episodeNumber;
  final int seasonNumber;
  final String? name;
  final String? overview;
  final String? stillPath;
  final double voteAverage;
  final int? runtime;
  final String? airDate;

  Episode({
    required this.id,
    required this.episodeNumber,
    required this.seasonNumber,
    this.name,
    this.overview,
    this.stillPath,
    this.voteAverage = 0.0,
    this.runtime,
    this.airDate,
  });

  factory Episode.fromJson(Map<String, dynamic> json) {
    return Episode(
      id: json['id'] ?? 0,
      episodeNumber: json['episode_number'] ?? 0,
      seasonNumber: json['season_number'] ?? 0,
      name: json['name'],
      overview: json['overview'],
      stillPath: json['still_path'],
      voteAverage: (json['vote_average'] ?? 0).toDouble(),
      runtime: json['runtime'],
      airDate: json['air_date'],
    );
  }

  String get stillUrl =>
      stillPath != null ? 'https://image.tmdb.org/t/p/w500$stillPath' : '';

  String get runtimeText {
    if (runtime == null || runtime == 0) return '';
    return '${runtime}m';
  }
}

/// IPTV Channel from iptv-org API
class TvChannel {
  final String id;
  final String name;
  final String? logo;
  final String country;
  final List<String> categories;

  TvChannel({
    required this.id,
    required this.name,
    this.logo,
    required this.country,
    this.categories = const [],
  });

  factory TvChannel.fromJson(Map<String, dynamic> json) {
    return TvChannel(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      logo: json['logo'],
      country: json['country'] ?? '',
      categories: (json['categories'] as List?)?.cast<String>() ?? [],
    );
  }
}

/// IPTV Stream
class TvStream {
  final String channel;
  final String url;

  TvStream({required this.channel, required this.url});

  factory TvStream.fromJson(Map<String, dynamic> json) {
    return TvStream(
      channel: json['channel'] ?? '',
      url: json['url'] ?? '',
    );
  }
}
