import { createClient } from "https://esm.sh/@supabase/supabase-js@2.45.4";

export const cors = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
};

export function json(body: unknown, status = 200) {
  return new Response(JSON.stringify(body), {
    status,
    headers: { ...cors, "Content-Type": "application/json" },
  });
}

/** Client « admin » (clé service, jamais exposée au navigateur). */
export function adminClient() {
  return createClient(
    Deno.env.get("SUPABASE_URL")!,
    Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!,
  );
}

/** Identifie l'appelant à partir de son jeton de connexion et renvoie son profil. */
export async function caller(req: Request) {
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
