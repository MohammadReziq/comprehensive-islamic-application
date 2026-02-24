import 'package:video_player/video_player.dart';

/// Singleton that holds ONE VideoPlayerController shared between
/// LoginScreen and RegisterScreen — eliminates the blue-flash on navigation.
class AuthVideoManager {
  static final AuthVideoManager _instance = AuthVideoManager._();
  factory AuthVideoManager() => _instance;
  AuthVideoManager._();

  static const _videoAsset = 'assets/videos/mosque.mp4';

  VideoPlayerController? _controller;
  bool _ready = false;
  bool _initializing = false;

  bool get isReady =>
      _ready && _controller != null && _controller!.value.isInitialized;

  VideoPlayerController? get controller => _controller;

  /// Call from both screens. Safe to call concurrently — only initialises once.
  Future<bool> ensureReady() async {
    if (isReady) return true;
    if (_initializing) {
      // Wait until the other caller finishes
      while (_initializing) {
        await Future<void>.delayed(const Duration(milliseconds: 50));
      }
      return isReady;
    }
    _initializing = true;
    try {
      final ctrl = VideoPlayerController.asset(_videoAsset);
      await ctrl.initialize();
      ctrl.setLooping(true);
      await ctrl.setVolume(0);
      await ctrl.play();
      _controller = ctrl;
      _ready = true;
      return true;
    } catch (_) {
      return false;
    } finally {
      _initializing = false;
    }
  }

  /// Call when leaving the auth flow entirely (e.g. navigating to home/admin).
  void release() {
    _controller?.dispose();
    _controller = null;
    _ready = false;
    _initializing = false;
  }
}
