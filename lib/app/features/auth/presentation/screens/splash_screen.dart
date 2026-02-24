import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:video_player/video_player.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_storage_keys.dart';
import '../bloc/auth_bloc.dart';
import '../bloc/auth_state.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  VideoPlayerController? _controller;
  bool _videoReady    = false;
  bool _videoEnded    = false;
  bool _authResolved  = false;
  String? _destination;

  // مسار الفيديو — ضع ملفك هنا
  static const _videoAsset = 'assets/videos/splash.mp4';

  @override
  void initState() {
    super.initState();
    // إخفاء شريط الحالة أثناء السبلاش
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    _initVideo();
    WidgetsBinding.instance.addPostFrameCallback((_) => _checkCurrentAuth());
  }

  // ─── تهيئة الفيديو ───────────────────────────────────────────────────────
  Future<void> _initVideo() async {
    try {
      final ctrl = VideoPlayerController.asset(_videoAsset);
      await ctrl.initialize();
      ctrl.setLooping(false);
      ctrl.setVolume(0); // صامت — غيّر لـ 1.0 إذا عندك صوت
      ctrl.addListener(_onVideoTick);
      await ctrl.play();
      if (!mounted) return;
      setState(() {
        _controller  = ctrl;
        _videoReady  = true;
      });
    } catch (_) {
      // الفيديو مو موجود بعد → انتقل فوراً بعد تحليل Auth
      _videoEnded = true;
      _tryNavigate();
    }
  }

  void _onVideoTick() {
    final ctrl = _controller;
    if (ctrl == null || _videoEnded) return;
    final pos = ctrl.value.position;
    final dur = ctrl.value.duration;
    if (dur > Duration.zero && pos >= dur - const Duration(milliseconds: 100)) {
      _videoEnded = true;
      _tryNavigate();
    }
  }

  // ─── Auth ────────────────────────────────────────────────────────────────
  void _checkCurrentAuth() {
    if (!mounted) return;
    final state = context.read<AuthBloc>().state;
    _handleAuthState(state);
  }

  Future<void> _handleAuthState(AuthState state) async {
    if (state is AuthAuthenticated) {
      _destination  = '/home';
      _authResolved = true;
      _tryNavigate();
    } else if (state is AuthUnauthenticated || state is AuthError) {
      await _resolveUnauthenticated();
    }
    // AuthInitial / AuthLoading → ننتظر BlocListener
  }

  Future<void> _resolveUnauthenticated() async {
    final prefs = await SharedPreferences.getInstance();
    final seen  = prefs.getBool(AppStorageKeys.onboardingSeen) ?? false;
    _destination  = seen ? '/login' : '/onboarding';
    _authResolved = true;
    _tryNavigate();
  }

  // ─── الانتقال عندما ينتهي الفيديو + يتحل الـ Auth ───────────────────────
  void _tryNavigate() {
    if (!mounted || !_authResolved || !_videoEnded) return;
    final dest = _destination;
    if (dest == null) return;
    // إعادة شريط الحالة
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    context.go(dest);
  }

  @override
  void dispose() {
    _controller?.removeListener(_onVideoTick);
    _controller?.dispose();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    super.dispose();
  }

  // ─── UI ──────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return BlocListener<AuthBloc, AuthState>(
      listener: (context, state) => _handleAuthState(state),
      child: Scaffold(
        backgroundColor: AppColors.primaryDark,
        body: _buildBody(),
      ),
    );
  }

  Widget _buildBody() {
    final ctrl = _controller;

    // ─ فيديو جاهز ─
    if (_videoReady && ctrl != null && ctrl.value.isInitialized) {
      return SizedBox.expand(
        child: FittedBox(
          fit: BoxFit.cover,
          child: SizedBox(
            width:  ctrl.value.size.width,
            height: ctrl.value.size.height,
            child:  VideoPlayer(ctrl),
          ),
        ),
      );
    }

    // ─ شاشة سوداء ريثما يحمّل الفيديو — بتبيّن وكأنه الفيديو بلّش فوراً ─
    return const SizedBox.expand();
  }
}
