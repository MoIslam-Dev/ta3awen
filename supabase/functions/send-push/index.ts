// Ta3awen — push fan-out over Firebase Cloud Messaging (HTTP v1).
//
// Invoked by the `notifications_push_trg` DB trigger through pg_net, which POSTs
// `{ record: <notifications row> }` with an `x-push-secret` header. This function
// never talks to the app directly: it looks up the recipient's registered device
// tokens and asks FCM to deliver a localized OS notification.
//
// Secrets (set with `supabase secrets set`, never in the repo):
//   FCM_SERVICE_ACCOUNT   — the Firebase service-account JSON (stringified)
//   PUSH_WEBHOOK_SECRET   — must match the value stored in Vault
// SUPABASE_URL / SUPABASE_SERVICE_ROLE_KEY are injected by the platform.

interface NotifRecord {
  id: string;
  user_id: string;
  type: string;
  actor_name: string | null;
  listing_id: string | null;
  request_id: string | null;
}

interface DeviceToken {
  token: string;
  locale: string;
}

type Locale = "ar" | "en" | "fr";

// Mirror of the `notif*` strings in lib/l10n/app_*.arb. {name} is substituted
// with the actor's display name.
const STRINGS: Record<string, Record<Locale, { title: string; body: string }>> = {
  listing_claimed: {
    ar: { title: "تم حجز إعلانك", body: "قام {name} بحجز إعلانك، بانتظار تأكيد التسليم" },
    en: { title: "Your listing was reserved", body: "{name} reserved your listing, awaiting confirmation" },
    fr: { title: "Votre annonce a été réservée", body: "{name} a réservé votre annonce, en attente de confirmation" },
  },
  listing_released: {
    ar: { title: "تم إلغاء الحجز", body: "ألغى {name} حجز إعلانك، وهو متاح من جديد" },
    en: { title: "Reservation released", body: "{name} released the reservation — it's available again" },
    fr: { title: "Réservation annulée", body: "{name} a annulé la réservation — l'annonce est de nouveau disponible" },
  },
  listing_given: {
    ar: { title: "تم تأكيد التسليم", body: "أكّد {name} تسليم الغرض لك" },
    en: { title: "Delivery confirmed", body: "{name} confirmed handing the item over" },
    fr: { title: "Remise confirmée", body: "{name} a confirmé la remise de l'objet" },
  },
  request_matched: {
    ar: { title: "وجد أحدهم ما تحتاجه", body: "{name} يمكنه مساعدتك في طلبك" },
    en: { title: "Someone responded to your request", body: "{name} can help with your request" },
    fr: { title: "Quelqu'un a répondu à votre demande", body: "{name} peut vous aider pour votre demande" },
  },
  blood_matched: {
    ar: { title: "متبرع متاح", body: "{name} يستطيع التبرع بالدم — تواصل بسرعة" },
    en: { title: "A donor is available", body: "{name} can donate blood — reach out quickly" },
    fr: { title: "Un donneur est disponible", body: "{name} peut donner son sang — contactez rapidement" },
  },
  request_released: {
    ar: { title: "تم سحب المطابقة", body: "سحب {name} موافقته، والطلب مفتوح من جديد" },
    en: { title: "Match withdrawn", body: "{name} withdrew their response — the post is open again" },
    fr: { title: "Correspondance retirée", body: "{name} a retiré sa réponse — la publication est de nouveau ouverte" },
  },
  request_closed: {
    ar: { title: "تم إغلاق الطلب", body: "أغلق {name} الطلب الذي كنت مطابقاً له" },
    en: { title: "Request closed", body: "{name} closed the post you responded to" },
    fr: { title: "Demande clôturée", body: "{name} a clôturé la publication à laquelle vous avez répondu" },
  },
  report_new: {
    ar: { title: "بلاغ جديد", body: "أرسل {name} بلاغاً بانتظار المراجعة" },
    en: { title: "New report", body: "{name} filed a report awaiting review" },
    fr: { title: "Nouveau signalement", body: "{name} a envoyé un signalement en attente de traitement" },
  },
};

