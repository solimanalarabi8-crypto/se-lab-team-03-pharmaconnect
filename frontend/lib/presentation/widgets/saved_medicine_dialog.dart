import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/theme_controller.dart';
import '../../core/utils/validation_mixins.dart';
import '../../data/local/database_helper.dart';
import '../../data/models/saved_medicine_model.dart';

/// كلاس منعزل لحوار وصندوق تعبئة بيانات الدواء في خزانة المريض:
/// - تطبيق صريح للمحاضرة التاسعة:
///   "طريقة بناء الأدوات بكلاسات منعزلة داخل ملف منعزل، من أجل أن يتم استخدامه عدة مرات، ولتقليل كمية الأكواد في الصفحات"
/// - واجهة طبية احترافية ملائمة للمستخدمين والمرضى (Patient-Centric Medical UX)
/// - استيفاء كامل لقاعدة بيانات SQLite المحلية بدون أي تعقيد تقني للمريض
class SavedMedicineDialog extends StatefulWidget {
  final SavedMedicineModel? initialMedicine;
  final VoidCallback onSaved;

  const SavedMedicineDialog({
    super.key,
    this.initialMedicine,
    required this.onSaved,
  });

  static Future<void> show(
    BuildContext context, {
    SavedMedicineModel? medicine,
    required VoidCallback onSaved,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      constraints: const BoxConstraints(maxWidth: 540),
      backgroundColor: Colors.transparent,
      builder: (ctx) => SavedMedicineDialog(
        initialMedicine: medicine,
        onSaved: onSaved,
      ),
    );
  }

  @override
  State<SavedMedicineDialog> createState() => _SavedMedicineDialogState();
}

class _SavedMedicineDialogState extends State<SavedMedicineDialog> with FormValidatorMixin {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _dosageController;
  late final TextEditingController _notesController;
  late final TextEditingController _priceController;
  late final TextEditingController _pharmacyController;

  String _selectedCategory = 'مسكنات';
  bool _isAvailable = true;
  bool _isSubmitting = false;

  bool get _isEditing => widget.initialMedicine != null;

  final List<String> _quickDosageChips = [
    'حبة بعد الأكل',
    'مرتين يومياً',
    'قبل النوم',
    'عند اللزوم',
    'قبل الأكل بنصف ساعة',
  ];

  final List<String> _categoryOptions = [
    'مسكنات',
    'مضادات حيوية',
    'أمراض مزمنة',
    'فيتامينات',
    'معدة وهضم',
    'عام',
  ];

  @override
  void initState() {
    super.initState();
    final m = widget.initialMedicine;
    _nameController = TextEditingController(text: m?.name ?? '');
    _dosageController = TextEditingController(text: m?.genericName ?? '');
    _notesController = TextEditingController(text: m?.notes ?? '');
    _priceController = TextEditingController(text: m != null && m.price > 0 ? m.price.toStringAsFixed(0) : '');
    _pharmacyController = TextEditingController(text: m?.pharmacyName ?? '');
    _selectedCategory = m?.category ?? 'مسكنات';
    if (!_categoryOptions.contains(_selectedCategory)) {
      _selectedCategory = 'عام';
    }
    _isAvailable = m?.isAvailable ?? true;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _dosageController.dispose();
    _notesController.dispose();
    _priceController.dispose();
    _pharmacyController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);

