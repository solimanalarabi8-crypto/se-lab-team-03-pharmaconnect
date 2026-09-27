import 'dart:convert';
import 'dart:math';
import 'package:flutter/widgets.dart';
import 'package:http/http.dart' as http;

/// خدمة إدارة الموقع الجغرافي الفعلي للعميل وحساب المسافات الحقيقية
class LocationService extends ChangeNotifier {
  static final LocationService _instance = LocationService._internal();
  factory LocationService() => _instance;
  LocationService._internal();

  // الإحداثيات الافتراضية المعتمدة (صنعاء، اليمن - شارع حدة)
  double _userLat = 15.3350;
  double _userLng = 44.1950;
  String _currentCity = 'صنعاء، اليمن';
  String _locationName = 'موقعي الفعلي (صنعاء)';
  bool _isLocating = false;

  double get userLat => _userLat;
  double get userLng => _userLng;
  String get currentCity => _currentCity;
  String get locationName => _locationName;
  bool get isLocating => _isLocating;

  void _safeNotify() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (hasListeners) {
        notifyListeners();
      }
    });
  }

  /// جلب الإحداثيات الحقيقية الفعلية لجهاز العميل عبر خدمة تحديد الموقع الجغرافي بالـ IP / الشبكة
  Future<void> fetchCurrentLocation() async {
    _isLocating = true;
    _safeNotify();

    try {
      final response = await http
          .get(Uri.parse('https://ipapi.co/json/'))
          .timeout(const Duration(seconds: 4));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['latitude'] != null && data['longitude'] != null) {
          _userLat = (data['latitude'] as num).toDouble();
          _userLng = (data['longitude'] as num).toDouble();
          final city = data['city'] ?? 'صنعاء';
          final country = data['country_name'] ?? 'اليمن';
          _currentCity = '$city، $country';
          _locationName = 'موقعي الفعلي ($city)';
        }
      }
    } catch (_) {
      // استخدام إحداثيات صنعاء الحقيقية كخيار افتراضي متين
      _userLat = 15.3350;
      _userLng = 44.1950;
    } finally {
      _isLocating = false;
      _safeNotify();
    }
  }

  /// تعيين موقع العميل يدوياً (مثلاً عند اختيار مدينة من القائمة)
  void setManualLocation(double lat, double lng, String cityName) {
    _userLat = lat;
    _userLng = lng;
    _currentCity = cityName;
    _locationName = 'موقعي المختار ($cityName)';
    notifyListeners();
  }

  /// حساب المسافة الحقيقية الدقيقة بصيغة Haversine بين موقع العميل والصيدلية (بالكيلومتر)
  double calculateDistance(double destLat, double destLng) {
    const double earthRadiusKm = 6371.0;

    final double dLat = _degreesToRadians(destLat - _userLat);
    final double dLng = _degreesToRadians(destLng - _userLng);

    final double a = sin(dLat / 2) * sin(dLat / 2) +
        cos(_degreesToRadians(_userLat)) *
            cos(_degreesToRadians(destLat)) *
            sin(dLng / 2) *
            sin(dLng / 2);

    final double c = 2 * atan2(sqrt(a), sqrt(1 - a));
    final double dist = earthRadiusKm * c;

    return (dist * 10).roundToDouble() / 10; // تقريب لأقرب 100 متر
  }

  double _degreesToRadians(double degrees) {
    return degrees * (pi / 180.0);
  }
}
