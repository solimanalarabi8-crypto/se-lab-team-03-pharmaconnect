import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import '../../core/errors/app_exceptions.dart';
import '../models/saved_medicine_model.dart';

/// كلاس مساعد قاعدة البيانات المحلية SQFlite (DatabaseHelper):
/// - تطبيق نمط المفرد (Singleton Pattern) لمنع تكرار فتح الاتصالات (المحاضرة 9 و OOP المحاضرة 3)
/// - استدعاء getDatabasesPath() وتكوين مسار الملف pharmaconnect.db (المحاضرة 9)
/// - تنفيذ استعلام إنشاء الجدول db.execute(CREATE TABLE) (المحاضرة 9)
/// - توفير دوال العمليات الأساسية الأربع (CRUD) باستخدام دوال المساعدة و raw SQL:
///   * الإدراج: insert & rawInsert
///   * الاستعلام: query & rawQuery
///   * التحديث: update & rawUpdate
///   * الحذف: delete & rawDelete
/// - معالجة الاستثناءات باستخدام AppDatabaseException (المحاضرة 4)
/// - دعم هجين متقدم: SQLite أصلي على أنظمة Windows, Android, iOS مع تخزين ويب سلس على المتصفح

class DatabaseHelper {
  // 1. المتغير الثابت الحامل للنسخة الوحيدة (Singleton Instance)
  static final DatabaseHelper _instance = DatabaseHelper._internal();

  // 2. دالة البناء المصنعية (Factory Constructor) لإعادة نفس الكائن دائماً
  factory DatabaseHelper() => _instance;

  // 3. دالة البناء الخاصة المعزولة لمنع الإنشاء الخارجي
  DatabaseHelper._internal();

  // كائن قاعدة البيانات المحلي
  static Database? _database;

  // مخزن البيانات على متصفح الويب (Web In-Memory Store) لتفادي غياب FFI على المتصفح
  static final List<SavedMedicineModel> _webMedicines = [];
  static int _webIdCounter = 1;

  // اسم الجدول والحقول الثابتة
  static const String tableName = 'saved_medicines';
  static const String dbName = 'pharmaconnect.db';
  static const int dbVersion = 1;

  // دالة الحصول على قاعدة البيانات مع التهيئة المتأخرة عند الحاجة (Lazy Initialization)
  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  // دالة فتح وتهيئة قاعدة البيانات
  Future<Database> _initDatabase() async {
    try {
      if (!kIsWeb && (Platform.isWindows || Platform.isLinux || Platform.isMacOS)) {
        sqfliteFfiInit();
        databaseFactory = databaseFactoryFfi;
      }
      final databasesPath = await getDatabasesPath();
      final path = p.join(databasesPath, dbName);

      return await openDatabase(
        path,
        version: dbVersion,
        onCreate: _onCreate,
      );
    } catch (e) {
      throw AppDatabaseException('فشل في تهيئة قاعدة البيانات المحلية: $e');
    }
  }

