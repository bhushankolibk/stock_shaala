import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';

import '../../core/di/injection.dart';
import '../../core/services/youtube_service.dart';
import '../../core/theme/app_colors.dart';
import '../../data/models/youtube_models.dart';

class WatchSection extends StatefulWidget {
  const WatchSection({super.key});

  @override
  State<WatchSection> createState() => _WatchSectionState();
}

class _WatchSectionState extends State<WatchSection>
    with AutomaticKeepAliveClientMixin {
  List<YTPlaylist> _playlists = [];
  bool _loading = true;
  String? _error;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final playlists = await sl<YouTubeService>().fetchPlaylists();
      if (mounted) setState(() { _playlists = playlists; _loading = false; });
    } catch (_) {
      if (mounted) setState(() { _error = 'Could not load playlists'; _loading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    if (_loading) {
      return const Center(
          child: CircularProgressIndicator(color: AppColors.accent, strokeWidth: 2));
    }
    if (_error != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.wifi_off, color: AppColors.muted, size: 32),
            const SizedBox(height: 10),
            Text(_error!, style: const TextStyle(color: AppColors.muted, fontSize: 13)),
            const SizedBox(height: 14),
            GestureDetector(
              onTap: () { setState(() { _loading = true; _error = null; }); _load(); },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                decoration: BoxDecoration(
                  color: AppColors.accent.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.accent.withValues(alpha: 0.3)),
                ),
                child: const Text('Retry',
                    style: TextStyle(color: AppColors.accent, fontSize: 13, fontWeight: FontWeight.w600)),
              ),
            ),
          ],
        ),
      );
    }
    if (_playlists.isEmpty) {
      return const Center(
          child: Text('No playlists found', style: TextStyle(color: AppColors.muted)));
    }
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 24),
      itemCount: _playlists.length,
      itemBuilder: (_, i) => _playlistCard(_playlists[i]),
    );
  }

  Widget _playlistCard(YTPlaylist playlist) {
    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => PlaylistVideosPage(playlist: playlist),
        ),
      ),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          children: [
            if (playlist.thumbnailUrl != null)
              ClipRRect(
                borderRadius: const BorderRadius.horizontal(left: Radius.circular(13)),
                child: Image.network(
                  playlist.thumbnailUrl!,
                  width: 110,
                  height: 80,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(
                    width: 110,
                    height: 80,
                    color: AppColors.dim,
                    child: const Icon(Icons.play_circle_outline, color: AppColors.muted, size: 28),
                  ),
                ),
              )
            else
              Container(
                width: 110,
                height: 80,
                decoration: const BoxDecoration(
                  color: AppColors.dim,
                  borderRadius: BorderRadius.horizontal(left: Radius.circular(13)),
                ),
                child: const Icon(Icons.play_circle_outline, color: AppColors.muted, size: 28),
              ),
            const SizedBox(width: 12),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFF0000).withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(color: const Color(0xFFFF0000).withValues(alpha: 0.25)),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.play_arrow, size: 10, color: Color(0xFFFF0000)),
                          SizedBox(width: 3),
                          Text('PLAYLIST', style: TextStyle(fontSize: 8, fontWeight: FontWeight.w700, color: Color(0xFFFF0000))),
                        ],
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(playlist.title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, height: 1.3)),
                    const SizedBox(height: 4),
                    Text('${playlist.videoCount} videos',
                        style: const TextStyle(fontSize: 10, color: AppColors.muted)),
                  ],
                ),
              ),
            ),
            const Padding(
              padding: EdgeInsets.only(right: 12),
              child: Icon(Icons.chevron_right, color: AppColors.muted, size: 20),
            ),
          ],
        ),
      ),
    );
  }
}

// ──────────────────────────────────────────────
// Playlist videos screen
// ──────────────────────────────────────────────

class PlaylistVideosPage extends StatefulWidget {
  final YTPlaylist playlist;
  const PlaylistVideosPage({super.key, required this.playlist});

  @override
  State<PlaylistVideosPage> createState() => _PlaylistVideosPageState();
}

