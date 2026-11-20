// Importe le titre, le texte et la photo d'une publication Facebook à partir de son lien.
// 1) Si FB_PAGE_TOKEN est défini : lecture officielle via l'API Graph (fiable pour VOTRE page).
// 2) Sinon : lecture des balises publiques « og: » (limité, Facebook peut refuser).
import { createClient } from "https://esm.sh/@supabase/supabase-js@2.45.4";

const cors = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
};

function json(body: unknown, status = 200) {
  return new Response(JSON.stringify(body), {
    status,
    headers: { ...cors, "Content-Type": "application/json" },
  });
}

/** Client « admin » (clé service, jamais exposée au navigateur). */
function adminClient() {
  return createClient(
    Deno.env.get("SUPABASE_URL")!,
    Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!,
  );
}

/** Identifie l'appelant à partir de son jeton de connexion et renvoie son profil. */
async function caller(req: Request) {
  const auth = req.headers.get("Authorization") ?? "";
  const userClient = createClient(
    Deno.env.get("SUPABASE_URL")!,
    Deno.env.get("SUPABASE_ANON_KEY")!,
    { global: { headers: { Authorization: auth } } },
  );
  const { data } = await userClient.auth.getUser();
  if (!data.user) return null;
  const { data: profile } = await adminClient()
    .from("profiles").select("id, role").eq("id", data.user.id).maybeSingle();
  return profile as { id: string; role: string } | null;
}


const OK_HOSTS = ["facebook.com", "fb.com", "fb.watch", "fb.me"];
const hostOk = (u: URL) => OK_HOSTS.some((h) => u.hostname === h || u.hostname.endsWith("." + h));

