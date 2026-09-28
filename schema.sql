-- BLACKOUT CITY / Supabase database setup
-- Run this entire file in Supabase Dashboard -> SQL Editor.
-- This file does NOT contain any secret/service-role key.

create table if not exists public.player_saves (
  user_id uuid primary key references auth.users(id) on delete cascade,
  save_data jsonb not null default '{}'::jsonb,
  updated_at timestamptz not null default now()
);

create table if not exists public.leaderboard (
  user_id uuid primary key references auth.users(id) on delete cascade,
  username text not null unique,
  display_name text not null default 'Rookie',
  level integer not null default 1,
  net_worth numeric not null default 0,
  fight_wins integer not null default 0,
  color text not null default '#e8b93c',
  hat integer not null default 0,
  motto text not null default '',
  updated_at timestamptz not null default now()
);

create index if not exists leaderboard_net_worth_idx on public.leaderboard (net_worth desc);
create index if not exists leaderboard_level_idx on public.leaderboard (level desc);
create index if not exists leaderboard_fight_wins_idx on public.leaderboard (fight_wins desc);

alter table public.player_saves enable row level security;
alter table public.leaderboard enable row level security;

-- Remove/recreate policies so this script can safely be run again.
drop policy if exists "player_saves_select_own" on public.player_saves;
drop policy if exists "player_saves_insert_own" on public.player_saves;
drop policy if exists "player_saves_update_own" on public.player_saves;
drop policy if exists "leaderboard_public_read" on public.leaderboard;
drop policy if exists "leaderboard_insert_own" on public.leaderboard;
drop policy if exists "leaderboard_update_own" on public.leaderboard;

create policy "player_saves_select_own"
on public.player_saves for select
using (auth.uid() = user_id);

create policy "player_saves_insert_own"
on public.player_saves for insert
with check (auth.uid() = user_id);

create policy "player_saves_update_own"
on public.player_saves for update
using (auth.uid() = user_id)
with check (auth.uid() = user_id);

create policy "leaderboard_public_read"
on public.leaderboard for select
using (true);

create policy "leaderboard_insert_own"
on public.leaderboard for insert
with check (auth.uid() = user_id);

create policy "leaderboard_update_own"
on public.leaderboard for update
using (auth.uid() = user_id)
with check (auth.uid() = user_id);

-- Keep updated_at current when a save/leaderboard row changes.
create or replace function public.touch_updated_at()
returns trigger
language plpgsql
as $$
begin
  new.updated_at = now();
  return new;
end;
$$;

drop trigger if exists player_saves_touch_updated_at on public.player_saves;
create trigger player_saves_touch_updated_at
before update on public.player_saves
for each row execute function public.touch_updated_at();

drop trigger if exists leaderboard_touch_updated_at on public.leaderboard;
create trigger leaderboard_touch_updated_at
before update on public.leaderboard
for each row execute function public.touch_updated_at();

-- Optional realtime support for live leaderboard updates.
-- If the publication/table already exists, the DO block avoids an error.
do $$
begin
  begin
    alter publication supabase_realtime add table public.leaderboard;
  exception when duplicate_object then
    null;
  when undefined_object then
    null;
  end;
end $$;
