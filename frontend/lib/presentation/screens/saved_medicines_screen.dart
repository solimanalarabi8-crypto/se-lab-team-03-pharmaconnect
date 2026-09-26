import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/theme_controller.dart';
import '../../core/utils/validation_mixins.dart';
import '../../data/local/database_helper.dart';
import '../../data/models/saved_medicine_model.dart';
import '../widgets/saved_medicine_dialog.dart';
import '../../main.dart';

/// شاشة الأدوية المحفوظة محلياً الفاخرة (SQFlite Local Database Screen):
/// - تطبيق المحاضرة التاسعة بحذافيرها:
///   1. FutureBuilder لقراءة البيانات غير المتزامنة
///   2. مؤشر الانتظار الدائري CircularProgressIndicator
///   3. تمرير البيانات لصندوق التعديل والحذف
///   4. البحث الفوري بدون اتصال بالإنترنت
/// - تصميم بصري راقٍ بمستوى تطبيقات الصحة والمستشفيات العالمية

class SavedMedicinesScreen extends StatefulWidget {
  const SavedMedicinesScreen({super.key});

  @override
  State<SavedMedicinesScreen> createState() => _SavedMedicinesScreenState();
}

class _SavedMedicinesScreenState extends State<SavedMedicinesScreen> with CurrencyFormatterMixin {
  late Future<List<SavedMedicineModel>> _medicinesFuture;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadMedicines();
  }

  void _loadMedicines() {
    setState(() {
      if (_searchQuery.trim().isEmpty) {
        _medicinesFuture = DatabaseHelper().getAllMedicines();
      } else {
        _medicinesFuture = DatabaseHelper().searchMedicines(_searchQuery);
      }
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged(String query) {
    setState(() {
      _searchQuery = query;
    });
    _loadMedicines();
  }

  void _openAddDialog() {
    SavedMedicineDialog.show(
      context,
      onSaved: _loadMedicines,
    );
  }

  void _openEditDialog(SavedMedicineModel item) {
    SavedMedicineDialog.show(
      context,
      medicine: item,
      onSaved: _loadMedicines,
    );
  }

  Future<void> _deleteMedicine(int id) async {
    await DatabaseHelper().deleteMedicine(id);
    _loadMedicines();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          content: const Text('تم حذف الدواء من قاعدة البيانات المحلية بنجاح'),
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = ThemeController().isDarkMode;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          tooltip: 'العودة للرئيسية والبحث',
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () {
            if (Navigator.canPop(context)) {
              Navigator.pop(context);
            } else {
              HomeScreen.selectTab(context, 0);
            }
          },
        ),
        title: const Text(
          'خزانة أدويتي ومفضلتي',
          style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18),
        ),
        actions: [
          IconButton(
            tooltip: 'إضافة دواء جديد',
            icon: const Icon(Icons.add_circle_outline_rounded, color: PharmaTheme.primaryGreen),
            onPressed: _openAddDialog,
          ),
          IconButton(
            tooltip: 'تحديث البيانات',
            icon: const Icon(Icons.refresh_rounded),
            onPressed: _loadMedicines,
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: PharmaTheme.primaryGreen,
        foregroundColor: Colors.white,
        elevation: 4,
        icon: const Icon(Icons.add_rounded),
        label: const Text('إضافة دواء للخزانة', style: TextStyle(fontWeight: FontWeight.bold)),
        onPressed: _openAddDialog,
      ),
      body: Column(
        children: [
          // شريط البحث المباشر في قاعدة البيانات المحلية
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: Container(
              decoration: BoxDecoration(
                color: isDark ? PharmaTheme.darkSurface : Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withAlpha(isDark ? 20 : 6),
                    blurRadius: 10,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: TextField(
                controller: _searchController,
                onChanged: _onSearchChanged,
                decoration: InputDecoration(
                  hintText: 'ابحث في أدويتك المحفوظة...',
                  hintStyle: TextStyle(fontSize: 13, color: Colors.grey.shade500),
                  prefixIcon: const Icon(Icons.search_rounded, color: PharmaTheme.primaryGreen),
                  suffixIcon: _searchQuery.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear_rounded),
                          onPressed: () {
                            _searchController.clear();
                            _onSearchChanged('');
                          },
                        )
                      : null,
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                ),
              ),
            ),
          ),

          // عرض البيانات عبر FutureBuilder و CircularProgressIndicator (المحاضرة 9)
          Expanded(
            child: FutureBuilder<List<SavedMedicineModel>>(
              future: _medicinesFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CircularProgressIndicator(color: PharmaTheme.primaryGreen),
                        SizedBox(height: 16),
                        Text(
                          'جاري تحميل أدويتك المحفوظة...',
                          style: TextStyle(fontSize: 13, color: Colors.grey),
                        ),
                      ],
                    ),
                  );
                }

                if (snapshot.hasError) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.error_outline_rounded, color: Colors.red, size: 48),
                          const SizedBox(height: 12),
                          Text(
                            'تعذر قراءة الأدوية المحفوظة: ${snapshot.error}',
                            textAlign: TextAlign.center,
                            style: const TextStyle(color: Colors.red),
                          ),
                          const SizedBox(height: 16),
                          ElevatedButton(
                            onPressed: _loadMedicines,
                            child: const Text('إعادة المحاولة'),
                          ),
                        ],
                      ),
                    ),
                  );
                }

                final medicines = snapshot.data ?? [];

                if (medicines.isEmpty) {
                  return Center(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(32),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(24),
                            decoration: BoxDecoration(
                              color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.bookmark_border_rounded,
                              size: 64,
                              color: isDark ? Colors.white38 : Colors.grey.shade400,
                            ),
                          ),
                          const SizedBox(height: 18),
                          Text(
                            _searchQuery.isNotEmpty
                                ? 'لا توجد نتائج مطابقة لبحثك في الأدوية المحفوظة'
                                : 'خزانة أدويتك ومفضلاتك فارغة حالياً',
                            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            _searchQuery.isNotEmpty
                                ? 'تأكد من كتابة الاسم بصورة صحيحة أو ابحث باسم آخر'
                                : 'احفظ أدويتك المفضلة أو التي تتناولها بانتظام لتتذكر مواعيدها وجرعاتها بدون إنترنت.',
                            style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 20),
                          ElevatedButton.icon(
                            onPressed: _openAddDialog,
                            icon: const Icon(Icons.add_rounded),
                            label: const Text('إضافة دواء جديد إلى خزانتي'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: PharmaTheme.primaryGreen,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 6, 16, 80),
                  itemCount: medicines.length,
                  itemBuilder: (context, index) {
                    final item = medicines[index];
                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      decoration: BoxDecoration(
                        color: isDark ? PharmaTheme.darkSurface : Colors.white,
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(
                          color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                          width: 1.2,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withAlpha(isDark ? 25 : 6),
                            blurRadius: 10,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(14),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                CircleAvatar(
                                  radius: 20,
                                  backgroundColor: item.isAvailable
                                      ? (isDark ? const Color(0xFF064E3B) : const Color(0xFFD1FAE5))
                                      : (isDark ? const Color(0xFF7F1D1D) : const Color(0xFFFEE2E2)),
                                  child: Icon(
                                    Icons.medication_rounded,
                                    size: 20,
                                    color: item.isAvailable ? const Color(0xFF059669) : Colors.red,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        item.name,
                                        style: TextStyle(
                                          fontWeight: FontWeight.w800,
                                          fontSize: 16,
                                          color: isDark ? Colors.white : PharmaTheme.textMain,
                                        ),
                                      ),
                                      if (item.genericName.isNotEmpty) ...[
                                        const SizedBox(height: 2),
                                        Text(
                                          item.genericName,
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: isDark ? Colors.white60 : Colors.grey.shade600,
                                            fontStyle: FontStyle.italic,
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                                ),
                                item.price > 0
                                    ? Text(
                                        formatYemeniRial(item.price),
                                        style: TextStyle(
                                          fontWeight: FontWeight.w900,
                                          fontSize: 16,
                                          color: isDark ? PharmaTheme.darkNeonGreen : PharmaTheme.primaryGreenDark,
                                        ),
                                      )
                                    : Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                        decoration: BoxDecoration(
                                          color: PharmaTheme.primaryGreen.withAlpha(25),
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        child: const Text(
                                          'أوفلاين 🌿',
                                          style: TextStyle(
                                            fontSize: 11,
                                            fontWeight: FontWeight.bold,
                                            color: PharmaTheme.primaryGreen,
                                          ),
                                        ),
                                      ),
                              ],
                            ),
                            const Padding(
                              padding: EdgeInsets.symmetric(vertical: 8),
                              child: Divider(height: 1),
                            ),
                            Row(
                              children: [
                                Icon(Icons.storefront_rounded, size: 14, color: Colors.grey.shade500),
                                const SizedBox(width: 4),
                                Expanded(
                                  child: Text(
                                    item.pharmacyName.isNotEmpty ? item.pharmacyName : 'خزانتي الشخصية',
                                    style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: PharmaTheme.primaryGreen.withAlpha(25),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    item.category,
                                    style: const TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                      color: PharmaTheme.primaryGreenDark,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            if (item.notes.isNotEmpty) ...[
                              const SizedBox(height: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Row(
                                  children: [
                                    const Icon(Icons.notes_rounded, size: 14, color: Colors.teal),
                                    const SizedBox(width: 6),
                                    Expanded(
                                      child: Text(
                                        item.notes,
                                        style: const TextStyle(fontSize: 11, color: Colors.teal),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                            const SizedBox(height: 8),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                TextButton.icon(
                                  onPressed: () => _openEditDialog(item),
                                  icon: const Icon(Icons.edit_rounded, size: 16),
                                  label: const Text('تعديل', style: TextStyle(fontSize: 12)),
                                  style: TextButton.styleFrom(
                                    foregroundColor: PharmaTheme.primaryGreen,
                                  ),
                                ),
                                const SizedBox(width: 4),
                                TextButton.icon(
                                  onPressed: () {
                                    if (item.id != null) {
                                      _deleteMedicine(item.id!);
                                    }
                                  },
                                  icon: const Icon(Icons.delete_outline_rounded, size: 16),
                                  label: const Text('حذف', style: TextStyle(fontSize: 12)),
                                  style: TextButton.styleFrom(
                                    foregroundColor: Colors.red,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
