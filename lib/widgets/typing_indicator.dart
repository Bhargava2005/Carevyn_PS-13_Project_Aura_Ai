// lib/widgets/typing_indicator.dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../utils/app_theme.dart';

class TypingIndicator extends StatefulWidget {
  const TypingIndicator({super.key});
  @override
  State<TypingIndicator> createState() => _TypingIndicatorState();
}

class _TypingIndicatorState extends State<TypingIndicator> with TickerProviderStateMixin {
  late List<AnimationController> _ctrls;
  late List<Animation<double>> _anims;

  @override
  void initState() {
    super.initState();
    _ctrls = List.generate(3, (i) =>
        AnimationController(vsync: this, duration: const Duration(milliseconds: 550)));
    _anims = _ctrls.map((c) =>
        Tween<double>(begin: 0, end: 1).animate(CurvedAnimation(parent: c, curve: Curves.easeInOut))).toList();
    for (int i = 0; i < 3; i++) {
      Future.delayed(Duration(milliseconds: i * 190), () {
        if (mounted) _ctrls[i].repeat(reverse: true);
      });
    }
  }

  @override
  void dispose() { for (final c in _ctrls) c.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          // Neural AI avatar
          Container(
            width: 30, height: 30,
            decoration: BoxDecoration(
              color: AppTheme.bgSurface,
              borderRadius: BorderRadius.circular(9),
              border: Border.all(color: AppTheme.primary.withOpacity(0.4)),
            ),
            child: Center(
              child: ShaderMask(
                shaderCallback: (b) => const LinearGradient(
                    colors: [Color(0xFF00C9FF), Color(0xFF7B5EA7)]).createShader(b),
                child: const Icon(Icons.hub_outlined, size: 15, color: Colors.white),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: AppTheme.aiBubble,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(18), topRight: Radius.circular(18),
                bottomRight: Radius.circular(18), bottomLeft: Radius.circular(4),
              ),
              border: Border.all(color: AppTheme.divider),
            ),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              Text('Thinking',
                  style: GoogleFonts.dmSans(color: AppTheme.textSecondary, fontSize: 13, fontStyle: FontStyle.italic)),
              const SizedBox(width: 8),
              ...List.generate(3, (i) => AnimatedBuilder(
                animation: _anims[i],
                builder: (_, __) => Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 2),
                  child: Transform.translate(
                    offset: Offset(0, -4 * _anims[i].value),
                    child: Container(
                      width: 5, height: 5,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Color.lerp(
                          AppTheme.primary.withOpacity(0.3),
                          AppTheme.primary,
                          _anims[i].value,
                        ),
                      ),
                    ),
                  ),
                ),
              )),
            ]),
          ),
        ],
      ),
    );
  }
}