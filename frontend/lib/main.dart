import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'core/constants/app_constants.dart';
import 'core/constants/app_enums.dart';
import 'core/network/api_service.dart';
import 'core/theme/app_theme.dart';
import 'core/theme/theme_controller.dart';
import 'data/models/medicine_search_model.dart';
import 'presentation/screens/auth_screen.dart';
import 'presentation/screens/medicine_details_screen.dart';
import 'presentation/screens/my_reservations_screen.dart';
import 'presentation/screens/pharmacy_api_screen.dart';
import 'presentation/screens/profile_screen.dart';
import 'presentation/screens/saved_medicines_screen.dart';
import 'presentation/widgets/app_drawer_widget.dart';
import 'presentation/widgets/medicine_card_widget.dart';
import 'presentation/widgets/medicine_filter_card.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  if (!kIsWeb && (Platform.isWindows || Platform.isLinux || Platform.isMacOS)) {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  }
  runApp(const PharmaConnectApp());
}

/// كلاس التطبيق الرئيسي PharmaConnectApp:
/// - تطبيق معايير واجهات المستخدم الطبية الحديثة وتوافق WCAG 2.1 AA
/// - استيفاء المحاضرة الخامسة (runApp, StatefulWidget, MaterialApp & Scaffold)
/// - استيفاء المحاضرة الثامنة (جدول المسارات المسماة routes: {} ومولد المسارات onGenerateRoute)
class PharmaConnectApp extends StatefulWidget {
  const PharmaConnectApp({super.key});

  @override
  State<PharmaConnectApp> createState() => _PharmaConnectAppState();
}

class _PharmaConnectAppState extends State<PharmaConnectApp> {
  @override
  void initState() {
    super.initState();
    ThemeController().addListener(_onThemeChanged);
  }

  @override
  void dispose() {
    ThemeController().removeListener(_onThemeChanged);
    super.dispose();
  }

  void _onThemeChanged() {
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: AppConstants.appName,
      debugShowCheckedModeBanner: false,
      theme: PharmaTheme.lightTheme,
      darkTheme: PharmaTheme.darkTheme,
      themeMode: ThemeController().themeMode,
      locale: const Locale('ar', 'YE'),
      supportedLocales: const [
        Locale('ar', 'YE'),
        Locale('ar', ''),
      ],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],

      // جدول المسارات المسماة (المحاضرة 8)
      initialRoute: ApiService().isAuthenticated ? AppConstants.homeRoute : AppConstants.authRoute,
      routes: {
        AppConstants.homeRoute: (context) => HomeScreen(key: HomeScreen.homeKey),
        AppConstants.authRoute: (context) => const AuthScreen(),
        AppConstants.reservationsRoute: (context) => const MyReservationsScreen(),
        AppConstants.savedMedicinesRoute: (context) => const SavedMedicinesScreen(),
        AppConstants.pharmacyApiRoute: (context) => const PharmacyApiScreen(),
        AppConstants.profileRoute: (context) => const ProfileScreen(),
      },
      onGenerateRoute: (settings) {
        if (settings.name == AppConstants.medicineDetailsRoute) {
          final item = settings.arguments as MedicineSearchItem?;
          if (item != null) {
            return MaterialPageRoute(
              builder: (context) => MedicineDetailsScreen(item: item),
              settings: settings,
            );
          }
        }
        return null;
      },
    );
  }
}

/// الشاشة الرئيسية الاحترافية HomeScreen (World-Class Medical Experience):
/// - تطبيق المحاضرة السابعة (AppBar, Drawer, BottomNavigationBar, Tabs)
/// - استيفاء المحاضرة العاشرة (الفلاتر والقوائم المنسدلة وأزرار الاختيار)
/// - استيفاء المحاضرة السادسة والتاسعة (بطاقات الأدوية والحفظ المحلي بـ SQLite)
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  static final GlobalKey<HomeScreenState> homeKey = GlobalKey<HomeScreenState>();

  /// تبديل التبويب برمجياً من أي مكان داخل التطبيق
  static void selectTab(BuildContext context, int tabIndex) {
    if (homeKey.currentState != null) {
      homeKey.currentState!.switchTab(tabIndex);
    } else {
      final state = context.findAncestorStateOfType<HomeScreenState>();
      state?.switchTab(tabIndex);
    }
  }

  @override
  State<HomeScreen> createState() => HomeScreenState();
}

class HomeScreenState extends State<HomeScreen> {
  int _currentTabIndex = 0;

  void switchTab(int index) {
    if (mounted) {
      setState(() {
        _currentTabIndex = index;
      });
    }
  }
  final TextEditingController _searchController = TextEditingController();
  List<MedicineSearchItem> _searchResults = [];
  bool _isLoading = false;
  Timer? _badgeTicker;

