-- ============================================================================
-- Guéra Hebdo : schéma Supabase (tables, sécurité RLS, stockage des images)
-- À exécuter une fois dans Supabase > SQL Editor, puis exécuter supabase/seed.sql.
-- ============================================================================

-- ---------- Profils des rédacteurs --------------------------------------------
-- Rôles : writer (rédacteur), editor (éditeur), admin (administrateur).
create table public.profiles (
  id         uuid primary key references auth.users (id) on delete cascade,
  full_name  text not null default '',
  role       text not null default 'writer' check (role in ('writer', 'editor', 'admin')),
  created_at timestamptz not null default now()
);

-- Un profil est créé automatiquement pour chaque nouveau compte.
create or replace function public.handle_new_user()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  insert into public.profiles (id, full_name)
  values (new.id, coalesce(new.raw_user_meta_data ->> 'full_name', ''))
  on conflict (id) do nothing;
  return new;
end;
$$;

create trigger on_auth_user_created
  after insert on auth.users
  for each row execute function public.handle_new_user();

-- Fonctions d'aide pour les règles de sécurité.
create or replace function public.app_role()
returns text
language sql
stable
security definer
set search_path = public
as $$
  select role from public.profiles where id = auth.uid();
$$;

create or replace function public.is_staff()
returns boolean
language sql
stable
security definer
set search_path = public
as $$
  select coalesce(public.app_role() in ('editor', 'admin'), false);
$$;

create or replace function public.is_admin()
returns boolean
language sql
stable
security definer
set search_path = public
as $$
  select coalesce(public.app_role() = 'admin', false);
$$;

-- ---------- Villes (sous-préfectures du Guéra) --------------------------------
create table public.towns (
  id         text primary key,
  name       text not null,
  department text not null,
  dx         numeric(4, 3) not null check (dx between 0 and 1),
  dy         numeric(4, 3) not null check (dy between 0 and 1),
  subtitle   text
);

-- ---------- Articles ------------------------------------------------------------
create table public.articles (
  id           uuid primary key default gen_random_uuid(),
  slug         text not null unique check (slug ~ '^[a-z0-9]+(-[a-z0-9]+)*$'),
  title        text not null check (length(title) between 3 and 250),
  category     text not null,
  summary      text not null default '',
  body         text not null default '',   -- paragraphes séparés par une ligne vide
  town_id      text references public.towns (id) on update cascade on delete set null,
  author_id    uuid references public.profiles (id) on delete set null,
  author_name  text,
  cover_url    text,
  video_url    text,                       -- lien Facebook de la vidéo
  status       text not null default 'draft'
               check (status in ('draft', 'review', 'published', 'archived')),
  review_note  text,                       -- message de l'éditeur au rédacteur
  published_at timestamptz,
  created_at   timestamptz not null default now(),
  updated_at   timestamptz not null default now(),
  check (status <> 'published' or published_at is not null)
);

create index articles_status_published_idx on public.articles (status, published_at desc);
create index articles_town_idx on public.articles (town_id);

create or replace function public.articles_before_write()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  new.updated_at := now();
  if tg_op = 'INSERT' then
    if new.author_id is null then
      new.author_id := auth.uid();
    end if;
    if new.author_name is null and new.author_id is not null then
      select full_name into new.author_name from public.profiles where id = new.author_id;
    end if;
  end if;
  if new.status = 'published' and new.published_at is null then
    new.published_at := now();
  end if;
  return new;
end;
$$;

create trigger articles_before_write
  before insert or update on public.articles
  for each row execute function public.articles_before_write();

-- ---------- Sondages « La voix du Guéra » ----------------------------------------
create table public.polls (
  id         uuid primary key default gen_random_uuid(),
  question   text not null,
  is_active  boolean not null default true,
  closes_at  timestamptz,
  created_at timestamptz not null default now()
);

create table public.poll_options (
  id      uuid primary key default gen_random_uuid(),
  poll_id uuid not null references public.polls (id) on delete cascade,
  letter  text not null,
  label   text not null,
  sort    int not null default 0,
  unique (poll_id, letter)
);

