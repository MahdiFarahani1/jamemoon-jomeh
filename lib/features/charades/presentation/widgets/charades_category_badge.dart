import 'package:flutter/material.dart';

class CharadesCategoryStyle {
  const CharadesCategoryStyle(this.key, this.title, this.icon, this.color);

  final String key;
  final String title;
  final IconData icon;
  final Color color;

  static const categories = [
    CharadesCategoryStyle(
      'all',
      'همهٔ دسته‌ها',
      Icons.auto_awesome_rounded,
      Color(0xFFFFC857),
    ),
    CharadesCategoryStyle(
      'کارت‌های من',
      'کارت‌های من',
      Icons.style_rounded,
      Color(0xFFFFD18A),
    ),
    CharadesCategoryStyle(
      'کارها و حرکت‌ها',
      'کارها و حرکت‌ها',
      Icons.directions_run_rounded,
      Color(0xFF86D8F1),
    ),
    CharadesCategoryStyle(
      'چالش‌های نمایشی',
      'چالش‌های نمایشی',
      Icons.theater_comedy_rounded,
      Color(0xFFF4B6D2),
    ),
    CharadesCategoryStyle(
      'شخصیت‌ها',
      'شخصیت‌ها',
      Icons.masks_rounded,
      Color(0xFFC7A9F5),
    ),
    CharadesCategoryStyle(
      'حیوانات',
      'حیوانات',
      Icons.pets_rounded,
      Color(0xFF79D8B6),
    ),
    CharadesCategoryStyle(
      'خوراکی‌ها',
      'خوراکی‌ها',
      Icons.restaurant_rounded,
      Color(0xFFFFA37C),
    ),
    CharadesCategoryStyle(
      'وسایل',
      'وسایل',
      Icons.chair_alt_rounded,
      Color(0xFF8CC8F0),
    ),
    CharadesCategoryStyle(
      'طبیعت',
      'طبیعت',
      Icons.park_rounded,
      Color(0xFF98DE86),
    ),
    CharadesCategoryStyle(
      'شغل‌ها',
      'شغل‌ها',
      Icons.work_rounded,
      Color(0xFFDFB0F3),
    ),
    CharadesCategoryStyle(
      'ورزش‌ها',
      'ورزش‌ها',
      Icons.sports_soccer_rounded,
      Color(0xFFFFC681),
    ),
    CharadesCategoryStyle(
      'احساسات',
      'احساسات',
      Icons.mood_rounded,
      Color(0xFFFF9EB1),
    ),
    CharadesCategoryStyle(
      'جاها',
      'جاها',
      Icons.place_rounded,
      Color(0xFFA4B6FF),
    ),
  ];

  static CharadesCategoryStyle forKey(String key) => categories.firstWhere(
    (category) => category.key == key,
    orElse: () => categories.first,
  );
}

/// A distinct colored pictogram and sparkle for each acting category.
class CharadesCategoryBadge extends StatelessWidget {
  const CharadesCategoryBadge({
    super.key,
    required this.category,
    this.size = 36,
  });

  final CharadesCategoryStyle category;
  final double size;

  @override
  Widget build(BuildContext context) => SizedBox.square(
    dimension: size,
    child: Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          decoration: BoxDecoration(
            color: category.color.withValues(alpha: .18),
            shape: BoxShape.circle,
            border: Border.all(color: category.color.withValues(alpha: .6)),
          ),
          child: Center(
            child: Icon(category.icon, color: category.color, size: size * .58),
          ),
        ),
        Positioned(
          top: 0,
          right: 0,
          child: Container(
            width: size * .17,
            height: size * .17,
            decoration: BoxDecoration(
              color: category.color,
              shape: BoxShape.circle,
              border: Border.all(color: const Color(0xFF1C1D45), width: 1.5),
            ),
          ),
        ),
      ],
    ),
  );
}
