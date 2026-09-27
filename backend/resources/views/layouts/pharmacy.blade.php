<!DOCTYPE html>
<html lang="ar" dir="rtl">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <meta http-equiv="Content-Security-Policy" content="upgrade-insecure-requests">
    <title>@yield('title', 'بوابة إدارة الصيدلية') - PharmaConnect</title>
    <!-- Google Fonts: Tajawal -->
    <link rel="preconnect" href="https://fonts.googleapis.com">
    <link rel="preconnect" href="https://fonts.gstatic.com" crossorigin>
    <link href="https://fonts.googleapis.com/css2?family=Tajawal:wght@400;500;700;800&display=swap" rel="stylesheet">
    <style>
        :root {
            --primary: #059669;
            --primary-dark: #065F46;
            --primary-light: #10B981;
            --mint-bg: #ECFDF5;
            --mint-accent: #D1FAE5;
            --surface-white: #FFFFFF;
            --bg-light: #F8FAFC;
            --border-color: #E2E8F0;
            --text-main: #0F172A;
            --text-muted: #64748B;
            --status-danger: #DC2626;
            --status-warning: #D97706;
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

        /* Navbar */
        .navbar {
            background-color: var(--surface-white);
            border-bottom: 1px solid var(--border-color);
            padding: 1rem 2rem;
            display: flex;
            justify-content: space-between;
            align-items: center;
            box-shadow: 0 1px 3px rgba(0,0,0,0.03);
        }

        .brand {
            display: flex;
            align-items: center;
            gap: 12px;
            font-size: 1.3rem;
            font-weight: 800;
            color: var(--primary-dark);
            text-decoration: none;
        }

        .brand-icon {
            background: var(--mint-accent);
            color: var(--primary);
            padding: 8px 12px;
            border-radius: 10px;
            font-size: 1.2rem;
        }

        .nav-links {
            display: flex;
            gap: 1.5rem;
            align-items: center;
        }

        .nav-link {
            color: var(--text-muted);
            text-decoration: none;
            font-weight: 600;
            padding: 6px 12px;
            border-radius: 8px;
            transition: all 0.2s;
        }

        .nav-link:hover, .nav-link.active {
            color: var(--primary);
            background-color: var(--mint-bg);
        }

        /* Container & Layout */
        .container {
            max-width: 1200px;
            margin: 2rem auto;
            padding: 0 1.5rem;
            width: 100%;
            flex: 1;
        }

        /* Cards */
        .card {
            background: var(--surface-white);
            border: 1px solid var(--border-color);
            border-radius: 16px;
            padding: 1.5rem;
            box-shadow: 0 2px 4px rgba(0,0,0,0.02);
            margin-bottom: 1.5rem;
        }

        /* Buttons */
        .btn {
            display: inline-flex;
            align-items: center;
            gap: 8px;
            padding: 0.6rem 1.2rem;
            border-radius: 10px;
            font-weight: 700;
            font-size: 0.95rem;
            cursor: pointer;
            border: none;
            text-decoration: none;
            transition: all 0.2s;
        }

        .btn-primary {
            background-color: var(--primary);
            color: white;
        }

        .btn-primary:hover {
            background-color: var(--primary-dark);
        }

        .btn-outline {
            background: transparent;
            border: 1px solid var(--border-color);
            color: var(--text-main);
        }

        .btn-outline:hover {
            background: var(--bg-light);
        }

        .btn-danger {
            background-color: var(--status-danger);
            color: white;
        }

        /* Badges */
        .badge {
            display: inline-block;
            padding: 4px 10px;
            border-radius: 20px;
            font-size: 0.8rem;
            font-weight: 700;
        }

        .badge-success {
            background-color: var(--mint-accent);
            color: var(--primary-dark);
        }

        .badge-warning {
            background-color: #FEF3C7;
            color: var(--status-warning);
        }

        .badge-danger {
            background-color: #FEE2E2;
            color: var(--status-danger);
        }

        /* Alerts */
        .alert {
            padding: 1rem;
            border-radius: 12px;
            margin-bottom: 1.5rem;
            font-weight: 600;
        }

        .alert-success {
            background-color: var(--mint-bg);
            color: var(--primary-dark);
            border: 1px solid var(--mint-accent);
        }

        .alert-danger {
            background-color: #FEF2F2;
            color: var(--status-danger);
            border: 1px solid #FECACA;
        }

        /* Forms & Inputs */
        .form-control {
            width: 100%;
            padding: 0.75rem 1rem;
            border: 1px solid var(--border-color);
            border-radius: 10px;
            font-size: 0.95rem;
            outline: none;
            transition: border 0.2s;
        }

        .form-control:focus {
            border-color: var(--primary);
            box-shadow: 0 0 0 3px rgba(5, 150, 105, 0.1);
        }

        /* Tables */
        .table-responsive {
            overflow-x: auto;
        }

        table {
            width: 100%;
            border-collapse: collapse;
            text-align: right;
        }

        th {
            background-color: var(--bg-light);
            color: var(--text-muted);
            padding: 0.9rem 1rem;
            font-weight: 700;
            border-bottom: 1px solid var(--border-color);
        }

        td {
            padding: 1rem;
            border-bottom: 1px solid var(--border-color);
            vertical-align: middle;
        }

        tr:hover td {
            background-color: #FAFAFA;
        }

        /* Footer */
        footer {
            background: var(--surface-white);
            border-top: 1px solid var(--border-color);
            padding: 1.5rem;
            text-align: center;
            color: var(--text-muted);
            font-size: 0.9rem;
        }
    </style>
    @yield('styles')
</head>
<body>
    <nav class="navbar">
        <a href="{{ route('pharmacy.inventory') }}" class="brand">
            <span class="brand-icon">💊</span>
            <span>PharmaConnect | بوابة الصيدلية</span>
        </a>
        <div class="nav-links">
            <a href="{{ route('pharmacy.inventory') }}" class="nav-link {{ request()->routeIs('pharmacy.inventory') ? 'active' : '' }}">📦 إدارة المخزون</a>
            <a href="{{ route('pharmacy.reservations') }}" class="nav-link {{ request()->routeIs('pharmacy.reservations') ? 'active' : '' }}">⏱️ الحجوزات الواردة</a>
            @auth
                @if(Auth::user()->isAdmin())
                    <a href="{{ route('admin.dashboard') }}" class="nav-link" style="color: #4F46E5; font-weight: 700;">🛡️ لوحة المشرف العام</a>
                @endif
                <span style="color: var(--text-muted); font-size: 0.9rem;">
                    {{ Auth::user()->pharmacy ? 'صيدلية: ' : 'المشرف: ' }}<strong>{{ Auth::user()->pharmacy?->name ?? Auth::user()->name }}</strong>
                </span>
                <form action="{{ route('logout') }}" method="POST" style="display: inline;">
                    @csrf
                    <button type="submit" class="btn btn-outline" style="padding: 4px 10px; font-size: 0.85rem;">خروج</button>
                </form>
            @endauth
        </div>
    </nav>

    <main class="container">
        @if(session('success'))
            <div class="alert alert-success">
                ✅ {{ session('success') }}
            </div>
        @endif

        @if($errors->any())
            <div class="alert alert-danger">
                ⚠️ {{ $errors->first() }}
            </div>
        @endif

        @yield('content')
    </main>

    <footer>
        <p>نظام فارما-كونكت (PharmaConnect) - منصة تتبع وفرة الأدوية وإدارة المخزون متعدد الصيدليات &copy; {{ date('Y') }}</p>
    </footer>

    @yield('scripts')
</body>
</html>
