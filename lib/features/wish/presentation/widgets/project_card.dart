import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../data/project_model.dart';
import '../../../../core/theme.dart';

class ProjectCard extends StatefulWidget {
  final ProjectModel project;
  final VoidCallback onTap;

  /// true이면 게이지바가 0%에서 실제 진행률까지 애니메이션
  final bool animate;

  /// 애니메이션 완료 콜백 — 완료 후 상위에서 animate 플래그 초기화용
  final VoidCallback? onAnimationEnd;

  const ProjectCard({
    super.key,
    required this.project,
    required this.onTap,
    this.animate = false,
    this.onAnimationEnd,
  });

  @override
  State<ProjectCard> createState() => _ProjectCardState();
}

class _ProjectCardState extends State<ProjectCard>
    with TickerProviderStateMixin {
  late AnimationController _controller;
  late AnimationController _entranceController;
  late Animation<double> _progressAnimation;
  late Animation<double> _entranceOpacity;
  late Animation<Offset> _entranceOffset;

  double get _targetProgress => widget.project.targetAmount > 0
      ? (widget.project.currentAmount / widget.project.targetAmount)
          .clamp(0.0, 1.0)
      : 0.0;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );

    _entranceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _entranceOpacity = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _entranceController, curve: Curves.easeOut),
    );
    _entranceOffset = Tween<Offset>(
      begin: const Offset(0, 24),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _entranceController,
      curve: Curves.easeOut,
    ));

    if (widget.animate) {
      _progressAnimation = Tween<double>(
        begin: 0.0,
        end: _targetProgress,
      ).animate(CurvedAnimation(
        parent: _controller,
        curve: Curves.easeOut,
      ));
      _entranceController.forward();
      Future.delayed(const Duration(milliseconds: 300), () {
        if (mounted) {
          _controller.forward().then((_) {
            widget.onAnimationEnd?.call();
          });
        }
      });
    } else {
      _progressAnimation = AlwaysStoppedAnimation(_targetProgress);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _entranceController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final endDate = widget.project.endDate ?? DateTime.now();
    final int dDay = endDate.difference(DateTime.now()).inDays;
    final String dDayText = dDay >= 0 ? "D-$dDay" : "종료";

    final formatter = NumberFormat('#,###');

    Widget card = GestureDetector(
      onTap: widget.onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 15,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(20),
              ),
              child: Stack(
                children: [
                  widget.project.thumbnailUrl != null &&
                          widget.project.thumbnailUrl!.isNotEmpty
                      ? Image.network(
                          widget.project.thumbnailUrl!,
                          height: 180,
                          width: double.infinity,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) =>
                              Container(
                                height: 180,
                                color: Colors.grey[200],
                                child: const Icon(
                                  Icons.broken_image,
                                  color: Colors.grey,
                                ),
                              ),
                        )
                      : Container(
                          height: 180,
                          color: Colors.grey[200],
                          child: const Center(
                            child: Icon(
                              Icons.image,
                              size: 50,
                              color: Colors.grey,
                            ),
                          ),
                        ),
                  Positioned(
                    top: 16,
                    right: 16,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: dDay >= 0 ? AppTheme.primary : Colors.grey,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        dDayText,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.project.title,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textHeading,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    widget.project.description ?? '',
                    style: const TextStyle(
                      fontSize: 14,
                      color: AppTheme.textBody,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 16),
                  AnimatedBuilder(
                    animation: _progressAnimation,
                    builder: (context, child) {
                      final animatedProgress = _progressAnimation.value;
                      final animatedPercent = (animatedProgress * 100).toInt();

                      return Column(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(4),
                            child: LinearProgressIndicator(
                              value: animatedProgress,
                              backgroundColor: Colors.grey[100],
                              valueColor:
                                  const AlwaysStoppedAnimation<Color>(
                                AppTheme.primary,
                              ),
                              minHeight: 6,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                "$animatedPercent% 달성",
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: AppTheme.primary,
                                  fontSize: 12,
                                ),
                              ),
                              Text(
                                "${formatter.format(widget.project.targetAmount)}원",
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: AppTheme.textHeading,
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        ],
                      );
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );

    if (widget.animate) {
      return AnimatedBuilder(
        animation: _entranceController,
        builder: (context, child) {
          return Transform.translate(
            offset: _entranceOffset.value,
            child: Opacity(
              opacity: _entranceOpacity.value,
              child: card,
            ),
          );
        },
      );
    }
    return card;
  }
}
