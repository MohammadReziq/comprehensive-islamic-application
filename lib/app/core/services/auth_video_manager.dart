import 'package:flutter/foundation.dart';
import 'package:video_player/video_player.dart';

/// Singleton that manages TWO VideoPlayerControllers for a seamless Ping-Pong
/// background video effect on the auth screens (Login + Register).
///
/// How it works:
///   - _fwdCtrl plays  mosque.mp4         (forward)
///   - _revCtrl plays  mosque_reverse.mp4 (pre-reversed by FFmpeg)
///   - The decoder always plays FORWARD — no seekTo during playback → zero drops.
///   - On each natural end: pause outgoing, start incoming (already at frame 0),
///     then reset outgoing to frame 0 in background for the next cycle.
///
/// Extends ChangeNotifier so UI widgets can listen and rebuild on controller
/// switches without polling or callbacks.
class AuthVideoManager extends ChangeNotifier {
  static final AuthVideoManager _instance = AuthVideoManager._();
  factory AuthVideoManager() => _instance;
  AuthVideoManager._();

  static const _fwdAsset = 'assets/videos/mosque.mp4';
  static const _revAsset = 'assets/videos/mosque_reverse.mp4';

  /// Playback speed: 1.0 = normal, 0.5 = half speed (slower). Applied to both clips.
  static const double playbackSpeed = 0.5;

  VideoPlayerController? _fwdCtrl;
  VideoPlayerController? _revCtrl;

  bool _isFwd = true;
  bool _ready = false;
  bool _initializing = false;
  bool _switching = false;

  bool get isReady => _ready;
  bool get isForward => _isFwd;

  /// The individual controllers — used by the UI to keep BOTH VideoPlayer
  /// widgets always in the tree (crossfade approach — prevents flash on switch).
  VideoPlayerController? get forwardController => _fwdCtrl;
  VideoPlayerController? get reverseController => _revCtrl;

  /// Convenience: returns the currently active controller (legacy / simple use).
  VideoPlayerController? get controller => _isFwd ? _fwdCtrl : _revCtrl;

  /// Call from both screens. Safe to call concurrently — only initialises once.
  Future<bool> ensureReady() async {
    if (_ready) return true;
    if (_initializing) {
      while (_initializing) {
        await Future<void>.delayed(const Duration(milliseconds: 50));
      }
      return _ready;
    }
    _initializing = true;
    try {
      // mixWithOthers: true يمنع أخذ audio focus من التطبيقات الأخرى (مثل تشغيل القرآن)
      final videoOpts = VideoPlayerOptions(mixWithOthers: true);
      _fwdCtrl = VideoPlayerController.asset(_fwdAsset, videoPlayerOptions: videoOpts);
      _revCtrl = VideoPlayerController.asset(_revAsset, videoPlayerOptions: videoOpts);

      // Initialize both in parallel
      await Future.wait([
        _fwdCtrl!.initialize(),
        _revCtrl!.initialize(),
      ]);

      _fwdCtrl!.setLooping(false);
      _revCtrl!.setLooping(false);
      await Future.wait([
        _fwdCtrl!.setVolume(0),
        _revCtrl!.setVolume(0),
      ]);

      await _fwdCtrl!.setPlaybackSpeed(playbackSpeed);
      await _revCtrl!.setPlaybackSpeed(playbackSpeed);

      _fwdCtrl!.addListener(_onFwdTick);
      _revCtrl!.addListener(_onRevTick);

      // Only forward starts playing; reverse waits at frame 0
      _isFwd = true;
      await _fwdCtrl!.play();

      _ready = true;
      return true;
    } catch (_) {
      return false;
    } finally {
      _initializing = false;
    }
  }

  // ─── End-of-video detection ──────────────────────────────────────────────

  void _onFwdTick() {
    if (!_isFwd || _switching) return;
    final ctrl = _fwdCtrl;
    if (ctrl == null || !ctrl.value.isInitialized) return;
    if (_hasEnded(ctrl)) _switchTo(forward: false);
  }

  void _onRevTick() {
    if (_isFwd || _switching) return;
    final ctrl = _revCtrl;
    if (ctrl == null || !ctrl.value.isInitialized) return;
    if (_hasEnded(ctrl)) _switchTo(forward: true);
  }

  bool _hasEnded(VideoPlayerController ctrl) {
    if (ctrl.value.duration == Duration.zero) return false;
    final remaining = ctrl.value.duration - ctrl.value.position;
    // Primary: remaining time < 200 ms
    if (remaining.inMilliseconds < 200 && ctrl.value.position > Duration.zero) {
      return true;
    }
    // Fallback: video stopped naturally at the end
    if (!ctrl.value.isPlaying &&
        !ctrl.value.isBuffering &&
        ctrl.value.position > const Duration(milliseconds: 500) &&
        remaining.inMilliseconds < 500) {
      return true;
    }
    return false;
  }

  // ─── Controller switch ───────────────────────────────────────────────────

  /// Wait until [ctrl] has advanced past start (first frame rendered) or timeout.
  Future<void> _waitForFirstFrame(VideoPlayerController ctrl, {int timeoutMs = 200}) async {
    final deadline = DateTime.now().add(Duration(milliseconds: timeoutMs));
    while (DateTime.now().isBefore(deadline)) {
      if (ctrl.value.position > Duration.zero) return;
      await Future<void>.delayed(const Duration(milliseconds: 16));
    }
  }

  Future<void> _switchTo({required bool forward}) async {
    if (_switching) return;
    _switching = true;

    final outgoing = forward ? _revCtrl : _fwdCtrl;
    final incoming = forward ? _fwdCtrl : _revCtrl;

    // Prepare incoming without changing what's visible: seek and play (still hidden).
    await incoming?.seekTo(Duration.zero);
    if (incoming != null) {
      await incoming.play();
      await _waitForFirstFrame(incoming);
    }

    // Only now pause outgoing and flip UI — user never sees a "paused" frame.
    outgoing?.pause();
    _isFwd = forward;
    notifyListeners();

    _switching = false;

    await Future<void>.delayed(const Duration(milliseconds: 1200));
    await outgoing?.seekTo(Duration.zero);
  }

  // ─── Lifecycle ───────────────────────────────────────────────────────────

  /// Call when leaving the auth flow entirely (navigating to home/admin/etc.)
  void release() {
    _fwdCtrl?.removeListener(_onFwdTick);
    _revCtrl?.removeListener(_onRevTick);
    _fwdCtrl?.dispose();
    _revCtrl?.dispose();
    _fwdCtrl = null;
    _revCtrl = null;
    _ready = false;
    _initializing = false;
    _isFwd = true;
    _switching = false;
    notifyListeners();
  }
}
