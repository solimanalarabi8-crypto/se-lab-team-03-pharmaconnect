# مخطط التسلسل (Sequence Diagrams)

> **PharmaConnect** — هندسة البرمجيات | الفريق 03

---

## Sequence Diagram 1: البحث عن دواء وعرض النتائج

```mermaid
sequenceDiagram
    actor Patient as 👤 المريض
    participant App as 📱 تطبيق الجوال
    participant API as 🔧 MedicineSearchController
    participant DB as 🗄️ قاعدة البيانات
    participant SQLite as 💾 SQLite (محلي)

    Patient->>App: يكتب اسم الدواء
    App->>API: GET /api/medicines/search?q={name}
    
    alt متصل بالإنترنت
        API->>DB: SELECT * FROM inventory WHERE medicine LIKE '%name%'
        DB-->>API: قائمة الصيدليات والكميات والأسعار
        API-->>App: JSON Response (200 OK)
        App->>SQLite: يحفظ النتائج محلياً
    else غير متصل
        App->>SQLite: SELECT * FROM cached_medicines
        SQLite-->>App: بيانات محلية محفوظة سابقاً
    end
    
    App-->>Patient: يعرض قائمة الصيدليات المتاحة
```

---

## Sequence Diagram 2: حجز دواء بنظام TTL (30 دقيقة)

```mermaid
sequenceDiagram
    actor Patient as 👤 المريض
    actor Pharmacist as 💊 الصيدلاني
    participant App as 📱 التطبيق
    participant API as 🔧 ReservationApiController
    participant DB as 🗄️ قاعدة البيانات
    participant Timer as ⏱️ TTL Timer

    Patient->>App: يضغط "احجز"
    App->>API: POST /api/reservations
    
    API->>DB: BEGIN TRANSACTION
    API->>DB: SELECT ... FOR UPDATE (Pessimistic Lock)
    
    alt الكمية متاحة
        DB-->>API: السجل مؤمَّن
        API->>DB: INSERT INTO reservations (status='pending', expires_at=+30min)
        API->>DB: UPDATE inventory SET quantity = quantity - 1
        API->>DB: COMMIT
        API->>Timer: يُطلق مؤقت 30 دقيقة
        API-->>App: 201 Created (reservation_id)
        App-->>Patient: "تم الحجز! تبقى 30 دقيقة"
        
        API-->>Pharmacist: إشعار بحجز جديد
        
        alt الصيدلاني يؤكد قبل 30 دقيقة
            Pharmacist->>API: PATCH /api/reservations/{id}/confirm
            API->>DB: UPDATE reservations SET status='confirmed'
            API-->>Patient: "تم التأكيد! الدواء جاهز للاستلام"
        else انتهت 30 دقيقة
            Timer->>API: انتهى الوقت
            API->>DB: UPDATE reservations SET status='expired'
            API->>DB: UPDATE inventory SET quantity = quantity + 1
            API-->>Patient: "انتهت مدة الحجز، يُرجى المحاولة مجدداً"
        end
        
    else الكمية غير متاحة
        DB-->>API: رفض التأمين
        API->>DB: ROLLBACK
        API-->>App: 409 Conflict
        App-->>Patient: "الدواء غير متاح حالياً"
    end
```

---

## Sequence Diagram 3: إدارة المخزون (الصيدلاني)

```mermaid
sequenceDiagram
    actor Pharmacist as 💊 الصيدلاني
    participant Web as 🌐 بوابة الويب
    participant Controller as 🔧 InventoryController
    participant DB as 🗄️ قاعدة البيانات

    Pharmacist->>Web: يسجل الدخول
    Web->>Controller: POST /pharmacy/login
    Controller-->>Web: Token + Dashboard

    Pharmacist->>Web: يضيف دواء للمخزون
    Web->>Controller: POST /pharmacy/inventory
    Controller->>DB: INSERT INTO inventory
    DB-->>Controller: تم الإدراج
    Controller-->>Web: إعادة توجيه للوحة
    Web-->>Pharmacist: "تم إضافة الدواء بنجاح"

    Pharmacist->>Web: يعرض الحجوزات المعلقة
    Web->>Controller: GET /pharmacy/reservations
    Controller->>DB: SELECT * WHERE status='pending'
    DB-->>Controller: قائمة الحجوزات
    Controller-->>Web: عرض الحجوزات
```
