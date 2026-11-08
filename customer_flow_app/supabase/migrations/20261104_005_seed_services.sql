-- Starter services for the customer catalog.

insert into public.services (
  category_id,
  name,
  slug,
  short_description,
  description,
  base_price,
  duration_minutes,
  icon_key,
  color_value,
  rating,
  review_count,
  is_active
)
select
  categories.id,
  seed.name,
  seed.slug,
  seed.short_description,
  seed.description,
  seed.base_price,
  seed.duration_minutes,
  seed.icon_key,
  seed.color_value,
  seed.rating,
  seed.review_count,
  true
from (
  values
    ('kebersihan', 'Kebersihan Rumah', 'home-cleaning',
      'Rumah bersih dan nyaman tanpa repot.',
      'Layanan kebersihan menyeluruh oleh tenaga profesional terverifikasi.',
      125000::bigint, 120, 'cleaning_services', 4283385573::bigint, 4.9, 328),
    ('perbaikan', 'Perbaikan Rumah', 'home-repair',
      'Teknisi berpengalaman datang ke lokasi.',
      'Bantuan teknisi untuk menangani berbagai kerusakan ringan di rumah.',
      150000::bigint, 90, 'handyman', 4294538006::bigint, 4.8, 214),
    ('laundry', 'Laundry', 'laundry',
      'Jemput, cuci, dan antar kembali.',
      'Laundry pakaian harian dengan proses higienis dan layanan antar jemput.',
      75000::bigint, 2880, 'local_laundry_service', 4279150057::bigint, 4.7, 176),
    ('perawatan', 'Perawatan Rutin', 'routine-care',
      'Layanan berkala agar rumah selalu terawat.',
      'Pemeriksaan dan perawatan rutin untuk menjaga fasilitas rumah.',
      200000::bigint, 120, 'home_repair_service', 4279548070::bigint, 4.9, 143),
    ('perawatan', 'Service AC', 'ac-service',
      'AC lebih dingin dan hemat listrik.',
      'Pembersihan unit AC oleh teknisi berpengalaman.',
      100000::bigint, 60, 'ac_unit', 4278359239::bigint, 4.8, 267),
    ('kebersihan', 'Pest Control', 'pest-control',
      'Perlindungan rumah dari hama.',
      'Penanganan hama rumah dengan metode aman dan terukur.',
      250000::bigint, 120, 'pest_control', 4284825613::bigint, 4.7, 98)
) as seed(
  category_slug,
  name,
  slug,
  short_description,
  description,
  base_price,
  duration_minutes,
  icon_key,
  color_value,
  rating,
  review_count
)
join public.service_categories categories
  on categories.slug = seed.category_slug
on conflict (slug) do update set
  category_id = excluded.category_id,
  name = excluded.name,
  short_description = excluded.short_description,
  description = excluded.description,
  base_price = excluded.base_price,
  duration_minutes = excluded.duration_minutes,
  icon_key = excluded.icon_key,
  color_value = excluded.color_value,
  rating = excluded.rating,
  review_count = excluded.review_count,
  is_active = true,
  updated_at = now();

delete from public.service_inclusions
where service_id in (
  select id from public.services
  where slug in (
    'home-cleaning',
    'home-repair',
    'laundry',
    'routine-care',
    'ac-service',
    'pest-control'
  )
);

insert into public.service_inclusions (service_id, label, sort_order)
select services.id, inclusion.label, inclusion.sort_order
from (
  values
    ('home-cleaning', 'Membersihkan lantai dan permukaan', 1),
    ('home-cleaning', 'Membersihkan kamar mandi', 2),
    ('home-cleaning', 'Membersihkan area dapur', 3),
    ('home-repair', 'Pemeriksaan awal oleh teknisi', 1),
    ('home-repair', 'Perbaikan ringan hingga 90 menit', 2),
    ('laundry', 'Penjemputan di lokasi customer', 1),
    ('laundry', 'Cuci, kering, setrika, dan lipat', 2),
    ('routine-care', 'Pemeriksaan fasilitas rumah', 1),
    ('routine-care', 'Laporan dan rekomendasi tindak lanjut', 2),
    ('ac-service', 'Pembersihan filter dan evaporator', 1),
    ('ac-service', 'Pemeriksaan kondisi dasar unit', 2),
    ('pest-control', 'Survei area terdampak', 1),
    ('pest-control', 'Penanganan hama dan kunjungan ulang', 2)
) as inclusion(service_slug, label, sort_order)
join public.services services on services.slug = inclusion.service_slug;
