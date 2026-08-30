import { seededChantIdValidationError } from "./chant_identity";
import { slugify, compositeSlug } from "./slugify";

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

export type CatalogueEra = "current" | "historic" | "evergreen";

export interface CatalogueMetadata {
  version: number;
  rosterSource: string;
  rosterAsOf: string;
}

export interface ChantData {
  id: string;
  title: string;
  subjectTag: string;
  playerName: string | null;
  lyrics: string;
  tuneName: string;
  contextNotes: string | null;
  chantType: string;
  mediaType: string;
  variations?: ChantVariationData[];
  era?: CatalogueEra;
  historicSubject?: string;
  reviewedAsOf?: string;
  ownerVerified?: boolean;
  sources?: string[];
}

export interface ClubData {
  team: {
    name: string;
    crestImageUrl: string | null;
  };
  squad: SquadMember[];
  chants: ChantData[];
  catalogue?: CatalogueMetadata;
}

const VALID_CATALOGUE_ERAS = ["current", "historic", "evergreen"];
const ISO_DATE_PATTERN = /^\d{4}-\d{2}-\d{2}$/;

function isHttpsUrl(value: unknown): value is string {
  if (typeof value !== "string") return false;
  try {
    const parsed = new URL(value);
    return parsed.protocol === "https:" && parsed.hostname.length > 0;
  } catch {
    return false;
  }
}

function isIsoDate(value: unknown): value is string {
  if (typeof value !== "string" || !ISO_DATE_PATTERN.test(value)) return false;
  const parsed = new Date(`${value}T00:00:00Z`);
  return !Number.isNaN(parsed.getTime()) &&
    parsed.toISOString().slice(0, 10) === value;
}

