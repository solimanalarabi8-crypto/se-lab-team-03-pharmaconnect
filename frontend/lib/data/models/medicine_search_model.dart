class MedicineSearchItem {
  final int stockId;
  final MedicineInfo medicine;
  final PharmacyInfo pharmacy;
  final int availableQuantity;
  final double price;
  final String currency;
  final String status;
  final double? distanceKm;

  MedicineSearchItem({
    required this.stockId,
    required this.medicine,
    required this.pharmacy,
    required this.availableQuantity,
    required this.price,
    required this.currency,
    required this.status,
    this.distanceKm,
  });

  factory MedicineSearchItem.fromJson(Map<String, dynamic> json) {
    return MedicineSearchItem(
      stockId: (json['stock_id'] as num?)?.toInt() ?? 0,
      medicine: MedicineInfo.fromJson(json['medicine'] ?? {}),
      pharmacy: PharmacyInfo.fromJson(json['pharmacy'] ?? {}),
      availableQuantity: (json['available_quantity'] as num?)?.toInt() ?? 0,
      price: (json['price'] as num?)?.toDouble() ?? 0.0,
      currency: json['currency'] ?? 'YER',
      status: json['status'] ?? 'available',
      distanceKm: (json['distance_km'] as num?)?.toDouble(),
    );
  }

  MedicineSearchItem copyWith({
    int? stockId,
    MedicineInfo? medicine,
    PharmacyInfo? pharmacy,
    int? availableQuantity,
    double? price,
    String? currency,
    String? status,
    double? distanceKm,
  }) {
    return MedicineSearchItem(
      stockId: stockId ?? this.stockId,
      medicine: medicine ?? this.medicine,
      pharmacy: pharmacy ?? this.pharmacy,
      availableQuantity: availableQuantity ?? this.availableQuantity,
      price: price ?? this.price,
      currency: currency ?? this.currency,
      status: status ?? this.status,
      distanceKm: distanceKm ?? this.distanceKm,
    );
  }
}

class MedicineInfo {
  final int id;
  final String tradeName;
  final String scientificName;
  final String? barcode;
  final String? dosageForm;
  final String? strength;
  final String? manufacturer;
  final String? category;
  final bool isPrescriptionRequired;
  final String? imageUrl;

  MedicineInfo({
    required this.id,
    required this.tradeName,
    required this.scientificName,
    this.barcode,
    this.dosageForm,
    this.strength,
    this.manufacturer,
    this.category,
    this.isPrescriptionRequired = false,
    this.imageUrl,
  });

  factory MedicineInfo.fromJson(Map<String, dynamic> json) {
    return MedicineInfo(
      id: (json['id'] as num?)?.toInt() ?? 0,
      tradeName: json['trade_name'] ?? '',
      scientificName: json['scientific_name'] ?? '',
      barcode: json['barcode'],
      dosageForm: json['dosage_form'],
      strength: json['strength'],
      manufacturer: json['manufacturer'],
      category: json['category'],
      isPrescriptionRequired: json['is_prescription_required'] ?? false,
      imageUrl: json['image_url'],
    );
  }
}

class PharmacyInfo {
  final int id;
  final String name;
  final String phone;
  final String address;
  final double? latitude;
  final double? longitude;

  PharmacyInfo({
    required this.id,
    required this.name,
    required this.phone,
    required this.address,
    this.latitude,
    this.longitude,
  });

  factory PharmacyInfo.fromJson(Map<String, dynamic> json) {
    return PharmacyInfo(
      id: (json['id'] as num?)?.toInt() ?? 0,
      name: json['name'] ?? '',
      phone: json['phone'] ?? '',
      address: json['address'] ?? '',
      latitude: (json['latitude'] as num?)?.toDouble(),
      longitude: (json['longitude'] as num?)?.toDouble(),
    );
  }
}
