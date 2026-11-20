# Guéra Hebdo — site Flutter + Supabase

Accueil en **carte interactive du Guéra** (12 sous-préfectures), page article, sondage
« La voix du Guéra » avec résultats réels, emplacements publicitaires.
Les données viennent de **Supabase** ; sans clés, l'application tourne en **mode démo**.

> Ce code a été écrit sans compilateur Flutter ni serveur Supabase (indisponibles dans
> l'environnement de création). Il n'a donc pas encore été lancé : à la première exécution,
> corrigeons ensemble toute erreur de `flutter analyze` / `flutter run`, ou de la base.

## 1. Lancer en mode démo (sans Supabase)

```bash
flutter create --platforms=web,android guera_hebdo
cd guera_hebdo
# copier ici : pubspec.yaml et lib/ (remplacer ceux créés)
flutter pub get
flutter run -d chrome
```

## 2. Brancher Supabase

1. Créer un projet sur supabase.com (région la plus proche des lecteurs).
2. **SQL Editor** : exécuter `supabase/migrations/20261114000000_init.sql`, puis `supabase/seed.sql`.
3. **Authentication > Providers > Email** : **désactiver les inscriptions publiques**
   (« Allow new users to sign up »). Seuls les comptes que vous créez à la main pourront écrire.
4. **Authentication > Users > Add user** : créer les comptes des 2 rédacteurs-éditeurs, puis donner
   le rôle (requête en bas de `seed.sql`). Votre compte : `role = 'admin'`.
5. **Project Settings > API** : copier l'URL du projet et la clé `anon`, puis :

```bash
flutter run -d chrome \
  --dart-define=SUPABASE_URL=https://xxxx.supabase.co \
  --dart-define=SUPABASE_ANON_KEY=eyJ...
```

La clé `anon` est publique par conception (la sécurité repose sur les règles RLS de la base).
**N'utilisez jamais la clé `service_role` dans l'application.**

## Ce que la base garantit (règles RLS)

| Qui | Peut |
| --- | --- |
| Visiteur | Lire articles publiés, villes, sondage actif, publicités actives, communiqués publiés ; voter ; proposer un communiqué (en attente) |
| Rédacteur (`writer`) | Créer et modifier ses propres brouillons / articles à relire. **Ne peut jamais publier** |
| Éditeur (`editor`) | Tout lire, relire, publier, supprimer, gérer sondages et communiqués |
| Administrateur (`admin`) | Tout, plus rôles, villes et publicités |

Images : bucket public `media` (JPEG/PNG/WebP, 2 Mo max, pour les lecteurs en bas débit).

## Structure

```
supabase/
  migrations/…_init.sql      tables, sécurité RLS, stockage des images
  seed.sql                   12 villes, premier sondage, articles de démonstration
lib/
  main.dart                  démarrage : Supabase si clés fournies, sinon démo
  app/                       routes (/ et /article/:slug), thème, configuration
  data/
    models.dart              Town, Article, Poll, Ad
    content_repository.dart  interface unique d'accès aux données
    supabase_content_repository.dart   version Supabase
    demo_content_repository.dart       version démo (sans serveur)
    voter_key.dart           clé d'appareil pour limiter à un vote par sondage
  features/home/             carte du Guéra + accueil
  features/article/          page article + partage WhatsApp / Facebook / lien
  widgets/                   logo, carte d'article, pub, sondage, pied de page
```

## À savoir

- **Plan gratuit Supabase** : 500 Mo de base, 1 Go de fichiers, 50 000 utilisateurs actifs/mois ;
  le projet est **mis en pause après 1 semaine d'inactivité**. Pour un média en production,
  prévoir le plan Pro (à partir de 25 $/mois), qui ne met pas en pause.
- **Anti-doublon du sondage** : une clé aléatoire par appareil. Simple, mais contournable.
- **Communiqués** : la table existe (le public peut en proposer, ils restent « en attente »
  jusqu'à validation) ; l'écran correspondant viendra avec le back-office.
- **Logo, couleurs, positions des villes** : provisoires (voir le dossier de projet).
- **Domaine** : `kSiteUrl` dans `lib/app/config.dart` est provisoire.

## Prochaine étape : le back-office

Connexion des rédacteurs, liste « mes articles », éditeur d'article avec envoi de photo,
file de relecture pour les éditeurs (publier / renvoyer avec une note), gestion du sondage
et des publicités.

---

## Mise à jour 0.3 : back-office et communiqués

**Base de données : une seule étape.** Dans Supabase > SQL Editor, collez et exécutez
`supabase/setup_complet.sql` (schéma + sécurité + droits + données de démonstration).
Les fichiers séparés (`migrations/…init.sql`, `migrations/…backoffice.sql`, `seed.sql`) contiennent la même chose.

**Lancer le site connecté** (la clé publishable est déjà dans `lib/app/config.dart`, il manque l'URL du projet) :

    flutter pub get
    flutter run -d chrome 

**Back-office** : `/admin` (connexion par e-mail et mot de passe).
- Rédacteur : crée et modifie ses articles, les envoie en relecture, ne publie jamais.
- Éditeur : publie, renvoie à l'auteur avec un message, archive, modère les communiqués, gère le sondage.
- Administrateur : tout cela + publicités.

**Public** : `/communique` permet à n'importe qui de proposer un communiqué ; il n'apparaît qu'après validation.

**À faire dans Supabase** : Authentication > Providers > Email : désactiver « Allow new users to sign up », créer les comptes
(Authentication > Users), puis donner les rôles (voir fin de `seed.sql`).
Le code n'a pas encore été compilé : au premier `flutter run`, signalez-moi les erreurs éventuelles.

---

## Liaison Facebook (import et publication)

Deux fonctions serveur Supabase (`supabase/functions/`) : `facebook-import` (lit un lien) et `facebook-publish` (publie sur la page).
Le jeton Facebook reste dans Supabase, jamais dans le site.

1. Exécutez aussi `supabase/migrations/20261115000000_facebook.sql` (déjà inclus dans `setup_complet.sql`).
2. developers.facebook.com : créer une application, y ajouter votre Page, générer un **jeton de Page longue durée**
   (permissions `pages_manage_posts`, `pages_read_engagement`).
3. Supabase > Edge Functions > Secrets : `FB_PAGE_ID`, `FB_PAGE_TOKEN`, `SITE_URL` (adresse du site).
4. Déployer : `supabase functions deploy facebook-import` et `supabase functions deploy facebook-publish`
   (ou copier le code dans l'éditeur de fonctions du tableau de bord).

---

## Mise en ligne de test (GitHub Pages)

Le dépôt contient un workflow (`.github/workflows/deploy.yml`) qui compile le site et le publie à chaque envoi sur la branche `main`.
Adresse de test : `https://VOTRE-COMPTE.github.io/NOM-DU-DEPOT/`.
La page contient `noindex` : Google ne l'indexe pas pendant la phase de test (à retirer dans `web/index.html` au lancement).
Aucun secret n'est dans le dépôt : l'URL et la clé « publishable » Supabase sont publiques par conception,
la sécurité vient des règles RLS. Les jetons Facebook restent dans les secrets Supabase.
