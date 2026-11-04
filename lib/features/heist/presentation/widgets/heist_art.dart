import 'package:flutter/material.dart';

class HeistAtlasTile extends StatelessWidget {
  const HeistAtlasTile({
    super.key,
    required this.asset,
    required this.columns,
    required this.rows,
    required this.index,
    this.borderRadius = 24,
  });

  final String asset;
  final int columns;
  final int rows;
  final int index;
  final double borderRadius;

  @override
  Widget build(BuildContext context) => ClipRRect(
    borderRadius: BorderRadius.circular(borderRadius),
    child: LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final height = constraints.maxHeight;
        final column = index % columns;
        final row = index ~/ columns;
        return Stack(
          clipBehavior: Clip.hardEdge,
          children: [
            Positioned(
              left: -column * width,
              top: -row * height,
              width: width * columns,
              height: height * rows,
              child: Image.asset(asset, fit: BoxFit.fill),
            ),
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  border: Border.all(
                    color: const Color(0x66D6A84B),
                    width: 1.2,
                  ),
                  borderRadius: BorderRadius.circular(borderRadius),
                ),
              ),
            ),
          ],
        );
      },
    ),
  );
}

class HeistBackdrop extends StatelessWidget {
  const HeistBackdrop({super.key, required this.child, this.hero = false});
  final Widget child;
  final bool hero;

  @override
  Widget build(BuildContext context) => Stack(
    fit: StackFit.expand,
    children: [
      Image.asset(
        'assets/heist/heist_vault_hero.png',
        fit: BoxFit.cover,
        alignment: hero ? Alignment.center : Alignment.topCenter,
      ),
      const DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xB8080A0F), Color(0xF20A0C12), Color(0xFF080A0F)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            stops: [0, .58, 1],
          ),
        ),
      ),
      const _SecuritySweep(),
      SafeArea(child: child),
    ],
  );
}

class _SecuritySweep extends StatefulWidget {
  const _SecuritySweep();
  @override
  State<_SecuritySweep> createState() => _SecuritySweepState();
}

class _SecuritySweepState extends State<_SecuritySweep>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 5),
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MediaQuery.disableAnimationsOf(context)) {
      _controller.value = .45;
    } else if (!_controller.isAnimating) {
      _controller.repeat(reverse: true);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => IgnorePointer(
    child: AnimatedBuilder(
      animation: _controller,
      builder: (context, _) =>
          CustomPaint(painter: _SecuritySweepPainter(_controller.value)),
    ),
  );
}

class _SecuritySweepPainter extends CustomPainter {
  const _SecuritySweepPainter(this.progress);
  final double progress;
  @override
  void paint(Canvas canvas, Size size) {
    final y = size.height * (.16 + progress * .5);
    canvas.drawRect(
      Rect.fromLTWH(0, y, size.width, 2),
      Paint()
        ..shader = const LinearGradient(
          colors: [Colors.transparent, Color(0xAFFF304A), Colors.transparent],
        ).createShader(Rect.fromLTWH(0, y, size.width, 2)),
    );
    for (var i = 0; i < 18; i++) {
      final dx = size.width * ((i * .173 + progress * .08) % 1);
      final dy = size.height * ((i * .119 + progress * .16) % 1);
      canvas.drawCircle(
        Offset(dx, dy),
        1 + i % 2,
        Paint()..color = const Color(0x66E6B85C),
      );
    }
  }

  @override
  bool shouldRepaint(covariant _SecuritySweepPainter oldDelegate) =>
      oldDelegate.progress != progress;
}

class HeistPanel extends StatelessWidget {
  const HeistPanel({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(18),
  });
  final Widget child;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) => Container(
    padding: padding,
    decoration: BoxDecoration(
      color: const Color(0xE6191B22),
      borderRadius: BorderRadius.circular(24),
      border: Border.all(color: const Color(0x665E4B2B)),
      boxShadow: const [
        BoxShadow(
          color: Color(0x99000000),
          blurRadius: 26,
          offset: Offset(0, 12),
        ),
      ],
    ),
    child: child,
  );
}

class HeistButton extends StatelessWidget {
  const HeistButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.danger = false,
    this.secondary = false,
  });
  final String label;
  final VoidCallback? onPressed;
  final bool danger;
  final bool secondary;

  @override
  Widget build(BuildContext context) => Semantics(
    button: true,
    enabled: onPressed != null,
    child: Opacity(
      opacity: onPressed == null ? .45 : 1,
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: secondary
                ? const [Color(0xFF2B2D35), Color(0xFF1C1E25)]
                : danger
                ? const [Color(0xFFC93645), Color(0xFF751F2D)]
                : const [Color(0xFFE7BE67), Color(0xFF9B6A20)],
          ),
          borderRadius: BorderRadius.circular(17),
          border: Border.all(color: const Color(0x66FFF1C7)),
          boxShadow: const [
            BoxShadow(
              color: Color(0x66000000),
              blurRadius: 12,
              offset: Offset(0, 5),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onPressed,
            borderRadius: BorderRadius.circular(17),
            child: ConstrainedBox(
              constraints: const BoxConstraints(minHeight: 54),
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  child: Text(
                    label,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: secondary
                          ? const Color(0xFFF4E9D3)
                          : const Color(0xFF17120A),
                      fontWeight: FontWeight.w900,
                      fontSize: 16,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    ),
  );
}
