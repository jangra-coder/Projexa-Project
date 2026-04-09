import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../models/warranty_model.dart';
import '../../providers/app_provider.dart';
import '../../theme/app_colors.dart';

class WarrantyDetailScreen extends StatelessWidget {
  final WarrantyModel warranty;

  const WarrantyDetailScreen({super.key, required this.warranty});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final dateFormat = DateFormat('MMMM dd, yyyy');
    final provider = context.read<AppProvider>();

    Color statusColor;
    String statusLabel;
    IconData statusIcon;
    switch (warranty.status) {
      case WarrantyStatus.active:
        statusColor = AppColors.activeGreen;
        statusLabel = 'Active';
        statusIcon = Icons.verified_rounded;
      case WarrantyStatus.expiringSoon:
        statusColor = AppColors.warningAmber;
        statusLabel = 'Expiring Soon';
        statusIcon = Icons.warning_amber_rounded;
      case WarrantyStatus.expired:
        statusColor = AppColors.expiredRed;
        statusLabel = 'Expired';
        statusIcon = Icons.error_outline_rounded;
    }

    // Get Drive image URLs
    final productImageUrl =
        provider.getDriveImageUrl(warranty.productImageDriveId);
    final receiptImageUrl =
        provider.getDriveImageUrl(warranty.receiptImageDriveId);
    final hasImages = productImageUrl != null || receiptImageUrl != null;
    final isProductPdf = warranty.productImagePath?.toLowerCase().endsWith('.pdf') ?? false;
    final isReceiptPdf = warranty.receiptImagePath?.toLowerCase().endsWith('.pdf') ?? false;

    return Scaffold(
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          // App bar with gradient
          SliverAppBar(
            expandedHeight: 200,
            pinned: true,
            backgroundColor:
                isDark ? AppColors.darkSurface : AppColors.accentBlue,
            foregroundColor: Colors.white,
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: const BoxDecoration(
                  gradient: AppColors.primaryGradient,
                ),
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const SizedBox(height: 40),
                      // Product emoji
                      Container(
                        width: 72,
                        height: 72,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Center(
                          child: Text(
                            warranty.category.emoji,
                            style: const TextStyle(fontSize: 40),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        warranty.productName,
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                      if (warranty.brand != null)
                        Text(
                          warranty.brand!,
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.white.withValues(alpha: 0.8),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ),

          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Status banner
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: statusColor.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: statusColor.withValues(alpha: 0.3),
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(statusIcon, color: statusColor, size: 28),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                statusLabel,
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                  color: statusColor,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                warranty.daysRemainingText,
                                style: TextStyle(
                                  fontSize: 13,
                                  color: statusColor.withValues(alpha: 0.8),
                                ),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 8),
                          decoration: BoxDecoration(
                            color: statusColor.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            '${warranty.daysRemaining.abs()} days',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w800,
                              color: statusColor,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Warranty timeline
                  _buildProgressBar(warranty, isDark),
                  const SizedBox(height: 28),

                  // Images section
                  if (hasImages) ...[
                    Text(
                      'IMAGES',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1,
                        color:
                            isDark ? AppColors.darkText : AppColors.lightText,
                      ),
                    ),
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        if (productImageUrl != null)
                          Expanded(
                            child: _ImageCard(
                              label: 'Product',
                              imageUrl: productImageUrl,
                              isDark: isDark,
                              isPdf: isProductPdf,
                              onTap: () {
                                if (isProductPdf && warranty.productImageDriveId != null) {
                                  launchUrl(Uri.parse('https://drive.google.com/file/d/${warranty.productImageDriveId}/view'));
                                } else {
                                  _showFullScreenImage(
                                    context,
                                    productImageUrl,
                                    'Product Photo',
                                  );
                                }
                              },
                            ),
                          ),
                        if (productImageUrl != null && receiptImageUrl != null)
                          const SizedBox(width: 12),
                        if (receiptImageUrl != null)
                          Expanded(
                            child: _ImageCard(
                              label: 'Receipt',
                              imageUrl: receiptImageUrl,
                              isDark: isDark,
                              isPdf: isReceiptPdf,
                              onTap: () {
                                if (isReceiptPdf && warranty.receiptImageDriveId != null) {
                                  launchUrl(Uri.parse('https://drive.google.com/file/d/${warranty.receiptImageDriveId}/view'));
                                } else {
                                  _showFullScreenImage(
                                    context,
                                    receiptImageUrl,
                                    'Receipt / Bill',
                                  );
                                }
                              },
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 24),
                  ],

                  // Cloud sync badge
                  if (warranty.hasCloudImages)
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: AppColors.accentBlue.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.cloud_done_rounded,
                              size: 14, color: AppColors.accentBlue),
                          const SizedBox(width: 6),
                          Text(
                            'Images backed up to Google Drive',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: AppColors.accentBlue,
                            ),
                          ),
                        ],
                      ),
                    ),
                  if (warranty.hasCloudImages) const SizedBox(height: 24),

