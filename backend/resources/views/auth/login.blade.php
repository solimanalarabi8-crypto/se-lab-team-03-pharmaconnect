<!DOCTYPE html>
<html lang="ar" dir="rtl">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <meta http-equiv="Content-Security-Policy" content="upgrade-insecure-requests">
    <title>تسجيل دخول الصيدلية - PharmaConnect</title>
    <!-- Google Fonts: Tajawal -->
    <link rel="preconnect" href="https://fonts.googleapis.com">
    <link rel="preconnect" href="https://fonts.gstatic.com" crossorigin>
    <link href="https://fonts.googleapis.com/css2?family=Tajawal:wght@400;600;700;800&display=swap" rel="stylesheet">
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
        }

        * {
            box-sizing: border-box;
            margin: 0;
            padding: 0;
            font-family: 'Tajawal', sans-serif;
        }

        body {
            background-color: var(--bg-light);
            display: flex;
            justify-content: center;
            align-items: center;
            min-height: 100vh;
            padding: 1rem;
        }

        .login-card {
            background: var(--surface-white);
            border: 1px solid var(--border-color);
            border-radius: 20px;
            padding: 2.5rem;
            width: 100%;
            max-width: 440px;
            box-shadow: 0 10px 25px -5px rgba(0, 0, 0, 0.05);
        }

        .brand-header {
            text-align: center;
            margin-bottom: 2rem;
        }

        .logo-box {
            display: inline-flex;
            background: var(--mint-bg);
            color: var(--primary);
            font-size: 2rem;
            padding: 1rem;
            border-radius: 16px;
            margin-bottom: 1rem;
            border: 1px solid var(--mint-accent);
        }

        .brand-title {
            font-size: 1.5rem;
            font-weight: 800;
            color: var(--primary-dark);
        }

        .brand-desc {
            color: var(--text-muted);
            font-size: 0.9rem;
            margin-top: 4px;
        }

        .form-group {
            margin-bottom: 1.25rem;
        }

        label {
            display: block;
            margin-bottom: 6px;
            font-weight: 600;
            color: var(--text-main);
            font-size: 0.95rem;
        }

        input[type="email"], input[type="password"] {
            width: 100%;
            padding: 0.8rem 1rem;
            border: 1px solid var(--border-color);
            border-radius: 12px;
            font-size: 0.95rem;
            outline: none;
            transition: all 0.2s;
        }

        input[type="email"]:focus, input[type="password"]:focus {
            border-color: var(--primary);
            box-shadow: 0 0 0 3px rgba(5, 150, 105, 0.15);
        }

        .btn-submit {
            width: 100%;
            background: var(--primary);
            color: white;
            padding: 0.9rem;
            border-radius: 12px;
            font-size: 1rem;
            font-weight: 700;
            border: none;
            cursor: pointer;
            transition: background 0.2s;
            margin-top: 0.5rem;
        }

        .btn-submit:hover {
            background: var(--primary-dark);
        }

        .demo-box {
            margin-top: 1.5rem;
            background: var(--mint-bg);
            border: 1px solid var(--mint-accent);
            padding: 1rem;
            border-radius: 12px;
            font-size: 0.85rem;
            color: var(--primary-dark);
        }

        .alert-danger {
            background: #FEF2F2;
            color: var(--status-danger);
            padding: 0.8rem;
            border-radius: 10px;
            margin-bottom: 1.25rem;
            font-size: 0.9rem;
            font-weight: 600;
        }
    </style>
</head>
<body>
    <div class="login-card">
        <div class="brand-header">
            <div class="logo-box">💊</div>
            <h1 class="brand-title">PharmaConnect</h1>
            <p class="brand-desc">بوابة إدارة المخزون للصيدليات المعتمدة</p>
        </div>

        @if($errors->any())
            <div class="alert-danger">
                ⚠️ {{ $errors->first() }}
            </div>
        @endif

        <form action="/login" method="POST">
            @csrf
            <div class="form-group">
                <label for="email">البريد الإلكتروني للصيدلية:</label>
                <input type="email" id="email" name="email" value="{{ old('email', 'shifa@pharmaconnect.ye') }}" required autofocus placeholder="example@pharmacy.com">
            </div>

            <div class="form-group">
                <label for="password">كلمة المرور:</label>
                <input type="password" id="password" name="password" required placeholder="••••••••">
            </div>

            <button type="submit" class="btn-submit">تسجيل الدخول إلى البوابة</button>
        </form>

        <div class="demo-box">
            <strong>🔑 حسابات تجريبية مهيأة مسبقاً:</strong>
            <div style="margin-top: 4px;">• <strong>مشرف النظام العام:</strong> <code>admin@pharmaconnect.ye</code></div>
            <div>• <strong>صيدلية الشفاء:</strong> <code>shifa@pharmaconnect.ye</code></div>
            <div>• <strong>صيدلية الأمل:</strong> <code>amal@pharmaconnect.ye</code></div>
            <div>• <strong>كلمة المرور للجميع:</strong> <code>password123</code></div>
        </div>
    </div>
</body>
</html>
