-- ============================================================================
-- Guéra Hebdo — Complément : droits d'accès, suppression de brouillons,
-- protection anti-spam des communiqués.
-- À exécuter APRÈS 20261114000000_init.sql (sans danger si rejoué).
-- ============================================================================

-- Droits d'accès aux tables (les règles RLS filtrent ensuite ligne par ligne).
grant usage on schema public to anon, authenticated;

grant select on public.towns, public.articles, public.polls, public.poll_options,
                public.ads, public.notices, public.poll_results to anon;
grant insert on public.notices to anon;

grant select, insert, update, delete on all tables in schema public to authenticated;
grant usage, select on all sequences in schema public to authenticated;

grant execute on function public.vote(uuid, text) to anon, authenticated;

-- Un rédacteur peut supprimer ses propres brouillons (jamais un article publié).
drop policy if exists "articles: auteur supprime ses brouillons" on public.articles;
create policy "articles: auteur supprime ses brouillons" on public.articles
  for delete to authenticated
  using (author_id = auth.uid() and status = 'draft');

-- Anti-spam : pas plus de 50 communiqués en attente à la fois.
create or replace function public.notices_before_insert()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  if new.status = 'pending'
     and (select count(*) from public.notices where status = 'pending') >= 50 then
    raise exception 'Trop de communiqués en attente, réessayez plus tard.';
  end if;
  return new;
end;
$$;

drop trigger if exists notices_before_insert on public.notices;
create trigger notices_before_insert
  before insert on public.notices
  for each row execute function public.notices_before_insert();

-- Date de publication posée automatiquement à la validation.
create or replace function public.notices_before_update()
returns trigger
language plpgsql
as $$
begin
  if new.status = 'published' and new.published_at is null then
    new.published_at := now();
  end if;
  return new;
end;
$$;

drop trigger if exists notices_before_update on public.notices;
create trigger notices_before_update
  before update on public.notices
  for each row execute function public.notices_before_update();
