# مخطط قاعدة البيانات (Entity-Relationship Diagram)

> **PharmaConnect** — هندسة البرمجيات | الفريق 03

---

## ERD — مخطط العلاقات بين الكيانات

```mermaid
erDiagram
    USERS {
        int id PK
        string name
        string email
        string password_hash
        enum role "patient | pharmacist | admin"
        timestamp created_at
    }

    PHARMACIES {
        int id PK
        string name
        string address
        string phone
        float latitude
        float longitude
        int owner_id FK
        timestamp created_at
    }

    MEDICINES {
        int id PK
        string name
        string scientific_name
        string category
        string description
        string unit
        timestamp created_at
    }

    INVENTORY {
        int id PK
        int pharmacy_id FK
        int medicine_id FK
        int quantity
        float price
        date expiry_date
        timestamp updated_at
    }

    RESERVATIONS {
        int id PK
        int patient_id FK
        int inventory_id FK
        int quantity
        enum status "pending | confirmed | expired | cancelled"
        timestamp reserved_at
        timestamp expires_at
    }

    SAVED_MEDICINES {
        int id PK
        int patient_id FK
        int medicine_id FK
        timestamp saved_at
    }

    USERS ||--o{ PHARMACIES : "يمتلك"
    USERS ||--o{ RESERVATIONS : "يحجز"
    USERS ||--o{ SAVED_MEDICINES : "يحفظ"
    PHARMACIES ||--o{ INVENTORY : "تمتلك"
    MEDICINES ||--o{ INVENTORY : "موجودة في"
    MEDICINES ||--o{ SAVED_MEDICINES : "محفوظة في"
    INVENTORY ||--o{ RESERVATIONS : "تُحجز من"
```

---

## وصف الكيانات

| الكيان | الوصف |
|:---|:---|
| **USERS** | المستخدمون (مريض، صيدلاني، مشرف) |
| **PHARMACIES** | الصيدليات المسجلة في النظام |
| **MEDICINES** | كتالوج الأدوية المرجعي |
| **INVENTORY** | مخزون كل دواء في كل صيدلية مع السعر والكمية |
| **RESERVATIONS** | الحجوزات مع نظام TTL (انتهاء في 30 دقيقة) |
| **SAVED_MEDICINES** | قائمة الأدوية المحفوظة محلياً لكل مريض |

---

## العلاقات الرئيسية

- **مستخدم واحد** يمكنه امتلاك **صيدلية واحدة** (صيدلاني) أو **حجوزات متعددة** (مريض).
- **صيدلية واحدة** لها **مخزون متعدد** من الأدوية المختلفة.
- **دواء واحد** يمكن أن يكون موجوداً في **صيدليات متعددة** بأسعار وكميات مختلفة.
- **الحجز** يرتبط بسجل **مخزون محدد** ويتضمن تاريخ انتهاء تلقائي.
