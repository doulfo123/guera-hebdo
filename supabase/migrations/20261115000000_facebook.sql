-- Guéra Hebdo — liaison Facebook : mémorise l'identifiant de la publication Facebook.
alter table public.articles add column if not exists facebook_post_id text;
