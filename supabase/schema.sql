-- SHAKE app: rankings schema
-- スコアは加速度の生値 (m/s²) で保存し、表示側で震度 / MMI に換算する。
-- Run this in Supabase SQL Editor.

create table if not exists public.rankings (
  id bigserial primary key,
  nickname text not null check (char_length(nickname) = 6),
  acceleration numeric(7, 2) not null check (acceleration >= 0 and acceleration <= 500),
  country_code text not null check (char_length(country_code) = 2),
  country_name text not null,
  created_at timestamptz not null default now()
);

create index if not exists rankings_acceleration_desc_idx
  on public.rankings (acceleration desc);

create index if not exists rankings_country_acceleration_desc_idx
  on public.rankings (country_code, acceleration desc);

-- Row Level Security
alter table public.rankings enable row level security;

drop policy if exists "rankings_anon_select" on public.rankings;
create policy "rankings_anon_select"
  on public.rankings
  for select
  to anon, authenticated
  using (true);

drop policy if exists "rankings_anon_insert" on public.rankings;
create policy "rankings_anon_insert"
  on public.rankings
  for insert
  to anon, authenticated
  with check (true);

-- update / delete は許可しない（policy を作らない＝拒否）

-- 世界順位を返す RPC（自分のスコアより大きい件数 + 1）
create or replace function public.world_rank_for(target_acceleration numeric)
returns integer
language sql
stable
as $$
  select (count(*) + 1)::int
  from public.rankings
  where acceleration > target_acceleration;
$$;

-- 国別順位
create or replace function public.country_rank_for(target_acceleration numeric, target_country text)
returns integer
language sql
stable
as $$
  select (count(*) + 1)::int
  from public.rankings
  where country_code = target_country
    and acceleration > target_acceleration;
$$;
