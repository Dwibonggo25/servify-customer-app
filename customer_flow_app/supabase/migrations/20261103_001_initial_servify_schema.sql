-- Servify initial database schema.
-- Run this migration in Supabase SQL Editor as the project owner.

create extension if not exists pgcrypto;

-- ---------------------------------------------------------------------------
-- Shared functions
-- ---------------------------------------------------------------------------

create or replace function public.set_updated_at()
returns trigger
language plpgsql
set search_path = ''
as $$
begin
  new.updated_at = now();
  return new;
end;
$$;

create or replace function public.generate_booking_number()
returns text
language sql
volatile
set search_path = ''
as $$
  select
    'SRV-' ||
    to_char(now(), 'YYYYMMDD') ||
    '-' ||
    upper(substr(replace(gen_random_uuid()::text, '-', ''), 1, 8));
$$;

-- ---------------------------------------------------------------------------
-- Tables
-- ---------------------------------------------------------------------------

create table if not exists public.profiles (
  id uuid primary key references auth.users(id) on delete cascade,
  full_name text not null default '',
  phone text,
  avatar_url text,
  role text not null default 'customer'
    check (role in ('customer', 'staff', 'admin')),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.service_categories (
  id uuid primary key default gen_random_uuid(),
  name text not null,
  slug text not null unique,
  icon_key text not null,
  color_value bigint not null,
  sort_order integer not null default 0,
  is_active boolean not null default true,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.services (
  id uuid primary key default gen_random_uuid(),
  category_id uuid not null
    references public.service_categories(id) on delete restrict,
  name text not null,
  slug text not null unique,
  short_description text not null,
  description text not null,
  base_price bigint not null check (base_price >= 0),
  duration_minutes integer not null check (duration_minutes > 0),
  icon_key text not null,
  color_value bigint not null,
  rating numeric(2, 1) not null default 0
    check (rating >= 0 and rating <= 5),
  review_count integer not null default 0 check (review_count >= 0),
  is_active boolean not null default true,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.service_inclusions (
  id uuid primary key default gen_random_uuid(),
  service_id uuid not null references public.services(id) on delete cascade,
  label text not null,
  sort_order integer not null default 0,
  created_at timestamptz not null default now()
);

create table if not exists public.customer_addresses (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null default auth.uid()
    references auth.users(id) on delete cascade,
  label text not null default 'Rumah',
  recipient_name text not null,
  phone text not null,
  address_line text not null,
  notes text,
  latitude double precision,
  longitude double precision,
  is_default boolean not null default false,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.bookings (
  id uuid primary key default gen_random_uuid(),
  booking_number text not null unique default public.generate_booking_number(),
  customer_id uuid not null default auth.uid()
    references auth.users(id) on delete cascade,
  service_id uuid not null references public.services(id) on delete restrict,
  staff_id uuid references auth.users(id) on delete set null,
  address_id uuid references public.customer_addresses(id) on delete set null,
  service_name text not null,
  service_price bigint not null check (service_price >= 0),
  customer_name text not null,
  customer_phone text not null,
  service_address text not null,
  scheduled_at timestamptz not null,
  payment_method text not null
    check (payment_method in ('cash', 'bank_transfer', 'ewallet')),
  note text,
  status text not null default 'pending'
    check (
      status in (
        'pending',
        'confirmed',
        'assigned',
        'on_the_way',
        'in_progress',
        'completed',
        'cancelled'
      )
    ),
  total_amount bigint not null check (total_amount >= 0),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.booking_status_history (
  id uuid primary key default gen_random_uuid(),
  booking_id uuid not null references public.bookings(id) on delete cascade,
  status text not null
    check (
      status in (
        'pending',
        'confirmed',
        'assigned',
        'on_the_way',
        'in_progress',
        'completed',
        'cancelled'
      )
    ),
  note text,
  changed_by uuid references auth.users(id) on delete set null,
  created_at timestamptz not null default now()
);

create table if not exists public.favorites (
  user_id uuid not null default auth.uid()
    references auth.users(id) on delete cascade,
  service_id uuid not null references public.services(id) on delete cascade,
  created_at timestamptz not null default now(),
  primary key (user_id, service_id)
);

create table if not exists public.booking_qr_codes (
  id uuid primary key default gen_random_uuid(),
  booking_id uuid not null unique
    references public.bookings(id) on delete cascade,
  token text not null unique,
  expires_at timestamptz not null,
  used_at timestamptz,
  is_active boolean not null default true,
  created_at timestamptz not null default now()
);

create table if not exists public.qr_scan_history (
  id uuid primary key default gen_random_uuid(),
  qr_code_id uuid references public.booking_qr_codes(id) on delete set null,
  booking_id uuid not null references public.bookings(id) on delete cascade,
  scanned_by uuid references auth.users(id) on delete set null,
  result text not null
    check (result in ('success', 'expired', 'already_used', 'invalid')),
  scanned_at timestamptz not null default now(),
  metadata jsonb not null default '{}'::jsonb
);

-- ---------------------------------------------------------------------------
-- Indexes
-- ---------------------------------------------------------------------------

create index if not exists services_category_id_idx
  on public.services(category_id);
create index if not exists services_active_sort_idx
  on public.services(is_active, created_at desc);
create index if not exists service_inclusions_service_id_idx
  on public.service_inclusions(service_id, sort_order);
create index if not exists customer_addresses_user_id_idx
  on public.customer_addresses(user_id);
create index if not exists bookings_customer_id_created_at_idx
  on public.bookings(customer_id, created_at desc);
create index if not exists bookings_staff_id_status_idx
  on public.bookings(staff_id, status);
create index if not exists bookings_scheduled_at_idx
  on public.bookings(scheduled_at);
create index if not exists booking_status_history_booking_id_idx
  on public.booking_status_history(booking_id, created_at desc);
create index if not exists qr_scan_history_booking_id_idx
  on public.qr_scan_history(booking_id, scanned_at desc);

-- ---------------------------------------------------------------------------
-- Automatic profile creation
-- ---------------------------------------------------------------------------

create or replace function public.handle_new_user()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
begin
  insert into public.profiles (id, full_name, phone)
  values (
    new.id,
    coalesce(
      nullif(new.raw_user_meta_data ->> 'full_name', ''),
      split_part(coalesce(new.email, ''), '@', 1),
      'Customer'
    ),
    nullif(new.raw_user_meta_data ->> 'phone', '')
  )
  on conflict (id) do nothing;

  return new;
end;
$$;

drop trigger if exists on_auth_user_created on auth.users;
create trigger on_auth_user_created
  after insert on auth.users
  for each row execute function public.handle_new_user();

-- ---------------------------------------------------------------------------
-- Booking snapshot and status history
-- ---------------------------------------------------------------------------

create or replace function public.prepare_new_booking()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
declare
  selected_service public.services%rowtype;
begin
  select *
  into selected_service
  from public.services
  where id = new.service_id and is_active = true;

  if not found then
    raise exception 'Selected service is unavailable';
  end if;

  if auth.uid() is not null then
    new.customer_id = auth.uid();
    new.status = 'pending';
    new.staff_id = null;
  end if;

  new.service_name = selected_service.name;
  new.service_price = selected_service.base_price;
  new.total_amount = selected_service.base_price;

  return new;
end;
$$;

drop trigger if exists prepare_booking_before_insert on public.bookings;
create trigger prepare_booking_before_insert
  before insert on public.bookings
  for each row execute function public.prepare_new_booking();

create or replace function public.record_booking_status()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
begin
  if tg_op = 'INSERT' or old.status is distinct from new.status then
    insert into public.booking_status_history (
      booking_id,
      status,
      changed_by
    ) values (
      new.id,
      new.status,
      auth.uid()
    );
  end if;

  return new;
end;
$$;

drop trigger if exists record_booking_status_after_change on public.bookings;
create trigger record_booking_status_after_change
  after insert or update of status on public.bookings
  for each row execute function public.record_booking_status();

-- ---------------------------------------------------------------------------
-- updated_at triggers
-- ---------------------------------------------------------------------------

drop trigger if exists profiles_set_updated_at on public.profiles;
create trigger profiles_set_updated_at
  before update on public.profiles
  for each row execute function public.set_updated_at();

drop trigger if exists service_categories_set_updated_at
  on public.service_categories;
create trigger service_categories_set_updated_at
  before update on public.service_categories
  for each row execute function public.set_updated_at();

drop trigger if exists services_set_updated_at on public.services;
create trigger services_set_updated_at
  before update on public.services
  for each row execute function public.set_updated_at();

drop trigger if exists customer_addresses_set_updated_at
  on public.customer_addresses;
create trigger customer_addresses_set_updated_at
  before update on public.customer_addresses
  for each row execute function public.set_updated_at();

drop trigger if exists bookings_set_updated_at on public.bookings;
create trigger bookings_set_updated_at
  before update on public.bookings
  for each row execute function public.set_updated_at();

-- ---------------------------------------------------------------------------
-- Row Level Security
-- ---------------------------------------------------------------------------

alter table public.profiles enable row level security;
alter table public.service_categories enable row level security;
alter table public.services enable row level security;
alter table public.service_inclusions enable row level security;
alter table public.customer_addresses enable row level security;
alter table public.bookings enable row level security;
alter table public.booking_status_history enable row level security;
alter table public.favorites enable row level security;
alter table public.booking_qr_codes enable row level security;
alter table public.qr_scan_history enable row level security;

drop policy if exists "Users can read own profile" on public.profiles;
create policy "Users can read own profile"
  on public.profiles for select
  to authenticated
  using (id = auth.uid());

drop policy if exists "Users can update own profile" on public.profiles;
create policy "Users can update own profile"
  on public.profiles for update
  to authenticated
  using (id = auth.uid())
  with check (id = auth.uid());

drop policy if exists "Users can create own profile" on public.profiles;
create policy "Users can create own profile"
  on public.profiles for insert
  to authenticated
  with check (
    id = auth.uid()
    and role = 'customer'
  );

drop policy if exists "Authenticated users can read active categories"
  on public.service_categories;
create policy "Authenticated users can read active categories"
  on public.service_categories for select
  to authenticated
  using (is_active = true);

drop policy if exists "Authenticated users can read active services"
  on public.services;
create policy "Authenticated users can read active services"
  on public.services for select
  to authenticated
  using (is_active = true);

drop policy if exists "Authenticated users can read service inclusions"
  on public.service_inclusions;
create policy "Authenticated users can read service inclusions"
  on public.service_inclusions for select
  to authenticated
  using (
    exists (
      select 1
      from public.services
      where services.id = service_inclusions.service_id
        and services.is_active = true
    )
  );

drop policy if exists "Users can read own addresses"
  on public.customer_addresses;
create policy "Users can read own addresses"
  on public.customer_addresses for select
  to authenticated
  using (user_id = auth.uid());

drop policy if exists "Users can create own addresses"
  on public.customer_addresses;
create policy "Users can create own addresses"
  on public.customer_addresses for insert
  to authenticated
  with check (user_id = auth.uid());

drop policy if exists "Users can update own addresses"
  on public.customer_addresses;
create policy "Users can update own addresses"
  on public.customer_addresses for update
  to authenticated
  using (user_id = auth.uid())
  with check (user_id = auth.uid());

drop policy if exists "Users can delete own addresses"
  on public.customer_addresses;
create policy "Users can delete own addresses"
  on public.customer_addresses for delete
  to authenticated
  using (user_id = auth.uid());

drop policy if exists "Customers can read own bookings" on public.bookings;
create policy "Customers can read own bookings"
  on public.bookings for select
  to authenticated
  using (customer_id = auth.uid());

drop policy if exists "Customers can create own bookings" on public.bookings;
create policy "Customers can create own bookings"
  on public.bookings for insert
  to authenticated
  with check (
    customer_id = auth.uid()
    and status = 'pending'
    and staff_id is null
    and scheduled_at >= now()
    and (
      address_id is null
      or exists (
        select 1
        from public.customer_addresses
        where customer_addresses.id = bookings.address_id
          and customer_addresses.user_id = auth.uid()
      )
    )
  );

drop policy if exists "Customers can read own booking history"
  on public.booking_status_history;
create policy "Customers can read own booking history"
  on public.booking_status_history for select
  to authenticated
  using (
    exists (
      select 1
      from public.bookings
      where bookings.id = booking_status_history.booking_id
        and bookings.customer_id = auth.uid()
    )
  );

drop policy if exists "Users can read own favorites" on public.favorites;
create policy "Users can read own favorites"
  on public.favorites for select
  to authenticated
  using (user_id = auth.uid());

drop policy if exists "Users can create own favorites" on public.favorites;
create policy "Users can create own favorites"
  on public.favorites for insert
  to authenticated
  with check (user_id = auth.uid());

drop policy if exists "Users can delete own favorites" on public.favorites;
create policy "Users can delete own favorites"
  on public.favorites for delete
  to authenticated
  using (user_id = auth.uid());

drop policy if exists "Customers can read own booking QR code"
  on public.booking_qr_codes;
create policy "Customers can read own booking QR code"
  on public.booking_qr_codes for select
  to authenticated
  using (
    exists (
      select 1
      from public.bookings
      where bookings.id = booking_qr_codes.booking_id
        and bookings.customer_id = auth.uid()
    )
  );

drop policy if exists "Customers can read own QR scan history"
  on public.qr_scan_history;
create policy "Customers can read own QR scan history"
  on public.qr_scan_history for select
  to authenticated
  using (
    exists (
      select 1
      from public.bookings
      where bookings.id = qr_scan_history.booking_id
        and bookings.customer_id = auth.uid()
    )
  );

-- ---------------------------------------------------------------------------
-- API grants
-- ---------------------------------------------------------------------------

grant usage on schema public to authenticated;

grant select on public.service_categories to authenticated;
grant select on public.services to authenticated;
grant select on public.service_inclusions to authenticated;

grant select on public.profiles to authenticated;
revoke insert on public.profiles from authenticated;
grant insert (id, full_name, phone, avatar_url)
  on public.profiles to authenticated;
revoke update on public.profiles from authenticated;
grant update (full_name, phone, avatar_url, updated_at)
  on public.profiles to authenticated;

grant select, insert, update, delete
  on public.customer_addresses to authenticated;
grant select, insert on public.bookings to authenticated;
grant select on public.booking_status_history to authenticated;
grant select, insert, delete on public.favorites to authenticated;
grant select on public.booking_qr_codes to authenticated;
grant select on public.qr_scan_history to authenticated;

