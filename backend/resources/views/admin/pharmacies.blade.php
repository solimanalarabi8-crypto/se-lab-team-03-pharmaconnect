@extends('layouts.admin')

@section('title', 'إدارة الصيدليات المسجلة')

@section('content')
<div style="display: flex; justify-content: space-between; align-items: center; margin-bottom: 2rem; flex-wrap: wrap; gap: 16px;">
    <div>
        <h1 style="font-size: 1.8rem; font-weight: 900; color: var(--text-main);">إدارة شبكة الصيدليات المعتمدة</h1>
        <p style="color: var(--text-muted); font-size: 0.95rem; margin-top: 4px;">مراجعة الصيدليات المسجلة، تفعيل أو تعطيل الحسابات، ومنح التوثيق والتراخيص ومعرفات الربط البرمجي.</p>
    </div>
</div>

<div class="panel-card">
    <div class="panel-header">
        <h3 class="panel-title">قائمة الصيدليات في منصة PharmaConnect ({{ $pharmacies->total() }} صيدلية)</h3>
    </div>
    <table>
        <thead>
            <tr>
                <th>معرف الصيدلية (ID / API)</th>
                <th>اسم الصيدلية وبياناتها</th>
                <th>الصيدلي المسؤول</th>
                <th>رقم الترخيص</th>
                <th>المخزون المتوفر</th>
                <th>الحالة التشغيلية</th>
                <th>التوثيق والاعتماد</th>
                <th>الإجراءات والتحكم</th>
            </tr>
        </thead>
        <tbody>
            @forelse($pharmacies as $ph)
                <tr>
                    <td>
                        <span class="badge badge-info" style="font-family: monospace; font-size: 0.85rem;">ID: #{{ $ph->id }}</span>
                    </td>
                    <td>
                        <strong>{{ $ph->name }}</strong>
                        <div style="font-size: 0.8rem; color: var(--text-muted); margin-top: 2px;">📍 {{ $ph->address }}</div>
                        <div style="font-size: 0.8rem; color: var(--text-muted);">📞 {{ $ph->phone }}</div>
                    </td>
                    <td>
                        <div>{{ $ph->user->name ?? 'غير مرتبط' }}</div>
                        <div style="font-size: 0.8rem; color: var(--text-muted);">{{ $ph->user->email ?? '-' }}</div>
                    </td>
                    <td>
                        <span style="font-family: monospace; font-weight: bold;">{{ $ph->license_number }}</span>
                    </td>
                    <td>
                        <strong style="color: var(--primary);">{{ $ph->medicines->count() }} صنف</strong>
                    </td>
                    <td>
                        @if($ph->is_active)
                            <span class="badge badge-success">نشطة ومتاحة</span>
                        @else
                            <span class="badge badge-danger">معطلة مؤقتاً</span>
                        @endif
                    </td>
                    <td>
                        @if($ph->is_verified)
                            <span class="badge badge-success">موثقة ومعتمدة ✓</span>
                        @else
                            <span class="badge badge-warning">قيد المراجعة</span>
                        @endif
                    </td>
                    <td>
                        <div style="display: flex; gap: 8px; flex-wrap: wrap;">
                            <!-- زر تفعيل / تعطيل -->
                            <form action="{{ route('admin.pharmacies.toggle-status', $ph->id) }}" method="POST" style="margin: 0;">
                                @csrf
                                <button type="submit" class="btn {{ $ph->is_active ? 'btn-danger-outline' : 'btn-primary' }}">
                                    {{ $ph->is_active ? 'تعطيل' : 'تفعيل' }}
                                </button>
                            </form>

                            <!-- زر توثيق / إلغاء توثيق -->
                            <form action="{{ route('admin.pharmacies.toggle-verify', $ph->id) }}" method="POST" style="margin: 0;">
                                @csrf
                                <button type="submit" class="btn btn-outline">
                                    {{ $ph->is_verified ? 'إلغاء التوثيق' : 'توثيق واعتَماد' }}
                                </button>
                            </form>
                        </div>
                    </td>
                </tr>
            @empty
                <tr><td colspan="8" style="text-align: center; color: var(--text-muted); padding: 2rem;">لا توجد صيدليات مضافة بعد.</td></tr>
            @endforelse
        </tbody>
    </table>

    <div style="margin-top: 1.5rem;">
        {{ $pharmacies->links() }}
    </div>
</div>
@endsection
