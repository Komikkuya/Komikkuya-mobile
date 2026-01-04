/// User profile model
class User {
  final int id;
  final String email;
  final String username;
  final String? profilePicture;
  final String? discordId;

  User({
    required this.id,
    required this.email,
    required this.username,
    this.profilePicture,
    this.discordId,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] as int,
      email: json['email'] as String,
      username: json['username'] as String,
      profilePicture: json['profile_picture'] as String?,
      discordId: json['discord_id'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'email': email,
    'username': username,
    'profile_picture': profilePicture,
    'discord_id': discordId,
  };
}

/// Discord profile linked to user
class DiscordProfile {
  final String id;
  final String username;
  final String? globalName;
  final String? avatar;
  final String? banner;
  final String? avatarDecoration;
  final DiscordClan? clan;
  final String? status;
  final List<dynamic>? activities;

  DiscordProfile({
    required this.id,
    required this.username,
    this.globalName,
    this.avatar,
    this.banner,
    this.avatarDecoration,
    this.clan,
    this.status,
    this.activities,
  });

  factory DiscordProfile.fromJson(Map<String, dynamic> json) {
    return DiscordProfile(
      id: json['id'] as String,
      username: json['username'] as String,
      globalName: json['global_name'] as String?,
      avatar: json['avatar'] as String?,
      banner: json['banner'] as String?,
      avatarDecoration: json['avatar_decoration'] as String?,
      clan: json['clan'] != null ? DiscordClan.fromJson(json['clan']) : null,
      status: json['status'] as String?,
      activities: json['activities'] as List<dynamic>?,
    );
  }
}

/// Discord clan info
class DiscordClan {
  final String? tag;
  final String? badge;

  DiscordClan({this.tag, this.badge});

  factory DiscordClan.fromJson(Map<String, dynamic> json) {
    return DiscordClan(
      tag: json['tag'] as String?,
      badge: json['badge'] as String?,
    );
  }
}

/// Auth API response model
class AuthResponse {
  final bool success;
  final String? message;
  final User? user;
  final String? token;
  final DiscordProfile? discord;

  AuthResponse({
    required this.success,
    this.message,
    this.user,
    this.token,
    this.discord,
  });

  factory AuthResponse.fromJson(Map<String, dynamic> json) {
    final data = json['data'] as Map<String, dynamic>?;

    User? user;
    if (data?['user'] != null) {
      user = User.fromJson(data!['user'] as Map<String, dynamic>);
    }

    DiscordProfile? discord;
    if (data?['discord'] != null) {
      discord = DiscordProfile.fromJson(
        data!['discord'] as Map<String, dynamic>,
      );
    }

    return AuthResponse(
      success: json['success'] as bool? ?? false,
      message: json['message'] as String?,
      user: user,
      token: data?['token'] as String?,
      discord: discord,
    );
  }
}