create table public.poll_votes (
  id         bigint generated always as identity primary key,
  poll_id    uuid not null references public.polls (id) on delete cascade,
  option_id  uuid not null references public.poll_options (id) on delete cascade,
  voter_key  text not null check (length(voter_key) between 16 and 64),
  created_at timestamptz not null default now(),
  unique (poll_id, voter_key)
);

-- Résultats publics (nombre de votes par option), sans exposer les votes eux-mêmes.
create view public.poll_results as
  select o.id as option_id, o.poll_id, o.letter, o.label, count(v.id) as votes
  from public.poll_options o
  join public.polls p on p.id = o.poll_id and p.is_active
  left join public.poll_votes v on v.option_id = o.id
  group by o.id;

-- Un vote par appareil et par sondage (cle aléatoire stockée dans l'appareil).
-- Protection simple : elle limite les doublons mais n'arrête pas un utilisateur déterminé.
create or replace function public.vote(p_option_id uuid, p_voter_key text)
returns void
language plpgsql
security definer
set search_path = public
as $$
declare
  v_poll uuid;
begin
  select poll_id into v_poll from public.poll_options where id = p_option_id;
  if v_poll is null then
    raise exception 'option_inconnue';
  end if;
  if not exists (
    select 1 from public.polls
    where id = v_poll and is_active and (closes_at is null or closes_at > now())
  ) then
    raise exception 'sondage_ferme';
  end if;
  insert into public.poll_votes (poll_id, option_id, voter_key)
  values (v_poll, p_option_id, p_voter_key)
  on conflict (poll_id, voter_key) do update set option_id = excluded.option_id;
end;
$$;

-- ---------- Publicités ---------------------------------------------------------
-- Formes retenues : bandeau image (top_banner, inline_banner) et encart « Annonce » (card).
create table public.ads (
  id         uuid primary key default gen_random_uuid(),
  placement  text not null check (placement in ('top_banner', 'inline_banner', 'card')),
  advertiser text not null,
  title      text,
  body       text,
  image_url  text,
  link_url   text,
  starts_on  date,
  ends_on    date,
  is_active  boolean not null default true,
  created_at timestamptz not null default now()
);

-- ---------- Communiqués et annonces locales ---------------------------------------
create table public.notices (
  id           uuid primary key default gen_random_uuid(),
  kind         text not null
               check (kind in ('nomination', 'avis', 'emploi', 'evenement', 'communique')),
  title        text not null check (length(title) between 3 and 200),
  body         text not null default '' check (length(body) <= 5000),
  town_id      text references public.towns (id) on update cascade on delete set null,
  contact      text check (length(contact) <= 200),
  status       text not null default 'pending' check (status in ('pending', 'published', 'rejected')),
  published_at timestamptz,
  created_at   timestamptz not null default now()
);

-- ============================================================================
-- SÉCURITÉ (Row Level Security)
-- ============================================================================
alter table public.profiles     enable row level security;
alter table public.towns        enable row level security;
alter table public.articles     enable row level security;
alter table public.polls        enable row level security;
alter table public.poll_options enable row level security;
alter table public.poll_votes   enable row level security;
alter table public.ads          enable row level security;
alter table public.notices      enable row level security;

-- Profils : chacun voit le sien, l'équipe éditoriale voit tout, seul l'admin change les rôles.
create policy "profiles: voir le sien ou tout si equipe" on public.profiles
  for select to authenticated using (id = auth.uid() or public.is_staff());
create policy "profiles: modifier le sien sans changer de role" on public.profiles
  for update to authenticated
  using (id = auth.uid())
  with check (id = auth.uid() and role = public.app_role());
create policy "profiles: admin modifie tout" on public.profiles
  for update to authenticated using (public.is_admin()) with check (public.is_admin());

-- Villes : lecture publique, écriture admin.
create policy "towns: lecture publique" on public.towns
  for select to anon, authenticated using (true);
create policy "towns: admin ecrit" on public.towns
  for all to authenticated using (public.is_admin()) with check (public.is_admin());

-- Articles : le public ne voit que le publié ; un rédacteur ne publie jamais lui-même.
create policy "articles: public lit le publie" on public.articles
  for select to anon, authenticated
  using (status = 'published' and published_at <= now());
create policy "articles: auteur lit les siens" on public.articles
  for select to authenticated using (author_id = auth.uid());
create policy "articles: equipe lit tout" on public.articles
  for select to authenticated using (public.is_staff());
create policy "articles: redacteur cree brouillon ou relecture" on public.articles
  for insert to authenticated
  with check (
    public.app_role() is not null
    and status in ('draft', 'review')
    and (author_id = auth.uid() or author_id is null)
  );
create policy "articles: equipe cree" on public.articles
  for insert to authenticated with check (public.is_staff());
create policy "articles: auteur modifie ses non-publies" on public.articles
  for update to authenticated
  using (author_id = auth.uid() and status in ('draft', 'review'))
  with check (author_id = auth.uid() and status in ('draft', 'review'));
create policy "articles: equipe modifie tout" on public.articles
  for update to authenticated using (public.is_staff()) with check (public.is_staff());
create policy "articles: equipe supprime" on public.articles
  for delete to authenticated using (public.is_staff());

-- Sondages : lecture publique des sondages actifs, gestion par l'équipe.
-- Les votes passent uniquement par la fonction vote() : aucune écriture directe.
create policy "polls: lecture publique" on public.polls
  for select to anon, authenticated using (is_active);
create policy "polls: equipe gere" on public.polls
  for all to authenticated using (public.is_staff()) with check (public.is_staff());
create policy "poll_options: lecture publique" on public.poll_options
  for select to anon, authenticated using (true);
create policy "poll_options: equipe gere" on public.poll_options
  for all to authenticated using (public.is_staff()) with check (public.is_staff());
create policy "poll_votes: equipe lit" on public.poll_votes
  for select to authenticated using (public.is_staff());

-- Publicités : visibles si actives et dans leurs dates ; gérées par l'administrateur.
create policy "ads: lecture publique des actives" on public.ads
  for select to anon, authenticated
  using (
    is_active
    and (starts_on is null or starts_on <= current_date)
    and (ends_on is null or ends_on >= current_date)
  );
create policy "ads: admin gere" on public.ads
  for all to authenticated using (public.is_admin()) with check (public.is_admin());

-- Communiqués : le public voit le publié et peut en proposer (en attente de validation).
create policy "notices: lecture du publie" on public.notices
  for select to anon, authenticated using (status = 'published');
create policy "notices: tout le monde propose" on public.notices
  for insert to anon, authenticated with check (status = 'pending' and published_at is null);
create policy "notices: equipe gere" on public.notices
  for all to authenticated using (public.is_staff()) with check (public.is_staff());

-- Accès aux résultats de sondage et à la fonction de vote.
grant select on public.poll_results to anon, authenticated;
grant execute on function public.vote(uuid, text) to anon, authenticated;

-- ============================================================================
-- STOCKAGE DES IMAGES (photos d'articles, visuels publicitaires)
-- 2 Mo maximum par image : lecteurs en bas débit, on garde des fichiers légers.
-- ============================================================================
insert into storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
values ('media', 'media', true, 2097152, array['image/jpeg', 'image/png', 'image/webp'])
on conflict (id) do nothing;

create policy "media: lecture publique" on storage.objects
  for select using (bucket_id = 'media');
create policy "media: equipe redactionnelle envoie" on storage.objects
  for insert to authenticated
  with check (bucket_id = 'media' and public.app_role() is not null);
create policy "media: equipe modifie" on storage.objects
  for update to authenticated using (bucket_id = 'media' and public.is_staff());
create policy "media: equipe supprime" on storage.objects
  for delete to authenticated using (bucket_id = 'media' and public.is_staff());
