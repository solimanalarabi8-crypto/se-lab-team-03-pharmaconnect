import 'medicine_search_model.dart';

class ReservationModel {
  final int id;
  final String reservationCode;
  final String status;
  final double totalAmount;
  final String currency;
  final DateTime? expiresAt;
  final int ttlSecondsRemaining;
  final bool isExpired;
  final PharmacyInfo pharmacy;
  final List<ReservationItemModel> items;
  final DateTime? createdAt;

  final DateTime clientLoadedAt;

  ReservationModel({
    required this.id,
    required this.reservationCode,
    required this.status,
    required this.totalAmount,
    required this.currency,
    this.expiresAt,
    required this.ttlSecondsRemaining,
    required this.isExpired,
    required this.pharmacy,
    required this.items,
    this.createdAt,
    DateTime? clientLoadedAt,
  }) : clientLoadedAt = clientLoadedAt ?? DateTime.now();

  factory ReservationModel.fromJson(Map<String, dynamic> json) {
    return ReservationModel(
      id: (json['id'] as num?)?.toInt() ?? 0,
      reservationCode: json['reservation_code'] ?? '',
      status: json['status'] ?? 'pending',
      totalAmount: (json['total_amount'] as num?)?.toDouble() ?? 0.0,
      currency: json['currency'] ?? 'YER',
      expiresAt: json['expires_at'] != null ? DateTime.tryParse(json['expires_at']) : null,
      ttlSecondsRemaining: (json['ttl_seconds_remaining'] as num?)?.toInt() ?? 1800,
      isExpired: json['is_expired'] == true,
      pharmacy: PharmacyInfo.fromJson(json['pharmacy'] ?? {}),
      items: (json['items'] as List<dynamic>?)
              ?.map((item) => ReservationItemModel.fromJson(item))
              .toList() ??
          [],
      createdAt: json['created_at'] != null ? DateTime.tryParse(json['created_at']) : null,
      clientLoadedAt: DateTime.now(),
    );
  }

  /// احتساب الثواني المتبقية الحقيقية بناءً على فارق توقيت النظام الآن
  int get currentRemainingSeconds {
    if (status == 'completed' || status == 'cancelled') return 0;
    if (status == 'expired') return 0;

    // 1. حساب المهلة المتبقية بناءً على التناقص المحلي للـ TTL المستلم من الخادم
    final elapsedSinceLoad = DateTime.now().difference(clientLoadedAt).inSeconds;
    final remainingFromTtl = ttlSecondsRemaining - elapsedSinceLoad;

    // 2. إذا توفر expiresAt وفارقه إيجابي نحسبه أيضاً
    if (expiresAt != null) {
      final diff = expiresAt!.toLocal().difference(DateTime.now()).inSeconds;
      if (diff > 0) {
        return diff;
      }
    }

    return remainingFromTtl > 0 ? remainingFromTtl : 0;
  }

  /// هل انتهت المهلة فعلياً
  bool get isCurrentlyExpired {
    if (status == 'completed' || status == 'cancelled') return false;
    if (status == 'expired') return true;
    return currentRemainingSeconds <= 0;
  }
}

class ReservationItemModel {
  final String medicineName;
  final String scientificName;
  final int quantity;
  final double unitPrice;
  final double subtotal;
  final String? imageUrl;

  ReservationItemModel({
    required this.medicineName,
    required this.scientificName,
    required this.quantity,
    required this.unitPrice,
    required this.subtotal,
    this.imageUrl,
  });

  factory ReservationItemModel.fromJson(Map<String, dynamic> json) {
    return ReservationItemModel(
      medicineName: json['medicine_name'] ?? '',
      scientificName: json['scientific_name'] ?? '',
      quantity: (json['quantity'] as num?)?.toInt() ?? 1,
      unitPrice: (json['unit_price'] as num?)?.toDouble() ?? 0.0,
      subtotal: (json['subtotal'] as num?)?.toDouble() ?? 0.0,
      imageUrl: json['image_url'],
    );
  }
}
