import 'package:flutter/material.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scale;
  late Animation<double> _opacity;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    _scale = Tween<double>(begin: 0.85, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: const Cubic(0.16, 1.0, 0.3, 1.0)),
    );
    _opacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: const Interval(0.0, 0.4, curve: Curves.easeOut)),
    );
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final d = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: d ? const Color(0xFF000000) : const Color(0xFFFFFFFF),
      body: Center(
        child: FadeTransition(
          opacity: _opacity,
          child: ScaleTransition(
            scale: _scale,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: const Color(0xFF5C5FE0),
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: const Center(
                    child: Text('S', style: TextStyle(color: Colors.white, fontSize: 36, fontWeight: FontWeight.w600)),
                  ),
                ),
                const SizedBox(height: 24),
                Text('SnapCal', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w600, color: d ? Colors.white : Colors.black)),
                const SizedBox(height: 4),
                Text('Calorie Tracker', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w400, color: d ? Colors.white38 : const Color(0xFF8E8E93))),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