const VALID_SUBJECT_TAGS = ["player", "coach", "club", "rival"];
const VALID_MEDIA_TYPES = [
  "none", "audio", "tuneRecording", "lyricVideo", "screenRecording", "crowdClip",
];
const VALID_CHANT_TYPE = ["sincere", "novelty"];

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

  // Optional offline catalogue metadata. Legacy files remain valid, but once a
  // catalogue block is present its contract is strict.
  if (d.catalogue !== undefined) {
    const catalogue = d.catalogue as unknown;
    if (!catalogue || typeof catalogue !== "object" || Array.isArray(catalogue)) {
      errors.push({
        field: "catalogue",
        message: "catalogue must be an object.",
      });
    } else {
      const metadata = catalogue as Partial<CatalogueMetadata>;
      if (metadata.version !== 1) {
        errors.push({
          field: "catalogue.version",
          message: "catalogue.version must be 1.",
        });
      }
      if (!isHttpsUrl(metadata.rosterSource)) {
        errors.push({
          field: "catalogue.rosterSource",
          message: "catalogue.rosterSource must be an HTTPS URL.",
        });
      }
      if (!isIsoDate(metadata.rosterAsOf)) {
        errors.push({
          field: "catalogue.rosterAsOf",
          message: "catalogue.rosterAsOf must use a real YYYY-MM-DD date.",
        });
      }
    }
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
    const chantIds = new Set<string>();
    const chantTitleSlugs = new Set<string>();
    for (let i = 0; i < d.chants.length; i++) {
      const c = d.chants[i];
      const idError = seededChantIdValidationError(c.id, teamSlug);
      if (idError) {
        errors.push({ field: `chants[${i}].id`, message: idError });
      } else if (chantIds.has(c.id)) {
        errors.push({
          field: `chants[${i}].id`,
          message: `Duplicate seeded chant ID: "${c.id}".`,
        });
      }
      if (typeof c.id === "string" && c.id.length > 0) {
        chantIds.add(c.id);
      }

      if (typeof c.title !== "string" || c.title.length === 0) {
        errors.push({ field: `chants[${i}].title`, message: "Chant title is required." });
      } else if (c.title.length > 200) {
        errors.push({
          field: `chants[${i}].title`,
          message: "Chant title must be at most 200 characters.",
        });
      }
      if (!VALID_SUBJECT_TAGS.includes(c.subjectTag)) {
        errors.push({
          field: `chants[${i}].subjectTag`,
          message: `Invalid subjectTag "${c.subjectTag}". Must be one of: ${VALID_SUBJECT_TAGS.join(", ")}.`,
        });
      }
      if (typeof c.lyrics !== "string" || c.lyrics.length === 0) {
        errors.push({ field: `chants[${i}].lyrics`, message: "Lyrics are required." });
      } else if (c.lyrics.length > 5000) {
        errors.push({
          field: `chants[${i}].lyrics`,
          message: "Lyrics must be at most 5000 characters.",
        });
      }
      if (typeof c.tuneName !== "string" || c.tuneName.length === 0) {
        errors.push({ field: `chants[${i}].tuneName`, message: "Tune name is required." });
      } else if (c.tuneName.length > 200) {
        errors.push({
          field: `chants[${i}].tuneName`,
          message: "Tune name must be at most 200 characters.",
        });
      }
      if (
        c.contextNotes !== null &&
        (typeof c.contextNotes !== "string" || c.contextNotes.length > 500)
      ) {
        errors.push({
          field: `chants[${i}].contextNotes`,
          message: "Context notes must be null or at most 500 characters.",
        });
      }
      if (!VALID_CHANT_TYPE.includes(c.chantType)) {
        errors.push({
          field: `chants[${i}].chantType`,
          message: `Invalid chantType "${c.chantType}". Must be "sincere" or "novelty".`,
        });
      }
      if (!VALID_MEDIA_TYPES.includes(c.mediaType)) {
        errors.push({
          field: `chants[${i}].mediaType`,
          message: `Invalid mediaType "${c.mediaType}". Must be one of: ${VALID_MEDIA_TYPES.join(", ")}.`,
        });
      }

      if (d.catalogue !== undefined) {
        if (!c.era || !VALID_CATALOGUE_ERAS.includes(c.era)) {
          errors.push({
            field: `chants[${i}].era`,
            message: `Invalid era "${c.era}". Must be one of: ${VALID_CATALOGUE_ERAS.join(", ")}.`,
          });
        }
        if (c.ownerVerified !== true) {
          errors.push({
            field: `chants[${i}].ownerVerified`,
            message: "Catalogue chants must be owner verified.",
          });
        }
        if (
          typeof c.reviewedAsOf !== "string" ||
          !isIsoDate(c.reviewedAsOf)
        ) {
          errors.push({
            field: `chants[${i}].reviewedAsOf`,
            message: "Catalogue chants must record reviewedAsOf as YYYY-MM-DD.",
          });
        }
        if (
          !Array.isArray(c.sources) ||
          c.sources.length === 0 ||
          c.sources.some(
            (source) => !isHttpsUrl(source)
          )
        ) {
          errors.push({
            field: `chants[${i}].sources`,
            message: "Catalogue chants must have at least one HTTPS source URL.",
          });
        }
        if (c.era === "historic") {
          if (c.subjectTag !== "club" || c.playerName !== null) {
            errors.push({
              field: `chants[${i}].era`,
              message: "Historic chants must use club linkage and null playerName.",
            });
          }
          if (
            typeof c.historicSubject !== "string" ||
            c.historicSubject.length === 0
          ) {
            errors.push({
              field: `chants[${i}].historicSubject`,
              message: "Historic chants must name their historic subject.",
            });
          }
        } else if (c.historicSubject !== undefined) {
          errors.push({
            field: `chants[${i}].historicSubject`,
            message: "Only historic chants may set historicSubject.",
          });
        }
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

      // Keep duplicate-content protection separate from stable document IDs.
      if (typeof c.title === "string" && c.title.length > 0) {
        const titleSlug = slugify(c.title);
        if (chantTitleSlugs.has(titleSlug)) {
          errors.push({
            field: `chants[${i}].title`,
            message: `Duplicate chant title slug: "${titleSlug}". Two titles normalize to the same value.`,
          });
        }
        chantTitleSlugs.add(titleSlug);
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
