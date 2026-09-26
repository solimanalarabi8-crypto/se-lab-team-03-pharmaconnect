# مخطط معمارية النظام (System Architecture Diagram)

> **PharmaConnect** — هندسة البرمجيات | الفريق 03

---

## Architecture Diagram — المعمارية العامة للنظام

```mermaid
graph TB
    subgraph Client["🖥️ طبقة العميل (Client Layer)"]
        Mobile["📱 تطبيق الجوال\n(Android/Kotlin)\nMalik Jubran"]
        Web["🌐 بوابة الويب للصيدلاني\n(Laravel Blade)\nSulaiman Al-Arabi"]
        SQLite["💾 SQLite\n(تخزين محلي)"]
    end

    subgraph API["⚙️ طبقة الخدمات (API Layer)"]
        SearchAPI["🔍 MedicineSearchController\n/api/medicines/search"]
        ReservationAPI["📋 ReservationApiController\n/api/reservations\n+ TTL Engine"]
        InventoryAPI["📦 InventoryController\n/pharmacy/inventory"]
        AuthAPI["🔐 AuthController\n/auth/login"]
    end

    subgraph Backend["🔧 الخادم (Backend - Laravel)"]
        Router["Laravel Router"]
        Middleware["Auth Middleware\n+ Rate Limiter"]
        Models["Eloquent Models\n(User, Medicine, Inventory\nReservation, SavedMedicine)"]
    end

    subgraph Database["🗄️ قاعدة البيانات"]
        MySQL[("MySQL\nProduction DB")]
        Migrations["📝 Database Migrations\n(Schema Versioning)"]
    end

    Mobile -->|"HTTPS REST"| SearchAPI
    Mobile -->|"HTTPS REST"| ReservationAPI
    Mobile <-->|"Local Cache"| SQLite
    Web -->|"HTTP"| InventoryAPI
    Web -->|"HTTP"| AuthAPI

    SearchAPI --> Router
    ReservationAPI --> Router
    InventoryAPI --> Router
    AuthAPI --> Router

    Router --> Middleware
    Middleware --> Models
    Models --> MySQL
    Migrations -.->|"يُعرِّف Schema"| MySQL
```

---

## مخطط طبقات المعمارية (Layered Architecture)

```mermaid
graph LR
    A["👤 المستخدم"] --> B["📱/🌐 واجهة المستخدم"]
    B --> C["🔧 طبقة التحكم\n(Controllers)"]
    C --> D["📊 طبقة المنطق\n(Models/Services)"]
    D --> E["🗄️ طبقة البيانات\n(MySQL)"]
    
    style A fill:#4CAF50,color:#fff
    style B fill:#2196F3,color:#fff
    style C fill:#FF9800,color:#fff
    style D fill:#9C27B0,color:#fff
    style E fill:#607D8B,color:#fff
```

---

## توزيع المسؤوليات على الفريق

| الطبقة | المكوّن | المسؤول |
|:---|:---|:---|
| **Mobile Client** | تطبيق الجوال + SQLite | مالك جبران |
| **Web Portal** | لوحة تحكم الصيدلاني | سليمان العربي |
| **Backend API** | Controllers + TTL Engine | يعقوب المهاجري |
| **Database** | Migrations + Schema | يعقوب المهاجري |

---

## تدفق البيانات الرئيسي

```mermaid
flowchart LR
    Patient(["👤 مريض"]) -->|"يبحث عن دواء"| SearchCtrl["🔍 Search API"]
    SearchCtrl -->|"استعلام"| DB[("🗄️ MySQL")]
    DB -->|"النتائج"| SearchCtrl
    SearchCtrl -->|"JSON"| Patient

    Patient -->|"يحجز"| ResCtrl["📋 Reservation API"]
    ResCtrl -->|"تأمين الكمية"| DB
    ResCtrl -->|"إشعار"| Pharmacist(["💊 صيدلاني"])
    Pharmacist -->|"يؤكد"| ResCtrl
    ResCtrl -->|"تأكيد"| Patient
```
