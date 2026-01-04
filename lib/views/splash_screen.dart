import 'dart:async';
import 'dart:math' as math;
import 'dart:io';
import 'package:flutter/material.dart';
import '../config/app_theme.dart';

/// Animated splash screen with premium effects
class SplashScreen extends StatefulWidget {
  final VoidCallback onComplete;

  const SplashScreen({super.key, required this.onComplete});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  // Animation controllers
  late AnimationController _logoController;
  late AnimationController _textController;
  late AnimationController _particleController;
  late AnimationController _pulseController;

  // Animations
  late Animation<double> _logoScale;
  late Animation<double> _logoOpacity;
  late Animation<double> _logoRotation;
  late Animation<double> _textOpacity;
  late Animation<Offset> _textSlide;
  late Animation<double> _pulseAnimation;

  // Internet check state
  bool _showNoInternetError = false;

  @override
  void initState() {
    super.initState();
    _setupAnimations();
    _startAnimationSequence();
  }

  void _setupAnimations() {
    // Logo animation controller (scale, opacity, rotation)
    _logoController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );

    // Pulse animation for logo glow
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );

    // Text animation controller
    _textController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    // Particle animation controller
    _particleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3000),
    );

    // Logo scale with elastic effect
    _logoScale = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _logoController, curve: Curves.elasticOut),
    );

    // Logo opacity
    _logoOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _logoController,
        curve: const Interval(0.0, 0.5, curve: Curves.easeOut),
      ),
    );

    // Logo rotation
    _logoRotation = Tween<double>(
      begin: -0.1,
      end: 0.0,
    ).animate(CurvedAnimation(parent: _logoController, curve: Curves.easeOut));

    // Pulse animation
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.15).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    // Text opacity
    _textOpacity = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _textController, curve: Curves.easeOut));

    // Text slide
    _textSlide = Tween<Offset>(begin: const Offset(0, 0.5), end: Offset.zero)
        .animate(
          CurvedAnimation(parent: _textController, curve: Curves.easeOutCubic),
        );
  }

  void _startAnimationSequence() async {
    // Start particle animation immediately
    if (!mounted) return;
    _particleController.repeat();

    // Wait a bit, then start logo animation
    await Future.delayed(const Duration(milliseconds: 200));
    if (!mounted) return;
    _logoController.forward();

    // Start pulse after logo appears
    await Future.delayed(const Duration(milliseconds: 600));
    if (!mounted) return;
    _pulseController.repeat(reverse: true);

    // Start text animation after logo is mostly done
    await Future.delayed(const Duration(milliseconds: 400));
    if (!mounted) return;
    _textController.forward();

    // Wait for animations, then check internet
    await Future.delayed(const Duration(milliseconds: 1200));
    if (!mounted) return;

    // Check internet connectivity
    await _checkInternetAndProceed();
  }

  /// Check internet connectivity and proceed or show error
  Future<void> _checkInternetAndProceed() async {
    if (!mounted) return;

    final hasInternet = await _checkInternet();

    if (!mounted) return;

    if (hasInternet) {
      widget.onComplete();
    } else {
      setState(() {
        _showNoInternetError = true;
      });
    }
  }

  /// Check if device has internet connection
  Future<bool> _checkInternet() async {
    try {
      final result = await InternetAddress.lookup(
        'google.com',
      ).timeout(const Duration(seconds: 5));
      return result.isNotEmpty && result[0].rawAddress.isNotEmpty;
    } on SocketException catch (_) {
      return false;
    } on TimeoutException catch (_) {
      return false;
    } catch (_) {
      return false;
    }
  }

  /// Retry internet check
  void _retryConnection() {
    setState(() {
      _showNoInternetError = false;
    });
    _checkInternetAndProceed();
  }

  @override
  void dispose() {
    // Stop all animations first to prevent callbacks after dispose
    _logoController.stop();
    _textController.stop();
    _particleController.stop();
    _pulseController.stop();

    _logoController.dispose();
    _textController.dispose();
    _particleController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.primaryBlack,
      body: Stack(
        children: [
          // Animated background gradient
          _buildAnimatedBackground(),

          // Floating particles
          _buildParticles(),

          // Main content
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Animated logo with glow
                _buildAnimatedLogo(),

                const SizedBox(height: 24),

                // Animated text
                _buildAnimatedText(),
              ],
            ),
          ),

          // Loading indicator at bottom (hide when error)
          if (!_showNoInternetError) _buildLoadingIndicator(),

          // No internet error overlay
          if (_showNoInternetError) _buildNoInternetOverlay(),
        ],
      ),
    );
  }

  Widget _buildNoInternetOverlay() {
    return Container(
      color: AppTheme.primaryBlack.withAlpha(240),
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Error icon with animation
              TweenAnimationBuilder<double>(
                tween: Tween(begin: 0.0, end: 1.0),
                duration: const Duration(milliseconds: 500),
                builder: (context, value, child) {
                  return Transform.scale(
                    scale: value,
                    child: Container(
                      width: 100,
                      height: 100,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.red.withAlpha(30),
                        border: Border.all(
                          color: Colors.red.withAlpha(100),
                          width: 2,
                        ),
                      ),
                      child: const Icon(
                        Icons.wifi_off_rounded,
                        size: 50,
                        color: Colors.red,
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(height: 32),
              // Error title
              const Text(
                'No Internet Connection',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              // Error description
              Text(
                'Please check your connection and try again',
                style: TextStyle(
                  fontSize: 14,
                  color: AppTheme.textGrey.withAlpha(200),
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              // Retry button
              GestureDetector(
                onTap: _retryConnection,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 40,
                    vertical: 16,
                  ),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        AppTheme.accentPurple,
                        AppTheme.accentPurple.withAlpha(180),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(30),
                    boxShadow: [
                      BoxShadow(
                        color: AppTheme.accentPurple.withAlpha(100),
                        blurRadius: 20,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.refresh, color: Colors.white),
                      SizedBox(width: 8),
                      Text(
                        'Try Again',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          letterSpacing: 1,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAnimatedBackground() {
    return AnimatedBuilder(
      animation: _particleController,
      builder: (context, child) {
        return Container(
          decoration: BoxDecoration(
            gradient: RadialGradient(
              center: Alignment.center,
              radius: 1.5 + (_particleController.value * 0.2),
              colors: [
                AppTheme.accentPurple.withAlpha(30),
                AppTheme.primaryBlack,
                AppTheme.primaryBlack,
              ],
              stops: const [0.0, 0.5, 1.0],
            ),
          ),
        );
      },
    );
  }

  Widget _buildParticles() {
    return AnimatedBuilder(
      animation: _particleController,
      builder: (context, child) {
        return CustomPaint(
          size: MediaQuery.of(context).size,
          painter: _ParticlePainter(
            animationValue: _particleController.value,
            color: AppTheme.accentPurple,
          ),
        );
      },
    );
  }

  Widget _buildAnimatedLogo() {
    return AnimatedBuilder(
      animation: Listenable.merge([_logoController, _pulseController]),
      builder: (context, child) {
        return Transform.scale(
          scale: _logoScale.value * _pulseAnimation.value,
          child: Transform.rotate(
            angle: _logoRotation.value,
            child: Opacity(
              opacity: _logoOpacity.value,
              child: Container(
                width: 160,
                height: 160,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.accentPurple.withAlpha(
                        (100 * _pulseAnimation.value).toInt().clamp(0, 255),
                      ),
                      blurRadius: 40 * _pulseAnimation.value,
                      spreadRadius: 10 * _pulseAnimation.value,
                    ),
                  ],
                ),
                child: ClipOval(
                  child: Image.asset(
                    'lib/assets/icon_nobg.png',
                    width: 160,
                    height: 160,
                    fit: BoxFit.contain,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        width: 160,
                        height: 160,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: LinearGradient(
                            colors: [
                              AppTheme.accentPurple,
                              AppTheme.accentPurple.withAlpha(150),
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                        ),
                        child: const Icon(
                          Icons.menu_book,
                          color: Colors.white,
                          size: 80,
                        ),
                      );
                    },
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildAnimatedText() {
    return AnimatedBuilder(
      animation: _textController,
      builder: (context, child) {
        return SlideTransition(
          position: _textSlide,
          child: Opacity(
            opacity: _textOpacity.value,
            child: Column(
              children: [
                // App name with gradient and bold font
                ShaderMask(
                  shaderCallback: (bounds) => LinearGradient(
                    colors: [
                      Colors.white,
                      AppTheme.accentPurple.withAlpha(220),
                    ],
                  ).createShader(bounds),
                  child: Text(
                    'KOMIKKUYA',
                    style: TextStyle(
                      fontSize: 42,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 4,
                      color: Colors.white,
                      shadows: [
                        Shadow(
                          color: Colors.white.withAlpha(100),
                          blurRadius: 2,
                          offset: const Offset(0, 0),
                        ),
                        Shadow(
                          color: AppTheme.accentPurple.withAlpha(150),
                          blurRadius: 10,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                // Tagline
                Text(
                  'Your Manga Universe',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                    letterSpacing: 3,
                    color: AppTheme.textGrey.withAlpha(200),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildLoadingIndicator() {
    return Positioned(
      bottom: 60,
      left: 0,
      right: 0,
      child: AnimatedBuilder(
        animation: Listenable.merge([_textController, _particleController]),
        builder: (context, child) {
          return Opacity(
            opacity: _textOpacity.value,
            child: Column(
              children: [
                // Animated dots loader
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(3, (index) {
                    final delay = index * 0.2;
                    final progress = (_particleController.value + delay) % 1.0;
                    final scale =
                        0.5 + (0.5 * (1 - (2 * (progress - 0.5)).abs()));
                    return Container(
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      child: Transform.scale(
                        scale: scale,
                        child: Container(
                          width: 10,
                          height: 10,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: AppTheme.accentPurple.withAlpha(
                              (255 * scale).toInt().clamp(100, 255),
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: AppTheme.accentPurple.withAlpha(100),
                                blurRadius: 8 * scale,
                                spreadRadius: 2 * scale,
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  }),
                ),
                const SizedBox(height: 16),
                Text(
                  'Loading...',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: AppTheme.textGrey.withAlpha(180),
                    letterSpacing: 1,
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

/// Custom painter for floating particles
class _ParticlePainter extends CustomPainter {
  final double animationValue;
  final Color color;
  final List<_Particle> particles;

  _ParticlePainter({required this.animationValue, required this.color})
    : particles = List.generate(20, (index) => _Particle(index));

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.fill;

    for (final particle in particles) {
      final progress = (animationValue + particle.offset) % 1.0;
      final x = particle.x * size.width;
      final y = size.height * (1 - progress) - 50 + particle.yOffset;
      final opacity = (1 - progress) * particle.opacity;
      final radius = particle.size * (1 - progress * 0.5);

      paint.color = color.withAlpha((opacity * 100).toInt().clamp(0, 255));
      canvas.drawCircle(Offset(x, y), radius, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _ParticlePainter oldDelegate) {
    return oldDelegate.animationValue != animationValue;
  }
}

/// Particle data
class _Particle {
  final double x;
  final double yOffset;
  final double size;
  final double opacity;
  final double offset;

  _Particle(int index)
    : x = (math.Random(index).nextDouble()),
      yOffset = math.Random(index + 100).nextDouble() * 100,
      size = math.Random(index + 200).nextDouble() * 3 + 1,
      opacity = math.Random(index + 300).nextDouble() * 0.5 + 0.3,
      offset = math.Random(index + 400).nextDouble();
}
