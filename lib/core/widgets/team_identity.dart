import 'package:flutter/material.dart';

import '../../app/theme/app_colors.dart';
import '../../app/theme/app_typography.dart';
import '../models/team_model.dart';
import 'party_button.dart';

class TeamIconOption {
  const TeamIconOption(this.key, this.label, this.icon);
  final String key;
  final String label;
  final IconData icon;
}

abstract final class TeamIcons {
  static const options = <TeamIconOption>[
    TeamIconOption('star', 'ستاره', Icons.auto_awesome_rounded),
    TeamIconOption('flash', 'آذرخش', Icons.bolt_rounded),
    TeamIconOption('rocket', 'موشک', Icons.rocket_launch_rounded),
    TeamIconOption('flame', 'آتش', Icons.local_fire_department_rounded),
    TeamIconOption('crown', 'تاج', Icons.workspace_premium_rounded),
    TeamIconOption('shield', 'سپر', Icons.shield_rounded),
    TeamIconOption('gamepad', 'دستهٔ بازی', Icons.sports_esports_rounded),
    TeamIconOption('paw', 'پنجه', Icons.pets_rounded),
    TeamIconOption('moon', 'ماه', Icons.nights_stay_rounded),
    TeamIconOption('diamond', 'الماس', Icons.diamond_rounded),
  ];

  static IconData forKey(String key) {
    for (final option in options) {
      if (option.key == key) return option.icon;
    }
    return Icons.auto_awesome_rounded;
  }
}

class TeamAvatar extends StatelessWidget {
  const TeamAvatar({super.key, required this.team, this.size = 46});
  final Team team;
  final double size;

  @override
  Widget build(BuildContext context) {
    final color = Color(team.colorValue);
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color.withValues(alpha: .17),
        borderRadius: BorderRadius.circular(size * .32),
        border: Border.all(color: color.withValues(alpha: .65), width: 1.5),
      ),
      child: Icon(
        TeamIcons.forKey(team.iconKey),
        color: color,
        size: size * .55,
      ),
    );
  }
}

class TeamAppearancePicker extends StatelessWidget {
  const TeamAppearancePicker({
    super.key,
    required this.colorValue,
    required this.iconKey,
    required this.onColorChanged,
    required this.onIconChanged,
  });
  final int colorValue;
  final String iconKey;
  final ValueChanged<int> onColorChanged;
  final ValueChanged<String> onIconChanged;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      const Text('رنگ تیم', style: AppTypography.titleLarge),
      const SizedBox(height: 10),
      Wrap(
        spacing: 9,
        runSpacing: 9,
        children: [
          for (var i = 0; i < AppColors.teamPalette.length; i++)
            Semantics(
              label: 'رنگ شمارهٔ ${i + 1}',
              button: true,
              selected: colorValue == AppColors.teamPalette[i].toARGB32(),
              child: InkWell(
                onTap: () =>
                    onColorChanged(AppColors.teamPalette[i].toARGB32()),
                customBorder: const CircleBorder(),
                child: Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: AppColors.teamPalette[i],
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: colorValue == AppColors.teamPalette[i].toARGB32()
                          ? Colors.white
                          : AppColors.surfaceBorder,
                      width: colorValue == AppColors.teamPalette[i].toARGB32()
                          ? 3
                          : 1,
                    ),
                  ),
                  child: colorValue == AppColors.teamPalette[i].toARGB32()
                      ? const Icon(
                          Icons.check_rounded,
                          color: AppColors.background,
                        )
                      : null,
                ),
              ),
            ),
        ],
      ),
      const SizedBox(height: 22),
      const Text('نشان تیم', style: AppTypography.titleLarge),
      const SizedBox(height: 10),
      Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          for (final option in TeamIcons.options)
            Semantics(
              label: 'نشان ${option.label}',
              button: true,
              selected: iconKey == option.key,
              child: InkWell(
                onTap: () => onIconChanged(option.key),
                borderRadius: BorderRadius.circular(15),
                child: Container(
                  width: 76,
                  height: 70,
                  decoration: BoxDecoration(
                    color: iconKey == option.key
                        ? Color(colorValue).withValues(alpha: .22)
                        : AppColors.surfaceLight,
                    borderRadius: BorderRadius.circular(15),
                    border: Border.all(
                      color: iconKey == option.key
                          ? Color(colorValue)
                          : AppColors.surfaceBorder,
                      width: iconKey == option.key ? 2 : 1,
                    ),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        option.icon,
                        color: iconKey == option.key
                            ? Color(colorValue)
                            : AppColors.textHeadline,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        option.label,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTypography.bodySmall.copyWith(fontSize: 10),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    ],
  );
}

class TeamAppearanceSheet extends StatefulWidget {
  const TeamAppearanceSheet({super.key, required this.team});
  final Team team;

  static Future<(int, String)?> show(BuildContext context, Team team) =>
      showModalBottomSheet<(int, String)>(
        context: context,
        isScrollControlled: true,
        builder: (_) => TeamAppearanceSheet(team: team),
      );

  @override
  State<TeamAppearanceSheet> createState() => _TeamAppearanceSheetState();
}

class _TeamAppearanceSheetState extends State<TeamAppearanceSheet> {
  late int _color = widget.team.colorValue;
  late String _icon = widget.team.iconKey;

  @override
  Widget build(BuildContext context) => SafeArea(
    child: Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 540),
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 14, 20, 28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  TeamAvatar(
                    team: widget.team.copyWith(
                      colorValue: _color,
                      iconKey: _icon,
                    ),
                    size: 58,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      widget.team.name,
                      style: AppTypography.headlineLarge,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 22),
              TeamAppearancePicker(
                colorValue: _color,
                iconKey: _icon,
                onColorChanged: (value) => setState(() => _color = value),
                onIconChanged: (value) => setState(() => _icon = value),
              ),
              const SizedBox(height: 24),
              PartyButton(
                label: 'ذخیرهٔ ظاهر تیم',
                icon: Icons.check_rounded,
                onPressed: () => Navigator.of(context).pop((_color, _icon)),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}