const SOMEONE: Record<Locale, string> = { ar: "أحد المستخدمين", en: "A user", fr: "Un utilisateur" };
const FALLBACK: Record<Locale, { title: string; body: string }> = {
  ar: { title: "إشعار جديد", body: "لديك إشعار جديد" },
  en: { title: "New notification", body: "You have a new notification" },
  fr: { title: "Nouvelle notification", body: "Vous avez une nouvelle notification" },
};

const SUPABASE_URL = Deno.env.get("SUPABASE_URL") ?? "";
const SERVICE_ROLE = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY") ?? "";
const PUSH_SECRET = Deno.env.get("PUSH_WEBHOOK_SECRET") ?? "";

const restHeaders = {
  apikey: SERVICE_ROLE,
  Authorization: `Bearer ${SERVICE_ROLE}`,
  "Content-Type": "application/json",
};

Deno.serve(async (req) => {
  if (req.method !== "POST") {
    return json({ error: "method-not-allowed" }, 405);
  }
  if (!PUSH_SECRET || req.headers.get("x-push-secret") !== PUSH_SECRET) {
    return json({ error: "unauthorized" }, 401);
  }

  let record: NotifRecord | undefined;
  try {
    record = (await req.json())?.record;
  } catch {
    /* fallthrough to validation */
  }
  if (!record?.user_id || !record?.id) {
    return json({ error: "bad-request" }, 400);
  }

  const tokens = await loadTokens(record.user_id);
  if (tokens.length === 0) {
    return json({ ok: true, delivered: 0, reason: "no-devices" });
  }

  let credentials;
  try {
    credentials = await fcmCredentials();
  } catch (e) {
    console.error("fcm-auth-failed", e);
    return json({ error: "fcm-auth-failed" }, 500);
  }

  const results = await Promise.all(
    tokens.map((d) => deliver(credentials, record!, d)),
  );
  const stale = results.filter((r) => r.stale).map((r) => r.token);
  if (stale.length > 0) await deleteTokens(stale);

  const delivered = results.filter((r) => r.ok).length;
  return json({ ok: true, delivered, staleRemoved: stale.length });
});

async function loadTokens(userId: string): Promise<DeviceToken[]> {
  const url =
    `${SUPABASE_URL}/rest/v1/device_tokens?user_id=eq.${userId}&select=token,locale`;
  const res = await fetch(url, { headers: restHeaders });
  if (!res.ok) {
    console.error("load-tokens-failed", res.status, await res.text());
    return [];
  }
  return await res.json() as DeviceToken[];
}

async function deleteTokens(tokens: string[]): Promise<void> {
  if (tokens.length === 0) return;
  const list = tokens.map((t) => `"${t}"`).join(",");
  const url = `${SUPABASE_URL}/rest/v1/device_tokens?token=in.(${list})`;
  const res = await fetch(url, { method: "DELETE", headers: restHeaders });
  if (!res.ok) console.error("prune-tokens-failed", res.status, await res.text());
}

interface Delivery { token: string; ok: boolean; stale: boolean }

