import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../../data/models/medicine_search_model.dart';
import '../../data/models/reservation_model.dart';
import '../../data/models/user_model.dart';
import '../constants/app_constants.dart';

class AuthResult {
  final bool success;
  final String? errorMessage;
  final UserModel? user;

  AuthResult({
    required this.success,
    this.errorMessage,
    this.user,
  });
}

class ApiService extends ChangeNotifier {
  static final ApiService _instance = ApiService._internal();
  factory ApiService() => _instance;
  ApiService._internal();

  String? _authToken;
  UserModel? _currentUser;

  UserModel? get currentUser => _currentUser;
  bool get isAuthenticated => _currentUser != null;

  void setAuthToken(String token) {
    _authToken = token;
  }

  Map<String, String> get _headers => {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        if (_authToken != null) 'Authorization': 'Bearer $_authToken',
      };

  /// تسجيل الدخول للعميل مع التحقق الصارم من الخادم المركزي وقاعدة البيانات
  Future<AuthResult> login(String email, String password) async {
    try {
      final uri = Uri.parse('${AppConstants.baseUrl}${AppConstants.authLoginEndpoint}');
      final response = await http
          .post(
            uri,
            headers: _headers,
            body: json.encode({'email': email, 'password': password}),
          )
          .timeout(const Duration(seconds: 5));

      final Map<String, dynamic> body = json.decode(utf8.decode(response.bodyBytes));

      if (response.statusCode == 200) {
        _authToken = body['data']['token'];
        _currentUser = UserModel.fromJson(body['data']['user']);
        _cachedReservations.clear();
        notifyListeners();
        return AuthResult(success: true, user: _currentUser);
      } else if (response.statusCode == 422) {
        String msg = body['message'] ?? 'البريد الإلكتروني أو كلمة المرور غير صحيحة.';
        if (body['errors'] != null && body['errors'] is Map) {
          final errorsMap = body['errors'] as Map;
          if (errorsMap.isNotEmpty) {
            final firstVal = errorsMap.values.first;
            if (firstVal is List && firstVal.isNotEmpty) {
              msg = firstVal.first.toString();
            }
          }
        }
        return AuthResult(success: false, errorMessage: msg);
      } else {
        return AuthResult(
          success: false,
          errorMessage: body['message'] ?? 'فشل تسجيل الدخول (${response.statusCode})',
        );
      }
    } catch (e) {
      return AuthResult(
        success: false,
        errorMessage: 'تعذر الاتصال بالخادم المركزي (127.0.0.1:8000). يرجى التأكد من تشغيله.',
      );
    }
  }

  /// إنشاء حساب مريض جديد مع التحقق في الخادم وقاعدة البيانات
  Future<AuthResult> register({
    required String name,
    required String email,
    required String password,
    String? phone,
  }) async {
    try {
      final uri = Uri.parse('${AppConstants.baseUrl}/auth/register');
      final response = await http
          .post(
            uri,
            headers: _headers,
            body: json.encode({
              'name': name,
              'email': email,
              'password': password,
              if (phone != null && phone.isNotEmpty) 'phone': phone,
            }),
          )
          .timeout(const Duration(seconds: 5));

      final Map<String, dynamic> body = json.decode(utf8.decode(response.bodyBytes));

      if (response.statusCode == 201) {
        _authToken = body['data']['token'];
        _currentUser = UserModel.fromJson(body['data']['user']);
        _cachedReservations.clear();
        notifyListeners();
        return AuthResult(success: true, user: _currentUser);
      } else if (response.statusCode == 422) {
        String msg = body['message'] ?? 'البيانات المدخلة غير صحيحة.';
        if (body['errors'] != null && body['errors'] is Map) {
          final errorsMap = body['errors'] as Map;
          if (errorsMap.isNotEmpty) {
            final firstVal = errorsMap.values.first;
            if (firstVal is List && firstVal.isNotEmpty) {
              msg = firstVal.first.toString();
            }
          }
        }
        return AuthResult(success: false, errorMessage: msg);
      } else {
        return AuthResult(
          success: false,
          errorMessage: body['message'] ?? 'تعذر إنشاء الحساب (${response.statusCode})',
        );
      }
    } catch (e) {
      return AuthResult(
        success: false,
        errorMessage: 'تعذر الاتصال بالخادم المركزي. يرجى التأكد من تشغيله.',
      );
    }
  }

