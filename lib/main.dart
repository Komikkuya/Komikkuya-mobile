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
import 'controllers/auth_controller.dart';
import 'controllers/favorites_controller.dart';
import 'controllers/history_controller.dart';
import 'services/storage_service.dart';
import 'services/notification_navigation_service.dart';
import 'views/main_layout.dart';
import 'views/splash_screen.dart';
import 'views/login_screen.dart';
import 'views/register_screen.dart';
import 'views/manga_detail_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize storage for JWT tokens
  await StorageService.init();

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
        ChangeNotifierProvider(create: (_) => AuthController()),
        ChangeNotifierProvider(create: (_) => FavoritesController()),
        ChangeNotifierProvider(create: (_) => HistoryController()),
      ],
      child: MaterialApp(
        title: 'Komikkuya',
        debugShowCheckedModeBanner: false,
        navigatorKey: NotificationNavigationService.navigatorKey,
        theme: _buildTheme(),
        home: const AppWrapper(),
        onGenerateRoute: _generateRoute,
      ),
    );
  }

  /// Generate routes for named navigation
  Route<dynamic>? _generateRoute(RouteSettings settings) {
    switch (settings.name) {
      case '/detail':
        final args = settings.arguments as Map<String, dynamic>?;
        final url = args?['url'] as String? ?? '';
        return MaterialPageRoute(
          builder: (_) => MangaDetailScreen(mangaUrl: url),
          settings: settings,
        );
      default:
        return null;
    }
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

/// App wrapper that shows splash screen first, then routes based on auth
class AppWrapper extends StatefulWidget {
  const AppWrapper({super.key});

  @override
  State<AppWrapper> createState() => _AppWrapperState();
}

class _AppWrapperState extends State<AppWrapper>
    with SingleTickerProviderStateMixin {
  bool _showSplash = true;
  bool _isLoggedIn = false;
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
    // Check if user is logged in after splash
    final authController = context.read<AuthController>();
    _isLoggedIn = authController.isLoggedIn;

    // Sync data if logged in
    if (_isLoggedIn) {
      _syncAppData();
    }

    _transitionController.forward().then((_) {
      setState(() {
        _showSplash = false;
      });

      // Process pending notification navigation after splash and auth check
      _processPendingNotification();
    });
  }

  /// Process pending notification deep link
  void _processPendingNotification() {
    final navService = NotificationNavigationService();
    if (navService.hasPendingNavigation && _isLoggedIn) {
      // Wait a bit for the UI to settle, then navigate
      Future.delayed(const Duration(milliseconds: 500), () {
        final pendingUrl = navService.consumePendingNavigation();
        if (pendingUrl != null && mounted) {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => MangaDetailScreen(mangaUrl: pendingUrl),
            ),
          );
        }
      });
    }
  }

  /// Sync favorites and history with server
  void _syncAppData() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<FavoritesController>().loadFavorites();
      context.read<HistoryController>().loadHistory(limit: 50);
    });
  }

  /// Called when user logs in from login screen
  void _onLoginSuccess() {
    _syncAppData();
    setState(() {
      _isLoggedIn = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthController>(
      builder: (context, authController, child) {
        // Use AuthController's isLoggedIn for reactive updates (e.g., after logout)
        final isAuthenticated = !_showSplash && authController.isLoggedIn;

        return AnimatedBuilder(
          animation: _transitionController,
          builder: (context, child) {
            return Stack(
              children: [
                // Target screen (behind, fades/scales in)
                if (_transitionController.value > 0.3 || !_showSplash)
                  Opacity(
                    opacity: _showSplash ? _fadeIn.value : 1.0,
                    child: Transform.scale(
                      scale: _showSplash ? _scaleIn.value : 1.0,
                      child: SlideTransition(
                        position: _showSplash
                            ? _slideIn
                            : AlwaysStoppedAnimation(Offset.zero),
                        // Route based on auth status (reactive)
                        child: isAuthenticated
                            ? const MainLayout()
                            : _AuthRequiredScreen(
                                onLoginSuccess: _onLoginSuccess,
                              ),
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
      },
    );
  }
}

/// Screen shown when auth is required
class _AuthRequiredScreen extends StatelessWidget {
  final VoidCallback onLoginSuccess;

  const _AuthRequiredScreen({required this.onLoginSuccess});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.primaryBlack,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            children: [
              const Spacer(),
              // Logo
              Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: [
                      AppTheme.accentPurple,
                      AppTheme.accentPurple.withAlpha(150),
                    ],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.accentPurple.withAlpha(100),
                      blurRadius: 30,
                      spreadRadius: 10,
                    ),
                  ],
                ),
                child: ClipOval(
                  child: Image.asset(
                    'lib/assets/icon_nobg.png',
                    fit: BoxFit.contain,
                    errorBuilder: (_, __, ___) => const Icon(
                      Icons.menu_book_rounded,
                      color: Colors.white,
                      size: 60,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 32),
              const Text(
                'Welcome to Komikkuya',
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              Text(
                'Your manga universe awaits.\nLogin or create an account to continue.',
                style: TextStyle(
                  fontSize: 14,
                  color: AppTheme.textGrey.withAlpha(180),
                  height: 1.5,
                ),
                textAlign: TextAlign.center,
              ),
              const Spacer(),
              // Login button
              _buildButton(
                context: context,
                label: 'Login',
                isPrimary: true,
                onTap: () => _navigateToLogin(context),
              ),
              const SizedBox(height: 16),
              // Register button
              _buildButton(
                context: context,
                label: 'Create Account',
                isPrimary: false,
                onTap: () => _navigateToRegister(context),
              ),
              const SizedBox(height: 48),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildButton({
    required BuildContext context,
    required String label,
    required bool isPrimary,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        height: 56,
        decoration: BoxDecoration(
          gradient: isPrimary
              ? LinearGradient(
                  colors: [
                    AppTheme.accentPurple,
                    AppTheme.accentPurple.withAlpha(180),
                  ],
                )
              : null,
          color: isPrimary ? null : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
          border: isPrimary
              ? null
              : Border.all(color: AppTheme.accentPurple, width: 2),
          boxShadow: isPrimary
              ? [
                  BoxShadow(
                    color: AppTheme.accentPurple.withAlpha(80),
                    blurRadius: 15,
                    offset: const Offset(0, 5),
                  ),
                ]
              : null,
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: isPrimary ? Colors.white : AppTheme.accentPurple,
              letterSpacing: 1,
            ),
          ),
        ),
      ),
    );
  }

  void _navigateToLogin(BuildContext context) async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => const LoginScreen()),
    );
    if (result == true) {
      onLoginSuccess();
    }
  }

  void _navigateToRegister(BuildContext context) async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => const RegisterScreen()),
    );
    if (result == true) {
      onLoginSuccess();
    }
  }
}
