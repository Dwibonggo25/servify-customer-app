-- Initial categories used by the customer application.

insert into public.service_categories (
  name,
  slug,
  icon_key,
  color_value,
  sort_order,
  is_active
)
values
  (
    'Kebersihan',
    'kebersihan',
    'cleaning_services',
    4283385573,
    1,
    true
  ),
  (
    'Perbaikan',
    'perbaikan',
    'handyman',
    4294538006,
    2,
    true
  ),
  (
    'Laundry',
    'laundry',
    'local_laundry_service',
    4279150057,
    3,
    true
  ),
  (
    'Perawatan',
    'perawatan',
    'home_repair_service',
    4279548070,
    4,
    true
  )
on conflict (slug) do update
set
  name = excluded.name,
  icon_key = excluded.icon_key,
  color_value = excluded.color_value,
  sort_order = excluded.sort_order,
  is_active = excluded.is_active,
  updated_at = now();