                  // Details section
                  Text(
                    'DETAILS',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1,
                      color: isDark ? AppColors.darkText : AppColors.lightText,
                    ),
                  ),
                  const SizedBox(height: 14),

                  _DetailRow(
                    icon: Icons.category_outlined,
                    label: 'Category',
                    value:
                        '${warranty.category.emoji} ${warranty.category.label}',
                    isDark: isDark,
                  ),
                  _DetailRow(
                    icon: Icons.shopping_bag_outlined,
                    label: 'Purchase Date',
                    value: dateFormat.format(warranty.purchaseDate),
                    isDark: isDark,
                  ),
                  _DetailRow(
                    icon: Icons.event_outlined,
                    label: 'Warranty Until',
                    value: dateFormat.format(warranty.warrantyEndDate),
                    isDark: isDark,
                  ),
                  if (warranty.serialNumber != null)
                    _DetailRow(
                      icon: Icons.qr_code_2_outlined,
                      label: 'Serial Number',
                      value: warranty.serialNumber!,
                      isDark: isDark,
                    ),
                  if (warranty.storeName != null)
                    _DetailRow(
                      icon: Icons.store_outlined,
                      label: 'Store',
                      value: warranty.storeName!,
                      isDark: isDark,
                    ),
                  if (warranty.purchasePrice != null)
                    _DetailRow(
                      icon: Icons.currency_rupee_rounded,
                      label: 'Purchase Price',
                      value: '₹${warranty.purchasePrice!.toStringAsFixed(0)}',
                      isDark: isDark,
                    ),
                  if (warranty.notes != null) ...[
                    const SizedBox(height: 20),
                    Text(
                      'NOTES',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1,
                        color:
                            isDark ? AppColors.darkText : AppColors.lightText,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: isDark
                            ? AppColors.darkCardBg
                            : AppColors.lightCardBg,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isDark
                              ? AppColors.darkDivider
                              : AppColors.lightDivider,
                          width: 0.5,
                        ),
                      ),
                      child: Text(
                        warranty.notes!,
                        style: TextStyle(
                          fontSize: 14,
                          color: isDark
                              ? AppColors.darkSubtext
                              : AppColors.lightSubtext,
                          height: 1.4,
                        ),
                      ),
                    ),
                  ],
                  const SizedBox(height: 32),

                  // Delete button
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: OutlinedButton.icon(
                      onPressed: () async {
                        final confirmed = await showDialog<bool>(
                          context: context,
                          builder: (ctx) => AlertDialog(
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20),
                            ),
                            backgroundColor: isDark
                                ? AppColors.darkSurface
                                : AppColors.lightSurface,
                            title: const Text('Delete Warranty'),
                            content: Text(
                              'Are you sure you want to delete "${warranty.productName}"?',
                            ),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(ctx, false),
                                child: const Text('Cancel'),
                              ),
                              TextButton(
                                onPressed: () => Navigator.pop(ctx, true),
                                child: const Text(
                                  'Delete',
                                  style:
                                      TextStyle(color: AppColors.dangerRed),
                                ),
                              ),
                            ],
                          ),
                        );

                        if (confirmed == true && context.mounted) {
                          context
                              .read<AppProvider>()
                              .deleteWarranty(warranty.id);
                          Navigator.of(context).pop();
                        }
                      },
                      icon: const Icon(Icons.delete_outline_rounded,
                          color: AppColors.dangerRed),
                      label: const Text(
                        'Delete Warranty',
                        style: TextStyle(
                          color: AppColors.dangerRed,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: AppColors.dangerRed),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 30),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressBar(WarrantyModel warranty, bool isDark) {
    final totalDays =
        warranty.warrantyEndDate.difference(warranty.purchaseDate).inDays;
    final elapsed = DateTime.now().difference(warranty.purchaseDate).inDays;
    double progress =
        totalDays > 0 ? (elapsed / totalDays).clamp(0.0, 1.0) : 1.0;

    Color progressColor;
    if (progress < 0.7) {
      progressColor = AppColors.activeGreen;
    } else if (progress < 0.9) {
      progressColor = AppColors.warningAmber;
    } else {
      progressColor = AppColors.expiredRed;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Warranty Timeline',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: isDark ? AppColors.darkText : AppColors.lightText,
              ),
            ),
            Text(
              '${(progress * 100).toInt()}% used',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: progressColor,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: LinearProgressIndicator(
            value: progress,
            minHeight: 8,
            backgroundColor:
                isDark ? AppColors.darkDivider : AppColors.lightDivider,
            valueColor: AlwaysStoppedAnimation<Color>(progressColor),
          ),
        ),
      ],
    );
  }

  void _showFullScreenImage(
      BuildContext context, String imageUrl, String title) {
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(ctx),
                  icon:
                      const Icon(Icons.close_rounded, color: Colors.white),
                ),
              ],
            ),
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Image.network(
                imageUrl,
                fit: BoxFit.contain,
                loadingBuilder: (_, child, progress) {
                  if (progress == null) return child;
                  return Container(
                    height: 300,
                    alignment: Alignment.center,
                    child: const CircularProgressIndicator(
                      color: Colors.white,
                    ),
                  );
                },
                errorBuilder: (_, __, ___) => Container(
                  height: 200,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.broken_image_outlined,
                          color: Colors.white54, size: 48),
                      SizedBox(height: 8),
                      Text(
                        'Could not load image',
                        style: TextStyle(color: Colors.white54),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ImageCard extends StatelessWidget {
  final String label;
  final String imageUrl;
  final bool isDark;
  final bool isPdf;
  final VoidCallback onTap;

  const _ImageCard({
    required this.label,
    required this.imageUrl,
    required this.isDark,
    this.isPdf = false,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 120,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isDark ? AppColors.darkDivider : AppColors.lightDivider,
          ),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(14),
          child: Stack(
            fit: StackFit.expand,
            children: [
              if (isPdf)
                Container(
                  color: isDark ? AppColors.darkInputBg : AppColors.lightInputBg,
                  child: Center(
                    child: Icon(
                      Icons.picture_as_pdf_outlined,
                      color: AppColors.warningAmber,
                      size: 48,
                    ),
                  ),
                )
              else
                Image.network(
                  imageUrl,
                  fit: BoxFit.cover,
                  loadingBuilder: (_, child, progress) {
                    if (progress == null) return child;
                    return Center(
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: isDark
                            ? AppColors.accentTeal
                            : AppColors.accentBlue,
                      ),
                    );
                  },
                  errorBuilder: (_, __, ___) => Center(
                    child: Icon(
                      Icons.image_not_supported_outlined,
                      color: isDark
                          ? AppColors.darkSubtext
                          : AppColors.lightSubtext,
                    ),
                  ),
                ),
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.transparent,
                        Colors.black.withValues(alpha: 0.7),
                      ],
                    ),
                  ),
                  child: Text(
                    label,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final bool isDark;

  const _DetailRow({
    required this.icon,
    required this.label,
    required this.value,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: AppColors.accentBlue.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 18, color: AppColors.accentBlue),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 11,
                    color: isDark
                        ? AppColors.darkSubtext
                        : AppColors.lightSubtext,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: isDark ? AppColors.darkText : AppColors.lightText,
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
