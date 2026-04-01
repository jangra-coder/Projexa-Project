import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/warranty_model.dart';
import '../theme/app_colors.dart';

class WarrantyCard extends StatelessWidget {
  final WarrantyModel warranty;
  final VoidCallback? onTap;
  final bool compact;

  const WarrantyCard({
    super.key,
    required this.warranty,
    this.onTap,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final dateFormat = DateFormat('MMMM dd, yyyy');

    Color statusColor;
    switch (warranty.status) {
      case WarrantyStatus.active:
        statusColor = AppColors.activeGreen;
      case WarrantyStatus.expiringSoon:
        statusColor = AppColors.expiredRed;
      case WarrantyStatus.expired:
        statusColor = AppColors.expiredRed;
    }

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkCardBg : AppColors.lightCardBg,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isDark ? AppColors.darkDivider : AppColors.lightDivider,
            width: 0.5,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.06),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          children: [
            // Product icon/image
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: isDark
                      ? [AppColors.darkBackground, AppColors.darkSurface]
                      : [AppColors.lightInputBg, AppColors.lightBackground],
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Center(
                child: Text(
                  warranty.category.emoji,
                  style: const TextStyle(fontSize: 28),
                ),
              ),
            ),
            const SizedBox(width: 14),
            // Product info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    warranty.productName,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: isDark ? AppColors.darkText : AppColors.lightText,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Warranty expire on\n${dateFormat.format(warranty.warrantyEndDate)}',
                    style: TextStyle(
                      fontSize: 11,
                      color: isDark
                          ? AppColors.darkSubtext
                          : AppColors.lightSubtext,
                      height: 1.3,
                    ),
                  ),
                ],
              ),
            ),
            // Days remaining
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '${warranty.daysRemaining > 0 ? "-" : ""}${warranty.daysRemaining.abs()} days',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: statusColor,
                  ),
                ),
                if (!compact)
                  Container(
                    margin: const EdgeInsets.only(top: 6),
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: statusColor.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      warranty.status == WarrantyStatus.active
                          ? 'Active'
                          : warranty.status == WarrantyStatus.expiringSoon
                              ? 'Expiring'
                              : 'Expired',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: statusColor,
                      ),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
