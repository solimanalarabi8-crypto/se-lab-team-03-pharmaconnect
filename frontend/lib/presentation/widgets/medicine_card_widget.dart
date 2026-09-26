import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/theme_controller.dart';
import '../../core/utils/validation_mixins.dart';
import '../../data/local/database_helper.dart';
import '../../data/models/medicine_search_model.dart';
import '../../data/models/saved_medicine_model.dart';
import '../screens/medicine_details_screen.dart';

/// بطاقة عرض الدواء الفاخرة (Luxury Medical Card):
/// - تطبيق معايير واجهات المستخدم الطبية الحديثة (Clean, Elegant, WCAG 2.1 AA)
/// - استيفاء المحاضرة السادسة (Visual Containers, Media & Buttons)
/// - استيفاء المحاضرة التاسعة (حفظ وتحديث في قاعدة بيانات SQLite المحلية بنقرة واحدة)
/// - استيفاء المحاضرة الرابعة (استخدام المكسينات CurrencyFormatterMixin لتنسيق الأسعار والمسافات)

class MedicineCardWidget extends StatefulWidget {
  final MedicineSearchItem item;
  final VoidCallback? onReservePressed;

  const MedicineCardWidget({
    super.key,
    required this.item,
    this.onReservePressed,
  });

  @override
  State<MedicineCardWidget> createState() => _MedicineCardWidgetState();
}

