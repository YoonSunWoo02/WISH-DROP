import 'package:flutter/material.dart';
import 'package:intl/intl.dart'; // 금액 포맷팅을 위해 필요
import '../../data/project_model.dart';
import '../../../../core/theme.dart';

class ProjectCard extends StatelessWidget {
  final ProjectModel project;
  final VoidCallback onTap;

  const ProjectCard({super.key, required this.project, required this.onTap});

  @override
  Widget build(BuildContext context) {
    // 1. 진행률 계산 (0.0 ~ 1.0 사이 값)
    final double progress = project.targetAmount > 0
        ? (project.currentAmount / project.targetAmount).clamp(0.0, 1.0)
        : 0.0;

    // 2. 퍼센트 계산
    final int percent = (progress * 100).toInt();

    // 3. D-Day 계산 (endDate nullable 대응)
    final endDate = project.endDate ?? DateTime.now();
    final int dDay = endDate.difference(DateTime.now()).inDays;
    final String dDayText = dDay >= 0 ? "D-$dDay" : "종료";

    // 4. 금액 포맷팅 (350,000원 형식)
    final formatter = NumberFormat('#,###');

    return GestureDetector(
      onTap: onTap,
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
            // 썸네일 이미지 영역
            ClipRRect(
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(20),
              ),
              child: Stack(
                children: [
                  project.thumbnailUrl != null &&
                          project.thumbnailUrl!.isNotEmpty
                      ? Image.network(
                          project.thumbnailUrl!,
                          height: 180,
                          width: double.infinity,
                          fit: BoxFit.cover,
                          // 이미지 로딩 실패 시 처리
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
                  // 🔥 실제 데이터 기반 D-Day 배지
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
            // 텍스트 정보 영역
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    project.title,
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
                    project.description ?? '',
                    style: const TextStyle(
                      fontSize: 14,
                      color: AppTheme.textBody,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 16),
                  // 🔥 실제 진행률 바
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: progress,
                      backgroundColor: Colors.grey[100],
                      valueColor: const AlwaysStoppedAnimation<Color>(
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
                        "$percent% 달성", // 🔥 실제 퍼센트
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: AppTheme.primary,
                          fontSize: 12,
                        ),
                      ),
                      Text(
                        "${formatter.format(project.targetAmount)}원", // 🔥 실제 포맷팅된 목표 금액
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: AppTheme.textHeading,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
