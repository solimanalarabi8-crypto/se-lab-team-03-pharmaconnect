@extends('layouts.admin')

@section('title', 'لوحة الإدارة المركزية والمؤشرات')

@section('content')
<div style="margin-bottom: 2rem;">
    <h1 style="font-size: 1.8rem; font-weight: 900; color: var(--text-main);">لوحة التحكم والإدارة المركزية لنظام PharmaConnect</h1>
    <p style="color: var(--text-muted); font-size: 0.95rem; margin-top: 4px;">مراقبة حية وشاملة لشبكة الصيدليات، تطبيق المرضى، الحجوزات اللحظية، وتكاملات الـ B2B API.</p>
</div>

<!-- بطاقات المؤشرات الرقمية العامة (System Metrics) -->
<div class="stats-grid">
    <div class="stat-card">
        <div class="stat-title">إجمالي الصيدليات</div>
        <div class="stat-value">{{ $stats['total_pharmacies'] }}</div>
        <div class="stat-desc">{{ $stats['active_pharmacies'] }} صيدلية مفعلة ونشطة</div>
    </div>
    <div class="stat-card">
        <div class="stat-title">المرضى المسجلين (التطبيق)</div>
        <div class="stat-value">{{ $stats['total_patients'] }}</div>
        <div class="stat-desc">عملاء نشطين عبر تطبيق الهاتف</div>
    </div>
    <div class="stat-card">
        <div class="stat-title">الأدوية بالفهرس العام</div>
        <div class="stat-value">{{ $stats['total_medicines'] }}</div>
        <div class="stat-desc">أصناف مسجلة بالباركود والجرعات</div>
    </div>
    <div class="stat-card">
        <div class="stat-title">إجمالي الحجوزات اللحظية</div>
        <div class="stat-value">{{ $stats['total_reservations'] }}</div>
        <div class="stat-desc">{{ $stats['completed_reservations'] }} مكتملة | {{ $stats['pending_reservations'] }} قيد الانتظار</div>
    </div>
</div>

<!-- بطاقة الربط البرمجي لأنظمة الصيدليات (Partner Integration API Guide) -->
<div class="panel-card" style="background: linear-gradient(135deg, #0F172A, #1E293B); color: white; border: none;">
    <div style="display: flex; justify-content: space-between; align-items: flex-start; flex-wrap: wrap; gap: 16px;">
        <div>
            <span class="badge" style="background: rgba(16, 185, 129, 0.2); color: #34D399; margin-bottom: 8px;">واجهة الربط البرمجي B2B REST API</span>
            <h2 style="font-size: 1.3rem; font-weight: 800; margin-bottom: 6px;">ربط أنظمة الصيدليات الخارجية مع PharmaConnect</h2>
            <p style="color: #94A3B8; font-size: 0.9rem; max-width: 800px; line-height: 1.5;">
                يوفر نظامنا واجهات برمجة تطبيقات موحدة (RESTful Endpoints) تتيح لأي صيدلية ربط نظامها المحاسبي أو برنامج نقاط البيع (POS / Onyx Pro) مع منصتنا تلقائياً دون الحاجة لتعديل يدوي.
            </p>
        </div>
        <div style="background: rgba(255,255,255,0.08); padding: 12px 18px; border-radius: 12px; border: 1px solid rgba(255,255,255,0.1);">
            <div style="font-size: 0.75rem; color: #94A3B8;">مسار المزامنة العام (Sync Endpoint)</div>
            <code style="color: #34D399; font-size: 0.9rem; font-weight: bold;">POST /api/v1/partner/inventory/sync</code>
        </div>
    </div>
    <div style="display: grid; grid-template-columns: repeat(auto-fit, minmax(280px, 1fr)); gap: 1rem; margin-top: 1.25rem;">
        <div style="background: rgba(255,255,255,0.05); padding: 12px; border-radius: 10px;">
            <div style="font-weight: 700; color: #E2E8F0; font-size: 0.9rem;">1. مزامنة المخزون بالجملة (Batch Sync)</div>
            <div style="color: #94A3B8; font-size: 0.8rem; margin-top: 4px;"><code>POST /api/v1/partner/inventory/sync</code> لإرسال تحديثات الفواتير والكميات آلياً.</div>
        </div>
        <div style="background: rgba(255,255,255,0.05); padding: 12px; border-radius: 10px;">
            <div style="font-weight: 700; color: #E2E8F0; font-size: 0.9rem;">2. تحديث الكاشير اللحظي (POS Single Sale)</div>
            <div style="color: #94A3B8; font-size: 0.8rem; margin-top: 4px;"><code>POST /api/v1/partner/inventory/update-item</code> لخصم الكمية فور بيع العلبة.</div>
        </div>
        <div style="background: rgba(255,255,255,0.05); padding: 12px; border-radius: 10px;">
            <div style="font-weight: 700; color: #E2E8F0; font-size: 0.9rem;">3. سحب وتأكيد الحجوزات (Reservations)</div>
            <div style="color: #94A3B8; font-size: 0.8rem; margin-top: 4px;"><code>GET /api/v1/partner/reservations</code> لسحب طلبات المرضى إلى شاشة الكاشير.</div>
        </div>
    </div>
