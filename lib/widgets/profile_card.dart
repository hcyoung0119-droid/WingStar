import 'dart:convert';
import 'package:flutter/material.dart';

class ProfileStyles {
  static const colors = <String, (String, Color, Color)>{
    'sky': ('하늘', Color(0xFF306E92), Color(0xFF389CAA)),
    'mint': ('숲', Color(0xFF247464), Color(0xFF579A79)),
    'lavender': ('라벤더', Color(0xFF665B9B), Color(0xFF9682B5)),
    'sunset': ('노을', Color(0xFF9A5447), Color(0xFFC67F4E)),
  };
  static const badges = <String, (String, IconData)>{
    'leaf': ('새싹', Icons.eco_rounded),
    'sparkle': ('반짝임', Icons.auto_awesome_rounded),
    'walk': ('발걸음', Icons.directions_walk_rounded),
    'heart': ('마음', Icons.favorite_rounded),
  };
}

class ProfileCard extends StatelessWidget {
  const ProfileCard({
    super.key,
    required this.name,
    required this.job,
    required this.bio,
    required this.photo,
    required this.color,
    required this.badge,
    this.onEdit,
    this.footer,
  });
  final String name, job, bio, photo, color, badge;
  final VoidCallback? onEdit;
  final Widget? footer;

  @override
  Widget build(BuildContext context) {
    final style = ProfileStyles.colors[color] ?? ProfileStyles.colors['sky']!;
    final decoration =
        ProfileStyles.badges[badge] ?? ProfileStyles.badges['leaf']!;
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [style.$2, style.$3],
        ),
        boxShadow: [
          BoxShadow(
            color: style.$2.withValues(alpha: .2),
            blurRadius: 24,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            right: -36,
            top: -54,
            child: ExcludeSemantics(
              child: Icon(
                Icons.circle_outlined,
                size: 220,
                color: Colors.white.withValues(alpha: .09),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(22),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Expanded(
                      child: Text(
                        'WINGSTAR  /  MY SPACE',
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 10,
                          letterSpacing: 1.8,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    if (onEdit != null)
                      IconButton(
                        key: const Key('edit-profile'),
                        tooltip: '프로필 꾸미기',
                        onPressed: onEdit,
                        icon: const Icon(
                          Icons.edit_outlined,
                          size: 20,
                          color: Colors.white,
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 14),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Stack(
                      clipBehavior: Clip.none,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: Colors.white54,
                              width: 1.5,
                            ),
                          ),
                          child: ProfileAvatar(photo: photo, name: name),
                        ),
                        Positioned(
                          right: -3,
                          bottom: -2,
                          child: Container(
                            padding: const EdgeInsets.all(6),
                            decoration: const BoxDecoration(
                              shape: BoxShape.circle,
                              color: Color(0xFFFFE3A3),
                            ),
                            child: Icon(
                              decoration.$2,
                              size: 17,
                              color: const Color(0xFF71551C),
                              semanticLabel: decoration.$1,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            name.isEmpty ? '나의 프로필' : name,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 22,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          if (job.isNotEmpty)
                            Padding(
                              padding: const EdgeInsets.only(top: 5),
                              child: Text(
                                job,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  color: Colors.white70,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                Text(
                  bio.isEmpty ? '나만의 속도로, 오늘도 한 걸음.' : bio,
                  style: const TextStyle(
                    color: Colors.white,
                    height: 1.6,
                    fontSize: 13,
                  ),
                ),
                if (footer != null) ...[
                  const Divider(color: Colors.white24, height: 30),
                  footer!,
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class ProfileAvatar extends StatelessWidget {
  const ProfileAvatar({super.key, required this.photo, required this.name});
  final String photo, name;
  @override
  Widget build(BuildContext context) {
    final fallback = Center(
      child: Text(
        name.isEmpty ? 'W' : name.characters.first,
        style: const TextStyle(
          fontSize: 28,
          fontWeight: FontWeight.w800,
          color: Color(0xFF306E92),
        ),
      ),
    );
    Widget content = fallback;
    if (photo.startsWith('data:image/jpeg;base64,')) {
      try {
        content = Image.memory(
          base64Decode(photo.split(',').last),
          width: 72,
          height: 72,
          fit: BoxFit.cover,
          gaplessPlayback: true,
          semanticLabel: '프로필 사진',
          errorBuilder: (_, _, _) => fallback,
        );
      } catch (_) {
        content = fallback;
      }
    }
    return ClipOval(
      child: ColoredBox(
        color: const Color(0xFFE9F6FC),
        child: SizedBox(width: 72, height: 72, child: content),
      ),
    );
  }
}
