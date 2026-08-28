import * as admin from "firebase-admin";
import { HttpsError } from "firebase-functions/v2/https";

export const PUBLIC_SHARE_ORIGIN = "https://chantsfc.com";

type PublicTargetType = "chant" | "performance" | "creator";
type PublicShareInput = { targetType: PublicTargetType; targetId: string };
type Data = admin.firestore.DocumentData;

type PublicPage = {
  status: 200 | 404;
  title: string;
  description: string;
  canonicalUrl: string;
  eyebrow: string;
  heading: string;
  detail: string;
  performanceId?: string;
};

export type PublicPerformanceMediaGateway = {
  signReadUrl: (path: string, expiresAtMs: number) => Promise<string>;
};

function isRecord(value: unknown): value is Record<string, unknown> {
  return typeof value === "object" && value !== null && !Array.isArray(value);
}

function hasExactKeys(value: Record<string, unknown>, expected: string[]): boolean {
  const keys = Object.keys(value).sort();
  const sorted = [...expected].sort();
  return keys.length === sorted.length &&
    keys.every((key, index) => key === sorted[index]);
}

function cleanId(value: unknown): string {
  return typeof value === "string" && /^[A-Za-z0-9_-]{1,200}$/.test(value)
    ? value
    : "";
}

export function parsePublicShareInput(value: unknown): PublicShareInput {
  if (!isRecord(value) || !hasExactKeys(value, ["targetId", "targetType"])) {
    throw new HttpsError("invalid-argument", "Invalid public share request.");
  }
  const targetId = cleanId(value.targetId);
  if (
    !targetId ||
    (value.targetType !== "chant" &&
      value.targetType !== "performance" &&
      value.targetType !== "creator")
  ) {
    throw new HttpsError("invalid-argument", "Invalid public share request.");
  }
  return { targetType: value.targetType, targetId };
}

function visibleChant(data: Data | undefined): data is Data {
  return !!data &&
    data.hidden === false &&
    data.removed === false &&
    typeof data.title === "string" &&
    typeof data.tuneName === "string" &&
    (data.status === "canonical" || data.status === "community");
}

function visiblePerformance(
  data: Data | undefined,
  performanceId: string
): data is Data {
  return !!data &&
    data.schemaVersion === 1 &&
    data.publicationState === "approved" &&
    data.hidden === false &&
    data.removed === false &&
    typeof data.chantTitle === "string" &&
    typeof data.creatorDisplayName === "string" &&
    typeof data.teamName === "string" &&
    data.mediaPath === `performance-media/${performanceId}/source` &&
    (data.chantStatus === "canonical" || data.chantStatus === "community");
}

function visibleCreator(data: Data | undefined): data is Data {
  return !!data &&
    data.hidden === false &&
    data.removed === false &&
    typeof data.handle === "string" &&
    typeof data.displayName === "string";
}

export async function handleResolvePublicShareDestination(params: {
  data: unknown;
  firestore: admin.firestore.Firestore;
}): Promise<{ url: string }> {
  const input = parsePublicShareInput(params.data);
  if (input.targetType === "chant") {
    const snapshot = await params.firestore
      .collection("chants")
      .doc(input.targetId)
      .get();
    if (!visibleChant(snapshot.data())) {
      throw new HttpsError("not-found", "This chant is unavailable.");
    }
    return { url: `${PUBLIC_SHARE_ORIGIN}/chants/${input.targetId}` };
  }
  if (input.targetType === "performance") {
    const snapshot = await params.firestore
      .collection("performances")
      .doc(input.targetId)
      .get();
    if (!visiblePerformance(snapshot.data(), input.targetId)) {
      throw new HttpsError("not-found", "This performance is unavailable.");
    }
    return { url: `${PUBLIC_SHARE_ORIGIN}/performances/${input.targetId}` };
  }
  const snapshot = await params.firestore
    .collection("creatorProfiles")
    .doc(input.targetId)
    .get();
  const creator = snapshot.data();
  if (!visibleCreator(creator)) {
    throw new HttpsError("not-found", "This creator is unavailable.");
  }
  return { url: `${PUBLIC_SHARE_ORIGIN}/creators/${creator.handle}` };
}