async function deliver(
  credentials: { token: string; projectId: string },
  record: NotifRecord,
  device: DeviceToken,
): Promise<Delivery> {
  const locale: Locale = (["ar", "en", "fr"] as const).includes(device.locale as Locale)
    ? (device.locale as Locale)
    : "ar";
  const strings = STRINGS[record.type]?.[locale] ?? FALLBACK[locale];
  const name = (record.actor_name ?? "").trim() || SOMEONE[locale];
  const title = strings.title;
  const body = strings.body.replace("{name}", name);

  const data: Record<string, string> = { type: record.type, notification_id: record.id };
  if (record.listing_id) data.listing_id = record.listing_id;
  if (record.request_id) data.request_id = record.request_id;

  const url = `https://fcm.googleapis.com/v1/projects/${credentials.projectId}/messages:send`;
  const res = await fetch(url, {
    method: "POST",
    headers: {
      Authorization: `Bearer ${credentials.token}`,
      "Content-Type": "application/json",
    },
    body: JSON.stringify({
      message: {
        token: device.token,
        notification: { title, body },
        data,
        android: {
          priority: "high",
          notification: { channel_id: "ta3awen_default", sound: "default" },
        },
      },
    }),
  });

  if (res.ok) return { token: device.token, ok: true, stale: false };

  const text = await res.text();
  console.error("fcm-send-failed", res.status, text);
  const stale = res.status === 404 || text.includes("UNREGISTERED") || text.includes("NOT_FOUND");
  return { token: device.token, ok: false, stale };
}

// --- Google OAuth2 (service account -> access token), cached in the isolate ---

let cached: { token: string; projectId: string; expiresAt: number } | null = null;

async function fcmCredentials(): Promise<{ token: string; projectId: string }> {
  const now = Math.floor(Date.now() / 1000);
  if (cached && cached.expiresAt - 60 > now) return cached;

  const sa = JSON.parse(Deno.env.get("FCM_SERVICE_ACCOUNT") ?? "{}");
  if (!sa.client_email || !sa.private_key || !sa.project_id) {
    throw new Error("FCM_SERVICE_ACCOUNT missing or malformed");
  }

  const header = { alg: "RS256", typ: "JWT" };
  const claims = {
    iss: sa.client_email,
    scope: "https://www.googleapis.com/auth/firebase.messaging",
    aud: "https://oauth2.googleapis.com/token",
    iat: now,
    exp: now + 3600,
  };
  const unsigned = `${b64url(JSON.stringify(header))}.${b64url(JSON.stringify(claims))}`;

  const key = await crypto.subtle.importKey(
    "pkcs8",
    pemToBytes(sa.private_key),
    { name: "RSASSA-PKCS1-v1_5", hash: "SHA-256" },
    false,
    ["sign"],
  );
  const signature = await crypto.subtle.sign(
    "RSASSA-PKCS1-v1_5",
    key,
    new TextEncoder().encode(unsigned),
  );
  const assertion = `${unsigned}.${b64urlBytes(new Uint8Array(signature))}`;

  const res = await fetch("https://oauth2.googleapis.com/token", {
    method: "POST",
    headers: { "Content-Type": "application/x-www-form-urlencoded" },
    body: new URLSearchParams({
      grant_type: "urn:ietf:params:oauth:grant-type:jwt-bearer",
      assertion,
    }),
  });
  if (!res.ok) throw new Error(`token-exchange ${res.status}: ${await res.text()}`);

  const { access_token, expires_in } = await res.json();
  cached = {
    token: access_token,
    projectId: sa.project_id,
    expiresAt: now + (expires_in ?? 3600),
  };
  return cached;
}

function pemToBytes(pem: string): ArrayBuffer {
  const b64 = pem.replace(/-----[^-]+-----/g, "").replace(/\s+/g, "");
  const binary = atob(b64);
  const bytes = new Uint8Array(binary.length);
  for (let i = 0; i < binary.length; i++) bytes[i] = binary.charCodeAt(i);
  return bytes.buffer;
}

function b64url(input: string): string {
  return b64urlBytes(new TextEncoder().encode(input));
}

function b64urlBytes(bytes: Uint8Array): string {
  let binary = "";
  for (const b of bytes) binary += String.fromCharCode(b);
  return btoa(binary).replace(/\+/g, "-").replace(/\//g, "_").replace(/=+$/, "");
}

function json(body: unknown, status = 200): Response {
  return new Response(JSON.stringify(body), {
    status,
    headers: { "Content-Type": "application/json" },
  });
}
