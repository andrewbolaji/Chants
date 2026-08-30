import { ChantData } from "./validate";

export const CHANT_CONTENT_FIELDS = [
  "title",
  "lyrics",
  "tuneName",
  "contextNotes",
  "subjectTag",
  "playerId",
  "chantType",
  "mediaType",
  "coverImageUrl",
  "mediaUrl",
  "variations",
  "origin",
];

interface BuildSeededChantDataOptions {
  chant: ChantData;
  sportSlug: string;
  competitionSlug: string;
  teamSlug: string;
  playerId: string | null;
  timestamp: unknown;
}

export function buildSeededChantData({
  chant,
  sportSlug,
  competitionSlug,
  teamSlug,
  playerId,
  timestamp,
}: BuildSeededChantDataOptions): Record<string, unknown> {
  return {
    title: chant.title,
    sportId: sportSlug,
    competitionId: competitionSlug,
    teamId: teamSlug,
    playerId,
    subjectTag: chant.subjectTag,
    lyrics: chant.lyrics,
    tuneName: chant.tuneName,
    contextNotes: chant.contextNotes ?? null,
    coverImageUrl: null,
    mediaUrl: null,
    mediaType: chant.mediaType,
    status: "canonical",
    chantType: chant.chantType,
    variations: chant.variations ?? [],
    origin: "alreadySung",
    upvotes: 0,
    downvotes: 0,
    score: 0,
    commentCount: 0,
    createdBy: "system",
    createdAt: timestamp,
    updatedAt: timestamp,
    flagCount: 0,
    hidden: false,
    removed: false,
  };
}
