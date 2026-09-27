import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:zuno/models/tv_show.dart';
import 'package:zuno/services/iptv_service.dart';
import 'package:zuno/ui/screens/Movies/video_player_screen.dart';
import 'package:zuno/ui/widgets/tv_focus_wrapper.dart';

class LiveTvScreen extends StatefulWidget {
  const LiveTvScreen({super.key});

  @override
  State<LiveTvScreen> createState() => _LiveTvScreenState();
}

class _LiveTvScreenState extends State<LiveTvScreen> {
  final IptvService _iptvService = Get.find<IptvService>();
  List<TvChannel> _channels = [];
  List<TvChannel> _filteredChannels = [];
  List<String> _categories = [];
  String? _selectedCategory;
  bool _isLoading = true;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadChannels();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadChannels() async {
    try {
      final channels = await _iptvService.getIndianChannels();
      final categories = await _iptvService.getCategories();
      setState(() {
        _channels = channels;
        _filteredChannels = channels;
        _categories = categories;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  void _filterChannels(String query) {
    setState(() {
      if (query.isEmpty && _selectedCategory == null) {
        _filteredChannels = _channels;
      } else {
        _filteredChannels = _channels.where((c) {
          final matchesSearch = query.isEmpty ||
              c.name.toLowerCase().contains(query.toLowerCase());
          final matchesCategory = _selectedCategory == null ||
              c.categories.contains(_selectedCategory);
          return matchesSearch && matchesCategory;
        }).toList();
      }
    });
  }

  void _selectCategory(String? category) {
    setState(() {
      _selectedCategory = category;
      _filterChannels(_searchController.text);
    });
  }

  Future<void> _playChannel(TvChannel channel) async {
    // Show loading dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(
          child: CircularProgressIndicator(color: Color(0xFFE50914))),
    );

    final streamUrl = await _iptvService.getStreamUrl(channel.id);
    if (!mounted) return;
    Navigator.pop(context); // dismiss loading

    if (streamUrl != null) {
      Navigator.of(context).push(MaterialPageRoute(
        builder: (_) => VideoPlayerScreen(
          title: channel.name,
          embedUrl: streamUrl,
        ),
      ));
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('No stream available for ${channel.name}'),
          backgroundColor: Colors.red[800],
        ),
      );
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
            // Title & Search
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Row(
                children: [
                  const Text('Live TV',
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.bold)),
                  const Spacer(),
                  Text('${_filteredChannels.length} channels',
                      style: TextStyle(color: Colors.grey[600], fontSize: 13)),
                ],
              ),
            ),

            // Search bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Container(
                decoration: BoxDecoration(
                    color: Colors.grey[900],
                    borderRadius: BorderRadius.circular(12)),
                child: TextField(
                  controller: _searchController,
                  onChanged: _filterChannels,
                  style: const TextStyle(color: Colors.white, fontSize: 15),
                  decoration: InputDecoration(
                    hintText: 'Search channels...',
                    hintStyle: TextStyle(color: Colors.grey[600]),
                    prefixIcon: Icon(Icons.search, color: Colors.grey[500]),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 12),
                  ),
                ),
              ),
            ),

            // Category chips
            if (_categories.isNotEmpty)
              SizedBox(
                height: 42,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: TVFocusWrapper(
                        onTap: () => _selectCategory(null),
                        borderRadius: BorderRadius.circular(20),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 8),
                          decoration: BoxDecoration(
                            color: _selectedCategory == null
                                ? const Color(0xFFE50914)
                                : Colors.grey[850],
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Center(
                              child: Text('All',
                                  style: TextStyle(
                                      color: _selectedCategory == null
                                          ? Colors.white
                                          : Colors.grey[400],
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold))),
                        ),
                      ),
                    ),
                    ..._categories.map((cat) => Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 4),
                          child: TVFocusWrapper(
                            onTap: () => _selectCategory(cat),
                            borderRadius: BorderRadius.circular(20),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 14, vertical: 8),
                              decoration: BoxDecoration(
                                color: _selectedCategory == cat
                                    ? const Color(0xFFE50914)
                                    : Colors.grey[850],
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Center(
                                  child: Text(cat,
                                      style: TextStyle(
                                          color: _selectedCategory == cat
                                              ? Colors.white
                                              : Colors.grey[400],
                                          fontSize: 12))),
                            ),
                          ),
                        )),
                  ],
                ),
              ),
            const SizedBox(height: 8),

            // Channel grid
            Expanded(
              child: _isLoading
                  ? const Center(
                      child:
                          CircularProgressIndicator(color: Color(0xFFE50914)))
                  : _filteredChannels.isEmpty
                      ? Center(
                          child: Text('No channels found',
                              style: TextStyle(color: Colors.grey[600])))
                      : GridView.builder(
                          padding: const EdgeInsets.all(12),
                          gridDelegate:
                              const SliverGridDelegateWithMaxCrossAxisExtent(
                            maxCrossAxisExtent: 160,
                            childAspectRatio: 1.0,
                            crossAxisSpacing: 10,
                            mainAxisSpacing: 10,
                          ),
                          itemCount: _filteredChannels.length,
                          itemBuilder: (context, index) =>
                              _buildChannelCard(_filteredChannels[index]),
                        ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChannelCard(TvChannel channel) {
    return TVFocusWrapper(
      onTap: () => _playChannel(channel),
      borderRadius: BorderRadius.circular(12),
      scaleFactor: 1.08,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.grey[900],
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey[800]!),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Channel logo
            if (channel.logo != null && channel.logo!.isNotEmpty)
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: CachedNetworkImage(
                  imageUrl: channel.logo!,
                  width: 60,
                  height: 60,
                  fit: BoxFit.contain,
                  errorWidget: (_, __, ___) => Container(
                    width: 60,
                    height: 60,
                    color: Colors.grey[800],
                    child:
                        const Icon(Icons.tv, color: Colors.white38, size: 30),
                  ),
                ),
              )
            else
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                    color: Colors.grey[800],
                    borderRadius: BorderRadius.circular(8)),
                child: const Icon(Icons.tv, color: Colors.white38, size: 30),
              ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 6),
              child: Text(
                channel.name,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.w500),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
