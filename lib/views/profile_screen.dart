import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import '../config/app_theme.dart';
import '../controllers/auth_controller.dart';
import '../models/cache_settings_model.dart';

/// Profile screen with Discord integration
class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _usernameController = TextEditingController();
  bool _isEditing = false;

  // Cache management
  CacheSettings _cacheSettings = const CacheSettings();
  int _currentCacheSize = 0;
  bool _isClearing = false;

  @override
  void initState() {
    super.initState();
    _usernameController.text =
        context.read<AuthController>().user?.username ?? '';
    _loadCacheInfo();
  }

  Future<void> _loadCacheInfo() async {
    final settings = await CacheSettings.load();
    final cacheManager = DefaultCacheManager();
    final cacheInfo = await cacheManager.store.getCacheSize();
    if (mounted) {
      setState(() {
        _cacheSettings = settings;
        _currentCacheSize = cacheInfo;
      });
    }
  }

  Future<void> _clearCache() async {
    setState(() => _isClearing = true);

    try {
      final cacheManager = DefaultCacheManager();
      await cacheManager.emptyCache();
      await _loadCacheInfo();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(
                  Icons.check_circle,
                  color: AppTheme.accentPurple,
                  size: 20,
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Text(
                    'Cache cleared successfully!',
                    style: TextStyle(
                      fontWeight: FontWeight.w500,
                      color: AppTheme.textWhite,
                    ),
                  ),
                ),
              ],
            ),
            backgroundColor: AppTheme.cardBlack,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Error: $e',
              style: const TextStyle(color: Colors.white),
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isClearing = false);
    }
  }

  void _showClearCacheDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.cardBlack,
        title: const Text(
          'Clear Cache?',
          style: TextStyle(color: Colors.white),
        ),
        content: Text(
          'This will delete ${CacheSettings.formatSize(_currentCacheSize)} of cached images. You will need to re-download images when reading.',
          style: const TextStyle(color: AppTheme.textGrey),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'Cancel',
              style: TextStyle(color: AppTheme.textGrey),
            ),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _clearCache();
            },
            child: const Text('Clear', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _usernameController.dispose();
    super.dispose();
  }

  Future<void> _pickAndUploadImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 512,
      maxHeight: 512,
      imageQuality: 85,
    );

    if (pickedFile != null && mounted) {
      final authController = context.read<AuthController>();
      await authController.uploadProfilePicture(File(pickedFile.path));
    }
  }

  Future<void> _saveUsername() async {
    if (_usernameController.text.trim().isEmpty) return;

    final authController = context.read<AuthController>();
    final success = await authController.updateProfile(
      username: _usernameController.text.trim(),
    );

    if (success && mounted) {
      setState(() => _isEditing = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Profile updated'),
          backgroundColor: AppTheme.accentPurple,
        ),
      );
    }
  }

  Future<void> _handleLogout() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.cardBlack,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Logout', style: TextStyle(color: Colors.white)),
        content: const Text(
          'Are you sure you want to logout?',
          style: TextStyle(color: AppTheme.textGrey),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text(
              'Cancel',
              style: TextStyle(color: AppTheme.textGrey),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Logout', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm == true && mounted) {
      await context.read<AuthController>().logout();
      // Pop all routes to return to root (auth required screen)
      Navigator.of(context).popUntil((route) => route.isFirst);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.primaryBlack,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          'Profile',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          if (_isEditing)
            IconButton(
              icon: const Icon(Icons.check, color: AppTheme.accentPurple),
              onPressed: _saveUsername,
            ),
        ],
      ),
      body: Consumer<AuthController>(
        builder: (context, authController, child) {
          if (authController.isLoading) {
            return const Center(
              child: CircularProgressIndicator(color: AppTheme.accentPurple),
            );
          }

          return RefreshIndicator(
            onRefresh: authController.refreshProfile,
            color: AppTheme.accentPurple,
            backgroundColor: AppTheme.surfaceBlack,
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  // Profile header
                  _buildProfileHeader(authController),
                  const SizedBox(height: 32),
                  // Discord card
                  if (authController.hasDiscord)
                    _buildDiscordCard(authController),
                  if (authController.hasDiscord) const SizedBox(height: 24),
                  // Profile info
                  _buildProfileInfo(authController),
                  const SizedBox(height: 24),
                  // Storage section
                  _buildStorageSection(),
                  const SizedBox(height: 32),
                  // Logout button
                  _buildLogoutButton(),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildProfileHeader(AuthController authController) {
    return Column(
      children: [
        // Avatar
        GestureDetector(
          onTap: _pickAndUploadImage,
          child: Stack(
            children: [
              Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: AppTheme.accentPurple, width: 3),
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.accentPurple.withAlpha(60),
                      blurRadius: 20,
                      spreadRadius: 5,
                    ),
                  ],
                ),
                child: ClipOval(
                  child: authController.avatarUrl != null
                      ? CachedNetworkImage(
                          imageUrl: authController.avatarUrl!,
                          fit: BoxFit.cover,
                          placeholder: (_, __) => Container(
                            color: AppTheme.cardBlack,
                            child: const Icon(
                              Icons.person,
                              size: 50,
                              color: AppTheme.textGrey,
                            ),
                          ),
                          errorWidget: (_, __, ___) => Container(
                            color: AppTheme.cardBlack,
                            child: const Icon(
                              Icons.person,
                              size: 50,
                              color: AppTheme.textGrey,
                            ),
                          ),
                        )
                      : Container(
                          color: AppTheme.cardBlack,
                          child: const Icon(
                            Icons.person,
                            size: 50,
                            color: AppTheme.textGrey,
                          ),
                        ),
                ),
              ),
              // Edit badge
              Positioned(
                bottom: 0,
                right: 0,
                child: Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: AppTheme.accentPurple,
                    shape: BoxShape.circle,
                    border: Border.all(color: AppTheme.primaryBlack, width: 3),
                  ),
                  child: const Icon(
                    Icons.camera_alt,
                    size: 18,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        // Display name
        Text(
          authController.displayName,
          style: const TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 4),
        // Email
        Text(
          authController.user?.email ?? '',
          style: TextStyle(
            fontSize: 14,
            color: AppTheme.textGrey.withAlpha(180),
          ),
        ),
      ],
    );
  }

  Widget _buildDiscordCard(AuthController authController) {
    final discord = authController.discordProfile!;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF5865F2).withAlpha(30),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF5865F2).withAlpha(100)),
      ),
      child: Row(
        children: [
          // Discord avatar
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: const Color(0xFF5865F2), width: 2),
            ),
            child: ClipOval(
              child: discord.avatar != null
                  ? CachedNetworkImage(
                      imageUrl: discord.avatar!,
                      fit: BoxFit.cover,
                    )
                  : Container(
                      color: const Color(0xFF5865F2),
                      child: const Icon(Icons.discord, color: Colors.white),
                    ),
            ),
          ),
          const SizedBox(width: 16),
          // Discord info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(
                      Icons.discord,
                      size: 16,
                      color: Color(0xFF5865F2),
                    ),
                    const SizedBox(width: 6),
                    const Text(
                      'Discord Linked',
                      style: TextStyle(
                        color: Color(0xFF5865F2),
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  discord.globalName ?? discord.username,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                if (discord.clan?.tag != null)
                  Container(
                    margin: const EdgeInsets.only(top: 4),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFF5865F2).withAlpha(50),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      discord.clan!.tag!,
                      style: const TextStyle(
                        color: Color(0xFF5865F2),
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          // Status
          if (discord.status != null)
            Container(
              width: 12,
              height: 12,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: _getStatusColor(discord.status!),
              ),
            ),
        ],
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'online':
        return Colors.green;
      case 'idle':
        return Colors.amber;
      case 'dnd':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  Widget _buildProfileInfo(AuthController authController) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.cardBlack,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.dividerColor),
      ),
      child: Column(
        children: [
          // Username field
          _buildInfoField(
            label: 'Username',
            value: authController.user?.username ?? '',
            icon: Icons.person_outline,
            isEditable: true,
          ),
          const Divider(color: AppTheme.dividerColor, height: 32),
          // Email field (read-only)
          _buildInfoField(
            label: 'Email',
            value: authController.user?.email ?? '',
            icon: Icons.email_outlined,
            isEditable: false,
          ),
        ],
      ),
    );
  }

  Widget _buildInfoField({
    required String label,
    required String value,
    required IconData icon,
    required bool isEditable,
  }) {
    return Row(
      children: [
        Icon(icon, color: AppTheme.accentPurple, size: 22),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  color: AppTheme.textGrey.withAlpha(150),
                  fontSize: 12,
                ),
              ),
              const SizedBox(height: 4),
              if (_isEditing && isEditable)
                TextField(
                  controller: _usernameController,
                  style: const TextStyle(color: Colors.white, fontSize: 16),
                  decoration: const InputDecoration(
                    isDense: true,
                    contentPadding: EdgeInsets.zero,
                    border: InputBorder.none,
                  ),
                )
              else
                Text(
                  value,
                  style: const TextStyle(color: Colors.white, fontSize: 16),
                ),
            ],
          ),
        ),
        if (isEditable && !_isEditing)
          IconButton(
            icon: const Icon(Icons.edit, color: AppTheme.textGrey, size: 20),
            onPressed: () => setState(() => _isEditing = true),
          ),
      ],
    );
  }

  Widget _buildStorageSection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.cardBlack,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.surfaceBlack),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          const Row(
            children: [
              Icon(Icons.storage, color: AppTheme.accentPurple, size: 24),
              SizedBox(width: 12),
              Text(
                'Storage',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Cache size display
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Image Cache',
                style: TextStyle(color: Colors.white, fontSize: 15),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: AppTheme.surfaceBlack,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  CacheSettings.formatSize(_currentCacheSize),
                  style: const TextStyle(
                    color: AppTheme.accentPurple,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Cache limit slider
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Cache Limit',
                style: TextStyle(color: Colors.white, fontSize: 15),
              ),
              Text(
                '${_cacheSettings.maxCacheSizeMB} MB',
                style: const TextStyle(color: AppTheme.textGrey),
              ),
            ],
          ),
          Slider(
            value: _cacheSettings.maxCacheSizeMB.toDouble(),
            min: 100,
            max: 1000,
            divisions: 9,
            activeColor: AppTheme.accentPurple,
            inactiveColor: AppTheme.surfaceBlack,
            onChanged: (value) {
              setState(() {
                _cacheSettings = _cacheSettings.copyWith(
                  maxCacheSizeMB: value.toInt(),
                );
              });
              _cacheSettings.save();
            },
          ),
          const SizedBox(height: 8),

          // Auto clear toggle
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Auto Clear Old Cache',
                      style: TextStyle(color: Colors.white, fontSize: 15),
                    ),
                    Text(
                      'Delete cache older than 7 days',
                      style: TextStyle(color: AppTheme.textGrey, fontSize: 12),
                    ),
                  ],
                ),
              ),
              Switch(
                value: _cacheSettings.autoCleanOldCache,
                activeThumbColor: AppTheme.accentPurple,
                onChanged: (value) {
                  setState(() {
                    _cacheSettings = _cacheSettings.copyWith(
                      autoCleanOldCache: value,
                    );
                  });
                  _cacheSettings.save();
                },
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Clear cache button
          GestureDetector(
            onTap: _isClearing ? null : _showClearCacheDialog,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 14),
              decoration: BoxDecoration(
                color: Colors.orange.withAlpha(20),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.orange.withAlpha(100)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (_isClearing)
                    const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.orange,
                      ),
                    )
                  else
                    const Icon(Icons.delete_sweep, color: Colors.orange),
                  const SizedBox(width: 8),
                  Text(
                    _isClearing ? 'Clearing...' : 'Clear Cache',
                    style: const TextStyle(
                      color: Colors.orange,
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLogoutButton() {
    return GestureDetector(
      onTap: _handleLogout,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: Colors.red.withAlpha(20),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.red.withAlpha(100)),
        ),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.logout, color: Colors.red),
            SizedBox(width: 8),
            Text(
              'Logout',
              style: TextStyle(
                color: Colors.red,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
