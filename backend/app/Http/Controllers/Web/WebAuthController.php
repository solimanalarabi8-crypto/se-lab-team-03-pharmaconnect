<?php

namespace App\Http\Controllers\Web;

use App\Http\Controllers\Controller;
use Illuminate\Http\RedirectResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Auth;
use Illuminate\View\View;

class WebAuthController extends Controller
{
    /**
     * عرض شاشة تسجيل دخول الصيدلية
     */
    public function showLogin(): View
    {
        return view('auth.login');
    }

    /**
     * معالجة تسجيل الدخول لبوابة الويب
     */
    public function login(Request $request): RedirectResponse
    {
        $credentials = $request->validate([
            'email' => 'required|email',
            'password' => 'required',
        ]);

        if (Auth::attempt($credentials, $request->boolean('remember'))) {
            $request->session()->regenerate();

            $user = Auth::user();
            if ($user->isAdmin()) {
                return redirect()->intended(route('admin.dashboard'))
                    ->with('success', 'مرحباً بك في لوحة الإدارة المركزية لنظام PharmaConnect.');
            }

            if ($user->isPharmacy()) {
                return redirect()->intended(route('pharmacy.inventory'))
                    ->with('success', 'مرحباً بك مجدداً في بوابة إدارة مخزون الصيدلية.');
            }

            Auth::logout();

            return back()->withErrors(['email' => 'عذراً، هذا الحساب غير مصرح له بالدخول للبوابة الإدارية.']);
        }

        return back()->withErrors(['email' => 'البريد الإلكتروني أو كلمة المرور غير صحيحة.'])->onlyInput('email');
    }

    /**
     * تسجيل الخروج
     */
    public function logout(Request $request): RedirectResponse
    {
        Auth::logout();
        $request->session()->invalidate();
        $request->session()->regenerateToken();

        return redirect()->route('login')->with('success', 'تم تسجيل الخروج بنجاح.');
    }
}
