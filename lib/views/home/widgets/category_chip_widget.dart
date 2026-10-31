import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_styles.dart';
import '../../../models/category_model.dart';

class CategoryChipWidget extends StatelessWidget {
  final List<CategoryDto> categories;
  final String? selectedCategoryId;
  final ValueChanged<String?> onCategorySelected;

  const CategoryChipWidget({
    Key? key,
    required this.categories,
    required this.selectedCategoryId,
    required this.onCategorySelected,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 42,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: categories.length,
        itemBuilder: (ctx, idx) {
          final cat = categories[idx];
          final isSelected = selectedCategoryId == cat.id || (selectedCategoryId == null && idx == 0);

          return GestureDetector(
            onTap: () => onCategorySelected(cat.id),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              margin: const EdgeInsets.only(right: 10),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                gradient: isSelected ? AppColors.primaryGradient : null,
                color: isSelected ? null : AppColors.bgDarkCard,
                borderRadius: BorderRadius.circular(AppStyles.borderRadiusMedium),
                border: Border.all(
                  color: isSelected ? AppColors.primary : AppColors.borderDark,
                ),
                boxShadow: isSelected ? [AppStyles.glowingShadow(AppColors.primary)] : null,
              ),
              child: Center(
                child: Text(
                  cat.name,
                  style: TextStyle(
                    color: isSelected ? Colors.white : AppColors.textSecondaryDark,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    fontSize: 13,
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
