import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:openlist_mobile/generated/l10n.dart';
import 'package:video_player/video_player.dart';

/// Native Android/iOS media playback backed by platform decoders.
class MediaPreviewView extends StatefulWidget {
  const MediaPreviewView({
    super.key,
    required this.url,
    required this.headers,
    required this.isVideo,
  });

  final String url;
  final Map<String, String> headers;
  final bool isVideo;

  @override
  State<MediaPreviewView> createState() => _MediaPreviewViewState();
}

class _MediaPreviewViewState extends State<MediaPreviewView> {
  late final VideoPlayerController _controller;
  Object? _error;

  @override
  void initState() {
    super.initState();
    _controller = VideoPlayerController.networkUrl(
      Uri.parse(widget.url),
      httpHeaders: widget.headers,
    )..addListener(_onChanged);
    _initialize();
  }

  Future<void> _initialize() async {
    try {
      await _controller.initialize();
      if (mounted) setState(() {});
    } catch (_) {
      if (mounted) {
        setState(() => _error = StateError(S.current.mediaPlaybackUnavailable));
      }
    }
  }

  void _onChanged() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _controller
      ..removeListener(_onChanged)
      ..dispose();
    super.dispose();
  }

  Future<void> _togglePlayback() async {
    if (_controller.value.isPlaying) {
      await _controller.pause();
    } else {
      await _controller.play();
    }
  }

  Future<void> _openFullscreen() async {
    await Navigator.of(context).push<void>(
      MaterialPageRoute(
        builder: (_) => _FullscreenMedia(controller: _controller),
      ),
    );
  }

  String _time(Duration value) {
    final minutes = value.inMinutes;
    final seconds = value.inSeconds % 60;
    return '$minutes:${seconds.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    if (_error != null) {
      return Center(child: Text(S.current.mediaPlaybackUnavailable));
    }
    final value = _controller.value;
    if (!value.isInitialized) {
      return const Center(child: CircularProgressIndicator());
    }
    final durationMs = value.duration.inMilliseconds;
    final positionMs = value.position.inMilliseconds.clamp(0, durationMs);

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (widget.isVideo)
          AspectRatio(
            aspectRatio: value.aspectRatio > 0 ? value.aspectRatio : 16 / 9,
            child: VideoPlayer(_controller),
          )
        else
          const Icon(Icons.audio_file_outlined, size: 88),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Row(
            children: [
              IconButton(
                tooltip: value.isPlaying ? S.current.pause : S.current.play,
                onPressed: _togglePlayback,
                icon: Icon(value.isPlaying ? Icons.pause : Icons.play_arrow),
              ),
              Text(_time(value.position)),
              Expanded(
                child: Slider(
                  min: 0,
                  max: durationMs > 0 ? durationMs.toDouble() : 1,
                  value: positionMs.toDouble().clamp(
                    0,
                    durationMs > 0 ? durationMs.toDouble() : 1,
                  ),
                  onChanged: durationMs <= 0
                      ? null
                      : (v) => _controller.seekTo(
                          Duration(milliseconds: v.round()),
                        ),
                ),
              ),
              Text(_time(value.duration)),
              if (widget.isVideo)
                IconButton(
                  tooltip: S.current.fullscreen,
                  onPressed: _openFullscreen,
                  icon: const Icon(Icons.fullscreen),
                ),
            ],
          ),
        ),
        if (value.isBuffering) const LinearProgressIndicator(),
        if (_controller.value.hasError)
          Padding(
            padding: const EdgeInsets.all(12),
            child: Text(S.current.mediaPlaybackInterrupted),
          ),
      ],
    );
  }
}

class _FullscreenMedia extends StatelessWidget {
  const _FullscreenMedia({required this.controller});

  final VideoPlayerController controller;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        systemOverlayStyle: SystemUiOverlayStyle.light,
      ),
      body: Center(
        child: AspectRatio(
          aspectRatio: controller.value.aspectRatio > 0
              ? controller.value.aspectRatio
              : 16 / 9,
          child: VideoPlayer(controller),
        ),
      ),
    );
  }
}