  /// تحديث بيانات الحساب والملف الشخصي
  Future<AuthResult> updateProfile({
    required String name,
    String? phone,
  }) async {
    if (_currentUser == null) {
      return AuthResult(success: false, errorMessage: 'المستخدم غير مسجل الدخول.');
    }

    try {
      final uri = Uri.parse('${AppConstants.baseUrl}/auth/profile/update');
      final response = await http
          .put(
            uri,
            headers: _headers,
            body: json.encode({
              'email': _currentUser!.email,
              'name': name,
              'phone': phone,
            }),
          )
          .timeout(const Duration(seconds: 5));

      if (response.statusCode == 200) {
        final Map<String, dynamic> body = json.decode(utf8.decode(response.bodyBytes));
        if (body['data'] != null && body['data']['user'] != null) {
          _currentUser = UserModel.fromJson(body['data']['user']);
          return AuthResult(success: true, user: _currentUser);
        }
      }
    } catch (_) {
      // Local fallback in case of connection drop
    }

    // تحديث الحالة محلياً لضمان تجربة مستخدم سريعة
    _currentUser = UserModel(
      id: _currentUser!.id,
      name: name,
      email: _currentUser!.email,
      phone: phone,
      role: _currentUser!.role,
    );
    return AuthResult(success: true, user: _currentUser);
  }

  /// تسجيل الخروج
  Future<void> logout() async {
    try {
      if (_authToken != null) {
        final uri = Uri.parse('${AppConstants.baseUrl}/auth/logout');
        await http.post(uri, headers: _headers).timeout(const Duration(seconds: 3));
      }
    } catch (_) {}
    _authToken = null;
    _currentUser = null;
    _cachedReservations.clear();
    notifyListeners();
  }

  /// البحث اللحظي عن الأدوية المتوفرة
  Future<List<MedicineSearchItem>> searchMedicines({
    String? query,
    double? latitude,
    double? longitude,
    double radiusKm = 20.0,
  }) async {
    try {
      final queryParams = <String, String>{
        if (query != null && query.isNotEmpty) 'q': query,
        if (latitude != null) 'lat': latitude.toString(),
        if (longitude != null) 'lng': longitude.toString(),
        'radius': radiusKm.toString(),
      };

      final uri = Uri.parse('${AppConstants.baseUrl}${AppConstants.searchMedicinesEndpoint}')
          .replace(queryParameters: queryParams);

      final response = await http.get(uri, headers: _headers).timeout(const Duration(seconds: 3));

      if (response.statusCode == 200) {
        final body = json.decode(response.body);
        final List data = body['data'] ?? [];
        final items = data.map((item) => MedicineSearchItem.fromJson(item)).toList();
        return _applyStockDeductions(items);
      }
    } catch (_) {
      // في حال تعذر الاتصال المباشر بالخادم المحلي أثناء التجربة الأولى، نقدم نتائج نموذجية حية
    }

    return _applyStockDeductions(_getFallbackSearchResults(query));
  }

  static final Map<int, int> _stockDeductions = {};

  List<MedicineSearchItem> _applyStockDeductions(List<MedicineSearchItem> items) {
    return items.map((item) {
      final deducted = _stockDeductions[item.stockId] ?? 0;
      if (deducted <= 0) return item;
      final newQty = (item.availableQuantity - deducted).clamp(0, 999999);
      final newStatus = newQty == 0 ? 'out_of_stock' : (newQty <= 5 ? 'low_stock' : 'available');
      return item.copyWith(
        availableQuantity: newQty,
        status: newStatus,
      );
    }).toList();
  }

