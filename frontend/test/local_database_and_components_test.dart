import 'package:flutter_test/flutter_test.dart';
import 'package:pharma_connect_client/core/constants/app_enums.dart';
import 'package:pharma_connect_client/core/errors/app_exceptions.dart';
import 'package:pharma_connect_client/core/utils/validation_mixins.dart';
import 'package:pharma_connect_client/data/local/database_helper.dart';
import 'package:pharma_connect_client/data/models/saved_medicine_model.dart';

class TestValidator with FormValidatorMixin, CurrencyFormatterMixin {}

void main() {
  group('Lecture Compliance - Unit Tests for Core & Models', () {
    test('SavedMedicineModel toMap and fromMap serialization (Lecture 9)', () {
      const model = SavedMedicineModel(
        id: 1,
        medicineId: 101,
        name: 'Panadol Extra',
        genericName: 'Paracetamol',
        category: 'مسكنات',
        price: 1500.0,
        pharmacyName: 'صيدلية النور',
        pharmacyPhone: '770123456',
        isAvailable: true,
        notes: 'حبتين بعد الأكل',
        savedAt: '2026-09-22T19:00:00Z',
      );

      final map = model.toMap();
      expect(map['medicine_id'], 101);
      expect(map['name'], 'Panadol Extra');
      expect(map['price'], 1500.0);
      expect(map['is_available'], 1);

      final reconstructed = SavedMedicineModel.fromMap(map);
      expect(reconstructed.name, 'Panadol Extra');
      expect(reconstructed.genericName, 'Paracetamol');
      expect(reconstructed.isAvailable, isTrue);
      expect(reconstructed.price, 1500.0);
    });

    test('Validation and Currency Formatter Mixins (Lecture 4)', () {
      final validator = TestValidator();

      // Test validation
      expect(validator.validateRequired('', 'اسم الدواء'), isNotNull);
      expect(validator.validateRequired('بانادول', 'اسم الدواء'), isNull);

      expect(validator.validatePhone('770123456'), isNull);
      expect(validator.validatePhone('12345'), isNotNull);

      expect(validator.validatePrice('2500'), isNull);
      expect(validator.validatePrice('-10'), isNotNull);

      // Test currency formatting
      expect(validator.formatYemeniRial(1200), '1200 ر.ي');
      expect(validator.formatDistance(500), '500 متر');
      expect(validator.formatDistance(2500), '2.5 كم');
    });

    test('Enums and exhaustive evaluation (Lecture 4 & 10)', () {
      expect(MedicineCategory.values.length, 6);
      expect(MedicineSortOption.values.length, 4);
      expect(ReservationDeliveryType.values.length, 2);

      // Verify label resolution
      expect(MedicineCategory.antibiotics.label, 'مضادات حيوية');
      expect(MedicineSortOption.lowestPrice.label, 'الأقل سعراً');
    });

    test('Custom Exceptions hierarchy (Lecture 4)', () {
      const netEx = NetworkException('فشل الاتصال', statusCode: 503);
      expect(netEx.statusCode, 503);
      expect(netEx.toString(), '[NETWORK_ERROR] فشل الاتصال');

      const dbEx = AppDatabaseException('خطأ في استعلام SQLite', query: 'SELECT *');
      expect(dbEx.query, 'SELECT *');
      expect(dbEx.toString(), '[DATABASE_ERROR] خطأ في استعلام SQLite');
    });

    test('DatabaseHelper SQLite CRUD Operations (Lecture 9)', () async {
      final dbHelper = DatabaseHelper();
      final db = await dbHelper.database;
      expect(db.isOpen, isTrue);

      const testItem = SavedMedicineModel(
        medicineId: 9999,
        name: 'Aspirin Test',
        genericName: 'Acetylsalicylic acid',
        category: 'مسكنات',
        price: 800.0,
        pharmacyName: 'صيدلية الاختبار',
        pharmacyPhone: '777000111',
        isAvailable: true,
        notes: 'اختبار محلي',
        savedAt: '2026-09-22T21:00:00Z',
      );

      // Insert
      final insertedId = await dbHelper.insertMedicine(testItem);
      expect(insertedId, greaterThan(0));

      // Query
      final isSaved = await dbHelper.isMedicineSaved(9999);
      expect(isSaved, isTrue);

      final list = await dbHelper.getAllMedicines();
      expect(list.any((m) => m.medicineId == 9999), isTrue);

      // Delete
      final deletedRows = await dbHelper.deleteByMedicineId(9999);
      expect(deletedRows, greaterThanOrEqualTo(1));

      final afterDelete = await dbHelper.isMedicineSaved(9999);
      expect(afterDelete, isFalse);
    });
  });
}
