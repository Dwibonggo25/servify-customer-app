-- Backfill profiles for users created before the profiles trigger existed.

insert into public.profiles (id, full_name, phone, role)
select
  users.id,
  coalesce(
    nullif(users.raw_user_meta_data ->> 'full_name', ''),
    nullif(split_part(coalesce(users.email, ''), '@', 1), ''),
    'Customer'
  ),
  nullif(users.raw_user_meta_data ->> 'phone', ''),
  'customer'
from auth.users as users
on conflict (id) do nothing;

drop policy if exists "Users can create own profile" on public.profiles;
create policy "Users can create own profile"
  on public.profiles for insert
  to authenticated
  with check (
    id = auth.uid()
    and role = 'customer'
  );

revoke insert on public.profiles from authenticated;
grant insert (id, full_name, phone, avatar_url)
  on public.profiles to authenticated;