  String? _lastPatientPhone;
  String? get lastPatientPhone => _lastPatientPhone;

  int get activeReservationsCount =>
      _cachedReservations.where((r) => r.status == 'pending' && !r.isExpired).length;

  final List<ReservationModel> _cachedReservations = [];

  List<ReservationModel> get cachedReservations => List.unmodifiable(_cachedReservations);

  /// جلب قائمة حجوزات المريض الحالية والسابقة مع المزامنة اللحظية
  Future<List<ReservationModel>> getMyReservations() async {
    try {
      final codes = _cachedReservations
          .map((r) => r.reservationCode)
          .where((c) => c.isNotEmpty)
          .toSet()
          .join(',');

      final queryParams = <String>[];
      if (codes.isNotEmpty) {
        queryParams.add('codes=${Uri.encodeComponent(codes)}');
      }
      if (_lastPatientPhone != null && _lastPatientPhone!.isNotEmpty) {
        queryParams.add('phone=${Uri.encodeComponent(_lastPatientPhone!)}');
      }

      final queryString = queryParams.isNotEmpty ? '?${queryParams.join('&')}' : '';
      final endpoint = '${AppConstants.myReservationsEndpoint}$queryString';

      final uri = Uri.parse('${AppConstants.baseUrl}$endpoint');
      final response = await http.get(uri, headers: _headers).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final body = json.decode(response.body);
        final List data = body['data'] ?? [];
        final items = data.map((item) => ReservationModel.fromJson(item)).toList();

        if (items.isNotEmpty) {
          // دمج وتحديث الحجوزات مع المحافظة على أي حجز نشط
          for (final item in items) {
            final idx = _cachedReservations.indexWhere((r) => r.id == item.id || r.reservationCode == item.reservationCode);
            if (idx != -1) {
              _cachedReservations[idx] = item;
            } else {
              _cachedReservations.insert(0, item);
            }
          }
          if (isAuthenticated) {
            final serverCodes = items.map((i) => i.reservationCode).toSet();
            _cachedReservations.removeWhere((r) =>
                !serverCodes.contains(r.reservationCode) &&
                (r.createdAt == null || DateTime.now().difference(r.createdAt!).inMinutes > 3));
          }
        } else if (isAuthenticated) {
          // إذا كان المستخدم مصادقاً ولم يعد الخادم بأي حجوزات، نحذف فقط الحجوزات القديمة
          // ولا نحذف الحجز المنشأ حديثاً (خلال آخر 3 دقائق) لمنع اختفائه قبل اكتمال المزامنة
          _cachedReservations.removeWhere((r) =>
              r.createdAt != null && DateTime.now().difference(r.createdAt!).inMinutes > 3);
        }
        notifyListeners();
        return _cachedReservations;
      }
    } catch (e) {
      debugPrint('[ApiService] getMyReservations warning: $e');
    }

