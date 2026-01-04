import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../config/app_theme.dart';
import '../controllers/navigation_controller.dart';
import '../controllers/auth_controller.dart';
import '../widgets/bottom_nav_bar.dart';
import 'home_screen.dart';
import 'popular_screen.dart';
import 'latest_screen.dart';
import 'genres_screen.dart';
import 'placeholder_screens.dart';
import 'favorites_screen.dart';
import 'search_screen.dart';
import 'login_screen.dart';
import 'profile_screen.dart';

/// Main layout with smooth page transitions
class MainLayout extends StatefulWidget {
  const MainLayout({super.key});

  @override
  State<MainLayout> createState() => _MainLayoutState();
}

class _MainLayoutState extends State<MainLayout> {
  late PageController _pageController;
  int _lastIndex = 0;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _navigateToSearch() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const SearchScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<NavigationController>(
      builder: (context, navController, child) {
        // Sync PageController if index changed externally (e.g., from genre click)
        if (navController.currentIndex != _lastIndex) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (_pageController.hasClients &&
                _pageController.page?.round() != navController.currentIndex) {
              _pageController.jumpToPage(navController.currentIndex);
            }
          });
          _lastIndex = navController.currentIndex;
        }

        final isHome = navController.currentIndex == 0;
        return Scaffold(
          backgroundColor: AppTheme.primaryBlack,
          extendBodyBehindAppBar: isHome,
          appBar: _buildAppBar(navController),
          body: PageView(
            controller: _pageController,
            physics: const NeverScrollableScrollPhysics(), // Disable swipe
            onPageChanged: (index) {
              navController.setIndex(index);
            },
            children: const [
              HomeScreen(),
              PopularScreen(),
              GenresScreen(),
              LatestScreen(),
              HistoryScreen(),
              FavoritesScreen(),
            ],
          ),
          bottomNavigationBar: BottomNavBar(
            currentIndex: navController.currentIndex,
            onTap: (index) {
              navController.setIndex(index);
              _pageController.animateToPage(
                index,
                duration: AppTheme.animationNormal,
                curve: Curves.easeInOutCubic,
              );
            },
          ),
        );
      },
    );
  }

  PreferredSizeWidget _buildAppBar(NavigationController navController) {
    final currentIndex = navController.currentIndex;
    final isHome = currentIndex == 0;
    final titles = [
      'Komikkuya',
      'Popular',
      'Genres',
      'Latest',
      'History',
      'Favorites',
    ];

    // Calculate background color based on scroll offset for Home
    Color bgColor = AppTheme.primaryBlack;
    if (isHome) {
      final double offset = navController.homeScrollOffset;
      // Fade from transparent to solid black over 200 pixels
      final double opacity = (offset / 200.0).clamp(0.0, 1.0);
      bgColor = AppTheme.primaryBlack.withAlpha((opacity * 255).toInt());
    }

    return AppBar(
      backgroundColor: bgColor,
      elevation: 0,
      flexibleSpace: isHome && navController.homeScrollOffset < 200
          ? Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withAlpha(180),
                    Colors.black.withAlpha(80),
                    Colors.transparent,
                  ],
                  stops: const [0.0, 0.5, 1.0],
                ),
              ),
            )
          : null,
      titleSpacing: isHome ? AppTheme.spacingL : null,
      title: isHome
          ? Image.asset(
              'lib/assets/icon_nobg.png',
              height: 35,
              fit: BoxFit.contain,
            )
          : Text(
              titles[currentIndex],
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 22),
            ),
      actions: [
        IconButton(
          onPressed: _navigateToSearch,
          icon: const Icon(Icons.search),
          tooltip: 'Search',
        ),
        _buildProfileButton(),
      ],
    );
  }

  Widget _buildProfileButton() {
    return Consumer<AuthController>(
      builder: (context, authController, child) {
        return GestureDetector(
          onTap: () => _navigateToProfile(authController),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: authController.isLoggedIn && authController.avatarUrl != null
                ? Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: AppTheme.accentPurple,
                        width: 2,
                      ),
                    ),
                    child: ClipOval(
                      child: CachedNetworkImage(
                        imageUrl: authController.avatarUrl!,
                        fit: BoxFit.cover,
                        placeholder: (_, __) => Container(
                          color: AppTheme.cardBlack,
                          child: const Icon(
                            Icons.person,
                            size: 16,
                            color: AppTheme.textGrey,
                          ),
                        ),
                        errorWidget: (_, __, ___) => Container(
                          color: AppTheme.cardBlack,
                          child: const Icon(
                            Icons.person,
                            size: 16,
                            color: AppTheme.textGrey,
                          ),
                        ),
                      ),
                    ),
                  )
                : Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: authController.isLoggedIn
                          ? AppTheme.accentPurple.withAlpha(30)
                          : AppTheme.cardBlack,
                      border: Border.all(
                        color: authController.isLoggedIn
                            ? AppTheme.accentPurple
                            : AppTheme.dividerColor,
                        width: 1.5,
                      ),
                    ),
                    child: Icon(
                      authController.isLoggedIn ? Icons.person : Icons.login,
                      size: 18,
                      color: authController.isLoggedIn
                          ? AppTheme.accentPurple
                          : AppTheme.textGrey,
                    ),
                  ),
          ),
        );
      },
    );
  }

  void _navigateToProfile(AuthController authController) {
    if (authController.isLoggedIn) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const ProfileScreen()),
      );
    } else {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const LoginScreen()),
      );
    }
  }
}