</div>

<div style="display: grid; grid-template-columns: 1fr 1fr; gap: 2rem; margin-bottom: 2rem;">
    <!-- أحدث الصيدليات -->
    <div class="panel-card" style="margin-bottom: 0;">
        <div class="panel-header">
            <h3 class="panel-title">أحدث الصيدليات المنضمة</h3>
            <a href="{{ route('admin.pharmacies') }}" class="btn btn-outline">عرض الكل &larr;</a>
        </div>
        <table>
            <thead>
                <tr>
                    <th>الصيدلية</th>
                    <th>الترخيص</th>
                    <th>الحالة</th>
                    <th>التوثيق</th>
                </tr>
            </thead>
            <tbody>
                @forelse($recentPharmacies as $ph)
                    <tr>
                        <td>
                            <strong>{{ $ph->name }}</strong>
                            <div style="font-size: 0.8rem; color: var(--text-muted);">{{ $ph->address }}</div>
                        </td>
                        <td>{{ $ph->license_number }}</td>
                        <td>
                            @if($ph->is_active)
                                <span class="badge badge-success">نشطة</span>
                            @else
                                <span class="badge badge-danger">معطلة</span>
                            @endif
                        </td>
                        <td>
                            @if($ph->is_verified)
                                <span class="badge badge-success">معتمدة ✓</span>
                            @else
                                <span class="badge badge-warning">قيد المراجعة</span>
                            @endif
                        </td>
                    </tr>
                @empty
                    <tr><td colspan="4" style="text-align: center; color: var(--text-muted);">لا توجد صيدليات مسجلة حالياً.</td></tr>
                @endforelse
            </tbody>
        </table>
    </div>

    <!-- أحدث المرضى المسجلين من التطبيق -->
    <div class="panel-card" style="margin-bottom: 0;">
        <div class="panel-header">
            <h3 class="panel-title">أحدث المرضى من تطبيق العميل</h3>
            <a href="{{ route('admin.patients') }}" class="btn btn-outline">عرض الكل &larr;</a>
        </div>
        <table>
            <thead>
                <tr>
                    <th>اسم المريض</th>
                    <th>البريد الإلكتروني</th>
                    <th>الهاتف</th>
                    <th>تاريخ الانضمام</th>
                </tr>
            </thead>
            <tbody>
                @forelse($recentPatients as $patient)
                    <tr>
                        <td><strong>{{ $patient->name }}</strong></td>
                        <td>{{ $patient->email }}</td>
                        <td>{{ $patient->phone ?? 'غير محدد' }}</td>
                        <td style="font-size: 0.85rem; color: var(--text-muted);">{{ $patient->created_at->diffForHumans() }}</td>
                    </tr>
                @empty
                    <tr><td colspan="4" style="text-align: center; color: var(--text-muted);">لا يوجد مرضى مسجلين حتى الآن.</td></tr>
                @endforelse
            </tbody>
        </table>
    </div>
</div>

<!-- أحدث الحجوزات اللحظية عبر الشبكة -->
<div class="panel-card">
    <div class="panel-header">
        <h3 class="panel-title">أحدث الحجوزات الطبية اللحظية عبر المنصة</h3>
    </div>
    <table>
        <thead>
            <tr>
                <th>كود الحجز</th>
                <th>الصيدلية المحجوز لديها</th>
                <th>المريض</th>
                <th>المبلغ الإجمالي</th>
                <th>الحالة</th>
                <th>وقت الطلب</th>
            </tr>
        </thead>
        <tbody>
            @forelse($recentReservations as $res)
                <tr>
                    <td><strong>{{ $res->reservation_code }}</strong></td>
                    <td>{{ $res->pharmacy->name ?? 'صيدلية غير محددة' }}</td>
                    <td>{{ $res->user->name ?? 'مريض زائر' }}</td>
                    <td><strong style="color: var(--primary);">{{ number_format($res->total_amount, 0) }} YER</strong></td>
                    <td>
                        @if($res->status === 'completed')
                            <span class="badge badge-success">تم الاستلام</span>
                        @elseif($res->status === 'pending')
                            <span class="badge badge-warning">قيد الانتظار (TTL)</span>
                        @elseif($res->status === 'cancelled')
                            <span class="badge badge-danger">ملغي</span>
                        @else
                            <span class="badge badge-info">{{ $res->status }}</span>
                        @endif
                    </td>
                    <td style="font-size: 0.85rem; color: var(--text-muted);">{{ $res->created_at->format('Y-m-d H:i') }}</td>
                </tr>
            @empty
                <tr><td colspan="6" style="text-align: center; color: var(--text-muted); padding: 2rem;">لا توجد حجوزات مسجلة حالياً.</td></tr>
            @endforelse
        </tbody>
    </table>
</div>
@endsection