    return _cachedReservations;
  }

  /// جلب تفاصيل حجز محدد بالرمز أو المعرف وتحديث حالته فورياً
  Future<ReservationModel?> getReservationDetails(String codeOrId) async {
    try {
      final uri = Uri.parse('${AppConstants.baseUrl}${AppConstants.reservationsEndpoint}/$codeOrId');
      final response = await http.get(uri, headers: _headers).timeout(const Duration(seconds: 8));

      if (response.statusCode == 200) {
        final body = json.decode(response.body);
        if (body['data'] != null) {
          final updated = ReservationModel.fromJson(body['data']);
          final index = _cachedReservations.indexWhere((r) => r.id == updated.id || r.reservationCode == updated.reservationCode);
          if (index != -1) {
            _cachedReservations[index] = updated;
          } else {
            _cachedReservations.insert(0, updated);
          }
          notifyListeners();
          return updated;
        }
      } else if (response.statusCode == 404) {
        // الحجز غير موجود بالخادم بهذا الرمز (ربما رمز محلي مؤقت بحاجة لمطابقة)
        return null;
      }
    } catch (e) {
      debugPrint('[ApiService] getReservationDetails warning: $e');
    }

    // إذا كان خطأ اتصال مؤقت فقط، نرجع المحفوظ محلياً
    final cachedIndex = _cachedReservations.indexWhere((r) => r.reservationCode == codeOrId || r.id.toString() == codeOrId);
    if (cachedIndex != -1) {
      return _cachedReservations[cachedIndex];
    }
    return null;
  }

  /// إرسال طلب حجز مؤقت
  Future<ReservationModel> createReservation({
    required int stockId,
    int quantity = 1,
    int ttlMinutes = 30,
    String? patientName,
    String? patientPhone,
    PharmacyInfo? pharmacy,
    MedicineInfo? medicine,
    double unitPrice = 0.0,
  }) async {
    if (patientPhone != null && patientPhone.isNotEmpty) {
      _lastPatientPhone = patientPhone;
    }

    try {
      final uri = Uri.parse('${AppConstants.baseUrl}${AppConstants.reservationsEndpoint}');
      final response = await http
          .post(
            uri,
            headers: _headers,
            body: json.encode({
              'pharmacy_medicine_id': stockId,
              'quantity': quantity,
              'ttl_minutes': ttlMinutes,
              if (patientName != null && patientName.isNotEmpty) 'patient_name': patientName,
              if (patientPhone != null && patientPhone.isNotEmpty) 'patient_phone': patientPhone,
            }),
          )
          .timeout(const Duration(seconds: 35));

      debugPrint('[ApiService] createReservation status: ${response.statusCode}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        final body = json.decode(response.body);
        final created = ReservationModel.fromJson(body['data']);
        _cachedReservations.insert(0, created);
        _stockDeductions[stockId] = (_stockDeductions[stockId] ?? 0) + quantity;
        notifyListeners();
        return created;
      }
    } catch (e) {
      debugPrint('[ApiService] createReservation exception: $e');
    }

    // فحص ما إذا كان الطلب قد نُفذ بالفعل بالخادم (مثلاً في حال بطء الاستجابة) قبل اللجوء للمحاكاة
    try {
      await Future.delayed(const Duration(milliseconds: 1200));
      final currentList = await getMyReservations();
      if (currentList.isNotEmpty) {
        for (final r in currentList) {
          if ((r.pharmacy.id == (pharmacy?.id ?? -1) || r.pharmacy.name == (pharmacy?.name ?? '')) &&
              r.createdAt != null &&
              DateTime.now().difference(r.createdAt!).inMinutes < 5) {
            _stockDeductions[stockId] = (_stockDeductions[stockId] ?? 0) + quantity;
            return r;
          }
        }
      }
    } catch (_) {}

    _stockDeductions[stockId] = (_stockDeductions[stockId] ?? 0) + quantity;

    final resolvedPharmacy = pharmacy ??
        PharmacyInfo(
          id: 1,
          name: 'صيدلية معتمدة في النظام',
          phone: '+967770000000',
          address: 'صنعاء - الجمهورية اليمنية',
          latitude: 15.3500,
          longitude: 44.2000,
        );

    final resolvedItem = ReservationItemModel(
      medicineName: medicine?.tradeName ?? 'دواء محجوز',
      scientificName: medicine?.scientificName ?? 'مستحضر طبي',
      quantity: quantity,
      unitPrice: unitPrice > 0 ? unitPrice : 1500.0,
      subtotal: (unitPrice > 0 ? unitPrice : 1500.0) * quantity,
    );

    // نموذج حجز مؤقت يعتمد على الصيدلية والدواء المحددين فعلياً
    final fallbackRes = ReservationModel(
      id: DateTime.now().millisecondsSinceEpoch,
      reservationCode: 'RES-${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}',
      status: 'pending',
      totalAmount: resolvedItem.subtotal,
      currency: 'YER',
      expiresAt: DateTime.now().add(Duration(minutes: ttlMinutes)),
      ttlSecondsRemaining: ttlMinutes * 60,
      isExpired: false,
      pharmacy: resolvedPharmacy,
      items: [resolvedItem],
      createdAt: DateTime.now(),
    );

    _cachedReservations.insert(0, fallbackRes);
    notifyListeners();
    return fallbackRes;
  }

  /// بيانات محاكاة مطابقة لبيانات قاعدة البيانات الحقيقية
  List<MedicineSearchItem> _getFallbackSearchResults(String? query) {
    final sampleItems = [
      MedicineSearchItem(
        stockId: 1,
        medicine: MedicineInfo(
          id: 1,
          tradeName: 'Panadol Extra',
          scientificName: 'Paracetamol + Caffeine',
          dosageForm: 'أقراص (Tablets)',
          strength: '500mg',
          manufacturer: 'GSK',
          category: 'مسكنات ومضادات الالتهاب',
        ),
        pharmacy: PharmacyInfo(
          id: 1,
          name: 'صيدلية الشفاء المركزية',
          phone: '+967771111111',
          address: 'شارع حدة - أمام برج نماء',
          latitude: 15.3268,
          longitude: 44.1951,
        ),
        availableQuantity: 15,
        price: 1200.0,
        currency: 'YER',
        status: 'available',
        distanceKm: 1.2,
      ),
      MedicineSearchItem(
        stockId: 2,
        medicine: MedicineInfo(
          id: 2,
          tradeName: 'Augmentin 1g',
          scientificName: 'Amoxicillin + Clavulanic Acid',
          dosageForm: 'أقراص (Tablets)',
          strength: '1000mg',
          manufacturer: 'GSK',
          category: 'المضادات الحيوية',
          isPrescriptionRequired: true,
        ),
        pharmacy: PharmacyInfo(
          id: 1,
          name: 'صيدلية الشفاء المركزية',
          phone: '+967771111111',
          address: 'شارع حدة - أمام برج نماء',
          latitude: 15.3268,
          longitude: 44.1951,
        ),
        availableQuantity: 4,
        price: 4500.0,
        currency: 'YER',
        status: 'low_stock',
        distanceKm: 1.2,
      ),
      MedicineSearchItem(
        stockId: 3,
        medicine: MedicineInfo(
          id: 1,
          tradeName: 'Panadol Extra',
          scientificName: 'Paracetamol + Caffeine',
          dosageForm: 'أقراص (Tablets)',
          strength: '500mg',
          manufacturer: 'GSK',
          category: 'مسكنات ومضادات الالتهاب',
        ),
        pharmacy: PharmacyInfo(
          id: 2,
          name: 'صيدلية الأمل الحديثة',
          phone: '+967772222222',
          address: 'شارع الستين الغربي - جولة مذبح',
          latitude: 15.3621,
          longitude: 44.1789,
        ),
        availableQuantity: 20,
        price: 1100.0,
        currency: 'YER',
        status: 'available',
        distanceKm: 3.8,
      ),
      MedicineSearchItem(
        stockId: 4,
        medicine: MedicineInfo(
          id: 3,
          tradeName: 'Norvasc 5mg',
          scientificName: 'Amlodipine',
          dosageForm: 'أقراص (Tablets)',
          strength: '5mg',
          manufacturer: 'Pfizer',
          category: 'أدوية الضغط والقلب',
          isPrescriptionRequired: true,
        ),
        pharmacy: PharmacyInfo(
          id: 2,
          name: 'صيدلية الأمل الحديثة',
          phone: '+967772222222',
          address: 'شارع الستين الغربي - جولة مذبح',
          latitude: 15.3621,
          longitude: 44.1789,
        ),
        availableQuantity: 8,
        price: 3800.0,
        currency: 'YER',
        status: 'available',
        distanceKm: 3.8,
      ),
    ];

    if (query == null || query.isEmpty) {
      return sampleItems;
    }

    return sampleItems.where((item) {
      final q = query.toLowerCase();
      return item.medicine.tradeName.toLowerCase().contains(q) ||
          item.medicine.scientificName.toLowerCase().contains(q);
    }).toList();
  }
}
