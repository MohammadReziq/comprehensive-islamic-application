import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/services/auth_video_manager.dart';

/// طبقة الخلفية المشتركة لشاشات المصادقة: تدرج + فيديو ping-pong + overlay.
/// لا يملك حالة الفيديو؛ الشاشة الأب تمرّر [videoReady] و [videoOpacity].
class AuthVideoBackground extends StatelessWidget {
  const AuthVideoBackground({
    super.key,
    required this.manager,
    required this.videoReady,
    this.videoOpacity = 1.0,
    required this.child,
  });

  final AuthVideoManager manager;
  final bool videoReady;
  final double videoOpacity;
  final Widget child;

  static Widget buildVideoLayer(VideoPlayerController ctrl) {
    return SizedBox.expand(
      child: FittedBox(
        fit: BoxFit.cover,
        child: SizedBox(
          width: ctrl.value.size.width,
          height: ctrl.value.size.height,
          child: VideoPlayer(ctrl),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // ─── Layer 1: Gradient fallback ───
        Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [AppColors.primaryDark, AppColors.primary],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
        ),

        // ─── Layer 2: Video ping-pong ───
        if (videoReady)
          AnimatedOpacity(
            opacity: videoOpacity,
            duration: const Duration(milliseconds: 300),
            child: Stack(
              children: [
                if (manager.forwardController != null)
                  Opacity(
                    opacity: manager.isForward ? 1.0 : 0.001,
                    child: buildVideoLayer(manager.forwardController!),
                  ),
                if (manager.reverseController != null)
                  Opacity(
                    opacity: manager.isForward ? 0.001 : 1.0,
                    child: buildVideoLayer(manager.reverseController!),
                  ),
              ],
            ),
          ),

        // ─── Layer 3: Gradient overlay ───
        Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Colors.black.withValues(alpha: 0.1),
                Colors.black.withValues(alpha: 0.5),
                Colors.black.withValues(alpha: 0.72),
              ],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              stops: const [0.0, 0.45, 1.0],
            ),
          ),
        ),

        // ─── Layer 4: Content ───
        child,
      ],
    );
  }
}
