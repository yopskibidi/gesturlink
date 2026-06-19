import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';

import '../../core/theme.dart';
import 'loading_screen.dart';

class UserGuideScreen extends StatefulWidget {
  const UserGuideScreen({super.key});

  @override
  State<UserGuideScreen> createState() => _UserGuideScreenState();
}

class _UserGuideScreenState extends State<UserGuideScreen> {
  final PageController _pageController = PageController();
  bool _isLastPage = false;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _completeOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('has_seen_onboarding', true);

    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (_, __, ___) => const LoadingScreen(),
        transitionDuration: const Duration(milliseconds: 600),
        transitionsBuilder: (_, anim, __, child) {
          return FadeTransition(opacity: anim, child: child);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bg,
      body: Stack(
        children: [
          // ── Background Glow ──
          Positioned(
            top: -100,
            right: -100,
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppTheme.accent.withOpacity(0.15),
              ),
            ),
          ),
          Positioned(
            bottom: -50,
            left: -100,
            child: Container(
              width: 250,
              height: 250,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppTheme.accent.withOpacity(0.1),
              ),
            ),
          ),

          // ── PageView ──
          PageView(
            controller: _pageController,
            onPageChanged: (index) {
              setState(() {
                _isLastPage = index == 2;
              });
            },
            physics: const BouncingScrollPhysics(),
            children: const [
              _GuidePage(
                icon: Icons.gesture_rounded,
                title: 'Selamat Datang di GesturLink',
                description:
                    'Kendalikan perangkat lain hanya dengan gerakan kepala Anda. Teknologi masa depan kini ada di genggaman Anda.',
              ),
              _GuidePage(
                icon: Icons.videocam_rounded,
                title: 'Mode Pengendali',
                description:
                    'Gunakan kamera depan untuk mendeteksi gerakan wajah. Miringkan, angguk, atau senyum untuk mengirim perintah secara instan.',
              ),
              _GuidePage(
                icon: Icons.sensors_rounded,
                title: 'Mode Penerima',
                description:
                    'Ubah perangkat ini menjadi penerima cerdas yang merespon setiap perintah masuk melalui koneksi Bluetooth rendah energi.',
              ),
            ],
          ),

          // ── Bottom Navigation Bar ──
          Positioned(
            bottom: 40 + MediaQuery.of(context).padding.bottom,
            left: 24,
            right: 24,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Tombol Skip (Hanya tampil jika bukan halaman terakhir)
                AnimatedOpacity(
                  opacity: _isLastPage ? 0.0 : 1.0,
                  duration: const Duration(milliseconds: 300),
                  child: TextButton(
                    onPressed: _isLastPage
                        ? null
                        : () => _pageController.animateToPage(
                              2,
                              duration: const Duration(milliseconds: 600),
                              curve: Curves.easeOutCubic,
                            ),
                    style: TextButton.styleFrom(
                      foregroundColor: AppTheme.textMuted,
                    ),
                    child: const Text(
                      'Lewati',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ),
                ),

                // Smooth Page Indicator
                SmoothPageIndicator(
                  controller: _pageController,
                  count: 3,
                  effect: const ExpandingDotsEffect(
                    activeDotColor: AppTheme.accent,
                    dotColor: AppTheme.border,
                    dotHeight: 8,
                    dotWidth: 8,
                    expansionFactor: 3,
                    spacing: 6,
                  ),
                ),

                // Tombol Next / Mulai
                AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  width: _isLastPage ? 120 : 60,
                  height: 48,
                  decoration: BoxDecoration(
                    color: AppTheme.accent,
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: AppTheme.accent.withOpacity(0.3),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      )
                    ],
                  ),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(24),
                      onTap: () {
                        if (_isLastPage) {
                          _completeOnboarding();
                        } else {
                          _pageController.nextPage(
                            duration: const Duration(milliseconds: 600),
                            curve: Curves.easeOutCubic,
                          );
                        }
                      },
                      child: Center(
                        child: _isLastPage
                            ? const Text(
                                'Mulai',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              )
                            : const Icon(
                                Icons.arrow_forward_ios_rounded,
                                color: Colors.white,
                                size: 18,
                              ),
                      ),
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
}

class _GuidePage extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;

  const _GuidePage({
    required this.icon,
    required this.title,
    required this.description,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: AppTheme.bgCard,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: AppTheme.border),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.2),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                )
              ],
            ),
            child: Icon(
              icon,
              size: 64,
              color: AppTheme.accent,
            ),
          ),
          const SizedBox(height: 48),
          Text(
            title,
            style: const TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.w800,
              color: AppTheme.text,
              height: 1.2,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            description,
            style: const TextStyle(
              fontSize: 16,
              color: AppTheme.textSub,
              height: 1.6,
            ),
          ),
          const SizedBox(height: 80), // Ruang untuk bottom nav
        ],
      ),
    );
  }
}