const decode = (s: string) =>
  s.replace(/&amp;/g, "&").replace(/&quot;/g, '"').replace(/&#039;/g, "'").replace(/&#x27;/g, "'")
    .replace(/&lt;/g, "<").replace(/&gt;/g, ">").replace(/&#(\d+);/g, (_, n) => String.fromCharCode(+n));

function meta(html: string, prop: string): string | null {
  const re = new RegExp(`<meta[^>]+(?:property|name)=["']${prop}["'][^>]*>`, "i");
  const tag = html.match(re)?.[0];
  const v = tag?.match(/content=["']([^"']*)["']/i)?.[1];
  return v ? decode(v) : null;
}

function postId(u: URL): string | null {
  const p = u.pathname;
  return (
    u.searchParams.get("story_fbid") ??
    u.searchParams.get("fbid") ??
    p.match(/\/(?:posts|videos|reel|reels)\/(?:[^/]+\/)?(\d{6,})/)?.[1] ??
    p.match(/\/(\d{10,})\/?$/)?.[1] ??
    null
  );
}

async function graph(path: string, token: string) {
  const r = await fetch(`https://graph.facebook.com/v21.0/${path}${path.includes("?") ? "&" : "?"}access_token=${token}`);
  return r.ok ? await r.json() : null;
}

async function storeImage(url: string): Promise<string | null> {
  try {
    const r = await fetch(url);
    if (!r.ok) return null;
    const type = r.headers.get("content-type") ?? "image/jpeg";
    if (!/image\/(jpeg|png|webp)/.test(type)) return null;
    const bytes = new Uint8Array(await r.arrayBuffer());
    if (bytes.length > 2 * 1024 * 1024) return null; // limite du stockage : 2 Mo
    const ext = type.includes("png") ? "png" : type.includes("webp") ? "webp" : "jpg";
    const path = `articles/fb-${Date.now()}.${ext}`;
    const db = adminClient();
    const { error } = await db.storage.from("media").upload(path, bytes, { contentType: type });
    if (error) return null;
    return db.storage.from("media").getPublicUrl(path).data.publicUrl;
  } catch {
    return null;
  }
}

/** Prépare les champs de l'article à partir du texte et de la photo d'une publication. */
async function build(message: string, image: string | null, videoUrl: string | null, source: string) {
  const text = message.replace(/\r/g, "").trim();
  const firstLine = text.split("\n").find((l) => l.trim().length > 0) ?? "";
  const title = firstLine.length > 120 ? firstLine.slice(0, 117).trimEnd() + "…" : firstLine;
  const stored = image ? await storeImage(image) : null;
  return {
    title,
    summary: text.length > 220 ? text.slice(0, 217).trimEnd() + "…" : text,
    body: text,
    cover_url: stored,
    video_url: videoUrl,
    source,
    image_skipped: image != null && stored == null,
  };
}

Deno.serve(async (req) => {
  if (req.method === "OPTIONS") return new Response("ok", { headers: cors });
  const me = await caller(req);
  if (!me) return json({ error: "Connexion requise." }, 401);

  const input = await req.json().catch(() => ({}));
  const token = Deno.env.get("FB_PAGE_TOKEN");
  const pageId = Deno.env.get("FB_PAGE_ID");
  const FIELDS = "id,message,full_picture,created_time,permalink_url,attachments{media_type}";

  // Mode 1 : liste des dernières publications de la page.
  if (input.list) {
    if (!token) return json({ error: "La clé de la page Facebook n'est pas configurée." }, 400);
    const d = await graph(`${pageId ?? "me"}/posts?fields=${FIELDS}&limit=25`, token);
    if (!d) return json({ error: "Facebook a refusé la lecture de la page. Vérifiez la clé et les permissions." }, 502);
    return json({
      posts: (d.data ?? []).map((p: any) => ({
        id: p.id,
        message: p.message ?? "",
        picture: p.full_picture ?? null,
        date: p.created_time ?? null,
      })),
    });
  }

  // Mode 2 : import d'une publication choisie dans la liste.
  if (input.postId) {
    if (!token) return json({ error: "La clé de la page Facebook n'est pas configurée." }, 400);
    const p = await graph(`${String(input.postId)}?fields=${FIELDS}`, token);
    if (!p) return json({ error: "Publication introuvable." }, 404);
    const video = (p.attachments?.data ?? []).some((a: any) => a.media_type === "video");
    return json(await build(p.message ?? "", p.full_picture ?? null, video ? p.permalink_url ?? null : null, "graph"));
  }

  let link: URL;
  try {
    link = new URL(String(input.url ?? "").trim());
  } catch {
    return json({ error: "Lien invalide." }, 400);
  }
  if (!hostOk(link)) return json({ error: "Ce lien ne vient pas de Facebook." }, 400);

  // Les liens « share » sont des redirections : on les suit pour trouver la vraie adresse.
  let finalUrl = link;
  let html = "";
  try {
    const r = await fetch(link.toString(), {
      redirect: "follow",
      headers: { "User-Agent": "facebookexternalhit/1.1 (+http://www.facebook.com/externalhit_uatext.php)" },
    });
    finalUrl = new URL(r.url);
    if (finalUrl.pathname.startsWith("/login")) {
      const next = finalUrl.searchParams.get("next");
      if (next) finalUrl = new URL(next);
    }
    if (hostOk(finalUrl)) html = await r.text();
  } catch { /* on tentera quand même l'API */ }

  let message: string | null = null;
  let image: string | null = null;
  let source = "og";
  const isVideo = /\/(videos|reel|reels)\/|fb\.watch/.test(finalUrl.pathname + link.hostname);

  const pid = postId(finalUrl) ?? postId(link);
  if (token && pid) {
    const fields = "message,description,full_picture,picture";
    const candidates = [pageId ? `${pageId}_${pid}` : null, pid].filter(Boolean) as string[];
    for (const id of candidates) {
      const d = await graph(`${id}?fields=${fields}`, token);
      if (d && (d.message || d.description || d.full_picture || d.picture)) {
        message = d.message ?? d.description ?? null;
        image = d.full_picture ?? d.picture ?? null;
        source = "graph";
        break;
      }
    }
  }
  if (!message && html) {
    message = meta(html, "og:description") ?? meta(html, "description");
    image = image ?? meta(html, "og:image");
    const t = meta(html, "og:title");
    if (!message && t) message = t;
  }
  if (!message && !image) {
    return json({
      error: "Impossible de lire ce lien (Facebook le protège). Utilisez plutôt « Choisir parmi les dernières " +
        "publications de la page », ou copiez le texte à la main.",
    }, 422);
  }

  return json(await build(message ?? "", image, isVideo ? finalUrl.toString() : null, source));
});
