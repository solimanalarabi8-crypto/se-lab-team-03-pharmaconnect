import 'package:flutter/material.dart';
import '../../core/constants/app_enums.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/theme_controller.dart';

/// بطاقة وخيارات الفرز والتصفية المتقدمة (Luxury Medical Filter Card):
/// - تطبيق المحاضرة العاشرة كاملة:
///   1. DropdownButton & DropdownMenuItem (للفئات الدوائية)
///   2. CheckboxListTile (للتوفر ودوام 24 ساعة)
///   3. RadioListTile (لترتيب النتائج مع groupValue موحدة)
///   4. SwitchListTile (لتفعيل البحث الجغرافي الفوري GPS)
/// - تصميم واجهة مستخدم احترافي يدعم التصفية السريعة والـ Modal Bottom Sheet

class MedicineFilterCard extends StatefulWidget {
  final String selectedCategory;
  final bool availableOnly;
  final bool open24HoursOnly;
  final bool gpsEnabled;
  final MedicineSortOption currentSort;
  final Function({
    required String category,
    required bool availableOnly,
    required bool open24HoursOnly,
    required bool gpsEnabled,
    required MedicineSortOption sortOption,
  }) onFiltersChanged;

  const MedicineFilterCard({
    super.key,
    required this.selectedCategory,
    required this.availableOnly,
    required this.open24HoursOnly,
    required this.gpsEnabled,
    required this.currentSort,
    required this.onFiltersChanged,
  });

