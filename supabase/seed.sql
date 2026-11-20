-- ============================================================================
-- Données de départ : villes du Guéra, premier sondage, articles de démonstration.
-- À exécuter après la migration. Supprimez les articles de démo avant le lancement.
-- ============================================================================

-- Les 12 sous-préfectures (position sur la carte stylisée : approximative).
insert into public.towns (id, name, department, dx, dy, subtitle) values
  ('mongo',      'Mongo',        'Guéra',        0.58, 0.52, 'CHEF-LIEU DE LA PROVINCE · DÉPARTEMENT DU GUÉRA'),
  ('bitkine',    'Bitkine',      'Abtouyour',    0.24, 0.58, null),
  ('bangbang',   'Bang Bang',    'Abtouyour',    0.28, 0.42, null),
  ('baro',       'Baro',         'Guéra',        0.46, 0.62, null),
  ('niergui',    'Niergui',      'Guéra',        0.59, 0.38, null),
  ('melfi',      'Mélfi',        'Barh Signaka', 0.42, 0.77, null),
  ('chinguil',   'Chinguil',     'Barh Signaka', 0.62, 0.79, null),
  ('mokofi',     'Mokofi',       'Barh Signaka', 0.26, 0.71, null),
  ('mangalme',   'Mangalmé',     'Mangalmé',     0.82, 0.49, null),
  ('eref',       'Eref',         'Mangalmé',     0.76, 0.61, null),
  ('kouka',      'Kouka Margni', 'Mangalmé',     0.82, 0.38, null),
  ('bitchotchi', 'Bitchotchi',   'Mangalmé',     0.77, 0.70, null)
on conflict (id) do nothing;

-- Premier sondage « La voix du Guéra ».
with p as (
  insert into public.polls (question)
  values ('Quel est le plus grand défi du Guéra ?')
  returning id
)
insert into public.poll_options (poll_id, letter, label, sort)
select p.id, o.letter, o.label, o.sort
from p,
  (values
    ('A', 'Infrastructures et services sociaux', 1),
    ('B', 'Emploi et entrepreneuriat des jeunes', 2),
    ('C', 'Agriculture, élevage et économie locale', 3),
    ('D', 'Valorisation et coordination des initiatives', 4)
  ) as o (letter, label, sort);

-- Articles de démonstration (titres tirés de vos publications ; textes à écrire).
insert into public.articles (slug, title, category, summary, body, town_id, author_name, status, published_at) values
  ('festival-cultures-mongo',
   'Mongo accueille la 12e édition du Festival des cultures',
   'CULTURE', 'Les 12 et 13 décembre 2026.',
   '[Texte de l''article, à rédiger dans le back-office.]',
   'mongo', 'La rédaction', 'published', '2026-11-11 12:00+01'),
  ('formation-points-focaux-mongo',
   'Formation des points focaux à l''Espace Betna Mongo',
   'ATELIER', 'Du 10 au 12 novembre 2026.',
   '[Texte de l''article, à rédiger dans le back-office.]',
   'mongo', 'La rédaction', 'published', '2026-11-11 11:00+01'),
  ('eclairage-public-bitkine',
   'La commune de Bitkine renforce son éclairage public',
   'BITKINE', 'Une opération de réhabilitation de l''éclairage public.',
   '[Texte de l''article, à rédiger dans le back-office.]',
   'bitkine', 'La rédaction', 'published', '2026-11-11 10:00+01'),
  ('conseil-provincial-travaux-urgence',
   'Le Conseil provincial du Guéra réceptionne les travaux d''urgence',
   'GUÉRA', 'Réception effectuée le mercredi 11 novembre 2026.',
   '[Texte de l''article, à rédiger dans le back-office.]',
   null, 'La rédaction', 'published', '2026-11-11 09:00+01'),
  ('festival-pastoral-abdelaziz-hassan',
   'Abdelaziz Hassan, président des éleveurs du Guéra, décroche le 3e prix',
   'FESTIVAL PASTORAL', 'Une distinction qui honore les acteurs pastoraux de la province.',
   '[Texte de l''article, à rédiger dans le back-office.]',
   null, 'La rédaction', 'published', '2026-11-11 08:00+01')
on conflict (slug) do nothing;

-- Communiqués de démonstration
insert into public.notices (kind, title, body, status, published_at)
select * from (values
  ('nomination', 'M. Aguid Kodo nommé SG programme La Tchadienne FEP-Tchad',
   'Décision N°00088/DRH/DG/SNE/CA/PCA/FEP26 du 5 nov. 2026.', 'published', '2026-11-11 10:00+01'::timestamptz),
  ('evenement', 'Atelier de formation des points focaux à l''Espace Betna Mongo',
   'Du 10 au 12 novembre 2026.', 'published', '2026-11-11 09:30+01'::timestamptz)
) as v(kind, title, body, status, published_at)
where not exists (select 1 from public.notices);

-- ============================================================================
-- Après avoir créé vos 2 comptes (Authentication > Users > Add user), donnez-leur
-- le rôle d'éditeur (remplacez l'adresse e-mail) :
--
--   update public.profiles
--   set role = 'editor', full_name = 'Prénom Nom'
--   where id = (select id from auth.users where email = 'redacteur1@exemple.com');
--
-- Pour vous-même (administrateur) : mettre role = 'admin'.
-- ============================================================================
