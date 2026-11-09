# Servify Customer Flow

Flutter customer application starter built from `base_flutter_project`. The
current scope contains splash, onboarding, login, registration, and home.

## Stack

- Flutter + Material 3
- Flutter BLoC
- Supabase Authentication
- GoRouter with onboarding and authentication guards
- Hive CE for local onboarding state
- Feature-first structure and reusable design-system widgets

## Included flow

```text
Splash
  ├─ first launch ─> Onboarding ─> Login/Register ─> Home
  └─ returning authenticated customer ─────────────> Home
```

The registration payload stores `full_name` and the `customer` role in
Supabase user metadata.

## Supabase setup

1. Create a Supabase project.
2. Open **Project Settings > API**.
3. Copy `config/example.json` to `config/dev.json`.
4. Add your project URL and publishable/anon key:

   ```json
   {
     "SUPABASE_URL": "https://YOUR_PROJECT.supabase.co",
     "SUPABASE_ANON_KEY": "YOUR_SUPABASE_PUBLISHABLE_OR_ANON_KEY"
   }
   ```

5. In Supabase Authentication, enable Email authentication. Decide whether
   email confirmation is required for your development environment.
6. Jalankan semua file pada `supabase/migrations` secara berurutan melalui
   Supabase SQL Editor. Migration `20261104_004` menambahkan workflow staff,
   sedangkan `20261108_006` menambahkan CRUD layanan khusus admin beserta RLS
   dan RPC transaksionalnya.

Untuk menjadikan akun yang sudah terdaftar sebagai staff, jalankan query ini
sebagai pemilik project (ganti emailnya):

```sql
update public.profiles
set role = 'staff'
where id = (
  select id from auth.users where email = 'staff@example.com'
);
```

Setelah login ulang, aplikasi membaca role dari `profiles` dan mengarahkan
akun ke staff dashboard. Registrasi dari aplikasi tetap selalu membuat akun
customer sehingga pengguna tidak dapat menaikkan role-nya sendiri.

Untuk menjadikan akun sebagai admin, gunakan UUID dari `auth.users` melalui
SQL Editor. Role tidak boleh diubah dari aplikasi client:

```sql
update public.profiles
set role = 'admin'
where id = (
  select id from auth.users where email = 'admin@example.com'
);
```

Admin akan diarahkan ke halaman pengelolaan layanan dan dapat menambah,
mengubah, mengaktifkan/nonaktifkan, serta menghapus layanan. Layanan yang
sudah memiliki riwayat pesanan akan diarsipkan, bukan dihapus permanen.

`config/dev.json` is ignored by Git. Never commit a service-role key to a
Flutter application. A publishable/anon key is the correct client key.

## Run

```bash
flutter pub get
flutter run \
  -t lib/app/launcher/main_dev.dart \
  --flavor dev \
  --dart-define-from-file=config/dev.json
```

The production launcher is available at
`lib/app/launcher/main_prod.dart`. Use a separate production config file when
preparing a store build.

## Quality checks

```bash
flutter analyze
flutter test
```

## Main structure

```text
lib/
├── app/
│   ├── launcher/
│   ├── router/
│   ├── session/
│   ├── app.dart
│   └── bootstrap.dart
├── features/
│   ├── auth/
│   ├── home/
│   ├── onboarding/
│   └── splash/
└── libraries/
    ├── core/
    └── design_system/
```

## Next customer features

- Supabase profile table and Row Level Security
- Service catalogue
- Service detail and ordering
- Realtime order tracking
- Customer order history and profile
