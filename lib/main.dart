import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';

import 'config/app_theme.dart';
import 'controllers/home_controller.dart';
import 'controllers/navigation_controller.dart';
import 'controllers/popular_controller.dart';
import 'controllers/latest_controller.dart';
import 'controllers/genres_controller.dart';
import 'views/main_layout.dart';
import 'views/splash_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  // Set system UI overlay style for immersive dark theme
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      systemNavigationBarColor: AppTheme.surfaceBlack,
      systemNavigationBarIconBrightness: Brightness.light,
    ),
  );

  runApp(const KomikkuyaApp());
}

class KomikkuyaApp extends StatelessWidget {
  const KomikkuyaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => HomeController()),
        ChangeNotifierProvider(create: (_) => NavigationController()),
        ChangeNotifierProvider(create: (_) => PopularController()),
        ChangeNotifierProvider(create: (_) => LatestController()),
        ChangeNotifierProvider(create: (_) => GenresController()),
      ],
      child: MaterialApp(
        title: 'Komikkuya',
        debugShowCheckedModeBanner: false,
        theme: _buildTheme(),
        home: const AppWrapper(),
      ),
    );
  }

  ThemeData _buildTheme() {
    // Start with the app's dark theme
    final baseTheme = AppTheme.darkTheme;

    // Apply Google Fonts
    return baseTheme.copyWith(
      textTheme: GoogleFonts.interTextTheme(baseTheme.textTheme),
    );
  }
}

/// App wrapper that shows splash screen first, then main layout
class AppWrapper extends StatefulWidget {
  const AppWrapper({super.key});

  @override
  State<AppWrapper> createState() => _AppWrapperState();
}

class _AppWrapperState extends State<AppWrapper>
    with SingleTickerProviderStateMixin {
  bool _showSplash = true;
  late AnimationController _transitionController;
  late Animation<double> _fadeOut;
  late Animation<double> _scaleOut;
  late Animation<double> _fadeIn;
  late Animation<double> _scaleIn;
  late Animation<Offset> _slideIn;

  @override
  void initState() {
    super.initState();
    _transitionController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    // Splash fade out (first half)
    _fadeOut = Tween<double>(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(
        parent: _transitionController,
        curve: const Interval(0.0, 0.5, curve: Curves.easeOut),
      ),
    );

    // Splash scale out (zoom effect)
    _scaleOut = Tween<double>(begin: 1.0, end: 1.2).animate(
      CurvedAnimation(
        parent: _transitionController,
        curve: const Interval(0.0, 0.5, curve: Curves.easeOut),
      ),
    );

    // Main layout fade in (second half)
    _fadeIn = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _transitionController,
        curve: const Interval(0.4, 1.0, curve: Curves.easeOut),
      ),
    );

    // Main layout scale in (zoom from small)
    _scaleIn = Tween<double>(begin: 0.9, end: 1.0).animate(
      CurvedAnimation(
        parent: _transitionController,
        curve: const Interval(0.4, 1.0, curve: Curves.easeOutCubic),
      ),
    );

    // Main layout slide up
    _slideIn = Tween<Offset>(begin: const Offset(0, 0.05), end: Offset.zero)
        .animate(
          CurvedAnimation(
            parent: _transitionController,
            curve: const Interval(0.4, 1.0, curve: Curves.easeOutCubic),
          ),
        );
  }

  @override
  void dispose() {
    _transitionController.dispose();
    super.dispose();
  }

  void _onSplashComplete() {
    _transitionController.forward().then((_) {
      setState(() {
        _showSplash = false;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _transitionController,
      builder: (context, child) {
        return Stack(
          children: [
            // Main Layout (behind, fades/scales in)
            if (_transitionController.value > 0.3 || !_showSplash)
              Opacity(
                opacity: _showSplash ? _fadeIn.value : 1.0,
                child: Transform.scale(
                  scale: _showSplash ? _scaleIn.value : 1.0,
                  child: SlideTransition(
                    position: _showSplash
                        ? _slideIn
                        : AlwaysStoppedAnimation(Offset.zero),
                    child: const MainLayout(),
                  ),
                ),
              ),

            // Splash Screen (in front, fades/scales out)
            if (_showSplash && _transitionController.value < 1.0)
              Opacity(
                opacity: _fadeOut.value,
                child: Transform.scale(
                  scale: _scaleOut.value,
                  child: SplashScreen(onComplete: _onSplashComplete),
                ),
              ),
          ],
        );
      },
    );
  }
}