  /// دالة لفتح نافذة الفلاتر السفلية المودال (Filter Bottom Sheet)
  static void showFilterSheet(
    BuildContext context, {
    required String selectedCategory,
    required bool availableOnly,
    required bool open24HoursOnly,
    required bool gpsEnabled,
    required MedicineSortOption currentSort,
    required Function({
      required String category,
      required bool availableOnly,
      required bool open24HoursOnly,
      required bool gpsEnabled,
      required MedicineSortOption sortOption,
    }) onFiltersChanged,
  }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: const EdgeInsets.only(top: 12),
        decoration: BoxDecoration(
          color: Theme.of(ctx).scaffoldBackgroundColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 44,
                height: 4,
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              MedicineFilterCard(
                selectedCategory: selectedCategory,
                availableOnly: availableOnly,
                open24HoursOnly: open24HoursOnly,
                gpsEnabled: gpsEnabled,
                currentSort: currentSort,
                onFiltersChanged: onFiltersChanged,
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  @override
  State<MedicineFilterCard> createState() => _MedicineFilterCardState();
}

class _MedicineFilterCardState extends State<MedicineFilterCard> {
  late String _category;
  late bool _availableOnly;
  late bool _open24HoursOnly;
  late bool _gpsEnabled;
  late MedicineSortOption _currentSort;
  bool _isExpanded = false;

  final List<String> _categories = [
    'الكل',
    'مضادات حيوية',
    'مسكنات وخافض حرارة',
    'أدوية الأمراض المزمنة',
    'فيتامينات ومكملات',
    'أدوية الجهاز الهضمي',
  ];

  @override
  void initState() {
    super.initState();
    _category = widget.selectedCategory;
    _availableOnly = widget.availableOnly;
    _open24HoursOnly = widget.open24HoursOnly;
    _gpsEnabled = widget.gpsEnabled;
    _currentSort = widget.currentSort;
  }

  void _applyChanges() {
    widget.onFiltersChanged(
      category: _category,
      availableOnly: _availableOnly,
      open24HoursOnly: _open24HoursOnly,
      gpsEnabled: _gpsEnabled,
      sortOption: _currentSort,
    );
  }

  void _resetFilters() {
    setState(() {
      _category = 'الكل';
      _availableOnly = false;
      _open24HoursOnly = false;
      _gpsEnabled = true;
      _currentSort = MedicineSortOption.nearest;
    });
    _applyChanges();
  }

  int get _activeFiltersCount {
    int count = 0;
    if (_category != 'الكل') count++;
    if (_availableOnly) count++;
    if (_open24HoursOnly) count++;
    if (_currentSort != MedicineSortOption.nearest) count++;
    return count;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = ThemeController().isDarkMode;
    final activeCount = _activeFiltersCount;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      decoration: BoxDecoration(
        color: isDark ? PharmaTheme.darkSurface : Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: isDark ? Colors.black.withAlpha(20) : const Color(0x060F172A),
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
            // ترويسة بطاقة الفلاتر التفاعلية
            InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: () {
                setState(() {
                  _isExpanded = !_isExpanded;
                });
              },
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: isDark ? const Color(0xFF064E3B) : PharmaTheme.mintBackground,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(
                            Icons.tune_rounded,
                            size: 18,
                            color: PharmaTheme.primaryGreen,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'خيارات الفرز والتصفية الذكية',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                                color: isDark ? Colors.white : PharmaTheme.textMain,
                              ),
                            ),
                            Text(
                              activeCount > 0 ? '$activeCount فلاتر مفعّلة حالياً' : 'تصفية حسب التوفر، السعر، والمسافة',
                              style: TextStyle(
                                fontSize: 11,
                                color: activeCount > 0 ? PharmaTheme.primaryGreen : Colors.grey.shade500,
                                fontWeight: activeCount > 0 ? FontWeight.bold : FontWeight.normal,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    Row(
                      children: [
                        if (activeCount > 0)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            margin: const EdgeInsets.only(left: 6),
                            decoration: BoxDecoration(
                              color: PharmaTheme.primaryGreen,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              '$activeCount',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        Icon(
                          _isExpanded ? Icons.keyboard_arrow_up_rounded : Icons.keyboard_arrow_down_rounded,
                          color: isDark ? Colors.white70 : Colors.grey.shade600,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            // شريط الفلاتر السريعة (Quick Filter Pills)
            const SizedBox(height: 8),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  // شارة المتوفر فقط
                  FilterChip(
                    label: const Text('متوفر الآن'),
                    selected: _availableOnly,
                    onSelected: (val) {
                      setState(() => _availableOnly = val);
                      _applyChanges();
                    },
                    selectedColor: isDark ? const Color(0xFF064E3B) : PharmaTheme.mintAccent,
                    checkmarkColor: PharmaTheme.primaryGreen,
                    labelStyle: TextStyle(
                      fontSize: 12,
                      fontWeight: _availableOnly ? FontWeight.bold : FontWeight.normal,
                      color: _availableOnly
                          ? (isDark ? PharmaTheme.darkNeonGreen : PharmaTheme.primaryGreenDark)
                          : (isDark ? Colors.white70 : Colors.grey.shade700),
                    ),
                  ),
                  const SizedBox(width: 6),
                  // شارة الأقرب
                  FilterChip(
                    label: const Text('الأقرب إليك'),
                    selected: _currentSort == MedicineSortOption.nearest,
                    onSelected: (val) {
                      setState(() => _currentSort = MedicineSortOption.nearest);
                      _applyChanges();
                    },
                    selectedColor: isDark ? const Color(0xFF064E3B) : PharmaTheme.mintAccent,
                    checkmarkColor: PharmaTheme.primaryGreen,
                    labelStyle: TextStyle(
                      fontSize: 12,
                      fontWeight: _currentSort == MedicineSortOption.nearest ? FontWeight.bold : FontWeight.normal,
                      color: _currentSort == MedicineSortOption.nearest
                          ? (isDark ? PharmaTheme.darkNeonGreen : PharmaTheme.primaryGreenDark)
                          : (isDark ? Colors.white70 : Colors.grey.shade700),
                    ),
                  ),
                  const SizedBox(width: 6),
                  // شارة الأقل سعراً
                  FilterChip(
                    label: const Text('الأقل سعراً'),
                    selected: _currentSort == MedicineSortOption.lowestPrice,
                    onSelected: (val) {
                      setState(() => _currentSort = MedicineSortOption.lowestPrice);
                      _applyChanges();
                    },
                    selectedColor: isDark ? const Color(0xFF064E3B) : PharmaTheme.mintAccent,
                    checkmarkColor: PharmaTheme.primaryGreen,
                    labelStyle: TextStyle(
                      fontSize: 12,
                      fontWeight: _currentSort == MedicineSortOption.lowestPrice ? FontWeight.bold : FontWeight.normal,
                      color: _currentSort == MedicineSortOption.lowestPrice
                          ? (isDark ? PharmaTheme.darkNeonGreen : PharmaTheme.primaryGreenDark)
                          : (isDark ? Colors.white70 : Colors.grey.shade700),
                    ),
                  ),
                  const SizedBox(width: 6),
                  // شارة 24/7
                  FilterChip(
                    label: const Text('صيدليات 24/7'),
                    selected: _open24HoursOnly,
                    onSelected: (val) {
                      setState(() => _open24HoursOnly = val);
                      _applyChanges();
                    },
                    selectedColor: isDark ? const Color(0xFF064E3B) : PharmaTheme.mintAccent,
                    checkmarkColor: PharmaTheme.primaryGreen,
                    labelStyle: TextStyle(
                      fontSize: 12,
                      fontWeight: _open24HoursOnly ? FontWeight.bold : FontWeight.normal,
                      color: _open24HoursOnly
                          ? (isDark ? PharmaTheme.darkNeonGreen : PharmaTheme.primaryGreenDark)
                          : (isDark ? Colors.white70 : Colors.grey.shade700),
                    ),
                  ),
                ],
              ),
            ),

            // التفاصيل الموسعة التي تضم أدوات المحاضرة العاشرة كاملة
            if (_isExpanded) ...[
              const Divider(height: 24),

              // 1. أداة DropdownButton و DropdownMenuItem (المحاضرة 10)
              const Text(
                'التصنيف الدوائي (القائمة المنسدلة):',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: isDark ? const Color(0xFF334155) : const Color(0xFFCBD5E1)),
                  color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    isExpanded: true,
                    value: _category,
                    dropdownColor: isDark ? PharmaTheme.darkSurface : Colors.white,
                    icon: const Icon(Icons.keyboard_arrow_down_rounded, color: PharmaTheme.primaryGreen),
                    items: _categories.map((String cat) {
                      return DropdownMenuItem<String>(
                        value: cat,
                        child: Text(cat, style: const TextStyle(fontSize: 13)),
                      );
                    }).toList(),
                    onChanged: (String? newValue) {
                      if (newValue != null) {
                        setState(() => _category = newValue);
                        _applyChanges();
                      }
                    },
                  ),
                ),
              ),

              const SizedBox(height: 14),

              // 2. أدوات CheckboxListTile (المحاضرة 10)
              const Text(
                'حالة التوفر والخدمة (مربعات الاختيار):',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
              ),
              CheckboxListTile(
                value: _availableOnly,
                activeColor: PharmaTheme.primaryGreen,
                contentPadding: EdgeInsets.zero,
                secondary: const Icon(Icons.check_circle_outline_rounded, color: PharmaTheme.primaryGreen, size: 20),
                title: const Text('الأدوية المتوفرة بالمخزون فقط', style: TextStyle(fontSize: 13)),
                onChanged: (bool? val) {
                  setState(() => _availableOnly = val ?? false);
                  _applyChanges();
                },
              ),
              CheckboxListTile(
                value: _open24HoursOnly,
                activeColor: PharmaTheme.primaryGreen,
                contentPadding: EdgeInsets.zero,
                secondary: const Icon(Icons.nightlight_round, color: Colors.indigo, size: 20),
                title: const Text('صيدليات تعمل على مدار 24 ساعة', style: TextStyle(fontSize: 13)),
                onChanged: (bool? val) {
                  setState(() => _open24HoursOnly = val ?? false);
                  _applyChanges();
                },
              ),

              const Divider(height: 16),

              // 3. أداة SwitchListTile (المحاضرة 10)
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('البحث الجغرافي الفوري (GPS)', style: TextStyle(fontSize: 13)),
                subtitle: const Text('حساب المسافة والترتيب بالاعتماد على موقعك', style: TextStyle(fontSize: 11)),
                secondary: const Icon(Icons.my_location_rounded, color: PharmaTheme.primaryGreenLight, size: 20),
                value: _gpsEnabled,
                activeTrackColor: PharmaTheme.primaryGreen,
                onChanged: (bool val) {
                  setState(() => _gpsEnabled = val);
                  _applyChanges();
                },
              ),

              const Divider(height: 16),

              // 4. أداة RadioListTile (المحاضرة 10)
              const Text(
                'ترتيب النتائج (أزرار الاختيار الأحادي Radio):',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
              ),
              ...MedicineSortOption.values.map((option) {
                return RadioListTile<MedicineSortOption>(
                  value: option,
                  // ignore: deprecated_member_use
                  groupValue: _currentSort,
                  activeColor: PharmaTheme.primaryGreen,
                  contentPadding: EdgeInsets.zero,
                  title: Text(option.label, style: const TextStyle(fontSize: 13)),
                  subtitle: Text(option.subtitle, style: const TextStyle(fontSize: 11)),
                  // ignore: deprecated_member_use
                  onChanged: (MedicineSortOption? val) {
                    if (val != null) {
                      setState(() => _currentSort = val);
                      _applyChanges();
                    }
                  },
                );
              }),

              const SizedBox(height: 12),

              // أزرار التحكم
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () {
                        setState(() => _isExpanded = false);
                        _applyChanges();
                      },
                      icon: const Icon(Icons.done_rounded, size: 16),
                      label: const Text('إغلاق وتطبيق الفلاتر'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: PharmaTheme.primaryGreen,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        padding: const EdgeInsets.symmetric(vertical: 10),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  OutlinedButton(
                    onPressed: _resetFilters,
                    style: OutlinedButton.styleFrom(
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 14),
                    ),
                    child: const Text('إعادة ضبط', style: TextStyle(fontSize: 12)),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}
