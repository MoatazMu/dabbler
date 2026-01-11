-- Venue favorites (saved/bookmarked venues)

create extension if not exists pgcrypto;

create table if not exists public.venue_favorites (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  venue_id uuid not null references public.venues(id) on delete cascade,
  created_at timestamptz not null default now(),
  unique (user_id, venue_id)
);

create index if not exists venue_favorites_user_id_idx on public.venue_favorites(user_id);
create index if not exists venue_favorites_venue_id_idx on public.venue_favorites(venue_id);

alter table public.venue_favorites enable row level security;

do $$
begin
  -- Read own favorites
  if not exists (
    select 1 from pg_policies
    where schemaname = 'public'
      and tablename = 'venue_favorites'
      and policyname = 'venue_favorites_select_own'
  ) then
    create policy venue_favorites_select_own
      on public.venue_favorites
      for select
      to authenticated
      using (user_id = auth.uid());
  end if;

  -- Insert own favorites
  if not exists (
    select 1 from pg_policies
    where schemaname = 'public'
      and tablename = 'venue_favorites'
      and policyname = 'venue_favorites_insert_own'
  ) then
    create policy venue_favorites_insert_own
      on public.venue_favorites
      for insert
      to authenticated
      with check (user_id = auth.uid());
  end if;

  -- Delete own favorites
  if not exists (
    select 1 from pg_policies
    where schemaname = 'public'
      and tablename = 'venue_favorites'
      and policyname = 'venue_favorites_delete_own'
  ) then
    create policy venue_favorites_delete_own
      on public.venue_favorites
      for delete
      to authenticated
      using (user_id = auth.uid());
  end if;
end $$;

create or replace function public.toggle_venue_favorite(
  venue_id uuid,
  user_id uuid
)
returns void
language plpgsql
as $$
begin
  if auth.uid() is null then
    raise exception 'Not authenticated';
  end if;

  if user_id <> auth.uid() then
    raise exception 'Unauthorized';
  end if;

  if exists (
    select 1
    from public.venue_favorites vf
    where vf.venue_id = toggle_venue_favorite.venue_id
      and vf.user_id = toggle_venue_favorite.user_id
  ) then
    delete from public.venue_favorites vf
    where vf.venue_id = toggle_venue_favorite.venue_id
      and vf.user_id = toggle_venue_favorite.user_id;
  else
    insert into public.venue_favorites (venue_id, user_id)
    values (toggle_venue_favorite.venue_id, toggle_venue_favorite.user_id)
    on conflict (user_id, venue_id) do nothing;
  end if;
end;
$$;
