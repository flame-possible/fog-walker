create table if not exists public.user_profiles (
  user_id uuid primary key references auth.users(id) on delete cascade,
  name text not null,
  passport_id text not null,
  level integer not null default 1 check (level >= 1),
  tier text not null,
  stamp_count integer not null default 0 check (stamp_count >= 0),
  email text,
  display_name text,
  photo_url text,
  updated_at timestamptz not null default now()
);

create table if not exists public.visited_cells (
  user_id uuid not null references auth.users(id) on delete cascade,
  cell_x integer not null,
  cell_y integer not null,
  visited_at timestamptz not null,
  updated_at timestamptz not null default now(),
  primary key (user_id, cell_x, cell_y)
);

create table if not exists public.walk_sessions (
  user_id uuid not null references auth.users(id) on delete cascade,
  id text not null,
  started_at timestamptz not null,
  ended_at timestamptz not null,
  distance_km double precision not null default 0 check (distance_km >= 0),
  cleared_km2 double precision not null default 0 check (cleared_km2 >= 0),
  new_cells_count integer not null default 0 check (new_cells_count >= 0),
  region_ids text[] not null default '{}',
  updated_at timestamptz not null default now(),
  primary key (user_id, id)
);

create table if not exists public.region_progress (
  user_id uuid not null references auth.users(id) on delete cascade,
  region_id text not null,
  unlocked_at timestamptz not null,
  visit_count integer not null default 1 check (visit_count >= 0),
  updated_at timestamptz not null default now(),
  primary key (user_id, region_id)
);

create index if not exists visited_cells_user_visited_at_idx
  on public.visited_cells (user_id, visited_at desc);

create index if not exists walk_sessions_user_started_at_idx
  on public.walk_sessions (user_id, started_at desc);

create index if not exists region_progress_user_unlocked_at_idx
  on public.region_progress (user_id, unlocked_at desc);

alter table public.user_profiles enable row level security;
alter table public.visited_cells enable row level security;
alter table public.walk_sessions enable row level security;
alter table public.region_progress enable row level security;

do $$
begin
  if not exists (
    select 1 from pg_policies
    where schemaname = 'public'
      and tablename = 'user_profiles'
      and policyname = 'user_profiles_own_rows'
  ) then
    create policy user_profiles_own_rows on public.user_profiles
      for all to authenticated
      using ((select auth.uid()) = user_id)
      with check ((select auth.uid()) = user_id);
  end if;
end $$;

do $$
begin
  if not exists (
    select 1 from pg_policies
    where schemaname = 'public'
      and tablename = 'visited_cells'
      and policyname = 'visited_cells_own_rows'
  ) then
    create policy visited_cells_own_rows on public.visited_cells
      for all to authenticated
      using ((select auth.uid()) = user_id)
      with check ((select auth.uid()) = user_id);
  end if;
end $$;

do $$
begin
  if not exists (
    select 1 from pg_policies
    where schemaname = 'public'
      and tablename = 'walk_sessions'
      and policyname = 'walk_sessions_own_rows'
  ) then
    create policy walk_sessions_own_rows on public.walk_sessions
      for all to authenticated
      using ((select auth.uid()) = user_id)
      with check ((select auth.uid()) = user_id);
  end if;
end $$;

do $$
begin
  if not exists (
    select 1 from pg_policies
    where schemaname = 'public'
      and tablename = 'region_progress'
      and policyname = 'region_progress_own_rows'
  ) then
    create policy region_progress_own_rows on public.region_progress
      for all to authenticated
      using ((select auth.uid()) = user_id)
      with check ((select auth.uid()) = user_id);
  end if;
end $$;
