import 'dart:math';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/services/location_service.dart';
import '../../core/theme/app_theme.dart';
import '../../data/models/medicine_search_model.dart';

class PharmacyRouteMapWidget extends StatefulWidget {
  final PharmacyInfo pharmacy;
  final double? distanceKm;
  final double? initialDistanceKm;

  const PharmacyRouteMapWidget({
    super.key,
    required this.pharmacy,
    this.distanceKm,
    this.initialDistanceKm,
  });

  @override
  State<PharmacyRouteMapWidget> createState() => _PharmacyRouteMapWidgetState();
}

class _PharmacyRouteMapWidgetState extends State<PharmacyRouteMapWidget> {
  final LocationService _locationService = LocationService();

  @override
  void initState() {
    super.initState();
    // جلب موقع العميل الفعلي بأمان بعد اكتمال مرحلة بناء الشجرة الأولى
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _locationService.fetchCurrentLocation();
      }
    });
  }

  // تحويل إحداثيات خطوط الطول والعرض إلى أرقام مربعات الخرائط الحقيقية (Web Mercator Slippy Tiles)
  int _lon2tile(double lon, int zoom) =>
      ((lon + 180.0) / 360.0 * (1 << zoom)).floor();

  int _lat2tile(double lat, int zoom) {
    final latRad = lat * pi / 180.0;
    return ((1.0 - (log(tan(latRad) + 1.0 / cos(latRad)) / pi)) / 2.0 * (1 << zoom)).floor();
  }

  Future<void> _openGoogleMapsRoute(double userLat, double userLng, double destLat, double destLng) async {
    final uri = Uri.parse(
      'https://www.google.com/maps/dir/?api=1&origin=$userLat,$userLng&destination=$destLat,$destLng&travelmode=driving',
    );

    try {
      if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
        await launchUrl(uri, mode: LaunchMode.platformDefault);
      }
    } catch (_) {
      // تجاهل الخطأ في حالة تعذر تشغيل التطبيق الخارجي
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = isDark ? PharmaTheme.darkSurface : Colors.white;
    final borderColor = isDark ? PharmaTheme.darkBorder : const Color(0xFFE2E8F0);
    final textMutedColor = isDark ? PharmaTheme.darkTextMuted : PharmaTheme.textMuted;
    final textMainColor = isDark ? PharmaTheme.darkTextMain : PharmaTheme.textMain;

    final destLat = widget.pharmacy.latitude ?? 15.32685;
    final destLng = widget.pharmacy.longitude ?? 44.19512;

    return ListenableBuilder(
      listenable: _locationService,
      builder: (context, _) {
        final userLat = _locationService.userLat;
        final userLng = _locationService.userLng;
        final isLocating = _locationService.isLocating;

        // حساب المسافة الحقيقية الدقيقة
        final calculatedDist = _locationService.calculateDistance(destLat, destLng);
        final distanceKm = calculatedDist > 0 ? calculatedDist : (widget.distanceKm ?? widget.initialDistanceKm ?? 1.2);

        final drivingMinutes = (distanceKm * 3.5).clamp(2, 60).ceil();
        final walkingMinutes = (distanceKm * 12).clamp(5, 180).ceil();

        // حساب بلاطات الخريطة الحقيقية لصنعاء عند مستوى تقريب 15
        const zoom = 15;
        final tileX = _lon2tile(destLng, zoom);
        final tileY = _lat2tile(destLat, zoom);

        // روابط بلاطات الخرائط الحقيقية العالمية المفتوحة (CartoDB Voyager للنهاري، Dark Matter لليلي)
        final tileUrl1 = isDark
            ? 'https://basemaps.cartocdn.com/rastertiles/dark_all/$zoom/$tileX/$tileY.png'
            : 'https://basemaps.cartocdn.com/rastertiles/voyager/$zoom/$tileX/$tileY.png';
        
        final tileUrl2 = isDark
            ? 'https://basemaps.cartocdn.com/rastertiles/dark_all/$zoom/${tileX + 1}/$tileY.png'
            : 'https://basemaps.cartocdn.com/rastertiles/voyager/$zoom/${tileX + 1}/$tileY.png';

        return Container(
          decoration: BoxDecoration(
            color: cardBg,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: borderColor),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withAlpha(isDark ? 35 : 10),
                blurRadius: 16,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // رأس الخريطة مع زر تحديد الموقع الفعلي
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF064E3B) : PharmaTheme.mintAccent,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Icon(
                        Icons.map_rounded,
                        color: isDark ? PharmaTheme.darkNeonGreen : PharmaTheme.primaryGreenDark,
                        size: 22,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'الخريطة الملاحية الحقيقية',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                              color: textMainColor,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            _locationService.locationName,
                            style: TextStyle(
                              color: textMutedColor,
                              fontSize: 11,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    // شارة المسافة المحسوبة مع زر التحديث
                    InkWell(
                      onTap: isLocating ? null : () => _locationService.fetchCurrentLocation(),
                      borderRadius: BorderRadius.circular(20),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: isDark ? const Color(0xFF064E3B).withAlpha(150) : PharmaTheme.mintBackground,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: isDark ? PharmaTheme.darkNeonGreen.withAlpha(100) : PharmaTheme.mintAccent,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (isLocating)
                              const SizedBox(
                                width: 12,
                                height: 12,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              )
                            else
                              Icon(
                                Icons.my_location_rounded,
                                size: 14,
                                color: isDark ? PharmaTheme.darkNeonGreen : PharmaTheme.primaryGreenDark,
                              ),
                            const SizedBox(width: 5),
                            Text(
                              '$distanceKm كم',
                              style: TextStyle(
                                fontWeight: FontWeight.w900,
                                color: isDark ? PharmaTheme.darkNeonGreen : PharmaTheme.primaryGreenDark,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // نافذة عرض الخريطة الحقيقية (Real Map Viewport)
              Container(
                height: 200,
                width: double.infinity,
                margin: const EdgeInsets.symmetric(horizontal: 16),
                clipBehavior: Clip.antiAlias,
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: borderColor),
                ),
                child: Stack(
                  children: [
                    // طبقة البلاطات الجغرافية الحقيقية (Real OpenStreetMap / CartoDB Tiles)
                    Positioned.fill(
                      child: Row(
                        children: [
                          Expanded(
                            child: Image.network(
                              tileUrl1,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) =>
                                  _buildMapFallback(isDark),
                            ),
                          ),
                          Expanded(
                            child: Image.network(
                              tileUrl2,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) =>
                                  _buildMapFallback(isDark),
                            ),
                          ),
                        ],
                      ),
                    ),

                    // طبقة تظليل ناعمة لزيادة وضوح المؤشرات والعناصر
                    Positioned.fill(
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.black.withAlpha(isDark ? 70 : 30),
                              Colors.transparent,
                              Colors.black.withAlpha(isDark ? 90 : 40),
                            ],
                          ),
                        ),
                      ),
                    ),

                    // مسار الملاحة الرابط بين موقع المريض والصيدلية
                    CustomPaint(
                      size: const Size(double.infinity, 200),
                      painter: _NavRouteOverlayPainter(isDark: isDark),
                    ),

                    // نقطة موقع المريض الفعلي (مع تأثير الرادار)
                    Positioned(
                      bottom: 20,
                      right: 20,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(9),
                            decoration: BoxDecoration(
                              color: const Color(0xFF0284C7),
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(0xFF0284C7).withAlpha(120),
                                  blurRadius: 12,
                                  spreadRadius: 3,
                                ),
                              ],
                            ),
                            child: const Icon(Icons.person_pin_circle_rounded, color: Colors.white, size: 20),
                          ),
                          const SizedBox(height: 4),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: isDark ? const Color(0xFF0F172A) : Colors.white,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: const Color(0xFF0284C7), width: 1.2),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withAlpha(30),
                                  blurRadius: 4,
                                ),
                              ],
                            ),
                            child: Text(
                              'موقعك الفعلي',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w900,
                                color: isDark ? Colors.white : const Color(0xFF0369A1),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    // بطاقة زمن الوصول التقديري في منتصف المسار
                    Center(
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                        decoration: BoxDecoration(
                          color: isDark ? const Color(0xFF1E293B) : Colors.white,
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(
                            color: isDark ? PharmaTheme.darkNeonGreen : PharmaTheme.primaryGreen,
                            width: 1.5,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withAlpha(40),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.directions_car_rounded,
                              size: 16,
                              color: isDark ? PharmaTheme.darkNeonGreen : PharmaTheme.primaryGreen,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              '~ $drivingMinutes دقائق بالسيارة',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                                color: isDark ? Colors.white : PharmaTheme.primaryGreenDark,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    // نقطة موقع الصيدلية المعتمد
                    Positioned(
                      top: 18,
                      left: 20,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(9),
                            decoration: BoxDecoration(
                              color: PharmaTheme.primaryGreen,
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: PharmaTheme.primaryGreen.withAlpha(140),
                                  blurRadius: 12,
                                  spreadRadius: 3,
                                ),
                              ],
                            ),
                            child: const Icon(Icons.local_pharmacy_rounded, color: Colors.white, size: 20),
                          ),
                          const SizedBox(height: 4),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: isDark ? const Color(0xFF0F172A) : Colors.white,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: PharmaTheme.primaryGreen, width: 1.2),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withAlpha(30),
                                  blurRadius: 4,
                                ),
                              ],
                            ),
                            child: Text(
                              widget.pharmacy.name,
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w900,
                                color: isDark ? Colors.white : PharmaTheme.primaryGreenDark,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),

                    // شارة مصدر الخريطة الحقيقي
                    Positioned(
                      bottom: 4,
                      left: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.black.withAlpha(120),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Text(
                          '© OpenStreetMap & CARTO',
                          style: TextStyle(fontSize: 8, color: Colors.white70),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // شريط المؤشرات السريعة وزر الملاحة المباشرة
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _buildMetric(Icons.directions_car_rounded, '$drivingMinutes د', 'قيادة بالسيارة', textMainColor, textMutedColor),
                        _buildDivider(borderColor),
                        _buildMetric(Icons.directions_walk_rounded, '$walkingMinutes د', 'سيراً على الأقدام', textMainColor, textMutedColor),
                        _buildDivider(borderColor),
                        _buildMetric(Icons.straighten_rounded, '$distanceKm كم', 'المسافة الجغرافية', textMainColor, textMutedColor),
                      ],
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        minimumSize: const Size(double.infinity, 50),
                        backgroundColor: const Color(0xFF0284C7),
                        foregroundColor: Colors.white,
                        elevation: 2,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      onPressed: () => _openGoogleMapsRoute(userLat, userLng, destLat, destLng),
                      icon: const Icon(Icons.navigation_rounded, size: 20),
                      label: const Text(
                        'فتح الملاحة والتوجيه الحي (Google Maps)',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildMapFallback(bool isDark) {
    return Container(
      color: isDark ? const Color(0xFF0F172A) : const Color(0xFFE2E8F0),
      child: Center(
        child: Icon(
          Icons.map_outlined,
          size: 48,
          color: isDark ? const Color(0xFF334155) : const Color(0xFFCBD5E1),
        ),
      ),
    );
  }

  Widget _buildDivider(Color color) {
    return Container(
      height: 30,
      width: 1,
      color: color,
    );
  }

  Widget _buildMetric(IconData icon, String value, String label, Color textColor, Color mutedColor) {
    return Column(
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 18, color: PharmaTheme.primaryGreen),
            const SizedBox(width: 4),
            Text(
              value,
              style: TextStyle(
                fontWeight: FontWeight.w900,
                fontSize: 14,
                color: textColor,
              ),
            ),
          ],
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: TextStyle(fontSize: 11, color: mutedColor),
        ),
      ],
    );
  }
}

class _NavRouteOverlayPainter extends CustomPainter {
  final bool isDark;

  _NavRouteOverlayPainter({required this.isDark});

  @override
  void paint(Canvas canvas, Size size) {
    final path = Path();
    // يبدأ من موقع المريض (أسفل اليمين) إلى الصيدلية (أعلى اليسار)
    path.moveTo(size.width - 45, size.height - 45);
    path.cubicTo(
      size.width * 0.75,
      size.height * 0.7,
      size.width * 0.35,
      size.height * 0.3,
      45,
      45,
    );

    // توهج خلفي للمسار
    final glowPaint = Paint()
      ..color = (isDark ? const Color(0xFF34D399) : PharmaTheme.primaryGreen).withAlpha(50)
      ..strokeWidth = 10.0
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;
    canvas.drawPath(path, glowPaint);

    // خط المسار الرئيسي
    final routePaint = Paint()
      ..color = isDark ? const Color(0xFF34D399) : PharmaTheme.primaryGreen
      ..strokeWidth = 4.0
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;
    canvas.drawPath(path, routePaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
