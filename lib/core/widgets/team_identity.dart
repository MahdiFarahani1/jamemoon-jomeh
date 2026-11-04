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
    TeamIconOption('trophy', 'جام قهرمانی', Icons.emoji_events_rounded),
    TeamIconOption('heart', 'قلب', Icons.favorite_rounded),
    TeamIconOption('robot', 'ربات', Icons.smart_toy_rounded),
    TeamIconOption('danger', 'خطر', Icons.dangerous_rounded),
    TeamIconOption('target', 'نشانه', Icons.track_changes_rounded),
    TeamIconOption('dice', 'تاس شانس', Icons.casino_rounded),
    TeamIconOption('sun', 'خورشید', Icons.wb_sunny_rounded),
    TeamIconOption('brain', 'مغز متفکر', Icons.psychology_rounded),
    TeamIconOption('bomb', 'بمب', Icons.crisis_alert_rounded),
    TeamIconOption('soccer', 'فوتبال', Icons.sports_soccer_rounded),
    TeamIconOption('basketball', 'بسکتبال', Icons.sports_basketball_rounded),
    TeamIconOption('medal', 'مدال', Icons.military_tech_rounded),
    TeamIconOption('music', 'موسیقی', Icons.music_note_rounded),
    TeamIconOption('party', 'جشن', Icons.celebration_rounded),
    TeamIconOption('palette', 'هنر', Icons.palette_rounded),
    TeamIconOption('snow', 'برف', Icons.ac_unit_rounded),
    TeamIconOption('flight', 'پرواز', Icons.flight_takeoff_rounded),
    TeamIconOption('lightbulb', 'ایده', Icons.lightbulb_rounded),
    TeamIconOption('person', 'کاپیتان', Icons.person_rounded),
    TeamIconOption('fitness', 'قدرت', Icons.fitness_center_rounded),
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

  static Future<(String, int, String)?> show(BuildContext context, Team team) =>
      showModalBottomSheet<(String, int, String)>(
        context: context,
        isScrollControlled: true,
        builder: (_) => TeamAppearanceSheet(team: team),
      );

  @override
  State<TeamAppearanceSheet> createState() => _TeamAppearanceSheetState();
}

class _TeamAppearanceSheetState extends State<TeamAppearanceSheet> {
  final ValueNotifier<int> _revision = ValueNotifier(0);
  late final TextEditingController _name = TextEditingController(
    text: widget.team.name,
  );
  late int _color = widget.team.colorValue;
  late String _icon = widget.team.iconKey;

  @override
  void dispose() {
    _name.dispose();
    _revision.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => ValueListenableBuilder<int>(
    valueListenable: _revision,
    builder: (context, _, _) => SafeArea(
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
                      child: TextField(
                        controller: _name,
                        maxLength: 32,
                        decoration: const InputDecoration(labelText: 'نام تیم'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 22),
                TeamAppearancePicker(
                  colorValue: _color,
                  iconKey: _icon,
                  onColorChanged: (value) {
                    _color = value;
                    _revision.value++;
                  },
                  onIconChanged: (value) {
                    _icon = value;
                    _revision.value++;
                  },
                ),
                const SizedBox(height: 24),
                PartyButton(
                  label: 'ذخیرهٔ تیم',
                  icon: Icons.check_rounded,
                  onPressed: () {
                    final name = _name.text.trim();
                    if (name.isEmpty) return;
                    Navigator.of(context).pop((name, _color, _icon));
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    ),
  );
}
