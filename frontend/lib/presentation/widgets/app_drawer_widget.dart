import 'package:flutter/material.dart';
import '../../core/network/api_service.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/theme_controller.dart';
import '../screens/pharmacy_api_screen.dart';
import '../../core/constants/app_constants.dart';
import '../../main.dart';

/// شريط التنقل الجانبي الطبي الفاخر (Luxury App Drawer):
/// - تطبيق المحاضرة السابعة (Drawer & UserAccountsDrawerHeader & CircleAvatar & ListTile)
/// - استيفاء المحاضرة العاشرة (SwitchListTile لتغيير المظهر)
/// - استيفاء المحاضرة الثامنة (التنقل بين الصفحات)

class AppDrawerWidget extends StatelessWidget {
  const AppDrawerWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: ThemeController(),
      builder: (context, _) {
        final isDark = ThemeController().isDarkMode;
        final user = ApiService().currentUser;
        final userName = user?.name ?? 'مستخدم فارما-كونكت';
        final userEmail = user?.email ?? 'مريض / باحث عن دواء';
        final isAuth = ApiService().isAuthenticated;

        return Drawer(
          backgroundColor: isDark ? PharmaTheme.darkBackground : const Color(0xFFF8FAFC),
          child: Column(
            children: [
          // 1. ترويسة الحساب الطبية الفاخرة (UserAccountsDrawerHeader - المحاضرة 7)
          Container(
            padding: EdgeInsets.fromLTRB(16, MediaQuery.paddingOf(context).top + 16, 16, 20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: isDark
                    ? [const Color(0xFF064E3B), const Color(0xFF0F172A)]
                    : [const Color(0xFF059669), const Color(0xFF065F46)],
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      radius: 28,
                      backgroundColor: isDark ? PharmaTheme.darkNeonGreen : Colors.white,
                      child: Icon(
                        Icons.person_rounded,
                        size: 32,
                        color: isDark ? PharmaTheme.darkSurface : PharmaTheme.primaryGreenDark,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Flexible(
                                child: Text(
                                  userName,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w900,
                                    fontSize: 16,
                                    color: Colors.white,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              const SizedBox(width: 4),
                              const Icon(Icons.verified_rounded, size: 16, color: Colors.amberAccent),
                            ],
                          ),
                          const SizedBox(height: 2),
                          Text(
                            userEmail,
                            style: TextStyle(
                              color: Colors.white.withAlpha(200),
                              fontSize: 12,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                // شريط معلومات سريع
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.black.withAlpha(30),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildHeaderStat('الحجوزات النشطة', '${ApiService().activeReservationsCount}'),
                      Container(width: 1, height: 20, color: Colors.white24),
                      _buildHeaderStat('المنظومة', '45 صيدلية'),
                      Container(width: 1, height: 20, color: Colors.white24),
                      _buildHeaderStat('الحالة', isAuth ? 'موثّق' : 'زائر'),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // 2. قائمة التنقل السريع (ListTile - المحاضرة 7)
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
              children: [
                _buildDrawerItem(
                  context,
                  icon: Icons.search_rounded,
                  title: 'الرئيسية والبحث عن الأدوية',
                  subtitle: 'استعلام لحظي عن الوفرة والأسعار',
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.popUntil(context, (route) => route.isFirst);
                    HomeScreen.selectTab(context, 0);
                  },
                  color: PharmaTheme.primaryGreen,
                  isDark: isDark,
                ),
                _buildDrawerItem(
                  context,
                  icon: Icons.bookmark_rounded,
                  title: 'خزانة أدويتي ومفضلتي',
                  subtitle: 'أدويتك المحفوظة للاستخدام بدون إنترنت',
                  color: Colors.amber.shade700,
                  isDark: isDark,
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.popUntil(context, (route) => route.isFirst);
                    HomeScreen.selectTab(context, 1);
                  },
                ),
                _buildDrawerItem(
                  context,
                  icon: Icons.receipt_long_rounded,
                  title: 'طلباتي وحجوزاتي',
                  subtitle: 'متابعة أكواد الحجز وتذاكر الاستلام',
                  badgeCount: ApiService().activeReservationsCount,
                  color: PharmaTheme.primaryGreen,
                  isDark: isDark,
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.popUntil(context, (route) => route.isFirst);
                    HomeScreen.selectTab(context, 2);
                  },
                ),
                _buildDrawerItem(
                  context,
                  icon: Icons.person_rounded,
                  title: 'الملف الشخصي والإعدادات',
                  subtitle: 'بيانات الحساب وتعديل الموقع',
                  color: PharmaTheme.primaryGreenDark,
                  isDark: isDark,
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.popUntil(context, (route) => route.isFirst);
                    HomeScreen.selectTab(context, 3);
                  },
                ),
                _buildDrawerItem(
                  context,
                  icon: Icons.api_rounded,
                  title: 'بوابة الصيدليات B2B API',
                  subtitle: 'واجهات الربط المحاسبي وسجل الطلبات',
                  color: PharmaTheme.primaryGreenLight,
                  isDark: isDark,
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.popUntil(context, (route) => route.isFirst);
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const PharmacyApiScreen()),
                    );
                  },
                ),

                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  child: Divider(),
                ),

                // 3. أداة SwitchListTile من المحاضرة العاشرة
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF1E293B) : Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                    ),
                  ),
                  child: SwitchListTile(
                    secondary: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF064E3B) : const Color(0xFFFEF3C7),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        isDark ? Icons.dark_mode_rounded : Icons.light_mode_rounded,
                        size: 18,
                        color: isDark ? PharmaTheme.darkNeonGreen : const Color(0xFFD97706),
                      ),
                    ),
                    title: Text(
                      'الوضع الليلي (Dark Mode)',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: isDark ? PharmaTheme.darkTextMain : PharmaTheme.textMain,
                      ),
                    ),
                    subtitle: Text(
                      isDark ? 'المظهر الداكن الطبي مفعّل' : 'المظهر النهاري الفاتح مفعّل',
                      style: TextStyle(
                        fontSize: 11,
                        color: isDark ? PharmaTheme.darkTextMuted : PharmaTheme.textMuted,
                      ),
                    ),
                    value: isDark,
                    activeTrackColor: PharmaTheme.darkNeonGreen,
                    onChanged: (bool value) {
                      ThemeController().toggleTheme();
                    },
                  ),
                ),
              ],
            ),
          ),

          // 4. زر تسجيل الدخول أو الخروج في أسفل القائمة
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isDark ? PharmaTheme.darkSurface : Colors.white,
              border: Border(
                top: BorderSide(
                  color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                ),
              ),
            ),
            child: isAuth
                ? OutlinedButton.icon(
                    onPressed: () async {
                      final navigator = Navigator.of(context, rootNavigator: true);
                      await ApiService().logout();
                      navigator.pushNamedAndRemoveUntil(
                        AppConstants.authRoute,
                        (route) => false,
                      );
                    },
                    icon: const Icon(Icons.logout_rounded, color: Colors.red, size: 18),
                    label: const Text('تسجيل الخروج من الحساب', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Colors.red),
                      minimumSize: const Size(double.infinity, 44),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  )
                : ElevatedButton.icon(
                    onPressed: () {
                      final navigator = Navigator.of(context, rootNavigator: true);
                      navigator.pushNamedAndRemoveUntil(
                        AppConstants.authRoute,
                        (route) => false,
                      );
                    },
                    icon: const Icon(Icons.login_rounded, size: 18),
                    label: const Text('تسجيل الدخول / إنشاء حساب', style: TextStyle(fontWeight: FontWeight.bold)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: PharmaTheme.primaryGreen,
                      foregroundColor: Colors.white,
                      minimumSize: const Size(double.infinity, 44),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
          ),
        ],
      ),
    );
      },
    );
  }

  static Widget _buildHeaderStat(String label, String value) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 13),
        ),
        Text(
          label,
          style: TextStyle(color: Colors.white.withAlpha(190), fontSize: 10),
        ),
      ],
    );
  }

  static Widget _buildDrawerItem(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    required Color color,
    required bool isDark,
    int? badgeCount,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 3),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(isDark ? 20 : 6),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ListTile(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withAlpha(isDark ? 50 : 25),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: color, size: 20),
        ),
        title: Text(
          title,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 13,
            color: isDark ? PharmaTheme.darkTextMain : PharmaTheme.textMain,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: TextStyle(
            fontSize: 11,
            color: isDark ? PharmaTheme.darkTextMuted : PharmaTheme.textMuted,
          ),
        ),
        trailing: badgeCount != null && badgeCount > 0
            ? Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: PharmaTheme.primaryGreen,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text('$badgeCount', style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
              )
            : Icon(
                Icons.arrow_back_ios_new_rounded,
                size: 13,
                color: isDark ? PharmaTheme.darkTextMuted : const Color(0xFF94A3B8),
              ),
        onTap: onTap,
      ),
    );
  }
}
