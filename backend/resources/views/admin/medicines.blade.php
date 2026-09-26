@extends('layouts.admin')

@section('title', 'الفهرس الوطني الموحد للأدوية')

@section('content')
<div style="display: flex; justify-content: space-between; align-items: center; margin-bottom: 2rem; flex-wrap: wrap; gap: 16px;">
    <div>
        <h1 style="font-size: 1.8rem; font-weight: 900; color: var(--text-main);">الفهرس الوطني العام للأدوية والمستلزمات</h1>
        <p style="color: var(--text-muted); font-size: 0.95rem; margin-top: 4px;">الدليل المركزي المعتمد للأدوية؛ تستخدمه الصيدليات للربط وتطبيق الهاتف للبحث الجغرافي الموحد.</p>
    </div>
    <button onclick="document.getElementById('addMedicineModal').style.display='block'" class="btn btn-primary" style="padding: 10px 18px; font-size: 0.95rem;">
        + إضافة دواء جديد للفهرس
    </button>
</div>

<!-- نافذة إضافة دواء جديد للفهرس العام -->
<div id="addMedicineModal" style="display: none; background: rgba(0,0,0,0.5); position: fixed; inset: 0; z-index: 1000; overflow-y: auto; padding: 2rem 1rem;">
    <div style="background: white; max-width: 600px; margin: 2rem auto; border-radius: 20px; padding: 2rem; position: relative;">
        <div style="display: flex; justify-content: space-between; align-items: center; margin-bottom: 1.5rem;">
            <h3 style="font-size: 1.3rem; font-weight: 800;">إضافة صنف دوائي جديد للفهرس الوطني</h3>
            <button onclick="document.getElementById('addMedicineModal').style.display='none'" style="background: none; border: none; font-size: 1.5rem; cursor: pointer; color: var(--text-muted);">&times;</button>
        </div>
        <form action="{{ route('admin.medicines.store') }}" method="POST">
            @csrf
            <div style="display: grid; grid-template-columns: 1fr 1fr; gap: 1rem; margin-bottom: 1rem;">
                <div>
                    <label style="display: block; font-weight: 700; font-size: 0.85rem; margin-bottom: 4px;">الاسم التجاري للدواء *</label>
                    <input type="text" name="trade_name" required placeholder="مثال: Panadol Extra" style="width: 100%; padding: 10px; border-radius: 8px; border: 1px solid var(--border-color);">
                </div>
                <div>
                    <label style="display: block; font-weight: 700; font-size: 0.85rem; margin-bottom: 4px;">الاسم العلمي والتركيبة *</label>
                    <input type="text" name="scientific_name" required placeholder="مثال: Paracetamol + Caffeine" style="width: 100%; padding: 10px; border-radius: 8px; border: 1px solid var(--border-color);">
                </div>
            </div>

            <div style="display: grid; grid-template-columns: 1fr 1fr; gap: 1rem; margin-bottom: 1rem;">
                <div>
                    <label style="display: block; font-weight: 700; font-size: 0.85rem; margin-bottom: 4px;">التصنيف العلاجي *</label>
                    <select name="category_id" required style="width: 100%; padding: 10px; border-radius: 8px; border: 1px solid var(--border-color);">
                        @foreach($categories as $cat)
                            <option value="{{ $cat->id }}">{{ $cat->name }}</option>
                        @endforeach
                    </select>
                </div>
                <div>
                    <label style="display: block; font-weight: 700; font-size: 0.85rem; margin-bottom: 4px;">الباركود الدولي (GTIN / Barcode)</label>
                    <input type="text" name="barcode" placeholder="6281001001234" style="width: 100%; padding: 10px; border-radius: 8px; border: 1px solid var(--border-color);">
                </div>
            </div>

            <div style="display: grid; grid-template-columns: 1fr 1fr 1fr; gap: 1rem; margin-bottom: 1.5rem;">
                <div>
                    <label style="display: block; font-weight: 700; font-size: 0.85rem; margin-bottom: 4px;">الشكل الصيدلاني *</label>
                    <input type="text" name="dosage_form" required placeholder="أقراص / شراب" style="width: 100%; padding: 10px; border-radius: 8px; border: 1px solid var(--border-color);">
                </div>
                <div>
                    <label style="display: block; font-weight: 700; font-size: 0.85rem; margin-bottom: 4px;">التركيز / العيار *</label>
                    <input type="text" name="strength" required placeholder="500mg" style="width: 100%; padding: 10px; border-radius: 8px; border: 1px solid var(--border-color);">
                </div>
                <div>
                    <label style="display: block; font-weight: 700; font-size: 0.85rem; margin-bottom: 4px;">الشركة المصنعة *</label>
                    <input type="text" name="manufacturer" required placeholder="GSK / Pfizer" style="width: 100%; padding: 10px; border-radius: 8px; border: 1px solid var(--border-color);">
                </div>
            </div>

            <div style="margin-bottom: 1.5rem;">
                <label style="display: flex; align-items: center; gap: 8px; cursor: pointer;">
                    <input type="checkbox" name="is_prescription_required" value="1">
                    <span style="font-weight: 600; font-size: 0.9rem;">يتطلب وصفة طبية للصرف (Rx Required)</span>
                </label>
            </div>

            <div style="display: flex; justify-content: flex-end; gap: 10px;">
                <button type="button" onclick="document.getElementById('addMedicineModal').style.display='none'" class="btn btn-outline">إلغاء</button>
                <button type="submit" class="btn btn-primary">حفظ في الفهرس العام</button>
            </div>
        </form>
    </div>
</div>

<div class="panel-card">
    <div class="panel-header">
        <h3 class="panel-title">قائمة الأدوية المعتمدة ({{ $medicines->total() }} صنف)</h3>
    </div>
    <table>
        <thead>
            <tr>
                <th># المعرف</th>
                <th>الاسم التجاري والعلمي</th>
                <th>التصنيف</th>
                <th>الباركود</th>
                <th>الشكل والتركيز</th>
                <th>الشركة المصنعة</th>
                <th>الوصفة الطبية</th>
            </tr>
        </thead>
        <tbody>
            @forelse($medicines as $med)
                <tr>
                    <td><span style="font-family: monospace; font-weight: bold;">#{{ $med->id }}</span></td>
                    <td>
                        <strong>{{ $med->trade_name }}</strong>
                        <div style="font-size: 0.8rem; color: var(--text-muted); font-style: italic;">{{ $med->scientific_name }}</div>
                    </td>
                    <td><span class="badge badge-info">{{ $med->category->name ?? 'عام' }}</span></td>
                    <td><code style="background: var(--bg-light); padding: 2px 6px; border-radius: 4px;">{{ $med->barcode ?? '-' }}</code></td>
                    <td>{{ $med->dosage_form }} ({{ $med->strength }})</td>
                    <td>{{ $med->manufacturer }}</td>
                    <td>
                        @if($med->is_prescription_required)
                            <span class="badge badge-danger">Rx إلزامي</span>
                        @else
                            <span class="badge badge-success">OTC بدون وصفة</span>
                        @endif
                    </td>
                </tr>
            @empty
                <tr><td colspan="7" style="text-align: center; color: var(--text-muted); padding: 2rem;">لا توجد أدوية مضافة بعد.</td></tr>
            @endforelse
        </tbody>
    </table>

    <div style="margin-top: 1.5rem;">
        {{ $medicines->links() }}
    </div>
</div>
@endsection
