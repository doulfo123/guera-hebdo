// Publie un article déjà PUBLIÉ sur la page Facebook de Guéra Hebdo.
// Réservé aux éditeurs et administrateurs. Le jeton de la page reste ici, côté serveur.
import { adminClient, caller, cors, json } from "../_shared/common.ts";

Deno.serve(async (req) => {
  if (req.method === "OPTIONS") return new Response("ok", { headers: cors });
  const me = await caller(req);
  if (!me || !["editor", "admin"].includes(me.role)) {
    return json({ error: "Réservé aux éditeurs." }, 403);
  }
  const token = Deno.env.get("FB_PAGE_TOKEN");
  const pageId = Deno.env.get("FB_PAGE_ID");
  const site = (Deno.env.get("SITE_URL") ?? "").replace(/\/$/, "");
  if (!token || !pageId) {
    return json({ error: "La liaison Facebook n'est pas encore configurée." }, 400);
  }

  const { articleId } = await req.json().catch(() => ({}));
  const db = adminClient();
  const { data: a } = await db.from("articles").select("*").eq("id", articleId).maybeSingle();
  if (!a) return json({ error: "Article introuvable." }, 404);
  if (a.status !== "published") return json({ error: "Publiez d'abord l'article sur le site." }, 400);
  if (a.facebook_post_id) return json({ error: "Déjà publié sur Facebook." }, 409);

  const url = site ? `${site}/article/${a.slug}` : "";
  const text = [a.title, a.summary, url].filter((s: string) => s && s.trim()).join("\n\n");

  const params = new URLSearchParams({ access_token: token });
  let endpoint: string;
  if (a.cover_url) {
    endpoint = `${pageId}/photos`;
    params.set("url", a.cover_url);
    params.set("caption", text);
  } else {
    endpoint = `${pageId}/feed`;
    params.set("message", text);
    if (url) params.set("link", url);
  }
  const r = await fetch(`https://graph.facebook.com/v21.0/${endpoint}`, { method: "POST", body: params });
  const out = await r.json().catch(() => ({}));
  if (!r.ok) {
    return json({ error: `Facebook a refusé : ${out?.error?.message ?? "erreur inconnue"}` }, 502);
  }
  const fbId = out.post_id ?? out.id;
  await db.from("articles").update({ facebook_post_id: fbId }).eq("id", a.id);
  return json({ ok: true, facebook_post_id: fbId });
});
