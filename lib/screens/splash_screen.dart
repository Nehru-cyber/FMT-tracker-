import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import 'dart:math';
import '../config/theme.dart';
import '../config/routes.dart';
import '../providers/auth_provider.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late AnimationController _particleController;
  late AnimationController _shimmerController;
  late List<_Particle> _particles;

  @override
  void initState() {
    super.initState();
    _particleController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 10),
    )..repeat();
    _shimmerController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat();

    final random = Random();
    _particles = List.generate(25, (index) {
      return _Particle(
        x: random.nextDouble(),
        y: random.nextDouble(),
        size: random.nextDouble() * 6 + 2,
        speed: random.nextDouble() * 0.3 + 0.1,
        opacity: random.nextDouble() * 0.4 + 0.1,
      );
    });

    _navigateNext();
  }

  @override
  void dispose() {
    _particleController.dispose();
    _shimmerController.dispose();
    super.dispose();
  }

  Future<void> _navigateNext() async {
    await Future.delayed(const Duration(milliseconds: 3000));
    if (!mounted) return;

    final authProvider = context.read<AuthProvider>();

    if (authProvider.isLoggedIn) {
      // If biometric lock is enabled, verify before entering home
      if (authProvider.biometricEnabled) {
        final authenticated = await authProvider.quickLoginWithBiometric();
        if (!mounted) return;
        if (authenticated) {
          Navigator.pushReplacementNamed(context, AppRoutes.home);
        } else {
          // Biometric failed, send to login screen
          Navigator.pushReplacementNamed(context, AppRoutes.login);
        }
      } else {
        Navigator.pushReplacementNamed(context, AppRoutes.home);
      }
    } else {
      Navigator.pushReplacementNamed(context, AppRoutes.onboarding);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Background gradient
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFF4F46E5),
                  Color(0xFF6366F1),
                  Color(0xFF8B5CF6),
                  Color(0xFFA855F7),
                ],
                stops: [0.0, 0.3, 0.7, 1.0],
              ),
            ),
          ),
          // Floating particles
          AnimatedBuilder(
            animation: _particleController,
            builder: (context, child) {
              return CustomPaint(
                size: MediaQuery.of(context).size,
                painter: _ParticlePainter(
                  particles: _particles,
                  animationValue: _particleController.value,
                ),
              );
            },
          ),
          // Main content
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Logo with glow effect
                    Container(
                      width: 150,
                      height: 150,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(38),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.white.withOpacity(0.35),
                            blurRadius: 50,
                            spreadRadius: 8,
                          ),
                          BoxShadow(
                            color: const Color(0xFF4F46E5).withOpacity(0.5),
                            blurRadius: 40,
                            offset: const Offset(0, 20),
                          ),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(38),
                        child: Image.asset(
                          'assets/images/logo.png',
                          width: 150,
                          height: 150,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return Container(
                              width: 150,
                              height: 150,
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(38),
                              ),
                              child: const Icon(
                                Icons.account_balance_wallet,
                                size: 75,
                                color: AppTheme.primaryColor,
                              ),
                            );
                          },
                        ),
                      ),
                    )
                        .animate()
                        .fadeIn(duration: 700.ms)
                        .scale(
                          begin: const Offset(0.5, 0.5),
                          end: const Offset(1, 1),
                          curve: Curves.easeOutBack,
                          duration: 900.ms,
                        )
                        .then()
                        .shimmer(
                          delay: 400.ms,
                          duration: 1800.ms,
                          color: Colors.white.withOpacity(0.15),
                        ),
                    const SizedBox(height: 44),
                    // App name with shimmer
                    AnimatedBuilder(
                      animation: _shimmerController,
                      builder: (context, child) {
                        return ShaderMask(
                          shaderCallback: (bounds) {
                            return LinearGradient(
                              colors: [
                                Colors.white,
                                Colors.white.withOpacity(0.5),
                                Colors.white,
                              ],
                              stops: [
                                (_shimmerController.value - 0.3).clamp(0.0, 1.0),
                                _shimmerController.value,
                                (_shimmerController.value + 0.3).clamp(0.0, 1.0),
                              ],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ).createShader(bounds);
                          },
                          child: Text(
                            'FMT Tracker',
                            style: Theme.of(context)
                                .textTheme
                                .displayMedium
                                ?.copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 1.5,
                                ),
                            textAlign: TextAlign.center,
                          ),
                        );
                      },
                    )
                        .animate()
                        .fadeIn(delay: 500.ms, duration: 600.ms)
                        .slideY(begin: 0.4, end: 0, curve: Curves.easeOut),
                    const SizedBox(height: 14),
                    // Tagline
                    Text(
                      'Track • Plan • Grow',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            color: Colors.white.withOpacity(0.85),
                            letterSpacing: 3,
                            fontWeight: FontWeight.w300,
                          ),
                      textAlign: TextAlign.center,
                    )
                        .animate()
                        .fadeIn(delay: 800.ms, duration: 500.ms)
                        .slideY(begin: 0.2, end: 0),
                    const SizedBox(height: 90),
                    // Loading indicator
                    SizedBox(
                      width: 36,
                      height: 36,
                      child: CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(
                            Colors.white.withOpacity(0.85)),
                        strokeWidth: 2.5,
                      ),
                    ).animate().fadeIn(delay: 1100.ms, duration: 400.ms),
                    const SizedBox(height: 14),
                    // Loading text
                    Text(
                      'Loading your finances...',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.6),
                        fontSize: 12,
                        letterSpacing: 0.5,
                      ),
                      textAlign: TextAlign.center,
                    ).animate().fadeIn(delay: 1300.ms, duration: 400.ms),
                    const SizedBox(height: 50),
                    // Version
                    Text(
                      'v1.0.0',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.35),
                        fontSize: 11,
                        letterSpacing: 1,
                      ),
                      textAlign: TextAlign.center,
                    ).animate().fadeIn(delay: 1500.ms, duration: 400.ms),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Particle {
  double x;
  double y;
  final double size;
  final double speed;
  final double opacity;

  _Particle({
    required this.x,
    required this.y,
    required this.size,
    required this.speed,
    required this.opacity,
  });
}

class _ParticlePainter extends CustomPainter {
  final List<_Particle> particles;
  final double animationValue;

  _ParticlePainter({required this.particles, required this.animationValue});

  @override
  void paint(Canvas canvas, Size size) {
    for (final particle in particles) {
      final dy = (particle.y - particle.speed * animationValue) % 1.0;
      final dx = particle.x +
          sin(animationValue * 2 * pi + particle.y * 10) * 0.02;

      final paint = Paint()
        ..color = Colors.white.withOpacity(particle.opacity)
        ..style = PaintingStyle.fill;

      canvas.drawCircle(
        Offset(dx * size.width, dy * size.height),
        particle.size,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _ParticlePainter oldDelegate) => true;
}
