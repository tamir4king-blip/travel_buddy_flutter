-- ============================================================
-- Travel Buddy — Initial Database Schema
-- ============================================================

-- ────────────────────────────────────────────────────────────
-- 1. PROFILES  (extends auth.users)
-- ────────────────────────────────────────────────────────────
create table public.profiles (
  id              uuid primary key references auth.users(id) on delete cascade,
  display_name    text not null,
  username        text unique,
  bio             text,
  avatar_url      text,
  total_xp        integer not null default 0,
  level           integer not null default 1,
  is_premium      boolean not null default false,
  is_public       boolean not null default true,
  current_streak  integer not null default 0,
  last_completion_date timestamptz,
  created_at      timestamptz not null default now(),
  updated_at      timestamptz not null default now()
);

-- Auto-update updated_at
create or replace function public.handle_updated_at()
returns trigger as $$
begin
  new.updated_at = now();
  return new;
end;
$$ language plpgsql;

create trigger profiles_updated_at
  before update on public.profiles
  for each row execute function public.handle_updated_at();

-- Auto-create a profile row when a user signs up
create or replace function public.handle_new_user()
returns trigger as $$
begin
  insert into public.profiles (id, display_name, username)
  values (
    new.id,
    coalesce(new.raw_user_meta_data->>'display_name', split_part(new.email, '@', 1)),
    null
  );
  return new;
end;
$$ language plpgsql security definer;

create trigger on_auth_user_created
  after insert on auth.users
  for each row execute function public.handle_new_user();

-- ────────────────────────────────────────────────────────────
-- 2. USER ACHIEVEMENTS
-- ────────────────────────────────────────────────────────────
create table public.user_achievements (
  id              uuid primary key default gen_random_uuid(),
  user_id         uuid not null references public.profiles(id) on delete cascade,
  achievement_id  text not null,          -- matches client-side registry id
  unlocked_at     timestamptz not null default now(),
  visit_date      timestamptz,            -- for retroactive claims
  notes           text,
  is_retroactive  boolean not null default false,
  photos          text[] default '{}',    -- storage URLs
  created_at      timestamptz not null default now(),

  unique(user_id, achievement_id)
);

create index idx_user_achievements_user on public.user_achievements(user_id);

-- ────────────────────────────────────────────────────────────
-- 3. USER QUEST COMPLETIONS
-- ────────────────────────────────────────────────────────────
create table public.user_quest_completions (
  id                uuid primary key default gen_random_uuid(),
  user_id           uuid not null references public.profiles(id) on delete cascade,
  quest_id          text not null,        -- matches client-side registry id
  completion_count  integer not null default 1,
  updated_at        timestamptz not null default now(),

  unique(user_id, quest_id)
);

create index idx_user_quest_completions_user on public.user_quest_completions(user_id);

create trigger user_quest_completions_updated_at
  before update on public.user_quest_completions
  for each row execute function public.handle_updated_at();

-- ────────────────────────────────────────────────────────────
-- 4. USER SKILL XP
-- ────────────────────────────────────────────────────────────
create table public.user_skill_xp (
  id          uuid primary key default gen_random_uuid(),
  user_id     uuid not null references public.profiles(id) on delete cascade,
  skill_id    text not null,              -- matches client-side skill registry id
  xp          integer not null default 0,
  updated_at  timestamptz not null default now(),

  unique(user_id, skill_id)
);

create index idx_user_skill_xp_user on public.user_skill_xp(user_id);

create trigger user_skill_xp_updated_at
  before update on public.user_skill_xp
  for each row execute function public.handle_updated_at();

-- ────────────────────────────────────────────────────────────
-- 5. USER MASTER ACHIEVEMENTS
-- ────────────────────────────────────────────────────────────
create table public.user_master_achievements (
  id                    uuid primary key default gen_random_uuid(),
  user_id               uuid not null references public.profiles(id) on delete cascade,
  master_achievement_id text not null,    -- matches client-side registry id
  unlocked_at           timestamptz not null default now(),

  unique(user_id, master_achievement_id)
);

create index idx_user_master_achievements_user on public.user_master_achievements(user_id);

-- ────────────────────────────────────────────────────────────
-- 6. USER COMPLETED COLLECTIONS
-- ────────────────────────────────────────────────────────────
create table public.user_completed_collections (
  id            uuid primary key default gen_random_uuid(),
  user_id       uuid not null references public.profiles(id) on delete cascade,
  collection_id text not null,            -- beaches, landmarks, parks, culture
  completed_at  timestamptz not null default now(),

  unique(user_id, collection_id)
);

