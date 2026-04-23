import 'dart:async';
import 'dart:typed_data';
import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:video_player/video_player.dart';

/// Looping, muted video preview shown in the swipe card for video assets.
///
/// Renders [thumbBytes] immediately, then fades to live video once the
/// controller is ready. Tap toggles pause / resume with a brief icon flash.
/// Disposing the widget always releases the [VideoPlayerController].
class VideoPreviewCard extends StatefulWidget {
  final AssetEntity asset;
  final Uint8List? thumbBytes;

  const VideoPreviewCard({
    super.key,
    required this.asset,
    this.thumbBytes,
  });

  @override
  State<VideoPreviewCard> createState() => _VideoPreviewCardState();
}

class _VideoPreviewCardState extends State<VideoPreviewCard> {
  VideoPlayerController? _ctrl;
  bool _initialized = false;
  bool _isPlaying = false;
  bool _showIcon = false;
  Timer? _iconTimer;

  @override
  void initState() {
    super.initState();
    _initVideo();
  }

  Future<void> _initVideo() async {
    final file = await widget.asset.file;
    if (file == null || !mounted) return;

    final ctrl = VideoPlayerController.file(file);
    try {
      await ctrl.initialize();
    } catch (_) {
      ctrl.dispose();
      return;
    }
    if (!mounted) {
      ctrl.dispose();
      return;
    }

    await ctrl.setLooping(true);
    await ctrl.setVolume(0.0);
    await ctrl.play();

    if (!mounted) {
      ctrl.dispose();
      return;
    }
    setState(() {
      _ctrl = ctrl;
      _initialized = true;
      _isPlaying = true;
    });
  }

  @override
  void dispose() {
    _iconTimer?.cancel();
    _ctrl?.dispose();
    super.dispose();
  }

  void _togglePlay() {
    final ctrl = _ctrl;
    if (ctrl == null) return;

    _iconTimer?.cancel();

    if (_isPlaying) {
      ctrl.pause();
      // Show play icon persistently while paused (no timer).
      setState(() {
        _isPlaying = false;
        _showIcon = true;
      });
    } else {
      ctrl.play();
      // Show pause icon briefly, then hide.
      setState(() {
        _isPlaying = true;
        _showIcon = true;
      });
      _iconTimer = Timer(const Duration(milliseconds: 900), () {
        if (mounted) setState(() => _showIcon = false);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final thumb = widget.thumbBytes;
    final ratio = _ctrl?.value.aspectRatio ?? 0;

    return GestureDetector(
      onTap: _togglePlay,
      child: Stack(
        fit: StackFit.expand,
        children: [
          // ── Blurred fill background (always from thumbnail) ──────────────────
          if (thumb != null)
            ImageFiltered(
              imageFilter: ImageFilter.blur(sigmaX: 26, sigmaY: 26),
              child: Image.memory(
                thumb,
                fit: BoxFit.cover,
                gaplessPlayback: true,
              ),
            )
          else
            Container(color: const Color(0xFF1C1C1E)),

          // ── Dark scrim ───────────────────────────────────────────────────────
          Container(color: Colors.black.withOpacity(0.40)),

          // ── Main content: crossfade thumbnail → live video ───────────────────
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 380),
            child: _initialized && ratio > 0
                ? Center(
                    key: const ValueKey('video'),
                    child: AspectRatio(
                      aspectRatio: ratio,
                      child: VideoPlayer(_ctrl!),
                    ),
                  )
                : (thumb != null
                    ? Image.memory(
                        key: const ValueKey('thumb'),
                        thumb,
                        fit: BoxFit.contain,
                        gaplessPlayback: true,
                      )
                    : const Center(
                        key: ValueKey('loading'),
                        child: CircularProgressIndicator(
                          color: Color(0xFF6B4EFF),
                          strokeWidth: 2,
                        ),
                      )),
          ),

          // ── Play / pause icon ────────────────────────────────────────────────
          // Visible persistently when paused, briefly after resuming.
          if (_showIcon)
            Center(
              child: AnimatedOpacity(
                opacity: _showIcon ? 1.0 : 0.0,
                duration: const Duration(milliseconds: 180),
                child: Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.55),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    _isPlaying
                        ? Icons.pause_rounded
                        : Icons.play_arrow_rounded,
                    color: Colors.white,
                    size: 34,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