    try {
      final enteredPrice = double.tryParse(_priceController.text.trim()) ?? 0.0;
      final now = DateTime.now().toIso8601String();

      final model = SavedMedicineModel(
        id: widget.initialMedicine?.id,
        medicineId: widget.initialMedicine?.medicineId,
        name: _nameController.text.trim(),
        genericName: _dosageController.text.trim(),
        category: _selectedCategory,
        price: enteredPrice,
        pharmacyName: _pharmacyController.text.trim().isNotEmpty
            ? _pharmacyController.text.trim()
            : 'خزانتي الشخصية',
        pharmacyPhone: widget.initialMedicine?.pharmacyPhone ?? '',
        isAvailable: _isAvailable,
        notes: _notesController.text.trim(),
        savedAt: widget.initialMedicine?.savedAt ?? now,
      );

      if (_isEditing) {
        await DatabaseHelper().updateMedicine(model);
      } else {
        await DatabaseHelper().insertMedicine(model);
      }

      if (mounted) {
        widget.onSaved();
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: PharmaTheme.primaryGreenDark,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            content: Row(
              children: [
                const Icon(Icons.check_circle_rounded, color: Colors.white),
                const SizedBox(width: 8),
                Text(
                  _isEditing
                      ? 'تم تحديث بيانات الدواء في خزانتك بنجاح ✓'
                      : 'تم حفظ الدواء في خزانتك الخاصة بنجاح ✓',
                ),
              ],
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('خطأ أثناء حفظ الدواء: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  Future<void> _delete() async {
    if (widget.initialMedicine?.id == null) return;
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('تأكيد الحذف'),
        content: const Text('هل أنت متأكد من رغبتك في حذف هذا الدواء من خزانتك الخاصة؟'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('حذف', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      setState(() => _isSubmitting = true);
      try {
        await DatabaseHelper().deleteMedicine(widget.initialMedicine!.id!);
        if (mounted) {
          widget.onSaved();
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              content: const Text('تم حذف الدواء من خزانتك بنجاح'),
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('تعذر الحذف: $e')),
          );
        }
      } finally {
        if (mounted) setState(() => _isSubmitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    final isDark = ThemeController().isDarkMode;

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.88,
      ),
      padding: EdgeInsets.fromLTRB(20, 20, 20, 20 + bottomInset),
      decoration: BoxDecoration(
        color: isDark ? PharmaTheme.darkSurface : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        boxShadow: const [
          BoxShadow(
            color: Colors.black26,
            blurRadius: 20,
            offset: Offset(0, -4),
          ),
        ],
      ),
      child: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // مقبض السحب العلوي الأنيق
              Center(
                child: Container(
                  width: 44,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: Colors.grey.withAlpha(80),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),

              // ترويسة الصندوق الفاخرة
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: PharmaTheme.primaryGreen.withAlpha(25),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.medical_services_rounded,
                          color: PharmaTheme.primaryGreen,
                          size: 22,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _isEditing ? 'تعديل دواء في خزانتي' : 'إضافة دواء إلى خزانتي',
                            style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 17),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'يُحفظ بأمان في هاتفك للرجوع إليه بدون إنترنت',
                            style: TextStyle(
                              fontSize: 11,
                              color: isDark ? Colors.white60 : Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: 18),

              // 1. حقل اسم الدواء
              TextFormField(
                controller: _nameController,
                decoration: InputDecoration(
                  labelText: 'اسم الدواء *',
                  hintText: 'مثال: بانادول، أوجمنتين، فيتامين د...',
                  prefixIcon: const Icon(Icons.medication_rounded, color: PharmaTheme.primaryGreen),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                  filled: true,
                  fillColor: isDark ? const Color(0xFF1E293B) : const Color(0xFFF8FAFC),
                ),
                validator: (val) => validateRequired(val, 'اسم الدواء'),
              ),
              const SizedBox(height: 14),

              // 2. الجرعة ومواعيد التناول
              TextFormField(
                controller: _dosageController,
                decoration: InputDecoration(
                  labelText: 'الجرعة ومواعيد التناول',
                  hintText: 'مثال: حبة بعد الأكل، مرتين يومياً...',
                  prefixIcon: const Icon(Icons.schedule_rounded, color: PharmaTheme.primaryGreen),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                  filled: true,
                  fillColor: isDark ? const Color(0xFF1E293B) : const Color(0xFFF8FAFC),
                ),
              ),
              const SizedBox(height: 8),

              // شرائح الجرعات السريعة (Quick Dosage Chips)
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: _quickDosageChips.map((chipText) {
                  return InkWell(
                    borderRadius: BorderRadius.circular(20),
                    onTap: () {
                      setState(() {
                        if (_dosageController.text.trim().isEmpty) {
                          _dosageController.text = chipText;
                        } else {
                          _dosageController.text = '${_dosageController.text.trim()} - $chipText';
                        }
                      });
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                        ),
                      ),
                      child: Text(
                        '+ $chipText',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: isDark ? PharmaTheme.darkNeonGreen : PharmaTheme.primaryGreenDark,
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 14),

              // 3. تصنيف الدواء
              const Text(
                'التصنيف الطبي:',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 6),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: _categoryOptions.map((cat) {
                    final isSelected = _selectedCategory == cat;
                    return Padding(
                      padding: const EdgeInsets.only(left: 6),
                      child: ChoiceChip(
                        label: Text(cat),
                        selected: isSelected,
                        selectedColor: PharmaTheme.primaryGreen.withAlpha(40),
                        labelStyle: TextStyle(
                          fontSize: 12,
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                          color: isSelected ? PharmaTheme.primaryGreen : null,
                        ),
                        onSelected: (val) {
                          if (val) setState(() => _selectedCategory = cat);
                        },
                      ),
                    );
                  }).toList(),
                ),
              ),
              const SizedBox(height: 14),

              // 4. ملاحظات شخصية أو تعليمات خاصة
              TextFormField(
                controller: _notesController,
                maxLines: 2,
                decoration: InputDecoration(
                  labelText: 'ملاحظات خاصة وتنبيهات (اختياري)',
                  hintText: 'مثال: يحفظ في الثلاجة، يؤخذ مع كوب ماء كبير...',
                  prefixIcon: const Icon(Icons.note_alt_outlined, color: PharmaTheme.primaryGreen),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                  filled: true,
                  fillColor: isDark ? const Color(0xFF1E293B) : const Color(0xFFF8FAFC),
                ),
              ),
              const SizedBox(height: 10),

              // 5. قسم التفاصيل الإضافية (اختياري ومنطوي لتفادي إرباك المريض)
              Theme(
                data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
                child: ExpansionTile(
                  tilePadding: EdgeInsets.zero,
                  leading: const Icon(Icons.tune_rounded, color: PharmaTheme.primaryGreen, size: 20),
                  title: const Text(
                    'تفاصيل إضافية (السعر والصيدلية - اختياري)',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                  ),
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _priceController,
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            decoration: InputDecoration(
                              labelText: 'السعر (ر.ي)',
                              prefixIcon: const Icon(Icons.payments_outlined),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                              isDense: true,
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: TextFormField(
                            controller: _pharmacyController,
                            decoration: InputDecoration(
                              labelText: 'اسم الصيدلية',
                              prefixIcon: const Icon(Icons.storefront_outlined),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                              isDense: true,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      value: _isAvailable,
                      activeTrackColor: PharmaTheme.primaryGreen,
                      title: const Text('متوفر حالياً لدي', style: TextStyle(fontSize: 12)),
                      onChanged: (val) => setState(() => _isAvailable = val),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // 6. أزرار الحفظ والحذف
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _isSubmitting ? null : _submit,
                      icon: _isSubmitting
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                            )
                          : const Icon(Icons.save_rounded),
                      label: Text(
                        _isEditing ? 'تحديث الدواء' : 'حفظ في خزانتي 💾',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: PharmaTheme.primaryGreen,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        elevation: 2,
                      ),
                    ),
                  ),
                  if (_isEditing) ...[
                    const SizedBox(width: 10),
                    OutlinedButton.icon(
                      onPressed: _isSubmitting ? null : _delete,
                      icon: const Icon(Icons.delete_outline_rounded, color: Colors.red, size: 18),
                      label: const Text('حذف', style: TextStyle(color: Colors.red)),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Colors.red),
                        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
