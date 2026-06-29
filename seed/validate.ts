export interface SportData {
  name: string;
  enabled: boolean;
}

export interface CompetitionData {
  sportId: string;
  name: string;
  enabled: boolean;
}

export interface SquadMember {
  name: string;
}

export interface ChantVariationData {
  label: string;
  lyric: string;
  contextNote?: string;
}

export interface ChantData {
  title: string;
  subjectTag: string;
  playerName: string | null;
  lyrics: string;
  tuneName: string;
  contextNotes: string | null;
  realOrParody: string;
  mediaType: string;
  variations?: ChantVariationData[];
}

export interface ClubData {
  team: {
    name: string;
    crestImageUrl: string | null;
  };
  squad: SquadMember[];
  chants: ChantData[];
}

const VALID_SUBJECT_TAGS = ["player", "coach", "club", "rival"];
const VALID_MEDIA_TYPES = [
  "none", "audio", "tuneRecording", "lyricVideo", "screenRecording", "crowdClip",
];
const VALID_REAL_OR_PARODY = ["real", "parody"];

export interface ValidationError {
  field: string;
  message: string;
}

export function validateSport(data: unknown): ValidationError[] {
  const errors: ValidationError[] = [];
  const d = data as Record<string, unknown>;
  if (!d || typeof d.name !== "string" || d.name.length === 0) {
    errors.push({ field: "name", message: "Sport name is required." });
  }
  if (typeof d.enabled !== "boolean") {
    errors.push({ field: "enabled", message: "enabled must be a boolean." });
  }
  return errors;
}

export function validateCompetition(data: unknown): ValidationError[] {
  const errors: ValidationError[] = [];
  const d = data as Record<string, unknown>;
  if (!d || typeof d.sportId !== "string" || d.sportId.length === 0) {
    errors.push({ field: "sportId", message: "sportId is required." });
  }
  if (typeof d.name !== "string" || d.name.length === 0) {
    errors.push({ field: "name", message: "Competition name is required." });
  }
  if (typeof d.enabled !== "boolean") {
    errors.push({ field: "enabled", message: "enabled must be a boolean." });
  }
  return errors;
}

import { slugify, compositeSlug } from "./slugify";

export function validateClub(
  data: unknown,
  teamSlug: string
): ValidationError[] {
  const errors: ValidationError[] = [];
  const d = data as ClubData;

  if (!d) {
    errors.push({ field: "root", message: "Club data is empty." });
    return errors;
  }

  // Team
  if (!d.team || typeof d.team.name !== "string" || d.team.name.length === 0) {
    errors.push({ field: "team.name", message: "Team name is required." });
  }

  // Squad
  if (!Array.isArray(d.squad) || d.squad.length === 0) {
    errors.push({ field: "squad", message: "At least one squad member is required." });
  } else {
    const playerSlugs = new Set<string>();
    for (let i = 0; i < d.squad.length; i++) {
      const p = d.squad[i];
      if (typeof p.name !== "string" || p.name.length === 0) {
        errors.push({ field: `squad[${i}].name`, message: "Player name is required." });
      }
      // Fix C: dedup on computed slug, not raw name
      if (p.name) {
        const pSlug = compositeSlug(teamSlug, p.name);
        if (playerSlugs.has(pSlug)) {
          errors.push({
            field: `squad[${i}].name`,
            message: `Duplicate player slug: "${pSlug}". Two names slugify to the same ID.`,
          });
        }
        playerSlugs.add(pSlug);
      }
    }
  }

  // Chants
  if (!Array.isArray(d.chants) || d.chants.length === 0) {
    errors.push({ field: "chants", message: "At least one chant is required." });
  } else {
    const squadNames = new Set((d.squad || []).map((p) => p.name));
    const chantSlugs = new Set<string>();
    for (let i = 0; i < d.chants.length; i++) {
      const c = d.chants[i];
      if (typeof c.title !== "string" || c.title.length === 0) {
        errors.push({ field: `chants[${i}].title`, message: "Chant title is required." });
      }
      if (!VALID_SUBJECT_TAGS.includes(c.subjectTag)) {
        errors.push({
          field: `chants[${i}].subjectTag`,
          message: `Invalid subjectTag "${c.subjectTag}". Must be one of: ${VALID_SUBJECT_TAGS.join(", ")}.`,
        });
      }
      if (typeof c.lyrics !== "string" || c.lyrics.length === 0) {
        errors.push({ field: `chants[${i}].lyrics`, message: "Lyrics are required." });
      }
      if (typeof c.tuneName !== "string" || c.tuneName.length === 0) {
        errors.push({ field: `chants[${i}].tuneName`, message: "Tune name is required." });
      }
      if (!VALID_REAL_OR_PARODY.includes(c.realOrParody)) {
        errors.push({
          field: `chants[${i}].realOrParody`,
          message: `Invalid realOrParody "${c.realOrParody}". Must be "real" or "parody".`,
        });
      }
      if (!VALID_MEDIA_TYPES.includes(c.mediaType)) {
        errors.push({
          field: `chants[${i}].mediaType`,
          message: `Invalid mediaType "${c.mediaType}". Must be one of: ${VALID_MEDIA_TYPES.join(", ")}.`,
        });
      }

      // subjectTag / playerName consistency
      if (c.subjectTag === "player") {
        if (!c.playerName || c.playerName.length === 0) {
          errors.push({
            field: `chants[${i}].playerName`,
            message: "Player chants must have a playerName.",
          });
        } else if (!squadNames.has(c.playerName)) {
          errors.push({
            field: `chants[${i}].playerName`,
            message: `playerName "${c.playerName}" does not match any squad member.`,
          });
        }
      } else {
        if (c.playerName != null) {
          errors.push({
            field: `chants[${i}].playerName`,
            message: `Non-player chants (subjectTag "${c.subjectTag}") must have null playerName.`,
          });
        }
      }

      // Fix C: dedup on computed slug, not raw title
      if (c.title) {
        const cSlug = compositeSlug(teamSlug, c.title);
        if (chantSlugs.has(cSlug)) {
          errors.push({
            field: `chants[${i}].title`,
            message: `Duplicate chant slug: "${cSlug}". Two titles slugify to the same ID.`,
          });
        }
        chantSlugs.add(cSlug);
      }

      // Variations (optional)
      if (c.variations !== undefined && c.variations !== null) {
        if (!Array.isArray(c.variations)) {
          errors.push({
            field: `chants[${i}].variations`,
            message: "variations must be an array.",
          });
        } else {
          for (let j = 0; j < c.variations.length; j++) {
            const v = c.variations[j];
            if (typeof v.label !== "string" || v.label.length === 0) {
              errors.push({
                field: `chants[${i}].variations[${j}].label`,
                message: "Variation label is required.",
              });
            }
            if (typeof v.lyric !== "string" || v.lyric.length === 0) {
              errors.push({
                field: `chants[${i}].variations[${j}].lyric`,
                message: "Variation lyric is required.",
              });
            }
          }
        }
      }
    }
  }

  return errors;
}