create index idx_user_completed_collections_user on public.user_completed_collections(user_id);

-- ────────────────────────────────────────────────────────────
-- 7. LEADERBOARD VIEW
-- ────────────────────────────────────────────────────────────
create or replace view public.leaderboard as
select
  p.id          as user_id,
  p.display_name,
  p.avatar_url,
  p.total_xp,
  p.level,
  p.is_public,
  rank() over (order by p.total_xp desc) as rank
from public.profiles p
where p.is_public = true
order by p.total_xp desc;

-- ────────────────────────────────────────────────────────────
-- 8. STORAGE BUCKET  (for photos)
-- ────────────────────────────────────────────────────────────
insert into storage.buckets (id, name, public)
values ('photos', 'photos', true)
on conflict (id) do nothing;

-- ============================================================
-- ROW LEVEL SECURITY
-- ============================================================
alter table public.profiles enable row level security;
alter table public.user_achievements enable row level security;
alter table public.user_quest_completions enable row level security;
alter table public.user_skill_xp enable row level security;
alter table public.user_master_achievements enable row level security;
alter table public.user_completed_collections enable row level security;

-- ── PROFILES ──
-- Anyone can read public profiles; users can read their own profile
create policy "Public profiles are viewable by everyone"
  on public.profiles for select
  using (is_public = true or auth.uid() = id);

-- Users can update their own profile
create policy "Users can update their own profile"
  on public.profiles for update
  using (auth.uid() = id)
  with check (auth.uid() = id);

-- Insert is handled by the trigger (security definer), but allow it for safety
create policy "Users can insert their own profile"
  on public.profiles for insert
  with check (auth.uid() = id);

-- ── USER ACHIEVEMENTS ──
create policy "Users can view their own achievements"
  on public.user_achievements for select
  using (auth.uid() = user_id);

create policy "Users can insert their own achievements"
  on public.user_achievements for insert
  with check (auth.uid() = user_id);

create policy "Users can update their own achievements"
  on public.user_achievements for update
  using (auth.uid() = user_id);

create policy "Users can delete their own achievements"
  on public.user_achievements for delete
  using (auth.uid() = user_id);

-- ── USER QUEST COMPLETIONS ──
create policy "Users can view their own quest completions"
  on public.user_quest_completions for select
  using (auth.uid() = user_id);

create policy "Users can insert their own quest completions"
  on public.user_quest_completions for insert
  with check (auth.uid() = user_id);

create policy "Users can update their own quest completions"
  on public.user_quest_completions for update
  using (auth.uid() = user_id);

-- ── USER SKILL XP ──
create policy "Users can view their own skill xp"
  on public.user_skill_xp for select
  using (auth.uid() = user_id);

create policy "Users can insert their own skill xp"
  on public.user_skill_xp for insert
  with check (auth.uid() = user_id);

create policy "Users can update their own skill xp"
  on public.user_skill_xp for update
  using (auth.uid() = user_id);

-- ── USER MASTER ACHIEVEMENTS ──
create policy "Users can view their own master achievements"
  on public.user_master_achievements for select
  using (auth.uid() = user_id);

create policy "Users can insert their own master achievements"
  on public.user_master_achievements for insert
  with check (auth.uid() = user_id);

-- ── USER COMPLETED COLLECTIONS ──
create policy "Users can view their own completed collections"
  on public.user_completed_collections for select
  using (auth.uid() = user_id);

create policy "Users can insert their own completed collections"
  on public.user_completed_collections for insert
  with check (auth.uid() = user_id);

-- ── STORAGE (photos bucket) ──
create policy "Users can upload their own photos"
  on storage.objects for insert
  with check (
    bucket_id = 'photos'
    and (storage.foldername(name))[1] = auth.uid()::text
  );

create policy "Users can view their own photos"
  on storage.objects for select
  using (
    bucket_id = 'photos'
    and (storage.foldername(name))[1] = auth.uid()::text
  );

create policy "Public photos are viewable by everyone"
  on storage.objects for select
  using (bucket_id = 'photos');

create policy "Users can delete their own photos"
  on storage.objects for delete
  using (
    bucket_id = 'photos'
    and (storage.foldername(name))[1] = auth.uid()::text
  );
