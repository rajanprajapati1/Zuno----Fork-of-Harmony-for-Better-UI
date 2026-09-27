import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:zuno/models/movie.dart';
import 'package:zuno/models/tv_show.dart';
import 'package:zuno/services/tmdb_service.dart';
import 'package:zuno/ui/screens/Movies/video_player_screen.dart';
import 'package:zuno/ui/widgets/tv_focus_wrapper.dart';
import 'package:url_launcher/url_launcher.dart';

class TvShowDetailScreen extends StatefulWidget {
  final int tvId;
  const TvShowDetailScreen({super.key, required this.tvId});

  @override
  State<TvShowDetailScreen> createState() => _TvShowDetailScreenState();
}

class _TvShowDetailScreenState extends State<TvShowDetailScreen> {
  final TmdbService _tmdbService = Get.find<TmdbService>();
  TvShowDetail? _detail;
  List<Episode> _episodes = [];
  int _selectedSeason = 1;
  bool _isLoading = true;
  bool _isLoadingEpisodes = false;

  @override
  void initState() {
    super.initState();
    _loadDetails();
  }

  Future<void> _loadDetails() async {
    try {
      final detail = await _tmdbService.getTvShowDetails(widget.tvId);
      setState(() {
        _detail = detail;
        _isLoading = false;
        if (detail.seasons.isNotEmpty) {
          _selectedSeason = detail.seasons.first.seasonNumber;
        }
      });
      _loadEpisodes(_selectedSeason);
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _loadEpisodes(int seasonNumber) async {
    setState(() => _isLoadingEpisodes = true);
    try {
      final episodes =
          await _tmdbService.getSeasonEpisodes(widget.tvId, seasonNumber);
      setState(() {
        _episodes = episodes;
        _isLoadingEpisodes = false;
      });
    } catch (e) {
      setState(() => _isLoadingEpisodes = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: Color(0xFFE50914)))
          : _detail == null
              ? const Center(
                  child: Text('Failed to load',
                      style: TextStyle(color: Colors.white)))
              : _buildContent(context),
    );
  }

  Widget _buildContent(BuildContext context) {
    final detail = _detail!;
    final show = detail.show;

    return CustomScrollView(
      slivers: [
        // Backdrop
        SliverAppBar(
          expandedHeight: 280,
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
                if (show.backdropUrl.isNotEmpty)
                  CachedNetworkImage(
                      imageUrl: show.backdropUrl, fit: BoxFit.cover),
                DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.transparent,
                        Colors.black.withValues(alpha: 0.8),
                        Colors.black
                      ],
                      stops: const [0.3, 0.8, 1.0],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),

        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Title
                Text(show.name,
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 26,
                        fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),

                // Tagline
                if (detail.tagline != null && detail.tagline!.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Text(detail.tagline!,
                        style: TextStyle(
                            color: Colors.grey[400],
                            fontStyle: FontStyle.italic)),
                  ),

                // Meta
                Wrap(
                  spacing: 12,
                  runSpacing: 4,
                  children: [
                    if (show.voteAverage > 0)
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                            color: const Color(0xFF21D07A),
                            borderRadius: BorderRadius.circular(4)),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.star,
                                color: Colors.white, size: 14),
                            const SizedBox(width: 3),
                            Text(show.ratingText,
                                style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13)),
                          ],
                        ),
                      ),
                    if (show.year.isNotEmpty)
                      Text(show.year,
                          style:
                              TextStyle(color: Colors.grey[400], fontSize: 14)),
                    if (detail.numberOfSeasons != null)
                      Text(
                          '${detail.numberOfSeasons} Season${detail.numberOfSeasons! > 1 ? 's' : ''}',
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
                      final genre = g as Genre;
                      return Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey[700]!),
                            borderRadius: BorderRadius.circular(20)),
                        child: Text(genre.name,
                            style: const TextStyle(
                                color: Colors.white, fontSize: 12)),
                      );
                    }).toList(),
                  ),
                const SizedBox(height: 16),

                // Play first episode
                if (_episodes.isNotEmpty)
                  TVFocusWrapper(
                    onTap: () => _playEpisode(_episodes.first),
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      decoration: BoxDecoration(
                          color: const Color(0xFFE50914),
                          borderRadius: BorderRadius.circular(8)),
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
                const SizedBox(height: 16),

                // Overview
                if (show.overview != null && show.overview!.isNotEmpty) ...[
                  Text(show.overview!,
                      style: TextStyle(
                          color: Colors.grey[300], fontSize: 14, height: 1.5)),
                  const SizedBox(height: 20),
                ],

                // Season selector
                if (detail.seasons.length > 1) ...[
                  const Text('Seasons',
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  SizedBox(
                    height: 40,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: detail.seasons.length,
                      itemBuilder: (context, index) {
                        final season = detail.seasons[index];
                        final isSelected =
                            season.seasonNumber == _selectedSeason;
                        return Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: TVFocusWrapper(
                            onTap: () {
                              setState(
                                  () => _selectedSeason = season.seasonNumber);
                              _loadEpisodes(season.seasonNumber);
                            },
                            borderRadius: BorderRadius.circular(20),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 8),
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? const Color(0xFFE50914)
                                    : Colors.grey[850],
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text('S${season.seasonNumber}',
                                  style: TextStyle(
                                      color: isSelected
                                          ? Colors.white
                                          : Colors.grey[400],
                                      fontWeight: FontWeight.bold)),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 16),
                ],

                // Episodes list
                const Text('Episodes',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                if (_isLoadingEpisodes)
                  const Center(
                      child: Padding(
                          padding: EdgeInsets.all(20),
                          child: CircularProgressIndicator(
                              color: Color(0xFFE50914))))
                else
                  ..._episodes.map((ep) => _buildEpisodeCard(ep)),

                // Cast
                if (detail.cast.isNotEmpty) ...[
                  const SizedBox(height: 20),
                  const Text('Cast',
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),
                  SizedBox(
                    height: 120,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: detail.cast.length,
                      itemBuilder: (context, index) {
                        final actor = detail.cast[index] as CastMember;
                        return Padding(
                          padding: const EdgeInsets.only(right: 12),
                          child: SizedBox(
                            width: 80,
                            child: Column(
                              children: [
                                CircleAvatar(
                                  radius: 30,
                                  backgroundColor: Colors.grey[800],
                                  backgroundImage: actor.profileUrl.isNotEmpty
                                      ? CachedNetworkImageProvider(
                                          actor.profileUrl)
                                      : null,
                                  child: actor.profileUrl.isEmpty
                                      ? const Icon(Icons.person,
                                          color: Colors.white54)
                                      : null,
                                ),
                                const SizedBox(height: 4),
                                Text(actor.name,
                                    textAlign: TextAlign.center,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                        color: Colors.white, fontSize: 10)),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],

                // Trailers
                if (detail.trailers.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  const Text('Trailers',
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  ...detail.trailers
                      .where((t) => (t as MovieTrailer).site == 'YouTube')
                      .take(3)
                      .map((t) {
                    final trailer = t as MovieTrailer;
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: TVFocusWrapper(
                        onTap: () async {
                          final uri = Uri.parse(trailer.youtubeUrl);
                          if (await canLaunchUrl(uri))
                            await launchUrl(uri,
                                mode: LaunchMode.externalApplication);
                        },
                        borderRadius: BorderRadius.circular(8),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 10),
                          decoration: BoxDecoration(
                              color: Colors.grey[900],
                              borderRadius: BorderRadius.circular(8)),
                          child: Row(
                            children: [
                              const Icon(Icons.play_circle_outline,
                                  color: Color(0xFFE50914), size: 24),
                              const SizedBox(width: 12),
                              Expanded(
                                  child: Text(trailer.name,
                                      style: const TextStyle(
                                          color: Colors.white, fontSize: 13),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis)),
                            ],
                          ),
                        ),
                      ),
                    );
                  }),
                ],

                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildEpisodeCard(Episode episode) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: TVFocusWrapper(
        onTap: () => _playEpisode(episode),
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
              color: Colors.grey[900], borderRadius: BorderRadius.circular(8)),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Episode thumbnail
              ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: SizedBox(
                  width: 130,
                  height: 75,
                  child: episode.stillUrl.isNotEmpty
                      ? CachedNetworkImage(
                          imageUrl: episode.stillUrl, fit: BoxFit.cover)
                      : Container(
                          color: Colors.grey[800],
                          child: const Icon(Icons.movie, color: Colors.white38),
                        ),
                ),
              ),
              const SizedBox(width: 12),
              // Episode info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'E${episode.episodeNumber}. ${episode.name ?? ''}',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                          fontSize: 14),
                    ),
                    if (episode.runtimeText.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 2),
                        child: Text(episode.runtimeText,
                            style: TextStyle(
                                color: Colors.grey[500], fontSize: 12)),
                      ),
                    if (episode.overview != null &&
                        episode.overview!.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text(episode.overview!,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                                color: Colors.grey[400],
                                fontSize: 12,
                                height: 1.3)),
                      ),
                  ],
                ),
              ),
              // Play icon
              const Padding(
                padding: EdgeInsets.only(left: 8, top: 20),
                child:
                    Icon(Icons.play_circle, color: Color(0xFFE50914), size: 28),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _playEpisode(Episode episode) {
    Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => VideoPlayerScreen.tvEpisode(
        title:
            '${_detail!.show.name} - S${episode.seasonNumber}E${episode.episodeNumber}',
        tmdbId: widget.tvId,
        season: episode.seasonNumber,
        episode: episode.episodeNumber,
      ),
    ));
  }
}
