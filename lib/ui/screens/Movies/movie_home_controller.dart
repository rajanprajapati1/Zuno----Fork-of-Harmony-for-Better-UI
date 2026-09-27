import 'package:get/get.dart';
import 'package:zuno/models/movie.dart';
import 'package:zuno/services/tmdb_service.dart';

class MovieHomeController extends GetxController {
  final TmdbService _tmdbService = Get.find<TmdbService>();

  final trendingMovies = <Movie>[].obs;
  final popularMovies = <Movie>[].obs;
  final topRatedMovies = <Movie>[].obs;
  final nowPlayingMovies = <Movie>[].obs;
  final upcomingMovies = <Movie>[].obs;
  final genres = <Genre>[].obs;

  final isLoading = true.obs;
  final selectedTabIndex = 0.obs;

  Movie? get bannerMovie =>
      trendingMovies.isNotEmpty ? trendingMovies.first : null;

  @override
  void onInit() {
    super.onInit();
    loadContent();
  }

  Future<void> loadContent() async {
    isLoading.value = true;
    try {
      await Future.wait([
        _loadTrending(),
        _loadPopular(),
        _loadTopRated(),
        _loadNowPlaying(),
        _loadUpcoming(),
        _loadGenres(),
      ]);
    } catch (e) {
      printError(info: 'Error loading movie content: $e');
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> _loadTrending() async {
    trendingMovies.value = await _tmdbService.getTrending();
  }

  Future<void> _loadPopular() async {
    popularMovies.value = await _tmdbService.getPopular();
  }

  Future<void> _loadTopRated() async {
    topRatedMovies.value = await _tmdbService.getTopRated();
  }

  Future<void> _loadNowPlaying() async {
    nowPlayingMovies.value = await _tmdbService.getNowPlaying();
  }

  Future<void> _loadUpcoming() async {
    upcomingMovies.value = await _tmdbService.getUpcoming();
  }

  Future<void> _loadGenres() async {
    genres.value = await _tmdbService.getGenres();
  }

  Future<void> refresh() async {
    await loadContent();
  }
}
