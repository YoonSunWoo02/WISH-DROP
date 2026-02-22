import 'package:flutter/material.dart';

/// 리스트 아이템 스태거드 등장 애니메이션 (index 순서대로 딜레이 후 fadeIn + 살짝 올라옴)
class StaggerFadeIn extends StatefulWidget {
  final int index;
  final Widget child;
  final int delayMs;
  final int durationMs;

  const StaggerFadeIn({
    super.key,
    required this.index,
    required this.child,
    this.delayMs = 70,
    this.durationMs = 280,
  });

  @override
  State<StaggerFadeIn> createState() => _StaggerFadeInState();
}

class _StaggerFadeInState extends State<StaggerFadeIn>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _opacity;
  late Animation<Offset> _offset;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: widget.durationMs),
    );
    _opacity = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );
    _offset = Tween<Offset>(
      begin: const Offset(0, 12),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOut,
    ));
    Future.delayed(
      Duration(milliseconds: widget.index * widget.delayMs),
      () {
        if (mounted) _controller.forward();
      },
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Opacity(
          opacity: _opacity.value,
          child: Transform.translate(
            offset: _offset.value,
            child: widget.child,
          ),
        );
      },
    );
  }
}
