import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';

class MedicineImageWidget extends StatelessWidget {
  final String? imageUrl;
  final String medicineName;
  final double width;
  final double height;
  final BorderRadius? borderRadius;
  final BoxFit fit;

  const MedicineImageWidget({
    super.key,
    this.imageUrl,
    required this.medicineName,
    this.width = 60,
    this.height = 60,
    this.borderRadius,
    this.fit = BoxFit.cover,
  });

  String? _getLocalAssetPath(String name) {
    final lower = name.toLowerCase();
    if (lower.contains('panadol')) {
      return 'assets/images/medicines/panadol_extra.jpg';
    } else if (lower.contains('augmentin')) {
      return 'assets/images/medicines/augmentin.jpg';
    } else if (lower.contains('norvasc')) {
      return 'assets/images/medicines/norvasc.jpg';
    } else if (lower.contains('brufen') || lower.contains('ibuprofen')) {
      return 'assets/images/medicines/brufen.jpg';
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final radius = borderRadius ?? BorderRadius.circular(12);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final localAsset = _getLocalAssetPath(medicineName);

    Widget imageContent;

    if (localAsset != null) {
      // تفضيل الأصول المحلية المجهزة بالدقة العالية (سرعة فورية وبدون استهلاك بيانات)
      imageContent = Image.asset(
        localAsset,
        width: width,
        height: height,
        fit: fit,
        errorBuilder: (context, error, stackTrace) => _buildFallback(isDark),
      );
    } else if (imageUrl != null && imageUrl!.startsWith('http')) {
      imageContent = Image.network(
        imageUrl!,
        width: width,
        height: height,
        fit: fit,
        loadingBuilder: (context, child, progress) {
          if (progress == null) return child;
          return Container(
            width: width,
            height: height,
            color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
            child: const Center(
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2, color: PharmaTheme.primaryGreen),
              ),
            ),
          );
        },
        errorBuilder: (context, error, stackTrace) => _buildFallback(isDark),
      );
    } else {
      imageContent = _buildFallback(isDark);
    }

    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        borderRadius: radius,
        border: Border.all(
          color: isDark ? PharmaTheme.darkBorder : const Color(0xFFE2E8F0),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(isDark ? 30 : 8),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: radius,
        child: imageContent,
      ),
    );
  }

  Widget _buildFallback(bool isDark) {
    return Container(
      width: width,
      height: height,
      color: isDark ? const Color(0xFF1E293B) : PharmaTheme.mintBackground,
      child: Center(
        child: Icon(
          Icons.medication_rounded,
          size: width * 0.45,
          color: isDark ? PharmaTheme.darkNeonGreen : PharmaTheme.primaryGreen,
        ),
      ),
    );
  }
}
