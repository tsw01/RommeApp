-- Rommé Punktezähler – Supabase Schema
-- Einmalig im Supabase SQL Editor ausführen

create table if not exists games (
  id          uuid primary key default gen_random_uuid(),
  created_at  timestamptz default now(),
  name        text,
  liga        text,
  players     text[]   not null,  -- ['Anna','Ben','Clara','Dan']
  teams       int[][]  not null,  -- [[0,2],[1,3]]
  status      text     not null default 'running',  -- 'running' | 'finished'
  total_rounds int     not null default 12,
  finished_at timestamptz
);

create table if not exists rounds (
  id          uuid primary key default gen_random_uuid(),
  game_id     uuid references games(id) on delete cascade,
  round_nr    int  not null,
  points      int[] not null,   -- [0, 42, 17, 33] – index = Spieler-Index
  winner      int  not null,    -- Spieler-Index
  romme_hand  bool not null default false
);

-- Liga-Zugriffssteuerung: ein Eintrag pro User+Liga, manuell in Supabase gepflegt
create table if not exists user_liga_access (
  id       uuid primary key default gen_random_uuid(),
  user_id  uuid not null references auth.users(id) on delete cascade,
  liga     text not null,
  role     text not null check (role in ('read', 'write')),
  unique (user_id, liga)
);

-- RLS aktivieren
alter table games            enable row level security;
alter table rounds           enable row level security;
alter table user_liga_access enable row level security;

-- user_liga_access: User darf nur seine eigenen Einträge lesen
create policy "user_read_own_liga_access"
  on user_liga_access for select
  using (auth.uid() = user_id);

-- Alte offene Policies entfernen (falls vorhanden)
drop policy if exists "anon_all_games"  on games;
drop policy if exists "anon_all_rounds" on rounds;

-- games: SELECT für alle User mit Liga-Zugriff
create policy "games_select"
  on games for select
  using (
    exists (
      select 1 from user_liga_access
      where user_liga_access.user_id = auth.uid()
        and user_liga_access.liga = games.liga
    )
  );

-- games: INSERT/UPDATE/DELETE nur mit 'write'-Rolle
create policy "games_insert"
  on games for insert
  with check (
    exists (
      select 1 from user_liga_access
      where user_liga_access.user_id = auth.uid()
        and user_liga_access.liga = games.liga
        and user_liga_access.role = 'write'
    )
  );

create policy "games_update"
  on games for update
  using (
    exists (
      select 1 from user_liga_access
      where user_liga_access.user_id = auth.uid()
        and user_liga_access.liga = games.liga
        and user_liga_access.role = 'write'
    )
  );

create policy "games_delete"
  on games for delete
  using (
    exists (
      select 1 from user_liga_access
      where user_liga_access.user_id = auth.uid()
        and user_liga_access.liga = games.liga
        and user_liga_access.role = 'write'
    )
  );

-- rounds: SELECT via JOIN auf games (rounds hat keine eigene liga-Spalte)
create policy "rounds_select"
  on rounds for select
  using (
    exists (
      select 1 from games
      join user_liga_access on user_liga_access.liga = games.liga
      where games.id = rounds.game_id
        and user_liga_access.user_id = auth.uid()
    )
  );

-- rounds: INSERT/UPDATE/DELETE nur mit 'write'-Rolle
create policy "rounds_insert"
  on rounds for insert
  with check (
    exists (
      select 1 from games
      join user_liga_access on user_liga_access.liga = games.liga
      where games.id = rounds.game_id
        and user_liga_access.user_id = auth.uid()
        and user_liga_access.role = 'write'
    )
  );

create policy "rounds_update"
  on rounds for update
  using (
    exists (
      select 1 from games
      join user_liga_access on user_liga_access.liga = games.liga
      where games.id = rounds.game_id
        and user_liga_access.user_id = auth.uid()
        and user_liga_access.role = 'write'
    )
  );

create policy "rounds_delete"
  on rounds for delete
  using (
    exists (
      select 1 from games
      join user_liga_access on user_liga_access.liga = games.liga
      where games.id = rounds.game_id
        and user_liga_access.user_id = auth.uid()
        and user_liga_access.role = 'write'
    )
  );
