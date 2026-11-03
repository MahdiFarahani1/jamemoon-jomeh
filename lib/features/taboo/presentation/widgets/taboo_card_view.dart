import 'package:flutter/material.dart';

import '../../../../app/theme/app_typography.dart';
import '../../../../core/widgets/brand_mark.dart';
import '../../data/taboo_card_model.dart';

class TabooCardView extends StatelessWidget {
  const TabooCardView({super.key, required this.card});
  final TabooCard card;
  static const _ink = Color(0xFF462B31);
  static const _muted = Color(0xFF83585C);
  @override
  Widget build(BuildContext context) => SingleChildScrollView(
    child: PartyEntrance(
      key: ValueKey(card.word),
      offset: 10,
      duration: const Duration(milliseconds: 200),
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          color: const Color(0xFFFFF0E9),
          borderRadius: BorderRadius.circular(28),
          boxShadow: const [
            BoxShadow(
              color: Color(0x22000000),
              blurRadius: 24,
              offset: Offset(0, 8),
            ),
          ],
        ),
        padding: const EdgeInsets.all(22),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    card.category,
                    style: AppTypography.bodySmall.copyWith(
                      color: _muted,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                const Icon(
                  Icons.chat_bubble_outline_rounded,
                  color: _muted,
                  size: 21,
                ),
              ],
            ),
            const SizedBox(height: 20),
            Text(
              card.word,
              style: AppTypography.gameCardTitle.copyWith(
                color: _ink,
                fontSize: 36,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                const Expanded(child: Divider(color: Color(0xFFDCC1BD))),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  child: Text(
                    'این‌ها رو نگو!',
                    style: AppTypography.bodySmall.copyWith(
                      color: _muted,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                const Expanded(child: Divider(color: Color(0xFFDCC1BD))),
              ],
            ),
            const SizedBox(height: 12),
            for (final word in card.forbiddenWords)
              Container(
                margin: const EdgeInsets.only(bottom: 7),
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 9,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFF2DDD8),
                  borderRadius: BorderRadius.circular(13),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.block_rounded, color: _muted, size: 17),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        word,
                        textAlign: TextAlign.center,
                        style: AppTypography.titleLarge.copyWith(
                          color: _ink,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    const SizedBox(width: 29),
                  ],
                ),
              ),
          ],
        ),
      ),
    ),
  );
}
