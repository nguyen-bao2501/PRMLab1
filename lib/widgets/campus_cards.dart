import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_dimens.dart';
import '../theme/app_typography.dart';
import 'campus_buttons.dart';

class CampusHeroCard extends StatelessWidget {
  const CampusHeroCard({
    super.key,
    required this.title,
    required this.subtitle,
    this.updateTime = '09:40',
  });

  final String title;
  final String subtitle;
  final String updateTime;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppDimens.space20),
      decoration: BoxDecoration(
        color: AppColors.heroBg,
        borderRadius: BorderRadius.circular(AppDimens.radiusCard),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: AppTypography.titleLarge.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: AppDimens.space6),
          Text(
            subtitle,
            style: AppTypography.bodyMedium.copyWith(
              color: Colors.white.withValues(alpha: 0.75),
            ),
          ),
          const SizedBox(height: AppDimens.space12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(AppDimens.radiusPill),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.refresh, color: Colors.white, size: 14),
                const SizedBox(width: 6),
                Text(
                  'Cập nhật lúc $updateTime',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class StatusBadgePill extends StatelessWidget {
  const StatusBadgePill({
    super.key,
    required this.label,
    this.statusType = StatusType.neutral,
    this.icon,
  });

  final String label;
  final StatusType statusType;
  final Widget? icon;

  @override
  Widget build(BuildContext context) {
    Color bg;
    Color fg;

    switch (statusType) {
      case StatusType.success:
        bg = AppColors.statusSuccessBg;
        fg = AppColors.statusSuccess;
        break;
      case StatusType.warning:
        bg = AppColors.statusWarningBg;
        fg = AppColors.statusWarning;
        break;
      case StatusType.danger:
        bg = AppColors.statusDangerBg;
        fg = AppColors.statusDanger;
        break;
      case StatusType.blue:
        bg = AppColors.statusBlueBg;
        fg = AppColors.statusBlue;
        break;
      case StatusType.neutral:
        bg = AppColors.statusNeutralBg;
        fg = AppColors.statusNeutral;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(AppDimens.radiusPill),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            icon!,
            const SizedBox(width: 4),
          ] else if (statusType == StatusType.success) ...[
            Container(
              width: 6,
              height: 6,
              decoration: BoxDecoration(
                color: fg,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 5),
          ],
          Text(
            label,
            style: AppTypography.labelSmall.copyWith(
              color: fg,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

enum StatusType { success, warning, danger, blue, neutral }

class MetricStatCard extends StatelessWidget {
  const MetricStatCard({
    super.key,
    required this.title,
    required this.value,
    required this.icon,
    required this.iconBg,
    required this.iconColor,
  });

  final String title;
  final String value;
  final IconData icon;
  final Color iconBg;
  final Color iconColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppDimens.space16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppDimens.radiusCard),
        border: Border.all(color: AppColors.borderCard),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: iconBg,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: iconColor, size: 22),
          ),
          const SizedBox(width: AppDimens.space12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title,
                  style: AppTypography.bodySmall.copyWith(
                    color: AppColors.textMuted,
                  ),
                ),
                Text(
                  value,
                  style: AppTypography.titleLarge.copyWith(
                    fontWeight: FontWeight.w800,
                    fontSize: 22,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class TeachingSessionCard extends StatelessWidget {
  const TeachingSessionCard({
    super.key,
    required this.subjectCode,
    required this.className,
    required this.room,
    required this.timeSlot,
    required this.statusLabel,
    required this.statusType,
    required this.actionText,
    required this.onAction,
    this.isActive = false,
  });

  final String subjectCode;
  final String className;
  final String room;
  final String timeSlot;
  final String statusLabel;
  final StatusType statusType;
  final String actionText;
  final VoidCallback onAction;
  final bool isActive;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppDimens.space12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppDimens.radiusCard),
        border: Border.all(
          color: isActive ? AppColors.statusSuccess.withValues(alpha: 0.6) : AppColors.borderCard,
          width: isActive ? 1.5 : 1.0,
        ),
      ),
      padding: const EdgeInsets.all(AppDimens.space16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Text(
                    subjectCode,
                    style: AppTypography.titleLarge.copyWith(
                      fontWeight: FontWeight.w800,
                      fontSize: 18,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceMuted,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      className,
                      style: AppTypography.labelSmall.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ),
                ],
              ),
              StatusBadgePill(label: statusLabel, statusType: statusType),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            'Phòng học: $room',
            style: AppTypography.bodySmall.copyWith(
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: AppColors.surfaceMuted,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                const Icon(Icons.access_time_rounded, size: 16, color: AppColors.textMuted),
                const SizedBox(width: 8),
                Text(
                  timeSlot,
                  style: AppTypography.bodyMedium.copyWith(
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          if (isActive)
            SizedBox(
              width: double.infinity,
              height: 44,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryDark,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppDimens.radiusMedium),
                  ),
                ),
                onPressed: onAction,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(actionText, style: AppTypography.labelLarge.copyWith(color: Colors.white)),
                    const SizedBox(width: 6),
                    const Icon(Icons.arrow_forward_rounded, size: 18, color: Colors.white),
                  ],
                ),
              ),
            )
          else
            SecondaryOutlineButton(
              text: actionText,
              height: 44,
              onPressed: onAction,
            ),
        ],
      ),
    );
  }
}

