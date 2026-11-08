-- Staff workflow, booking tracking, and in-app notifications.

create table if not exists public.staff_booking_responses (
  booking_id uuid not null references public.bookings(id) on delete cascade,
  staff_id uuid not null default auth.uid()
    references auth.users(id) on delete cascade,
  response text not null check (response in ('accepted', 'rejected')),
  created_at timestamptz not null default now(),
  primary key (booking_id, staff_id)
);

create table if not exists public.notifications (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  booking_id uuid references public.bookings(id) on delete cascade,
  title text not null,
  body text not null,
  type text not null default 'booking_update',
  read_at timestamptz,
  created_at timestamptz not null default now()
);

create index if not exists staff_booking_responses_staff_idx
  on public.staff_booking_responses(staff_id, response);
create index if not exists notifications_user_created_idx
  on public.notifications(user_id, created_at desc);

alter table public.staff_booking_responses enable row level security;
alter table public.notifications enable row level security;

create or replace function public.current_user_role()
returns text
language sql
stable
security definer
set search_path = ''
as $$
  select role from public.profiles where id = auth.uid();
$$;

drop policy if exists "Staff can read available and assigned bookings"
  on public.bookings;
create policy "Staff can read available and assigned bookings"
  on public.bookings for select
  to authenticated
  using (
    public.current_user_role() = 'staff'
    and (
      staff_id = auth.uid()
      or (
        staff_id is null
        and status = 'pending'
        and not exists (
          select 1
          from public.staff_booking_responses responses
          where responses.booking_id = bookings.id
            and responses.staff_id = auth.uid()
            and responses.response = 'rejected'
        )
      )
    )
  );

drop policy if exists "Staff can read relevant booking history"
  on public.booking_status_history;
create policy "Staff can read relevant booking history"
  on public.booking_status_history for select
  to authenticated
  using (
    public.current_user_role() = 'staff'
    and exists (
      select 1
      from public.bookings
      where bookings.id = booking_status_history.booking_id
        and (bookings.staff_id = auth.uid() or bookings.staff_id is null)
    )
  );

drop policy if exists "Staff can read own responses"
  on public.staff_booking_responses;
create policy "Staff can read own responses"
  on public.staff_booking_responses for select
  to authenticated
  using (staff_id = auth.uid());

drop policy if exists "Users can read own notifications"
  on public.notifications;
create policy "Users can read own notifications"
  on public.notifications for select
  to authenticated
  using (user_id = auth.uid());

drop policy if exists "Users can update own notifications"
  on public.notifications;
create policy "Users can update own notifications"
  on public.notifications for update
  to authenticated
  using (user_id = auth.uid())
  with check (user_id = auth.uid());

create or replace function public.respond_to_booking(
  p_booking_id uuid,
  p_accept boolean
)
returns void
language plpgsql
security definer
set search_path = ''
as $$
declare
  affected integer;
begin
  if public.current_user_role() <> 'staff' then
    raise exception 'Only staff can respond to bookings';
  end if;

  if p_accept then
    update public.bookings
    set staff_id = auth.uid(), status = 'assigned'
    where id = p_booking_id
      and staff_id is null
      and status = 'pending';
    get diagnostics affected = row_count;

    if affected = 0 then
      raise exception 'Booking is no longer available';
    end if;

    insert into public.staff_booking_responses (
      booking_id,
      staff_id,
      response
    ) values (p_booking_id, auth.uid(), 'accepted')
    on conflict (booking_id, staff_id) do update
    set response = excluded.response, created_at = now();
  else
    if not exists (
      select 1 from public.bookings
      where id = p_booking_id and staff_id is null and status = 'pending'
    ) then
      raise exception 'Booking is no longer available';
    end if;

    insert into public.staff_booking_responses (
      booking_id,
      staff_id,
      response
    ) values (p_booking_id, auth.uid(), 'rejected')
    on conflict (booking_id, staff_id) do update
    set response = excluded.response, created_at = now();
  end if;
end;
$$;

create or replace function public.update_booking_progress(
  p_booking_id uuid,
  p_status text
)
returns void
language plpgsql
security definer
set search_path = ''
as $$
declare
  current_status text;
begin
  if public.current_user_role() <> 'staff' then
    raise exception 'Only staff can update booking progress';
  end if;

  select status into current_status
  from public.bookings
  where id = p_booking_id and staff_id = auth.uid()
  for update;

  if current_status is null then
    raise exception 'Booking is not assigned to this staff member';
  end if;

  if not (
    (current_status = 'assigned' and p_status = 'on_the_way')
    or (current_status = 'on_the_way' and p_status = 'in_progress')
    or (current_status = 'in_progress' and p_status = 'completed')
  ) then
    raise exception 'Invalid booking status transition';
  end if;

  update public.bookings set status = p_status where id = p_booking_id;
end;
$$;

create or replace function public.create_booking_notifications()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
declare
  status_label text;
begin
  if tg_op = 'INSERT' then
    insert into public.notifications (user_id, booking_id, title, body, type)
    values (
      new.customer_id,
      new.id,
      'Pesanan berhasil dibuat',
      new.service_name || ' sedang menunggu konfirmasi staff.',
      'booking_created'
    );

    insert into public.notifications (user_id, booking_id, title, body, type)
    select
      profiles.id,
      new.id,
      'Pesanan baru tersedia',
      new.service_name || ' dijadwalkan untuk ' ||
        to_char(new.scheduled_at, 'DD Mon YYYY HH24:MI'),
      'new_booking'
    from public.profiles
    where profiles.role = 'staff';
  elsif old.status is distinct from new.status then
    status_label := case new.status
      when 'assigned' then 'telah diterima staff'
      when 'on_the_way' then 'staff sedang menuju lokasi'
      when 'in_progress' then 'sedang dikerjakan'
      when 'completed' then 'telah selesai'
      when 'cancelled' then 'dibatalkan'
      else new.status
    end;

    insert into public.notifications (user_id, booking_id, title, body, type)
    values (
      new.customer_id,
      new.id,
      'Status pesanan diperbarui',
      new.service_name || ' ' || status_label || '.',
      'booking_status'
    );
  end if;

  return new;
end;
$$;

drop trigger if exists create_booking_notifications_after_change
  on public.bookings;
create trigger create_booking_notifications_after_change
  after insert or update of status on public.bookings
  for each row execute function public.create_booking_notifications();

revoke all on function public.current_user_role() from public, anon;
revoke all on function public.respond_to_booking(uuid, boolean)
  from public, anon;
revoke all on function public.update_booking_progress(uuid, text)
  from public, anon;

grant select on public.staff_booking_responses to authenticated;
grant select, update (read_at) on public.notifications to authenticated;
grant execute on function public.current_user_role() to authenticated;
grant execute on function public.respond_to_booking(uuid, boolean)
  to authenticated;
grant execute on function public.update_booking_progress(uuid, text)
  to authenticated;