  // دالة إنشاء الجداول عند تشغيل التطبيق لأول مرة (onCreate)
  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE $tableName (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        medicine_id INTEGER,
        name TEXT NOT NULL,
        generic_name TEXT,
        category TEXT,
        price REAL,
        pharmacy_name TEXT,
        pharmacy_phone TEXT,
        is_available INTEGER DEFAULT 1,
        notes TEXT,
        saved_at TEXT
      )
    ''');
  }

  // =========================================================================
  // عمليات الإدراج (Create / Insert)
  // =========================================================================

  /// إدراج دواء جديد باستخدام الدالة المساعدة (db.insert)
  Future<int> insertMedicine(SavedMedicineModel medicine) async {
    if (kIsWeb) {
      final newId = medicine.id ?? _webIdCounter++;
      _webMedicines.removeWhere((m) =>
          (medicine.medicineId != null && m.medicineId == medicine.medicineId) ||
          m.id == newId);
      final itemToSave = SavedMedicineModel(
        id: newId,
        medicineId: medicine.medicineId,
        name: medicine.name,
        genericName: medicine.genericName,
        category: medicine.category,
        price: medicine.price,
        pharmacyName: medicine.pharmacyName,
        pharmacyPhone: medicine.pharmacyPhone,
        isAvailable: medicine.isAvailable,
        notes: medicine.notes,
        savedAt: medicine.savedAt,
      );
      _webMedicines.add(itemToSave);
      return newId;
    }

    try {
      final db = await database;
      return await db.insert(
        tableName,
        medicine.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    } catch (e) {
      throw AppDatabaseException('فشل في حفظ الدواء بقاعدة البيانات: $e');
    }
  }

  /// إدراج دواء باستخدام الاستعلام المباشر (rawInsert) - تطبيقاً للمحاضرة 9
  Future<int> rawInsertMedicine(SavedMedicineModel medicine) async {
    if (kIsWeb) {
      return await insertMedicine(medicine);
    }
    try {
      final db = await database;
      return await db.rawInsert(
        '''
        INSERT OR REPLACE INTO $tableName 
        (medicine_id, name, generic_name, category, price, pharmacy_name, pharmacy_phone, is_available, notes, saved_at)
        VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
        ''',
        [
          medicine.medicineId,
          medicine.name,
          medicine.genericName,
          medicine.category,
          medicine.price,
          medicine.pharmacyName,
          medicine.pharmacyPhone,
          medicine.isAvailable ? 1 : 0,
          medicine.notes,
          medicine.savedAt,
        ],
      );
    } catch (e) {
      throw AppDatabaseException('فشل استعلام الإدراج المباشر rawInsert: $e');
    }
  }

  // =========================================================================
  // عمليات القراءة والاستعلام (Read / Query)
  // =========================================================================

  /// استرجاع كافة الأدوية المحفوظة محلياً مرتبة بالأحدث
  Future<List<SavedMedicineModel>> getAllMedicines() async {
    if (kIsWeb) {
      return List<SavedMedicineModel>.from(_webMedicines.reversed);
    }

    try {
      final db = await database;
      final List<Map<String, dynamic>> maps = await db.query(
        tableName,
        orderBy: 'id DESC',
      );

      return maps.map((map) => SavedMedicineModel.fromMap(map)).toList();
    } catch (e) {
      throw AppDatabaseException('فشل في جلب الأدوية المحفوظة: $e');
    }
  }

  /// استرجاع الأدوية بالاستعلام المباشر (rawQuery) - تطبيقاً للمحاضرة 9
  Future<List<SavedMedicineModel>> rawGetAllMedicines() async {
    if (kIsWeb) {
      return await getAllMedicines();
    }

    try {
      final db = await database;
      final List<Map<String, dynamic>> maps = await db.rawQuery(
        'SELECT * FROM $tableName ORDER BY id DESC',
      );

      return maps.map((map) => SavedMedicineModel.fromMap(map)).toList();
    } catch (e) {
      throw AppDatabaseException('فشل استعلام الاختيار المباشر rawQuery: $e');
    }
  }

  /// التحقق مما إذا كان الدواء محفوظاً مسبقاً بالمفضلة المحلية
  Future<bool> isMedicineSaved(int? medicineId, {String? medicineName}) async {
    if (medicineId == null && (medicineName == null || medicineName.isEmpty)) {
      return false;
    }

    if (kIsWeb) {
      if (medicineId != null && medicineId > 0) {
        return _webMedicines.any((m) => m.medicineId == medicineId);
      }
      return _webMedicines.any((m) => m.name == medicineName);
    }

    try {
      final db = await database;
      List<Map<String, dynamic>> maps;
      if (medicineId != null && medicineId > 0) {
        maps = await db.query(
          tableName,
          where: 'medicine_id = ?',
          whereArgs: [medicineId],
          limit: 1,
        );
      } else {
        maps = await db.query(
          tableName,
          where: 'name = ?',
          whereArgs: [medicineName],
          limit: 1,
        );
      }
      return maps.isNotEmpty;
    } catch (e) {
      return false;
    }
  }

  /// البحث في الأدوية المحفوظة محلياً بدون إنترنت
  Future<List<SavedMedicineModel>> searchMedicines(String keyword) async {
    final clean = keyword.trim().toLowerCase();

    if (kIsWeb) {
      if (clean.isEmpty) return await getAllMedicines();
      return _webMedicines.reversed.where((m) {
        return m.name.toLowerCase().contains(clean) ||
            m.genericName.toLowerCase().contains(clean) ||
            m.category.toLowerCase().contains(clean) ||
            m.pharmacyName.toLowerCase().contains(clean);
      }).toList();
    }

    try {
      final db = await database;
      final List<Map<String, dynamic>> maps = await db.query(
        tableName,
        where: 'name LIKE ? OR generic_name LIKE ? OR category LIKE ? OR pharmacy_name LIKE ?',
        whereArgs: ['%$clean%', '%$clean%', '%$clean%', '%$clean%'],
        orderBy: 'id DESC',
      );

      return maps.map((map) => SavedMedicineModel.fromMap(map)).toList();
    } catch (e) {
      throw AppDatabaseException('فشل في تصفية الأدوية المحفوظة: $e');
    }
  }

  // =========================================================================
  // عمليات التحديث (Update)
  // =========================================================================

  /// تحديث بيانات دواء محفوظ باستخدام الدالة المساعدة (db.update)
  Future<int> updateMedicine(SavedMedicineModel medicine) async {
    if (medicine.id == null) {
      throw const AppDatabaseException('لا يمكن التحديث بدون تحديد معرف السجل id');
    }

    if (kIsWeb) {
      final index = _webMedicines.indexWhere((m) => m.id == medicine.id);
      if (index != -1) {
        _webMedicines[index] = medicine;
        return 1;
      }
      return 0;
    }

    try {
      final db = await database;
      return await db.update(
        tableName,
        medicine.toMap(),
        where: 'id = ?',
        whereArgs: [medicine.id],
      );
    } catch (e) {
      throw AppDatabaseException('فشل في تحديث بيانات الدواء: $e');
    }
  }

  /// تحديث بيانات دواء بالاستعلام المباشر (rawUpdate) - تطبيقاً للمحاضرة 9
  Future<int> rawUpdateMedicine(SavedMedicineModel medicine) async {
    if (kIsWeb) {
      return await updateMedicine(medicine);
    }

    if (medicine.id == null) {
      throw const AppDatabaseException('لا يمكن التحديث المباشر بدون id');
    }
    try {
      final db = await database;
      return await db.rawUpdate(
        '''
        UPDATE $tableName 
        SET name = ?, generic_name = ?, category = ?, price = ?, pharmacy_name = ?, pharmacy_phone = ?, is_available = ?, notes = ?
        WHERE id = ?
        ''',
        [
          medicine.name,
          medicine.genericName,
          medicine.category,
          medicine.price,
          medicine.pharmacyName,
          medicine.pharmacyPhone,
          medicine.isAvailable ? 1 : 0,
          medicine.notes,
          medicine.id,
        ],
      );
    } catch (e) {
      throw AppDatabaseException('فشل استعلام التحديث المباشر rawUpdate: $e');
    }
  }

  // =========================================================================
  // عمليات الحذف (Delete)
  // =========================================================================

  /// حذف دواء بواسطة معرفه المحلي id (db.delete)
  Future<int> deleteMedicine(int id) async {
    if (kIsWeb) {
      final before = _webMedicines.length;
      _webMedicines.removeWhere((m) => m.id == id);
      return before - _webMedicines.length;
    }

    try {
      final db = await database;
      return await db.delete(
        tableName,
        where: 'id = ?',
        whereArgs: [id],
      );
    } catch (e) {
      throw AppDatabaseException('فشل في حذف الدواء من قاعدة البيانات: $e');
    }
  }

  /// حذف دواء بواسطة معرّف السيرفر medicineId
  Future<int> deleteByMedicineId(int medicineId) async {
    if (kIsWeb) {
      final before = _webMedicines.length;
      _webMedicines.removeWhere((m) => m.medicineId == medicineId);
      return before - _webMedicines.length;
    }

    try {
      final db = await database;
      return await db.delete(
        tableName,
        where: 'medicine_id = ?',
        whereArgs: [medicineId],
      );
    } catch (e) {
      throw AppDatabaseException('فشل في حذف الدواء بمعرف السيرفر: $e');
    }
  }

  /// حذف دواء بالاستعلام المباشر (rawDelete) - تطبيقاً للمحاضرة 9
  Future<int> rawDeleteMedicine(int id) async {
    if (kIsWeb) {
      return await deleteMedicine(id);
    }

    try {
      final db = await database;
      return await db.rawDelete(
        'DELETE FROM $tableName WHERE id = ?',
        [id],
      );
    } catch (e) {
      throw AppDatabaseException('فشل استعلام الحذف المباشر rawDelete: $e');
    }
  }

  /// تفريغ الجدول بالكامل
  Future<int> clearAllMedicines() async {
    if (kIsWeb) {
      final count = _webMedicines.length;
      _webMedicines.clear();
      return count;
    }

    try {
      final db = await database;
      return await db.delete(tableName);
    } catch (e) {
      throw AppDatabaseException('فشل في تفريغ قاعدة البيانات: $e');
    }
  }
}
