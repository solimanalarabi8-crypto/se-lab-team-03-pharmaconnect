@extends('layouts.admin')

@section('title', 'إدارة المرضى ومستخدمي تطبيق العميل')

@section('content')
<div style="margin-bottom: 2rem;">
    <h1 style="font-size: 1.8rem; font-weight: 900; color: var(--text-main);">المرضى ومستخدمي تطبيق العميل (Flutter Mobile App)</h1>
    <p style="color: var(--text-muted); font-size: 0.95rem; margin-top: 4px;">متابعة الحسابات المنشأة عبر تطبيق الهاتف المحمول، أرقام التواصل، ونشاط الحجوزات الطبية.</p>
</div>

<div class="panel-card">
    <div class="panel-header">
        <h3 class="panel-title">قائمة المرضى المسجلين ({{ $patients->total() }} مريض)</h3>
    </div>
    <table>
        <thead>
            <tr>
                <th># المعرف</th>
                <th>اسم المريض</th>
                <th>البريد الإلكتروني</th>
                <th>رقم الهاتف للتواصل</th>
                <th>إجمالي الحجوزات الدوائية</th>
                <th>حالة الحساب</th>
                <th>تاريخ التسجيل</th>
            </tr>
        </thead>
        <tbody>
            @forelse($patients as $patient)
                <tr>
                    <td><span style="font-family: monospace; font-weight: bold;">#{{ $patient->id }}</span></td>
                    <td>
                        <div style="display: flex; align-items: center; gap: 8px;">
                            <span style="background: var(--mint-accent); color: var(--primary); padding: 4px 8px; border-radius: 8px; font-size: 0.9rem;">👤</span>
                            <strong>{{ $patient->name }}</strong>
                        </div>
                    </td>
                    <td>{{ $patient->email }}</td>
                    <td>
                        @if($patient->phone)
                            <span style="direction: ltr; display: inline-block;">{{ $patient->phone }}</span>
                        @else
                            <span style="color: var(--text-muted);">غير متوفر</span>
                        @endif
                    </td>
                    <td>
                        <span class="badge badge-info" style="font-size: 0.85rem;">{{ $patient->reservations_count }} حجز</span>
                    </td>
                    <td>
                        <span class="badge badge-success">نشط ومعتمد</span>
                    </td>
                    <td style="font-size: 0.85rem; color: var(--text-muted);">{{ $patient->created_at->format('Y-m-d H:i') }}</td>
                </tr>
            @empty
                <tr><td colspan="7" style="text-align: center; color: var(--text-muted); padding: 2rem;">لا يوجد مرضى مسجلين بعد.</td></tr>
            @endforelse
        </tbody>
    </table>

    <div style="margin-top: 1.5rem;">
        {{ $patients->links() }}
    </div>
</div>
@endsection