class _PlaylistVideosPageState extends State<PlaylistVideosPage> {
  List<YTVideo> _videos = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final videos = await sl<YouTubeService>().fetchPlaylistVideos(widget.playlist.id);
      if (mounted) setState(() { _videos = videos; _loading = false; });
    } catch (_) {
      if (mounted) setState(() { _error = 'Could not load videos'; _loading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        title: Text(widget.playlist.title,
            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(20),
          child: Padding(
            padding: const EdgeInsets.only(left: 16, bottom: 8),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text('${widget.playlist.videoCount} videos',
                  style: const TextStyle(fontSize: 11, color: AppColors.muted)),
            ),
          ),
        ),
      ),
      body: _body(),
    );
  }

  Widget _body() {
    if (_loading) {
      return const Center(
          child: CircularProgressIndicator(color: AppColors.accent, strokeWidth: 2));
    }
    if (_error != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.wifi_off, color: AppColors.muted, size: 32),
            const SizedBox(height: 10),
            Text(_error!, style: const TextStyle(color: AppColors.muted, fontSize: 13)),
            const SizedBox(height: 14),
            GestureDetector(
              onTap: () { setState(() { _loading = true; _error = null; }); _load(); },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                decoration: BoxDecoration(
                  color: AppColors.accent.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.accent.withValues(alpha: 0.3)),
                ),
                child: const Text('Retry',
                    style: TextStyle(color: AppColors.accent, fontSize: 13, fontWeight: FontWeight.w600)),
              ),
            ),
          ],
        ),
      );
    }
    if (_videos.isEmpty) {
      return const Center(
          child: Text('No videos in this playlist',
              style: TextStyle(color: AppColors.muted)));
    }
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 24),
      itemCount: _videos.length,
      itemBuilder: (_, i) => _videoCard(_videos[i], i + 1),
    );
  }

  Widget _videoCard(YTVideo video, int index) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Thumbnail — tap to watch inline
          GestureDetector(
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => VideoPlayerPage(video: video)),
            ),
            child: Stack(
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(13)),
                  child: video.thumbnailUrl != null
                      ? Image.network(
                          video.thumbnailUrl!,
                          height: 190,
                          width: double.infinity,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => _thumbPlaceholder(),
                        )
                      : _thumbPlaceholder(),
                ),
                // Video number badge
                Positioned(
                  top: 10,
                  left: 10,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.7),
                      borderRadius: BorderRadius.circular(5),
                    ),
                    child: Text('#$index',
                        style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: Colors.white)),
                  ),
                ),
                // Play overlay
                Positioned.fill(
                  child: Center(
                    child: Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.5),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.play_arrow, color: Colors.white, size: 28),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(video.title,
                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, height: 1.4)),
                if (video.description.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Text(
                    video.description.length > 100
                        ? '${video.description.substring(0, 100)}…'
                        : video.description,
                    style: const TextStyle(fontSize: 11, height: 1.5, color: Color(0xFF8A9DC0)),
                  ),
                ],
                const SizedBox(height: 12),
                // Watch on YouTube button
                GestureDetector(
                  onTap: () => _watchOnYouTube(video.youtubeUrl),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFF0000).withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: const Color(0xFFFF0000).withValues(alpha: 0.3)),
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.smart_display_outlined, size: 16, color: Color(0xFFFF0000)),
                        SizedBox(width: 6),
                        Text('Watch on YouTube',
                            style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFFFF0000))),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _thumbPlaceholder() => Container(
        height: 190,
        width: double.infinity,
        color: AppColors.dim,
        child: const Icon(Icons.play_circle_outline, color: AppColors.muted, size: 40),
      );

  Future<void> _watchOnYouTube(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }
}

// ──────────────────────────────────────────────
// In-app video player
// ──────────────────────────────────────────────

class VideoPlayerPage extends StatefulWidget {
  final YTVideo video;
  const VideoPlayerPage({super.key, required this.video});

  @override
  State<VideoPlayerPage> createState() => _VideoPlayerPageState();
}

class _VideoPlayerPageState extends State<VideoPlayerPage> {
  late final YoutubePlayerController _controller;
  bool _hasError = false;
  int _errorCode = 0;

  @override
  void initState() {
    super.initState();
    _controller = YoutubePlayerController(
      initialVideoId: widget.video.videoId,
      flags: const YoutubePlayerFlags(autoPlay: true, mute: false),
    )..addListener(_onControllerUpdate);
  }

  void _onControllerUpdate() {
    if (_controller.value.hasError && !_hasError) {
      setState(() {
        _hasError = true;
        _errorCode = _controller.value.errorCode;
      });
    }
  }

  @override
  void dispose() {
    _controller.removeListener(_onControllerUpdate);
    // Safety net in case the page is popped while still in fullscreen
    // (e.g. swipe-back gesture) — restore normal orientation/UI.
    SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_hasError) return _errorView();
    return YoutubePlayerBuilder(
      player: YoutubePlayer(
          controller: _controller, showVideoProgressIndicator: true),
      onEnterFullScreen: () {
        SystemChrome.setPreferredOrientations([
          DeviceOrientation.landscapeLeft,
          DeviceOrientation.landscapeRight,
        ]);
        SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersive);
      },
      onExitFullScreen: () {
        SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
        SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
      },
      builder: (context, player) {
        return Scaffold(
          backgroundColor: AppColors.bg,
          appBar: AppBar(
            backgroundColor: AppColors.surface,
            title: Text(widget.video.title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style:
                    const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
            actions: [
              IconButton(
                icon: const Icon(Icons.open_in_new, size: 18),
                tooltip: 'Watch on YouTube',
                onPressed: () => _watchOnYouTube(widget.video.youtubeUrl),
              ),
            ],
          ),
          body: SafeArea(
            child: ListView(
              children: [
                player,
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(widget.video.title,
                          style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              height: 1.4)),
                      if (widget.video.description.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Text(widget.video.description,
                            style: const TextStyle(
                                fontSize: 12,
                                height: 1.6,
                                color: Color(0xFF8A9DC0))),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _errorView() {
    final embeddingDisabled = _errorCode == 101 || _errorCode == 150;
    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        title: Text(widget.video.title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.smart_display_outlined,
                  color: AppColors.muted, size: 40),
              const SizedBox(height: 14),
              Text(
                embeddingDisabled
                    ? "This video's owner has disabled in-app playback."
                    : 'Could not play this video (error code: $_errorCode).',
                textAlign: TextAlign.center,
                style: const TextStyle(color: AppColors.muted, fontSize: 13),
              ),
              const SizedBox(height: 18),
              GestureDetector(
                onTap: () => _watchOnYouTube(widget.video.youtubeUrl),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFF0000).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                        color: const Color(0xFFFF0000).withValues(alpha: 0.3)),
                  ),
                  child: const Text('Watch on YouTube',
                      style: TextStyle(
                          color: Color(0xFFFF0000),
                          fontSize: 13,
                          fontWeight: FontWeight.w600)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _watchOnYouTube(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }
}
