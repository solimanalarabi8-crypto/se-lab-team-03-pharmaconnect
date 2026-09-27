# 📌 Claude Instructions & Engineering Guidelines for PharmaConnect

## 1. Project Context
- **Project Name:** PharmaConnect (فارما-كونكت)
- **Nature:** Distributed multi-pharmacy medicine inventory tracking & reservation system.
- **Academic Context:** Software Engineering Lab (2026/2027), supervised by Eng. Saher Al-Hamdani.
- **Team Members & Responsibilities:**
  1. **Yaaqob Almahajeri** (`jacobkhaled01-spec`): Team Coordinator & Backend Lead (Laravel 11, REST APIs, Database migrations).
  2. **Sulaiman Al-Arabi** (`solimanalarabi8-crypto`): Repository Maintainer & Web Portal Lead (Blade views, Admin/Pharmacy portals).
  3. **Malik Jubran** (`malik222020malik-cloud`): Requirements Owner & Mobile Client Lead (Flutter 3.x, SQLite offline cache, Geo-search).

## 2. Core Architecture & Tech Stack
- **Backend:** Laravel 11 (PHP 8.2+), Eloquent ORM, Sanctum Auth, SQLite/MySQL.
- **Frontend:** Flutter 3.41+ (Dart 3.11+), multiplatform (Web, Android, Windows), sqflite, provider.
- **CI/CD:** GitHub Actions workflows (`.github/workflows/backend-ci.yml`, `frontend-ci.yml`).
- **Documentation:** Mini-SRS (`docs/SRS.md`), AI Transparency Log (`AI_Log.md`), Project Board (`PharmaConnect Sprint Board`).

## 3. Strict Engineering Governance
1. **Zero Direct Main Pushes:** All modifications must follow the strict lifecycle:
   $$\text{Feature Branch} \longrightarrow \text{Commit \& Push} \longrightarrow \text{Pull Request} \longrightarrow \text{Peer Review} \longrightarrow \text{Merge}$$
2. **Branch Naming Standard:** `type/issue-number-short-description` (e.g., `feature/issue-3-medicine-search-api`).
3. **Commit Messages:** Follow Conventional Commits format (`feat:`, `fix:`, `docs:`, `test:`, `chore:`).
4. **Peer Code Review:** PR author cannot approve their own PR; another team member must perform review, comment constructively, and approve before merging.
5. **Transparency & AI Logging:** All non-trivial AI assistance must be logged in `AI_Log.md` with dates, prompts, suggestions, accepted/rejected reasons, and human review verification.

## 4. Run & Development Commands
- **Backend:**
  ```powershell
  cd backend
  composer install
  php artisan migrate:fresh --seed
  php artisan serve
  ```
- **Frontend:**
  ```powershell
  cd frontend
  flutter pub get
  flutter run -d chrome
  ```