  // إعدادات الفرز والتصفية (المحاضرة 10)
  String _selectedCategory = 'الكل';
  bool _availableOnly = false;
  bool _open24HoursOnly = false;
  bool _gpsEnabled = true;
  MedicineSortOption _sortOption = MedicineSortOption.nearest;

  // فئات الأدوية التفاعلية مع الأيقونات
  final List<Map<String, dynamic>> _categoryItems = [
    {'name': 'الكل', 'icon': Icons.medical_services_rounded},
    {'name': 'مضادات حيوية', 'icon': Icons.biotech_rounded},
    {'name': 'مسكنات وخافض حرارة', 'icon': Icons.healing_rounded},
    {'name': 'أدوية الأمراض المزمنة', 'icon': Icons.favorite_rounded},
    {'name': 'فيتامينات ومكملات', 'icon': Icons.spa_rounded},
    {'name': 'أدوية الجهاز الهضمي', 'icon': Icons.water_drop_rounded},
  ];

  final List<String> _popularKeywords = [
    'Panadol Extra',
    'Augmentin',
    'Brufen',
    'Norvasc',
    'Amoxicillin',
    'Paracetamol',
  ];

  @override
  void initState() {
    super.initState();
    _fetchMedicines();
    _badgeTicker = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() {});
    });
    ApiService().addListener(_onApiChange);
  }

  void _onApiChange() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _badgeTicker?.cancel();
    ApiService().removeListener(_onApiChange);
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _fetchMedicines([String? query]) async {
    final cleanQuery = query?.trim() ?? '';
    setState(() {
      _isLoading = true;
    });

    final results = await ApiService().searchMedicines(query: cleanQuery.isEmpty ? null : cleanQuery);

    if (mounted) {
      setState(() {
        _searchResults = results;
        _isLoading = false;
      });
    }
  }

  void _onQuickSearch(String keyword) {
    _searchController.text = keyword;
    _fetchMedicines(keyword);
  }

  void _onFiltersChanged({
    required String category,
    required bool availableOnly,
    required bool open24HoursOnly,
    required bool gpsEnabled,
    required MedicineSortOption sortOption,
  }) {
    setState(() {
      _selectedCategory = category;
      _availableOnly = availableOnly;
      _open24HoursOnly = open24HoursOnly;
      _gpsEnabled = gpsEnabled;
      _sortOption = sortOption;
    });
  }

  List<MedicineSearchItem> get _filteredResults {
    var list = List<MedicineSearchItem>.from(_searchResults);

    // تصفية الفئة
    if (_selectedCategory != 'الكل') {
      list = list.where((item) =>
          item.medicine.category?.toLowerCase() == _selectedCategory.toLowerCase() ||
          item.medicine.tradeName.contains(_selectedCategory)).toList();
    }

    // تصفية التوفر
    if (_availableOnly) {
      list = list.where((item) => item.status == 'available' && item.availableQuantity > 0).toList();
    }

    // ترتيب النتائج
    switch (_sortOption) {
      case MedicineSortOption.nearest:
        list.sort((a, b) => (a.distanceKm ?? 999.0).compareTo(b.distanceKm ?? 999.0));
        break;
      case MedicineSortOption.lowestPrice:
        list.sort((a, b) => a.price.compareTo(b.price));
        break;
      case MedicineSortOption.highestStock:
        list.sort((a, b) => b.availableQuantity.compareTo(a.availableQuantity));
        break;
      case MedicineSortOption.alphabetical:
        list.sort((a, b) => a.medicine.tradeName.compareTo(b.medicine.tradeName));
        break;
    }

    return list;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = ThemeController().isDarkMode;
    final user = ApiService().currentUser;

    return PopScope(
      canPop: _currentTabIndex == 0,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        if (_currentTabIndex != 0) {
          setState(() {
            _currentTabIndex = 0;
          });
        }
      },
      child: Scaffold(
        drawer: const AppDrawerWidget(),
      appBar: _currentTabIndex == 0
          ? AppBar(
              elevation: 0,
              leading: Builder(
                builder: (ctx) => IconButton(
                  icon: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      Icons.menu_rounded,
                      size: 20,
                      color: isDark ? PharmaTheme.darkNeonGreen : PharmaTheme.primaryGreenDark,
                    ),
                  ),
                  onPressed: () => Scaffold.of(ctx).openDrawer(),
                ),
              ),
              titleSpacing: 0,
              title: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        user != null ? 'مرحباً، ${user.name.split(' ').first}' : 'مرحباً بك',
                        style: TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 16,
                          color: isDark ? Colors.white : const Color(0xFF0F172A),
                        ),
                      ),
                      const SizedBox(width: 4),
                      const Text('🌿', style: TextStyle(fontSize: 14)),
                    ],
                  ),
                  Row(
                    children: [
                      const Icon(Icons.location_on_rounded, size: 12, color: PharmaTheme.primaryGreen),
                      const SizedBox(width: 2),
                      Text(
                        'صنعاء، اليمن • 45 صيدلية نشطة',
                        style: TextStyle(
                          fontSize: 11,
                          color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              actions: [
                IconButton(
                  tooltip: isDark ? 'الوضع النهاري' : 'الوضع الليلي',
                  icon: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      isDark ? Icons.light_mode_rounded : Icons.dark_mode_outlined,
                      size: 20,
                      color: isDark ? PharmaTheme.darkNeonGreen : PharmaTheme.primaryGreenDark,
                    ),
                  ),
                  onPressed: () => ThemeController().toggleTheme(),
                ),
                const SizedBox(width: 8),
              ],
            )
          : null,
      body: _buildSelectedTabBody(),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: isDark ? PharmaTheme.darkSurface : Colors.white,
          border: Border(
            top: BorderSide(
              color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
              width: 1,
            ),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha(isDark ? 30 : 8),
              blurRadius: 16,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: BottomNavigationBar(
          type: BottomNavigationBarType.fixed,
          backgroundColor: Colors.transparent,
          elevation: 0,
          currentIndex: _currentTabIndex,
          selectedItemColor: isDark ? PharmaTheme.darkNeonGreen : PharmaTheme.primaryGreen,
          unselectedItemColor: isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8),
          selectedLabelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
          unselectedLabelStyle: const TextStyle(fontSize: 11),
          onTap: (index) {
            setState(() {
              _currentTabIndex = index;
            });
          },
          items: [
            const BottomNavigationBarItem(
              icon: Icon(Icons.search_rounded),
              activeIcon: Icon(Icons.saved_search_rounded),
              label: 'البحث والوفرة',
            ),
            const BottomNavigationBarItem(
              icon: Icon(Icons.bookmark_border_rounded),
              activeIcon: Icon(Icons.bookmark_rounded),
              label: 'خزانتي الخاصة',
            ),
            BottomNavigationBarItem(
              icon: ApiService().activeReservationsCount > 0
                  ? Badge(
                      label: Text('${ApiService().activeReservationsCount}'),
                      child: const Icon(Icons.receipt_long_outlined),
                    )
                  : const Icon(Icons.receipt_long_outlined),
              activeIcon: ApiService().activeReservationsCount > 0
                  ? Badge(
                      label: Text('${ApiService().activeReservationsCount}'),
                      child: const Icon(Icons.receipt_long_rounded),
                    )
                  : const Icon(Icons.receipt_long_rounded),
              label: 'حجوزاتي',
            ),
            const BottomNavigationBarItem(
              icon: Icon(Icons.person_outline_rounded),
              activeIcon: Icon(Icons.person_rounded),
              label: 'حسابي',
            ),
          ],
        ),
      ),
    ),
  );
  }

  Widget _buildSelectedTabBody() {
    switch (_currentTabIndex) {
      case 0:
        return _buildSearchTab();
      case 1:
        return const SavedMedicinesScreen();
      case 2:
        return const MyReservationsScreen();
      case 3:
        return const ProfileScreen();
      default:
        return _buildSearchTab();
    }
  }

  Widget _buildSearchTab() {
    final isDark = ThemeController().isDarkMode;
    final results = _filteredResults;

    return RefreshIndicator(
      onRefresh: () => _fetchMedicines(_searchController.text),
      color: PharmaTheme.primaryGreen,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. ترويسة البحث الذكية الفاخرة (Hero Search Header)
            Container(
              margin: const EdgeInsets.fromLTRB(16, 8, 16, 12),
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: isDark
                      ? [const Color(0xFF064E3B), const Color(0xFF0F172A)]
                      : [const Color(0xFF059669), const Color(0xFF047857)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF059669).withAlpha(isDark ? 60 : 80),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'ابحث عن دوائك الآن',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'استعلم فورياً عن وفرة الأدوية، الأسعار، وأقرب صيدلية إليك',
                    style: TextStyle(
                      color: Colors.white.withAlpha(220),
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 16),

                  // حقل الإدخال العائم الفاخر
                  Container(
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF1E293B) : Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withAlpha(25),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: TextField(
                      controller: _searchController,
                      onChanged: (val) => _fetchMedicines(val),
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: isDark ? Colors.white : const Color(0xFF0F172A),
                      ),
                      decoration: InputDecoration(
                        hintText: 'اكتب اسم الدواء التجاري أو العلمي...',
                        hintStyle: TextStyle(
                          color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF94A3B8),
                          fontSize: 13,
                        ),
                        prefixIcon: const Icon(Icons.search_rounded, color: PharmaTheme.primaryGreen, size: 24),
                        suffixIcon: _searchController.text.isNotEmpty
                            ? IconButton(
                                icon: const Icon(Icons.clear_rounded, size: 20),
                                onPressed: () {
                                  _searchController.clear();
                                  _fetchMedicines('');
                                },
                              )
                            : IconButton(
                                tooltip: 'خيارات الفلاتر',
                                icon: const Icon(Icons.tune_rounded, color: PharmaTheme.primaryGreen, size: 20),
                                onPressed: () {
                                  MedicineFilterCard.showFilterSheet(
                                    context,
                                    selectedCategory: _selectedCategory,
                                    availableOnly: _availableOnly,
                                    open24HoursOnly: _open24HoursOnly,
                                    gpsEnabled: _gpsEnabled,
                                    currentSort: _sortOption,
                                    onFiltersChanged: _onFiltersChanged,
                                  );
                                },
                              ),
                        border: InputBorder.none,
                        enabledBorder: InputBorder.none,
                        focusedBorder: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // 2. شريط التصنيفات الدوائية التفاعلي الفاخر (Medical Category Carousel)
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: Text(
                'التصنيفات العلاجية:',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
              ),
            ),
            const SizedBox(height: 8),
            SizedBox(
              height: 42,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: _categoryItems.length,
                separatorBuilder: (context, index) => const SizedBox(width: 8),
                itemBuilder: (context, index) {
                  final cat = _categoryItems[index];
                  final isSelected = _selectedCategory == cat['name'];
                  return GestureDetector(
                    onTap: () {
                      setState(() {
                        _selectedCategory = cat['name'] as String;
                      });
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? PharmaTheme.primaryGreen
                            : (isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9)),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isSelected
                              ? PharmaTheme.primaryGreen
                              : (isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            cat['icon'] as IconData,
                            size: 16,
                            color: isSelected
                                ? Colors.white
                                : (isDark ? PharmaTheme.darkNeonGreen : PharmaTheme.primaryGreenDark),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            cat['name'] as String,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                              color: isSelected
                                  ? Colors.white
                                  : (isDark ? Colors.white70 : const Color(0xFF334155)),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 10),

            // 3. بطاقة الفلاتر الذكية والخيارات السريعة (المحاضرة 10)
            MedicineFilterCard(
              selectedCategory: _selectedCategory,
              availableOnly: _availableOnly,
              open24HoursOnly: _open24HoursOnly,
              gpsEnabled: _gpsEnabled,
              currentSort: _sortOption,
              onFiltersChanged: _onFiltersChanged,
            ),

            // 4. الكلمات الأكثر بحثاً (تظهر عند عدم الكتابة في حقل البحث)
            if (_searchController.text.trim().isEmpty) ...[
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'الأدوية الأكثر بحثاً بالصيدليات:',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: _popularKeywords.map((kw) {
                        return ActionChip(
                          avatar: const Icon(Icons.medication_outlined, size: 16, color: PharmaTheme.primaryGreen),
                          label: Text(kw),
                          backgroundColor: isDark ? const Color(0xFF1E293B) : const Color(0xFFF8FAFC),
                          side: BorderSide(
                            color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                          ),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          onPressed: () => _onQuickSearch(kw),
                        );
                      }).toList(),
                    ),
                  ],
                ),
              ),
            ],

            // 5. شريط عنوان النتائج
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 6),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      _searchController.text.trim().isNotEmpty
                          ? 'نتائج البحث عن «${_searchController.text.trim()}»'
                          : (_selectedCategory != 'الكل'
                              ? 'أدوية «$_selectedCategory»'
                              : 'الأدوية المتوفرة بالصيدليات والمستودعات'),
                      style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '${results.length} دواء',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: isDark ? PharmaTheme.darkNeonGreen : PharmaTheme.primaryGreenDark,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            if (_isLoading)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 48),
                child: Center(
                  child: CircularProgressIndicator(color: PharmaTheme.primaryGreen),
                ),
              )
            else if (results.isEmpty)
              Center(
                child: Padding(
                  padding: const EdgeInsets.all(36.0),
                  child: Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(Icons.search_off_rounded, size: 54, color: Colors.grey.shade400),
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'لم يتم العثور على أدوية مطابقة',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'تأكد من كتابة الاسم بصورة صحيحة أو جرب اختيار تصنيف دوائي آخر',
                        style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              )
            else
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: results.length,
                itemBuilder: (context, index) {
                  final item = results[index];
                  return MedicineCardWidget(
                    item: item,
                    onReservePressed: () async {
                      final reserved = await Navigator.push<bool>(
                        context,
                        MaterialPageRoute(
                          builder: (context) => MedicineDetailsScreen(item: item),
                        ),
                      );
                      if (reserved == true && mounted) {
                        _fetchMedicines(_searchController.text);
                      }
                    },
                  );
                },
              ),
            const SizedBox(height: 28),
          ],
        ),
      ),
    );
  }
}
