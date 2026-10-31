import 'package:flutter/material.dart';
import '../../../core/constants/api_endpoints.dart';
import '../../../core/constants/app_colors.dart';
import '../../../models/advisor_model.dart';
import '../../advisors/advisor_detail_screen.dart';

class AdvisorCardWidget extends StatelessWidget {
  final AdvisorDto advisor;
  final VoidCallback? onTap;

  const AdvisorCardWidget({
    Key? key,
    required this.advisor,
    this.onTap,
  }) : super(key: key);

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'online':
        return AppColors.onlineGreen;
      case 'busy':
        return AppColors.busyOrange;
      default:
        return AppColors.offlineGrey;
    }
  }

  void _openDetail(BuildContext context) {
    if (onTap != null) {
      onTap!();
    } else {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => AdvisorDetailScreen(advisor: advisor)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final statusColor = _getStatusColor(advisor.status);

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: AppColors.bgLightCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borderLight),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: InkWell(
        onTap: () => _openDetail(context),
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(14.0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Advisor Avatar + Status Badge + Free Minutes Ribbon
              Stack(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(14),
                    child: Container(
                      width: 72,
                      height: 82,
                      color: AppColors.primary.withOpacity(0.1),
                      child: advisor.profilePhoto != null
                          ? Image.network(
                              '${ApiEndpoints.imageBaseUrl}${advisor.profilePhoto}',
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) => Center(
                                child: Text(
                                  advisor.name.isNotEmpty ? advisor.name[0].toUpperCase() : 'A',
                                  style: const TextStyle(
                                    fontSize: 28,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.primary,
                                  ),
                                ),
                              ),
                            )
                          : Center(
                              child: Text(
                                advisor.name.isNotEmpty ? advisor.name[0].toUpperCase() : 'A',
                                style: const TextStyle(
                                  fontSize: 28,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.primary,
                                ),
                              ),
                            ),
                    ),
                  ),
                  Positioned(
                    top: 4,
                    right: 4,
                    child: Container(
                      width: 12,
                      height: 12,
                      decoration: BoxDecoration(
                        color: statusColor,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 14),

              // Info & Details
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            advisor.name,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textPrimaryLight,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: statusColor.withOpacity(0.12),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: statusColor.withOpacity(0.4)),
                          ),
                          child: Text(
                            advisor.status,
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: statusColor,
                            ),
                          ),
                        ),
                      ],
                    ),
                    if (advisor.categoryName != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        advisor.categoryName!,
                        style: const TextStyle(
                          color: AppColors.accentPurple,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                    const SizedBox(height: 6),

                    // Rating & Reviews
                    Row(
                      children: [
                        const Icon(Icons.star_rounded, color: AppColors.accentGoldDark, size: 16),
                        const SizedBox(width: 4),
                        Text(
                          advisor.rating.toStringAsFixed(1),
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                            color: AppColors.textPrimaryLight,
                          ),
                        ),
                        Text(
                          " (${advisor.reviewsCount} reviews)",
                          style: const TextStyle(color: AppColors.textSecondaryLight, fontSize: 12),
                        ),
                      ],
                    ),

                    const SizedBox(height: 10),

                    // Pricing & Web-style Green Action Buttons
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          "\$${advisor.pricePerMinute.toStringAsFixed(2)}/min",
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: AppColors.primary,
                          ),
                        ),
                        Row(
                          children: [
                            ElevatedButton.icon(
                              onPressed: () => _openDetail(context),
                              icon: const Icon(Icons.chat_bubble, size: 14, color: Colors.white),
                              label: const Text(
                                "Chat",
                                style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white),
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.ctaGreen,
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                minimumSize: Size.zero,
                                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                elevation: 0,
                              ),
                            ),
                            const SizedBox(width: 6),
                            ElevatedButton.icon(
                              onPressed: () => _openDetail(context),
                              icon: const Icon(Icons.phone, size: 14, color: Colors.white),
                              label: const Text(
                                "Call",
                                style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white),
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.ctaGreen,
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                minimumSize: Size.zero,
                                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                elevation: 0,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