function htmlEscape(value: string): string {
  return value
    .replace(/&/g, "&amp;")
    .replace(/</g, "&lt;")
    .replace(/>/g, "&gt;")
    .replace(/"/g, "&quot;")
    .replace(/'/g, "&#39;");
}

function trustLabel(status: unknown): string {
  return status === "canonical" ? "Terrace Proven" : "Chant Lab";
}

function notFoundPage(): PublicPage {
  return {
    status: 404,
    title: "Not available | Chants",
    description: "This Chants link is no longer available.",
    canonicalUrl: PUBLIC_SHARE_ORIGIN,
    eyebrow: "Chants",
    heading: "This link is not available",
    detail: "It may have been removed, hidden, or typed incorrectly.",
  };
}

async function pageForChant(
  id: string,
  firestore: admin.firestore.Firestore
): Promise<PublicPage> {
  const chantSnapshot = await firestore.collection("chants").doc(id).get();
  const chant = chantSnapshot.data();
  if (!visibleChant(chant)) return notFoundPage();
  const teamSnapshot = typeof chant.teamId === "string"
    ? await firestore.collection("teams").doc(chant.teamId).get()
    : undefined;
  const teamName = teamSnapshot?.data()?.name;
  const subject = typeof teamName === "string" ? teamName : "football supporters";
  const trust = trustLabel(chant.status);
  return {
    status: 200,
    title: `${chant.title} | Chants`,
    description: `${trust} chant for ${subject}. Tune: ${chant.tuneName}.`,
    canonicalUrl: `${PUBLIC_SHARE_ORIGIN}/chants/${id}`,
    eyebrow: trust,
    heading: chant.title,
    detail: `${subject} · Tune: ${chant.tuneName}`,
  };
}

async function pageForPerformance(
  id: string,
  firestore: admin.firestore.Firestore
): Promise<PublicPage> {
  const snapshot = await firestore.collection("performances").doc(id).get();
  const performance = snapshot.data();
  if (!visiblePerformance(performance, id)) return notFoundPage();
  const trust = trustLabel(performance.chantStatus);
  return {
    status: 200,
    title: `${performance.creatorDisplayName} performs ${performance.chantTitle} | Chants`,
    description: `${trust} performance for ${performance.teamName} on Chants.`,
    canonicalUrl: `${PUBLIC_SHARE_ORIGIN}/performances/${id}`,
    eyebrow: `${trust} performance`,
    heading: performance.chantTitle,
    detail: `Performed by ${performance.creatorDisplayName} for ${performance.teamName}`,
    performanceId: id,
  };
}

export function performanceIdFromPublicMediaPath(path: string): string {
  const segments = path.split("/").filter(Boolean);
  if (
    segments.length !== 3 ||
    segments[0] !== "media" ||
    segments[1] !== "performances"
  ) {
    return "";
  }
  return cleanId(segments[2]);
}

export async function handleResolvePublicPerformanceMedia(params: {
  performanceId: string;
  firestore: admin.firestore.Firestore;
  media: PublicPerformanceMediaGateway;
  nowMs: () => number;
}): Promise<{ url: string; expiresAtMs: number }> {
  const performanceId = cleanId(params.performanceId);
  if (!performanceId) {
    throw new HttpsError("not-found", "This performance is unavailable.");
  }
  const snapshot = await params.firestore
    .collection("performances")
    .doc(performanceId)
    .get();
  const performance = snapshot.data();
  if (!visiblePerformance(performance, performanceId)) {
    throw new HttpsError("not-found", "This performance is unavailable.");
  }
  const expiresAtMs = params.nowMs() + 2 * 60 * 1000;
  const url = await params.media.signReadUrl(
    performance.mediaPath as string,
    expiresAtMs
  );
  return { url, expiresAtMs };
}

async function pageForCreator(
  handle: string,
  firestore: admin.firestore.Firestore
): Promise<PublicPage> {
  const snapshot = await firestore
    .collection("creatorProfiles")
    .where("handle", "==", handle)
    .where("hidden", "==", false)
    .where("removed", "==", false)
    .limit(1)
    .get();
  const creator = snapshot.docs[0]?.data();
  if (!visibleCreator(creator)) return notFoundPage();
  return {
    status: 200,
    title: `${creator.displayName} (@${creator.handle}) | Chants`,
    description: `See ${creator.displayName}'s chant performances and ideas on Chants.`,
    canonicalUrl: `${PUBLIC_SHARE_ORIGIN}/creators/${creator.handle}`,
    eyebrow: `@${creator.handle}`,
    heading: creator.displayName,
    detail: "Creator on Chants",
  };
}

export async function resolvePublicPage(params: {
  path: string;
  firestore: admin.firestore.Firestore;
}): Promise<PublicPage> {
  const segments = params.path.split("/").filter(Boolean);
  if (segments.length !== 2) return notFoundPage();
  const id = cleanId(segments[1]);
  if (!id) return notFoundPage();
  if (segments[0] === "chants") return pageForChant(id, params.firestore);
  if (segments[0] === "performances") {
    return pageForPerformance(id, params.firestore);
  }
  if (segments[0] === "creators") return pageForCreator(id, params.firestore);
  return notFoundPage();
}

export function renderPublicPage(page: PublicPage): string {
  const title = htmlEscape(page.title);
  const description = htmlEscape(page.description);
  const canonicalUrl = htmlEscape(page.canonicalUrl);
  const eyebrow = htmlEscape(page.eyebrow);
  const heading = htmlEscape(page.heading);
  const detail = htmlEscape(page.detail);
  const image = `${PUBLIC_SHARE_ORIGIN}/share/og-default.png`;
  const performanceMedia = page.performanceId
    ? `<video controls playsinline preload="metadata" poster="${image}"
    aria-label="Watch ${heading} on Chants"><source
    src="${PUBLIC_SHARE_ORIGIN}/media/performances/${htmlEscape(page.performanceId)}"
    type="video/mp4">Your browser cannot play this performance.</video>`
    : "";
  return `<!doctype html>
<html lang="en">
<head>
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width,initial-scale=1">
  <title>${title}</title>
  <meta name="description" content="${description}">
  <link rel="canonical" href="${canonicalUrl}">
  <meta property="og:type" content="website">
  <meta property="og:site_name" content="Chants">
  <meta property="og:title" content="${title}">
  <meta property="og:description" content="${description}">
  <meta property="og:url" content="${canonicalUrl}">
  <meta property="og:image" content="${image}">
  <meta name="twitter:card" content="summary">
  <meta name="twitter:title" content="${title}">
  <meta name="twitter:description" content="${description}">
  <meta name="twitter:image" content="${image}">
  <style>
    :root{color-scheme:dark}*{box-sizing:border-box}body{margin:0;min-height:100vh;
    display:grid;place-items:center;background:#060606;color:#f5f1e8;font-family:Arial,sans-serif}
    main{width:min(640px,calc(100% - 32px));border:1px solid #3b3526;background:#161616;
    padding:40px;border-radius:20px;box-shadow:0 24px 80px #0008}.mark{color:#ffc02e;
    font-weight:900;letter-spacing:.12em;text-transform:uppercase;font-size:12px}h1{font-size:
    clamp(36px,9vw,72px);line-height:.96;margin:18px 0;text-transform:uppercase}p{color:#c7c1b6;
    font-size:18px;line-height:1.55}.trust{color:#ffc02e;font-weight:800;text-transform:uppercase}
    video{display:block;width:100%;max-height:70vh;aspect-ratio:4/5;object-fit:contain;
    margin:24px 0;background:#050505;border-radius:14px}
    a{display:inline-block;margin-top:24px;padding:14px 18px;border-radius:10px;background:#ffc02e;
    color:#17130a;text-decoration:none;font-weight:900}</style>
</head>
<body><main><div class="mark">Chants · ${eyebrow}</div><h1>${heading}</h1>
<p>${detail}</p>${performanceMedia}<p class="trust">The songbook, the workshop, and the stage.</p>
<a href="${PUBLIC_SHARE_ORIGIN}">Open Chants</a></main></body></html>`;
}
