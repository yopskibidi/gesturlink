import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/theme.dart';
import 'loading_screen.dart';
import 'user_guide_screen.dart';

/// Splash Screen — animasi cinematic premium.
///
/// Urutan animasi:
/// 1. Logo ikon muncul dengan scale + fade (0–800ms)
/// 2. Wordmark "GesturLink" fade-in dari bawah (400–1200ms)
/// 3. Tagline muncul halus (800–1500ms)
/// 4. Garis tipis progress bar berjalan (1200–2800ms)
/// 5. Seluruh layar fade-out, transisi ke LoadingScreen (3000ms)
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  // Controller utama untuk logo + wordmark
  late final AnimationController _logoController;
  late final Animation<double> _logoScale;
  late final Animation<double> _logoOpacity;

  // Controller untuk wordmark
  late final AnimationController _wordmarkController;
  late final Animation<double> _wordmarkOpacity;
  late final Animation<Offset> _wordmarkSlide;

  // Controller untuk tagline
  late final AnimationController _taglineController;
  late final Animation<double> _taglineOpacity;

  // Controller untuk progress bar
  late final AnimationController _progressController;

  // Controller untuk fade-out keseluruhan
  late final AnimationController _exitController;
  late final Animation<double> _exitOpacity;

  @override
  void initState() {
    super.initState();

    // ── 1. Logo: scale dari 0.6→1.0 + fade in ──
    _logoController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _logoScale = Tween<double>(begin: 0.6, end: 1.0).animate(
      CurvedAnimation(parent: _logoController, curve: Curves.easeOutCubic),
    );
    _logoOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _logoController, curve: Curves.easeOut),
    );

    // ── 2. Wordmark: fade + slide up ──
    _wordmarkController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _wordmarkOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _wordmarkController, curve: Curves.easeOut),
    );
    _wordmarkSlide = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(parent: _wordmarkController, curve: Curves.easeOutCubic),
    );

    // ── 3. Tagline: simple fade ──
    _taglineController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _taglineOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _taglineController, curve: Curves.easeOut),
    );

    // ── 4. Progress bar ──
    _progressController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    );

    // ── 5. Exit fade-out ──
    _exitController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _exitOpacity = Tween<double>(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(parent: _exitController, curve: Curves.easeIn),
    );

    _runSequence();
  }

  /// Menjalankan urutan animasi secara berurutan.
  Future<void> _runSequence() async {
    // Jeda awal singkat agar layar stabil
    await Future.delayed(const Duration(milliseconds: 200));

    // 1. Logo muncul
    _logoController.forward();
    await Future.delayed(const Duration(milliseconds: 400));

    // 2. Wordmark muncul
    _wordmarkController.forward();
    await Future.delayed(const Duration(milliseconds: 400));

    // 3. Tagline muncul
    _taglineController.forward();
    await Future.delayed(const Duration(milliseconds: 400));

    // 4. Progress bar berjalan
    _progressController.forward();
    await Future.delayed(const Duration(milliseconds: 1800));

    // 5. Fade out keseluruhan
    _exitController.forward();
    await Future.delayed(const Duration(milliseconds: 500));

    // Cek apakah user sudah melihat onboarding
    final prefs = await SharedPreferences.getInstance();
    final hasSeenOnboarding = prefs.getBool('has_seen_onboarding') ?? false;

    // Navigasi ke layar selanjutnya
    if (mounted) {
      Navigator.of(context).pushReplacement(
        PageRouteBuilder(
          pageBuilder: (_, __, ___) =>
              hasSeenOnboarding ? const LoadingScreen() : const UserGuideScreen(),
          transitionDuration: const Duration(milliseconds: 500),
          transitionsBuilder: (_, anim, __, child) {
            return FadeTransition(opacity: anim, child: child);
          },
        ),
      );
    }
  }

  @override
  void dispose() {
    _logoController.dispose();
    _wordmarkController.dispose();
    _taglineController.dispose();
    _progressController.dispose();
    _exitController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: FadeTransition(
        opacity: _exitOpacity,
        child: Container(
          width: double.infinity,
          height: double.infinity,
          color: AppTheme.bg,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Spacer(flex: 4),

              // ── Logo Ikon ──
              ScaleTransition(
                scale: _logoScale,
                child: FadeTransition(
                  opacity: _logoOpacity,
                  child: Container(
                    width: 72,
                    height: 72,
                    decoration: BoxDecoration(
                      color: AppTheme.accent,
                      borderRadius: BorderRadius.circular(18),
                      boxShadow: [
                        BoxShadow(
                          color: AppTheme.accent.withOpacity(0.25),
                          blurRadius: 40,
                          spreadRadius: 0,
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.gesture,
                      color: Colors.white,
                      size: 34,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // ── Wordmark ──
              SlideTransition(
                position: _wordmarkSlide,
                child: FadeTransition(
                  opacity: _wordmarkOpacity,
                  child: const Text(
                    'GesturLink',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.text,
                      letterSpacing: -0.5,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 8),

              // ── Tagline ──
              FadeTransition(
                opacity: _taglineOpacity,
                child: const Text(
                  'Interaksi Tanpa Sentuhan',
                  style: TextStyle(
                    fontSize: 14,
                    color: AppTheme.textMuted,
                    fontWeight: FontWeight.w400,
                    letterSpacing: 0.5,
                  ),
                ),
              ),

              const Spacer(flex: 3),

              // ── Progress Bar ──
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 80),
                child: AnimatedBuilder(
                  animation: _progressController,
                  builder: (_, __) {
                    return Container(
                      height: 2,
                      decoration: BoxDecoration(
                        color: AppTheme.border,
                        borderRadius: BorderRadius.circular(1),
                      ),
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: FractionallySizedBox(
                          widthFactor: _progressController.value,
                          child: Container(
                            decoration: BoxDecoration(
                              color: AppTheme.accent,
                              borderRadius: BorderRadius.circular(1),
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),

              const Spacer(flex: 1),
            ],
          ),
        ),
      ),
    );
  }
}

/// Widget pembantu untuk mendengarkan animasi tanpa boilerplate.
class AnimatedBuilder extends StatelessWidget {
  final Animation<double> animation;
  final Widget Function(BuildContext, Widget?) builder;

  const AnimatedBuilder({
    super.key,
    required this.animation,
    required this.builder,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder._internal(animation: animation, builder: builder);
  }

  // Menggunakan AnimatedBuilder internal dari Flutter
  static Widget _internal({
    required Animation<double> animation,
    required Widget Function(BuildContext, Widget?) builder,
  }) {
    return _AnimatedBuilderWidget(animation: animation, builder: builder);
  }
}

class _AnimatedBuilderWidget extends StatefulWidget {
  final Animation<double> animation;
  final Widget Function(BuildContext, Widget?) builder;

  const _AnimatedBuilderWidget({
    required this.animation,
    required this.builder,
  });

  @override
  State<_AnimatedBuilderWidget> createState() => _AnimatedBuilderWidgetState();
}

class _AnimatedBuilderWidgetState extends State<_AnimatedBuilderWidget> {
  @override
  void initState() {
    super.initState();
    widget.animation.addListener(_onTick);
  }

  @override
  void dispose() {
    widget.animation.removeListener(_onTick);
    super.dispose();
  }

  void _onTick() {
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return widget.builder(context, null);
  }
}
