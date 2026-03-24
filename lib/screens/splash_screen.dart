// lib/screens/splash_screen.dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../providers/chat_provider.dart';
import '../utils/app_theme.dart';
import '../widgets/neural_logo.dart';
import 'chat_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});
  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _rise, _fade;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 1300));
    _rise = Tween<double>(begin: 30, end: 0).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOutCubic));
    _fade = Tween<double>(begin: 0, end: 1).animate(CurvedAnimation(parent: _ctrl, curve: const Interval(0.0, 0.65)));
    _ctrl.forward();
    _initApp();
  }

  Future<void> _initApp() async {
    await Future.delayed(const Duration(milliseconds: 2000));
    if (!mounted) return;
    await context.read<ChatProvider>().initialize();
    if (!mounted) return;
    Navigator.of(context).pushReplacement(PageRouteBuilder(
      pageBuilder: (_, __, ___) => const ChatScreen(embedded: true,),
      transitionsBuilder: (_, anim, __, child) => FadeTransition(opacity: anim, child: child),
      transitionDuration: const Duration(milliseconds: 400),
    ));
  }

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bgDark,
      body: Stack(children: [
        // Background subtle glow
        Positioned.fill(
          child: Container(
            decoration: const BoxDecoration(
              gradient: RadialGradient(
                center: Alignment.center, radius: 0.8,
                colors: [Color(0xFF0A1525), Color(0xFF090E1A)],
              ),
            ),
          ),
        ),
        Center(
          child: AnimatedBuilder(
            animation: _ctrl,
            builder: (_, __) => Transform.translate(
              offset: Offset(0, _rise.value),
              child: Opacity(
                opacity: _fade.value,
                child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                  const NeuralLogo(size: 96),
                  const SizedBox(height: 26),
                  ShaderMask(
                    shaderCallback: (b) => const LinearGradient(
                      colors: [Color(0xFF00C9FF), Color(0xFF7B5EA7)],
                    ).createShader(b),
                    child: Text('Aura AI',
                        style: GoogleFonts.spaceGrotesk(
                            color: Colors.white, fontSize: 34, fontWeight: FontWeight.w700, letterSpacing: -0.5)),
                  ),
                  const SizedBox(height: 8),
                  Text('Neural-powered intelligence',
                      style: GoogleFonts.dmSans(color: AppTheme.textSecondary, fontSize: 14)),
                  const SizedBox(height: 56),
                  _PulseDots(),
                ]),
              ),
            ),
          ),
        ),
      ]),
    );
  }
}

class _PulseDots extends StatefulWidget {
  @override
  State<_PulseDots> createState() => _PulseDotsState();
}

class _PulseDotsState extends State<_PulseDots> with TickerProviderStateMixin {
  late List<AnimationController> _ctrls;
  late List<Animation<double>> _anims;

  @override
  void initState() {
    super.initState();
    _ctrls = List.generate(3, (i) =>
        AnimationController(vsync: this, duration: const Duration(milliseconds: 520)));
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
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(3, (i) => AnimatedBuilder(
        animation: _anims[i],
        builder: (_, __) => Container(
          margin: const EdgeInsets.symmetric(horizontal: 4),
          width: 7, height: 7,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Color.lerp(AppTheme.primary.withOpacity(0.25), AppTheme.secondary, _anims[i].value),
          ),
        ),
      )),
    );
  }
}