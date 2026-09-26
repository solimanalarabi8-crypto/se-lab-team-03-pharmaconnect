@extends('layouts.pharmacy')

@section('title', 'إدارة المخزون - ' . $pharmacy->name)

@section('content')
    <!-- كروت الإحصائيات السريعة -->
    <div style="display: grid; grid-template-columns: repeat(auto-fit, minmax(220px, 1fr)); gap: 1rem; margin-bottom: 1.5rem;">
        <div class="card" style="margin-bottom: 0;">
            <p style="color: var(--text-muted); font-size: 0.9rem; font-weight: 600;">إجمالي الأصناف بالمخزون</p>
            <h2 style="color: var(--primary); font-size: 1.8rem; margin-top: 5px;">{{ $stats['total_items'] }}</h2>
        </div>
        <div class="card" style="margin-bottom: 0;">
            <p style="color: var(--text-muted); font-size: 0.9rem; font-weight: 600;">أصناف متوفرة</p>
            <h2 style="color: var(--primary-dark); font-size: 1.8rem; margin-top: 5px;">{{ $stats['available_count'] }}</h2>
        </div>
        <div class="card" style="margin-bottom: 0;">
            <p style="color: var(--text-muted); font-size: 0.9rem; font-weight: 600;">أصناف قاربت على النفاذ</p>
            <h2 style="color: var(--status-warning); font-size: 1.8rem; margin-top: 5px;">{{ $stats['low_stock_count'] }}</h2>
        </div>
        <div class="card" style="margin-bottom: 0;">
            <p style="color: var(--text-muted); font-size: 0.9rem; font-weight: 600;">حجوزات نشطة جارية</p>
            <h2 style="color: #2563EB; font-size: 1.8rem; margin-top: 5px;">{{ $stats['pending_reservations'] }}</h2>
        </div>
    </div>

    <!-- شريط البحث وإضافة دواء -->
    <div class="card" style="display: flex; justify-content: space-between; align-items: center; flex-wrap: gap: 1rem;">
        <form action="{{ route('pharmacy.inventory') }}" method="GET" style="display: flex; gap: 0.5rem; flex: 1; max-width: 500px;">
            <input type="text" name="q" value="{{ request('q') }}" placeholder="ابحث باسم الدواء التجاري أو العلمي..." class="form-control">
            <button type="submit" class="btn btn-primary">بحث</button>
            @if(request('q'))
                <a href="{{ route('pharmacy.inventory') }}" class="btn btn-outline">إلغاء</a>
            @endif
        </form>

        <!-- زر إضافة دواء من الفهرس -->
        <button onclick="document.getElementById('addModal').style.display='block'" class="btn btn-primary">
            ➕ إضافة دواء جديد للمخزون
        </button>
    </div>

    <!-- جدول المخزون -->
    <div class="card">
        <h3 style="margin-bottom: 1rem; color: var(--text-main);">قائمة أدوية الصيدلية</h3>
        <div class="table-responsive">
            <table>
                <thead>
                    <tr>
                        <th>اسم الدواء التجاري</th>
                        <th>الاسم العلمي</th>
                        <th>الشكل والجرعة</th>
                        <th>الكمية المتوفرة</th>
                        <th>السعر (ريال)</th>
                        <th>حالة التوفر</th>
                        <th>الإجراءات والتحديث</th>
                    </tr>
                </thead>
                <tbody>
                    @forelse($stock as $item)
                        <tr>
                            <td>
                                <strong>{{ $item->medicine->trade_name }}</strong>
                                @if($item->medicine->is_prescription_required)
                                    <span style="font-size: 0.75rem; color: var(--status-danger);">[وصفة طبية]</span>
                                @endif
                            </td>
                            <td style="color: var(--text-muted); font-size: 0.9rem;">{{ $item->medicine->scientific_name }}</td>
                            <td>{{ $item->medicine->dosage_form }} ({{ $item->medicine->strength }})</td>
                            
                            <!-- نموذج تعديل فوري -->
                            <form action="{{ route('pharmacy.inventory.update', $item->id) }}" method="POST">
                                @csrf
                                <td>
                                    <input type="number" name="available_quantity" value="{{ $item->available_quantity }}" min="0" class="form-control" style="width: 90px; text-align: center;">
                                </td>
                                <td>
                                    <input type="number" step="0.5" name="price" value="{{ $item->price }}" min="0" class="form-control" style="width: 110px; text-align: center;">
                                </td>
                                <td>
                                    <select name="status" class="form-control" style="width: 130px;">
                                        <option value="available" {{ $item->status === 'available' ? 'selected' : '' }}>متوفر</option>
                                        <option value="low_stock" {{ $item->status === 'low_stock' ? 'selected' : '' }}>وشيك النفاذ</option>
                                        <option value="out_of_stock" {{ $item->status === 'out_of_stock' ? 'selected' : '' }}>غير متوفر</option>
                                    </select>
                                </td>
                                <td>
                                    <button type="submit" class="btn btn-outline" style="padding: 6px 12px; font-size: 0.85rem;">حفظ التعديل</button>
                                </td>
                            </form>
                        </tr>
                    @empty
                        <tr>
                            <td colspan="7" style="text-align: center; padding: 2rem; color: var(--text-muted);">
                                لا توجد أدوية مسجلة في المخزون حالياً. اضغط على "إضافة دواء جديد" لإضافة أدوية من الفهرس العام.
                            </td>
                        </tr>
                    @endforelse
                </tbody>
            </table>
        </div>

        <div style="margin-top: 1.5rem;">
            {{ $stock->links() }}
        </div>
    </div>

    <!-- نافذة منبثقة بسيطة (Modal) لإضافة دواء جديد -->
    <div id="addModal" style="display: none; position: fixed; top: 0; left: 0; right: 0; bottom: 0; background: rgba(0,0,0,0.5); z-index: 999; justify-content: center; align-items: center;">
        <div class="card" style="max-width: 500px; margin: 5rem auto; position: relative;">
            <h3 style="margin-bottom: 1rem; color: var(--primary-dark);">إضافة دواء إلى مخزون الصيدلية</h3>
            <form action="{{ route('pharmacy.inventory.add') }}" method="POST">
                @csrf
                <div style="margin-bottom: 1rem;">
                    <label style="display: block; margin-bottom: 6px; font-weight: 600;">اختر الدواء من الفهرس العام:</label>
                    <select name="medicine_id" required class="form-control">
                        <option value="">-- اختر صنفاً --</option>
                        @foreach($availableCatalog as $med)
                            <option value="{{ $med->id }}">{{ $med->trade_name }} ({{ $med->scientific_name }}) - {{ $med->strength }}</option>
                        @endforeach
                    </select>
                </div>
                <div style="margin-bottom: 1rem;">
                    <label style="display: block; margin-bottom: 6px; font-weight: 600;">الكمية المتوفرة حالياً:</label>
                    <input type="number" name="available_quantity" value="10" min="1" required class="form-control">
                </div>
                <div style="margin-bottom: 1.5rem;">
                    <label style="display: block; margin-bottom: 6px; font-weight: 600;">سعر البيع (ريال):</label>
                    <input type="number" step="0.5" name="price" placeholder="مثال: 1500" required class="form-control">
                </div>
                <div style="display: flex; gap: 1rem; justify-content: flex-end;">
                    <button type="button" onclick="document.getElementById('addModal').style.display='none'" class="btn btn-outline">إلغاء</button>
                    <button type="submit" class="btn btn-primary">إضافة للمخزون</button>
                </div>
            </form>
        </div>
    </div>
@endsection
