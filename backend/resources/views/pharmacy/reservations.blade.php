@extends('layouts.pharmacy')

@section('title', 'طلبات الحجز الواردة - ' . $pharmacy->name)

@section('content')
    <div class="card">
        <div style="display: flex; justify-content: space-between; align-items: center; flex-wrap: wrap; gap: 10px; margin-bottom: 0.5rem;">
            <h2 style="color: var(--primary-dark); margin: 0;">⏱️ طلبات الحجز المؤقت الواردة</h2>
            <div style="display: flex; align-items: center; gap: 8px;">
                <span id="sync-badge" class="badge badge-success" style="display: inline-flex; align-items: center; gap: 6px; padding: 6px 12px; font-size: 0.85rem;">
                    <span style="display: inline-block; width: 8px; height: 8px; background-color: #10B981; border-radius: 50%; box-shadow: 0 0 8px #10B981; animation: pulse 1.5s infinite;"></span>
                    المزامنة الحية نشطة (تحديث تلقائي)
                </span>
                <button type="button" id="toggle-sync-btn" onclick="toggleAutoSync()" class="btn btn-outline" style="padding: 4px 10px; font-size: 0.8rem;">
                    إيقاف مؤقت
                </button>
            </div>
        </div>
        <p style="color: var(--text-muted); font-size: 0.95rem; margin-bottom: 1.5rem;">
            تظهر هنا طلبات الحجز المؤقت التي قام المرضى بإرسالها من تطبيق الموبايل لحظياً، مع حفظ الكميات لهم لمدة 30 دقيقة.
        </p>

        @if($allPharmacies->count() > 1)
            <div style="background: var(--mint-bg); border: 1px solid var(--mint-accent); border-radius: 12px; padding: 12px 16px; margin-bottom: 1.5rem; display: flex; align-items: center; justify-content: space-between; flex-wrap: wrap; gap: 12px;">
                <div style="display: flex; align-items: center; gap: 8px;">
                    <span style="font-weight: 700; color: var(--primary-dark);">🏢 تصفية واستعراض الصيدلية:</span>
                    <select onchange="window.location.href='{{ route('pharmacy.reservations') }}?pharmacy_id=' + this.value" class="form-control" style="width: auto; padding: 6px 14px; font-weight: 600; display: inline-block;">
                        <option value="all" {{ $selectedPharmacyId === 'all' ? 'selected' : '' }}>🌟 كافة الصيدليات المشتركة (عرض شامل)</option>
                        @foreach($allPharmacies as $p)
                            <option value="{{ $p->id }}" {{ (string)$selectedPharmacyId === (string)$p->id ? 'selected' : '' }}>
                                {{ $p->name }}
                            </option>
                        @endforeach
                    </select>
                </div>
                <div style="font-size: 0.9rem; color: var(--primary-dark); font-weight: 600;">
                    إجمالي الحجوزات: <strong>{{ count($reservations) }}</strong>
                </div>
            </div>
        @endif

        <div class="table-responsive" id="reservations-table-wrapper">
            <table>
                <thead>
                    <tr>
                        <th>رمز الحجز</th>
                        @if($isSuperAdmin || $selectedPharmacyId === 'all')
                            <th>الصيدلية المستلمة</th>
                        @endif
                        <th>اسم المريض والهاتف</th>
                        <th>الأدوية المطلوبة والكمية</th>
                        <th>الإجمالي</th>
                        <th>المهلة المتبقية (TTL)</th>
                        <th>حالة الحجز</th>
                        <th>الإجراء</th>
                    </tr>
                </thead>
                <tbody>
                    @forelse($reservations as $res)
                        <tr>
                            <td>
                                <strong style="color: var(--primary); font-size: 1.05rem;">{{ $res->reservation_code }}</strong>
                                <div style="font-size: 0.75rem; color: var(--text-muted);">{{ $res->created_at->format('Y-m-d H:i') }}</div>
                            </td>
                            @if($isSuperAdmin || $selectedPharmacyId === 'all')
                                <td>
                                    <span style="font-weight: 700; color: var(--primary-dark);">{{ $res->pharmacy?->name ?? 'غير محدد' }}</span>
                                    <div style="font-size: 0.75rem; color: var(--text-muted);">{{ $res->pharmacy?->address }}</div>
                                </td>
                            @endif
                            <td>
                                <strong>{{ $res->user->name }}</strong>
                                <div style="font-size: 0.85rem; color: var(--text-muted);">{{ $res->user->phone ?? 'بدون هاتف' }}</div>
                            </td>
                            <td>
                                @foreach($res->reservationItems as $item)
                                    <div>
                                        • {{ $item->pharmacyMedicine?->medicine?->trade_name }} 
                                        <strong>× {{ $item->quantity }}</strong>
                                    </div>
                                @endforeach
                            </td>
                            <td><strong>{{ number_format($res->total_amount, 2) }} ريال</strong></td>
                            <td>
                                @if($res->status === 'pending')
                                    @if($res->expires_at->isPast())
                                        <span class="badge badge-danger">منتهي الصلاحية</span>
                                    @else
                                        <span class="badge badge-warning">
                                            متبقي {{ max(0, (int) now()->diffInMinutes($res->expires_at)) }} دقيقة
                                        </span>
                                    @endif
                                @else
                                    <span style="color: var(--text-muted);">-</span>
                                @endif
                            </td>
                            <td>
                                @if($res->status === 'pending')
                                    <span class="badge badge-warning">قيد الانتظار</span>
                                @elseif($res->status === 'completed')
                                    <span class="badge badge-success">تم التسليم والمحاسبة</span>
                                @elseif($res->status === 'expired')
                                    <span class="badge badge-danger">ملغي (انتهاء المهلة)</span>
                                @else
                                    <span class="badge badge-danger">{{ $res->status }}</span>
                                @endif
                            </td>
                            <td>
                                @if($res->status === 'pending' && ! $res->expires_at->isPast())
                                    <form action="{{ route('pharmacy.reservations.confirm', $res->id) }}" method="POST" onsubmit="return confirm('هل حضر المريض وتم تسليمه الدواء واستلام المبلغ؟')">
                                        @csrf
                                        <button type="submit" class="btn btn-primary" style="padding: 6px 14px; font-size: 0.85rem;">
                                            ✅ تأكيد التسليم
                                        </button>
                                    </form>
                                @else
                                    <span style="color: var(--text-muted); font-size: 0.85rem;">مكتمل</span>
                                @endif
                            </td>
                        </tr>
                    @empty
                        <tr>
                            <td colspan="{{ ($isSuperAdmin || $selectedPharmacyId === 'all') ? '8' : '7' }}" style="text-align: center; padding: 3rem; color: var(--text-muted);">
                                لا توجد حجوزات واردة حالياً. ستظهر هنا فور قيام أي مريض بالحجز عبر تطبيق الموبايل.
                            </td>
                        </tr>
                    @endforelse
                </tbody>
            </table>
        </div>
    </div>

    <style>
        @keyframes pulse {
            0% { transform: scale(0.95); opacity: 0.8; }
            50% { transform: scale(1.2); opacity: 1; }
            100% { transform: scale(0.95); opacity: 0.8; }
        }
    </style>

    <script>
        let autoSyncEnabled = true;
        let syncInterval = null;

        function toggleAutoSync() {
            autoSyncEnabled = !autoSyncEnabled;
            const badge = document.getElementById('sync-badge');
            const btn = document.getElementById('toggle-sync-btn');
            if (autoSyncEnabled) {
                badge.className = 'badge badge-success';
                badge.innerHTML = '<span style="display: inline-block; width: 8px; height: 8px; background-color: #10B981; border-radius: 50%; box-shadow: 0 0 8px #10B981; animation: pulse 1.5s infinite;"></span> المزامنة الحية نشطة (تحديث تلقائي)';
                btn.innerText = 'إيقاف مؤقت';
                startSync();
            } else {
                badge.className = 'badge badge-warning';
                badge.innerHTML = 'المزامنة الحية متوقفة مؤقتاً';
                btn.innerText = 'استئناف';
                if (syncInterval) clearInterval(syncInterval);
            }
        }

        async function fetchLatestReservations() {
            if (!autoSyncEnabled) return;
            try {
                const response = await fetch(window.location.href, {
                    headers: { 'X-Requested-With': 'XMLHttpRequest' }
                });
                if (response.ok) {
                    const htmlText = await response.text();
                    const parser = new DOMParser();
                    const doc = parser.parseFromString(htmlText, 'text/html');
                    const newWrapper = doc.getElementById('reservations-table-wrapper');
                    const currentWrapper = document.getElementById('reservations-table-wrapper');
                    if (newWrapper && currentWrapper) {
                        if (currentWrapper.innerHTML !== newWrapper.innerHTML) {
                            currentWrapper.innerHTML = newWrapper.innerHTML;
                        }
                    }
                }
            } catch (err) {
                console.warn('Auto-sync check failed:', err);
            }
        }

        function startSync() {
            if (syncInterval) clearInterval(syncInterval);
            syncInterval = setInterval(fetchLatestReservations, 5000);
        }

        // بدء المزامنة فور اكتمال تحميل الصفحة
        document.addEventListener('DOMContentLoaded', startSync);
    </script>
@endsection