class _MedicineCardWidgetState extends State<MedicineCardWidget> with CurrencyFormatterMixin {
  bool _isSavedLocally = false;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _checkSavedStatus();
  }

  Future<void> _checkSavedStatus() async {
    final saved = await DatabaseHelper().isMedicineSaved(
      widget.item.medicine.id,
      medicineName: widget.item.medicine.tradeName,
    );
    if (mounted) {
      setState(() {
        _isSavedLocally = saved;
      });
    }
  }

  Future<void> _toggleLocalBookmark() async {
    if (_isSaving) return;
    setState(() => _isSaving = true);

    try {
      if (_isSavedLocally) {
        await DatabaseHelper().deleteByMedicineId(widget.item.medicine.id);
        if (mounted) {
          setState(() => _isSavedLocally = false);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('تمت إزالة الدواء من خزانتك الخاصة'),
              duration: Duration(seconds: 2),
            ),
          );
        }
      } else {
        final localModel = SavedMedicineModel(
          medicineId: widget.item.medicine.id,
          name: widget.item.medicine.tradeName,
          genericName: widget.item.medicine.scientificName,
          category: widget.item.medicine.category ?? 'عام',
          price: widget.item.price,
          pharmacyName: widget.item.pharmacy.name,
          pharmacyPhone: widget.item.pharmacy.phone,
          isAvailable: widget.item.status == 'available' && widget.item.availableQuantity > 0,
          notes: widget.item.medicine.isPrescriptionRequired ? 'يتطلب وصفة طبية' : 'متوفر للشراء المباشر',
          savedAt: DateTime.now().toIso8601String(),
        );

        await DatabaseHelper().insertMedicine(localModel);

        if (mounted) {
          setState(() => _isSavedLocally = true);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              backgroundColor: PharmaTheme.primaryGreenDark,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              content: const Row(
                children: [
                  Icon(Icons.check_circle_rounded, color: Colors.white),
                  SizedBox(width: 8),
                  Text('تم حفظ الدواء في خزانتك الخاصة بنجاح ✓'),
                ],
              ),
              duration: const Duration(seconds: 2),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('حدث خطأ أثناء التعامل مع قاعدة البيانات: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = ThemeController().isDarkMode;
    final item = widget.item;
    final isAvailable = item.status == 'available' && item.availableQuantity > 0;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: isDark ? PharmaTheme.darkSurface : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: isDark ? Colors.black.withAlpha(40) : const Color(0x0A0F172A),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(20),
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: () => _openDetails(context),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 1. شريط الصيدلية المعتمدة في أعلى البطاقة
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF064E3B) : PharmaTheme.mintBackground,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        Icons.local_pharmacy_rounded,
                        size: 14,
                        color: PharmaTheme.primaryGreen,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Row(
                        children: [
                          Flexible(
                            child: Text(
                              item.pharmacy.name,
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: isDark ? Colors.white : PharmaTheme.textMain,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 4),
                          const Icon(Icons.verified_rounded, size: 14, color: PharmaTheme.primaryGreen),
                        ],
                      ),
                    ),
                    if (item.distanceKm != null) ...[
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.near_me_rounded, size: 12, color: PharmaTheme.primaryGreen),
                            const SizedBox(width: 3),
                            Text(
                              formatDistance(item.distanceKm! * 1000),
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: isDark ? PharmaTheme.darkNeonGreen : PharmaTheme.primaryGreenDark,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                    const SizedBox(width: 4),
                    // زر المفضلة والحفظ في قاعدة بيانات SQLite المحلية
                    IconButton(
                      constraints: const BoxConstraints(),
                      padding: const EdgeInsets.all(4),
                      tooltip: _isSavedLocally ? 'محفوظ محلياً' : 'حفظ في قاعدة البيانات المحلية',
                      onPressed: _toggleLocalBookmark,
                      icon: Icon(
                        _isSavedLocally ? Icons.bookmark_rounded : Icons.bookmark_border_rounded,
                        color: _isSavedLocally ? Colors.amber.shade700 : Colors.grey.shade400,
                        size: 22,
                      ),
                    ),
                  ],
                ),

                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 8),
                  child: Divider(height: 1, thickness: 0.8),
                ),

                // 2. تفاصيل الدواء والصورة
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // صورة الدواء المتطورة
                    ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                          ),
                        ),
                        child: item.medicine.imageUrl != null && item.medicine.imageUrl!.isNotEmpty
                            ? Image.network(
                                item.medicine.imageUrl!,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) => _buildFallbackImage(isDark),
                                loadingBuilder: (ctx, child, progress) {
                                  if (progress == null) return child;
                                  return const Center(
                                    child: SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(strokeWidth: 2, color: PharmaTheme.primaryGreen),
                                    ),
                                  );
                                },
                              )
                            : _buildFallbackImage(isDark),
                      ),
                    ),
                    const SizedBox(width: 14),

                    // اسم الدواء والتفاصيل
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item.medicine.tradeName,
                            style: TextStyle(
                              fontWeight: FontWeight.w800,
                              fontSize: 16,
                              color: isDark ? Colors.white : const Color(0xFF0F172A),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          if (item.medicine.scientificName.isNotEmpty) ...[
                            const SizedBox(height: 3),
                            Text(
                              item.medicine.scientificName,
                              style: TextStyle(
                                fontSize: 12,
                                color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                                fontStyle: FontStyle.italic,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                          const SizedBox(height: 8),

                          // شارات الحالة والشكل الصيدلاني والوصفة
                          Wrap(
                            spacing: 6,
                            runSpacing: 4,
                            children: [
                              // شارة الوفرة مع نقطة تفاعلية
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: isAvailable
                                      ? (isDark ? const Color(0xFF064E3B).withAlpha(150) : const Color(0xFFD1FAE5))
                                      : (isDark ? const Color(0xFF7F1D1D).withAlpha(150) : const Color(0xFFFEE2E2)),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Container(
                                      width: 6,
                                      height: 6,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        color: isAvailable ? const Color(0xFF059669) : const Color(0xFFDC2626),
                                      ),
                                    ),
                                    const SizedBox(width: 5),
                                    Text(
                                      isAvailable ? 'متوفر (${item.availableQuantity})' : 'غير متوفر',
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.bold,
                                        color: isAvailable ? const Color(0xFF065F46) : const Color(0xFF991B1B),
                                      ),
                                    ),
                                  ],
                                ),
                              ),

                              if (item.medicine.dosageForm != null && item.medicine.dosageForm!.isNotEmpty)
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    item.medicine.dosageForm!,
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF475569),
                                    ),
                                  ),
                                ),

                              if (item.medicine.isPrescriptionRequired)
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: Colors.amber.withAlpha(isDark ? 50 : 30),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    'وصفة طبية',
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                      color: isDark ? Colors.amber.shade300 : Colors.amber.shade900,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 14),

                // 3. صف السعر والأزرار المتجاوب مع كافة شاشات أندرويد (Adaptive Android Layout)
                LayoutBuilder(
                  builder: (context, constraints) {
                    final isCompact = constraints.maxWidth < 340;

                    if (isCompact) {
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'السعر بالصيدلية:',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                                ),
                              ),
                              Text(
                                formatYemeniRial(item.price),
                                style: TextStyle(
                                  fontWeight: FontWeight.w900,
                                  fontSize: 17,
                                  color: isDark ? PharmaTheme.darkNeonGreen : PharmaTheme.primaryGreenDark,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          Row(
                            children: [
                              Expanded(
                                child: OutlinedButton(
                                  onPressed: () => _openDetails(context),
                                  style: OutlinedButton.styleFrom(
                                    side: BorderSide(
                                      color: isDark ? const Color(0xFF334155) : const Color(0xFFCBD5E1),
                                    ),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                    padding: const EdgeInsets.symmetric(vertical: 10),
                                  ),
                                  child: Text(
                                    'التفاصيل',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: isDark ? Colors.white : PharmaTheme.textMain,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                flex: 2,
                                child: ElevatedButton.icon(
                                  onPressed: isAvailable ? (widget.onReservePressed ?? () => _openDetails(context)) : null,
                                  icon: const Icon(Icons.shopping_bag_outlined, size: 16),
                                  label: const Text(
                                    'حجز الآن',
                                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                                  ),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: PharmaTheme.primaryGreen,
                                    foregroundColor: Colors.white,
                                    elevation: 0,
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                    padding: const EdgeInsets.symmetric(vertical: 10),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      );
                    }

                    return Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // السعر بتنسيق طبي جذاب
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'السعر بالصيدلية',
                              style: TextStyle(
                                fontSize: 11,
                                color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              formatYemeniRial(item.price),
                              style: TextStyle(
                                fontWeight: FontWeight.w900,
                                fontSize: 18,
                                color: isDark ? PharmaTheme.darkNeonGreen : PharmaTheme.primaryGreenDark,
                              ),
                            ),
                          ],
                        ),

                        // الأزرار التفاعلية
                        Row(
                          children: [
                            OutlinedButton(
                              onPressed: () => _openDetails(context),
                              style: OutlinedButton.styleFrom(
                                side: BorderSide(
                                  color: isDark ? const Color(0xFF334155) : const Color(0xFFCBD5E1),
                                ),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                              ),
                              child: Text(
                                'التفاصيل',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: isDark ? Colors.white : PharmaTheme.textMain,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            ElevatedButton.icon(
                              onPressed: isAvailable ? (widget.onReservePressed ?? () => _openDetails(context)) : null,
                              icon: const Icon(Icons.shopping_bag_outlined, size: 16),
                              label: const Text(
                                'حجز الآن',
                                style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: PharmaTheme.primaryGreen,
                                foregroundColor: Colors.white,
                                elevation: 0,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
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
        ),
      ),
    );
  }

  Widget _buildFallbackImage(bool isDark) {
    return Center(
      child: Icon(
        Icons.medication_rounded,
        size: 38,
        color: isDark ? PharmaTheme.darkNeonGreen.withAlpha(160) : PharmaTheme.primaryGreen.withAlpha(180),
      ),
    );
  }

  void _openDetails(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => MedicineDetailsScreen(item: widget.item),
      ),
    );
  }
}
