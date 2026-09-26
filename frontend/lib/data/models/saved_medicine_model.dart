/// نموذج بيانات الأدوية المحفوظة محلياً في قاعدة بيانات SQFlite:
/// - تطبيق مبادئ OOP (المحاضرة 3) ودوال البناء المسماة (Named Constructors)
/// - التحديد الصريح للأنواع وتجنب الأخطاء (المحاضرة 2)
/// - دوال التحويل toMap و fromMap لقواعد بيانات SQLite (المحاضرة 9)
class SavedMedicineModel {
  final int? id; // المعرف المحلي التلقائي autoincrement
  final int? medicineId; // معرف الدواء على السيرفر المركزي
  final String name;
  final String genericName;
  final String category;
  final double price;
  final String pharmacyName;
  final String pharmacyPhone;
  final bool isAvailable;
  final String notes;
  final String savedAt;

  // دالة البناء الأساسية بالمعاملات المسماة
  const SavedMedicineModel({
    this.id,
    this.medicineId,
    required this.name,
    this.genericName = '',
    this.category = 'عام',
    required this.price,
    this.pharmacyName = '',
    this.pharmacyPhone = '',
    this.isAvailable = true,
    this.notes = '',
    required this.savedAt,
  });

  // دالة البناء المسماة للتحويل من Map القادمة من استعلام SQLite (المحاضرة 9)
  factory SavedMedicineModel.fromMap(Map<String, dynamic> map) {
    return SavedMedicineModel(
      id: map['id'] as int?,
      medicineId: map['medicine_id'] as int?,
      name: (map['name'] ?? '') as String,
      genericName: (map['generic_name'] ?? '') as String,
      category: (map['category'] ?? 'عام') as String,
      price: (map['price'] is num) ? (map['price'] as num).toDouble() : 0.0,
      pharmacyName: (map['pharmacy_name'] ?? '') as String,
      pharmacyPhone: (map['pharmacy_phone'] ?? '') as String,
      isAvailable: (map['is_available'] == 1 || map['is_available'] == true),
      notes: (map['notes'] ?? '') as String,
      savedAt: (map['saved_at'] ?? '') as String,
    );
  }

  // دالة تحويل الكائن إلى Map لتمريرها لأوامر الإدراج والتحديث في SQFlite (المحاضرة 9)
  Map<String, dynamic> toMap() {
    final map = <String, dynamic>{
      'medicine_id': medicineId,
      'name': name,
      'generic_name': genericName,
      'category': category,
      'price': price,
      'pharmacy_name': pharmacyName,
      'pharmacy_phone': pharmacyPhone,
      'is_available': isAvailable ? 1 : 0,
      'notes': notes,
      'saved_at': savedAt,
    };
    if (id != null) {
      map['id'] = id;
    }
    return map;
  }

  // دالة لإنشاء نسخة معدلة من الكائن (Immutability Pattern)
  SavedMedicineModel copyWith({
    int? id,
    int? medicineId,
    String? name,
    String? genericName,
    String? category,
    double? price,
    String? pharmacyName,
    String? pharmacyPhone,
    bool? isAvailable,
    String? notes,
    String? savedAt,
  }) {
    return SavedMedicineModel(
      id: id ?? this.id,
      medicineId: medicineId ?? this.medicineId,
      name: name ?? this.name,
      genericName: genericName ?? this.genericName,
      category: category ?? this.category,
      price: price ?? this.price,
      pharmacyName: pharmacyName ?? this.pharmacyName,
      pharmacyPhone: pharmacyPhone ?? this.pharmacyPhone,
      isAvailable: isAvailable ?? this.isAvailable,
      notes: notes ?? this.notes,
      savedAt: savedAt ?? this.savedAt,
    );
  }
}