class ClassItemCard extends StatelessWidget {
  const ClassItemCard({
    super.key,
    required this.subjectCode,
    required this.className,
    required this.semester,
    required this.studentCount,
    required this.sessionCount,
    required this.isLinkedSheet,
    required this.onTap,
  });

  final String subjectCode;
  final String className;
  final String semester;
  final int studentCount;
  final int sessionCount;
  final bool isLinkedSheet;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppDimens.space12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppDimens.radiusCard),
        border: Border.all(color: AppColors.borderCard),
      ),
      padding: const EdgeInsets.all(AppDimens.space16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Icon(Icons.menu_book_rounded, color: AppColors.textPrimary, size: 22),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.surfaceMuted,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  semester,
                  style: AppTypography.labelSmall.copyWith(color: AppColors.textMuted),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            subjectCode,
            style: AppTypography.titleLarge.copyWith(fontWeight: FontWeight.w800, fontSize: 19),
          ),
          Text(
            'LỚP $className',
            style: AppTypography.bodySmall.copyWith(
              color: AppColors.textMuted,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              const Icon(Icons.group_outlined, size: 16, color: AppColors.textMuted),
              const SizedBox(width: 6),
              Text('$studentCount sinh viên', style: AppTypography.bodySmall),
              const SizedBox(width: 20),
              const Icon(Icons.calendar_today_outlined, size: 16, color: AppColors.textMuted),
              const SizedBox(width: 6),
              Text('$sessionCount buổi học', style: AppTypography.bodySmall),
            ],
          ),
          const SizedBox(height: 14),
          const Divider(height: 1),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    width: 7,
                    height: 7,
                    decoration: BoxDecoration(
                      color: isLinkedSheet ? AppColors.statusSuccess : AppColors.textLight,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    isLinkedSheet ? 'Đã liên kết Google Sheet' : 'Chưa liên kết Sheet',
                    style: AppTypography.labelSmall.copyWith(
                      color: isLinkedSheet ? AppColors.statusSuccess : AppColors.textMuted,
                    ),
                  ),
                ],
              ),
              InkWell(
                onTap: onTap,
                borderRadius: BorderRadius.circular(6),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                  child: Row(
                    children: [
                      Text(
                        'Mở lớp',
                        style: AppTypography.labelMedium.copyWith(
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(width: 4),
                      const Icon(Icons.open_in_new_rounded, size: 14, color: AppColors.textPrimary),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class AttendanceStudentTile extends StatelessWidget {
  const AttendanceStudentTile({
    super.key,
    required this.name,
    required this.studentId,
    required this.statusLabel,
    required this.statusType,
    this.time,
    this.onEdit,
  });

  final String name;
  final String studentId;
  final String statusLabel;
  final StatusType statusType;
  final String? time;
  final VoidCallback? onEdit;

  @override
  Widget build(BuildContext context) {
    final initials = name.trim().split(' ').map((w) => w.isNotEmpty ? w[0] : '').take(2).join();

    return Container(
      margin: const EdgeInsets.only(bottom: AppDimens.space8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppDimens.radiusMedium),
        border: Border.all(
          color: statusType == StatusType.danger ? AppColors.statusDanger.withValues(alpha: 0.2) : AppColors.borderCard,
        ),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 18,
            backgroundColor: statusType == StatusType.danger
                ? AppColors.statusDangerBg
                : AppColors.statusSuccessBg,
            child: Text(
              initials,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: statusType == StatusType.danger
                    ? AppColors.statusDanger
                    : AppColors.statusSuccess,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: AppTypography.titleSmall.copyWith(fontSize: 14),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  '$studentId ${time != null ? "• $time" : ""}',
                  style: AppTypography.bodySmall.copyWith(fontSize: 12),
                ),
              ],
            ),
          ),
          StatusBadgePill(
            label: statusLabel,
            statusType: statusType,
          ),
          if (onEdit != null) ...[
            const SizedBox(width: 8),
            IconButton(
              icon: const Icon(Icons.edit_outlined, size: 18, color: AppColors.textMuted),
              onPressed: onEdit,
              tooltip: 'Sửa trạng thái',
            ),
          ],
        ],
      ),
    );
  }
}
