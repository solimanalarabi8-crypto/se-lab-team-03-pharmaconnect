<!DOCTYPE html>
<html lang="ar" dir="rtl">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <meta http-equiv="Content-Security-Policy" content="upgrade-insecure-requests">
    <title>@yield('title', 'لوحة الإدارة المركزية') - PharmaConnect Admin</title>
    <!-- Google Fonts: Tajawal -->
    <link rel="preconnect" href="https://fonts.googleapis.com">
    <link rel="preconnect" href="https://fonts.gstatic.com" crossorigin>
    <link href="https://fonts.googleapis.com/css2?family=Tajawal:wght@400;500;700;800;900&display=swap" rel="stylesheet">
    <style>
        :root {
            --admin-dark: #0F172A;
            --admin-sidebar: #1E293B;
            --primary: #059669;
            --primary-dark: #065F46;
            --primary-light: #10B981;
            --mint-accent: #D1FAE5;
            --surface-white: #FFFFFF;
            --bg-light: #F8FAFC;
            --border-color: #E2E8F0;
            --text-main: #0F172A;
            --text-muted: #64748B;
            --status-danger: #DC2626;
            --status-warning: #D97706;
            --status-success: #15803D;
        }

        * {
            box-sizing: border-box;
            margin: 0;
            padding: 0;
            font-family: 'Tajawal', sans-serif;
        }

        body {
            background-color: var(--bg-light);
            color: var(--text-main);
            min-height: 100vh;
            display: flex;
            flex-direction: column;
        }

        /* Top Header */
        .admin-nav {
            background-color: var(--admin-dark);
            color: white;
            padding: 0.9rem 2rem;
            display: flex;
            justify-content: space-between;
            align-items: center;
            box-shadow: 0 4px 12px rgba(0,0,0,0.1);
        }

        .admin-brand {
            display: flex;
            align-items: center;
            gap: 12px;
            font-size: 1.3rem;
            font-weight: 900;
            color: white;
            text-decoration: none;
        }

        .admin-badge {
            background: rgba(16, 185, 129, 0.2);
            color: #34D399;
            border: 1px solid rgba(52, 211, 153, 0.3);
            font-size: 0.75rem;
            padding: 3px 8px;
            border-radius: 6px;
            font-weight: 700;
        }

        .nav-items {
            display: flex;
            gap: 1rem;
            align-items: center;
        }

        .nav-item {
            color: #94A3B8;
            text-decoration: none;
            font-weight: 600;
            font-size: 0.95rem;
            padding: 6px 12px;
            border-radius: 8px;
            transition: all 0.2s;
        }

        .nav-item:hover, .nav-item.active {
            color: white;
            background-color: rgba(255,255,255,0.08);
        }

        .btn-logout {
            background-color: #334155;
            color: #F8FAFC;
            border: none;
            padding: 6px 14px;
            border-radius: 8px;
            font-weight: 700;
            cursor: pointer;
            transition: all 0.2s;
        }

        .btn-logout:hover {
            background-color: #EF4444;
            color: white;
        }

        /* Layout Container */
        .admin-container {
            max-width: 1300px;
            margin: 2rem auto;
            padding: 0 1.5rem;
            width: 100%;
            flex: 1;
        }

        /* Stats Grid */
        .stats-grid {
            display: grid;
            grid-template-columns: repeat(auto-fit, minmax(220px, 1fr));
            gap: 1.25rem;
            margin-bottom: 2rem;
        }

        .stat-card {
            background: white;
            padding: 1.5rem;
            border-radius: 16px;
            border: 1px solid var(--border-color);
            box-shadow: 0 1px 3px rgba(0,0,0,0.02);
            display: flex;
            flex-direction: column;
            justify-content: space-between;
        }

        .stat-title {
            color: var(--text-muted);
            font-size: 0.85rem;
            font-weight: 700;
            text-transform: uppercase;
        }

        .stat-value {
            font-size: 2rem;
            font-weight: 900;
            color: var(--text-main);
            margin: 0.5rem 0;
        }

        .stat-desc {
            font-size: 0.8rem;
            color: var(--primary);
            font-weight: 600;
        }

        /* Tables & Cards */
        .panel-card {
            background: white;
            border-radius: 16px;
            border: 1px solid var(--border-color);
            padding: 1.5rem;
            box-shadow: 0 1px 3px rgba(0,0,0,0.02);
            margin-bottom: 2rem;
        }

        .panel-header {
            display: flex;
            justify-content: space-between;
            align-items: center;
            margin-bottom: 1.25rem;
            padding-bottom: 0.75rem;
            border-bottom: 1px solid var(--border-color);
        }

        .panel-title {
            font-size: 1.15rem;
            font-weight: 800;
            color: var(--text-main);
        }

        table {
            width: 100%;
            border-collapse: collapse;
            text-align: right;
        }

        th {
            background-color: var(--bg-light);
            color: var(--text-muted);
            font-size: 0.85rem;
            font-weight: 700;
            padding: 0.75rem 1rem;
            border-bottom: 1px solid var(--border-color);
        }

        td {
            padding: 1rem;
            border-bottom: 1px solid var(--border-color);
            font-size: 0.95rem;
            vertical-align: middle;
        }

        tr:hover td {
            background-color: #F8FAFC;
        }

        /* Badges */
        .badge {
            display: inline-block;
            padding: 4px 10px;
            border-radius: 20px;
            font-size: 0.75rem;
            font-weight: 700;
        }

        .badge-success { background: #DCFCE7; color: #15803D; }
        .badge-danger { background: #FEE2E2; color: #DC2626; }
        .badge-warning { background: #FEF3C7; color: #D97706; }
        .badge-info { background: #E0F2FE; color: #0369A1; }

        /* Buttons */
        .btn {
            display: inline-flex;
            align-items: center;
            gap: 6px;
            padding: 6px 12px;
            border-radius: 8px;
            font-weight: 700;
            font-size: 0.85rem;
            cursor: pointer;
            text-decoration: none;
            border: none;
            transition: all 0.2s;
        }

        .btn-primary { background: var(--primary); color: white; }
        .btn-primary:hover { background: var(--primary-dark); }
        .btn-outline { background: white; border: 1px solid var(--border-color); color: var(--text-main); }
        .btn-outline:hover { background: var(--bg-light); }
        .btn-danger-outline { background: #FEF2F2; border: 1px solid #FECACA; color: #DC2626; }
        .btn-danger-outline:hover { background: #DC2626; color: white; }

        /* Alerts */
        .alert {
            padding: 1rem 1.25rem;
            border-radius: 12px;
            margin-bottom: 1.5rem;
            font-weight: 600;
            display: flex;
            align-items: center;
            gap: 10px;
        }

        .alert-success { background: #ECFDF5; border: 1px solid #A7F3D0; color: #065F46; }
        .alert-error { background: #FEF2F2; border: 1px solid #FECACA; color: #991B1B; }

        footer {
            text-align: center;
            padding: 1.5rem;
            color: var(--text-muted);
            font-size: 0.85rem;
            border-top: 1px solid var(--border-color);
            margin-top: auto;
            background: white;
        }
    </style>
</head>
<body>
    <nav class="admin-nav">
        <div style="display: flex; align-items: center; gap: 24px;">
            <a href="{{ route('admin.dashboard') }}" class="admin-brand">
                <span>🏥 PharmaConnect</span>
                <span class="admin-badge">الإدارة المركزية</span>
            </a>
            <div class="nav-items">
                <a href="{{ route('admin.dashboard') }}" class="nav-item {{ request()->routeIs('admin.dashboard') ? 'active' : '' }}">لوحة التحكم</a>
                <a href="{{ route('admin.pharmacies') }}" class="nav-item {{ request()->routeIs('admin.pharmacies*') ? 'active' : '' }}">إدارة الصيدليات</a>
                <a href="{{ route('admin.patients') }}" class="nav-item {{ request()->routeIs('admin.patients*') ? 'active' : '' }}">المرضى وتطبيق العميل</a>
                <a href="{{ route('admin.medicines') }}" class="nav-item {{ request()->routeIs('admin.medicines*') ? 'active' : '' }}">الفهرس العام للأدوية</a>
            </div>
        </div>
        <div style="display: flex; align-items: center; gap: 16px;">
            <span style="font-size: 0.9rem; color: #CBD5E1;">مرحباً، <strong>{{ auth()->user()->name }}</strong></span>
            <form action="{{ route('logout') }}" method="POST" style="margin: 0;">
                @csrf
                <button type="submit" class="btn-logout">تسجيل الخروج</button>
            </form>
        </div>
    </nav>

    <div class="admin-container">
        @if(session('success'))
            <div class="alert alert-success">
                <span>✓</span>
                <div>{{ session('success') }}</div>
            </div>
        @endif

        @if($errors->any())
            <div class="alert alert-error">
                <span>⚠</span>
                <div>{{ $errors->first() }}</div>
            </div>
        @endif

        @yield('content')
    </div>

    <footer>
        <p>نظام PharmaConnect المركزي لإدارة الصيدليات وتتبع وفرة الأدوية &copy; {{ date('Y') }} - لوحة التحكم والمراقبة المركزية</p>
    </footer>
</body>
</html>
