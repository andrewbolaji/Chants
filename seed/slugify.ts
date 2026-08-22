/**
 * Converts a string to a URL-safe slug for use as a Firestore document ID.
 * Lowercase, spaces and special chars become hyphens, accents stripped,
 * consecutive hyphens collapsed, leading/trailing hyphens removed.
 */
export function slugify(text: string): string {
  return text
    .normalize("NFD")
    .replace(/[\u0300-\u036f]/g, "")
    .toLowerCase()
    .replace(/[^a-z0-9]+/g, "-")
    .replace(/-+/g, "-")
    .replace(/^-|-$/g, "");
}

/**
 * Creates a composite slug: {prefix}-{slugified text}.
 * Used for player IDs and legacy seeded-chant compatibility checks. New seeded
 * chant IDs are explicit source data and must not be recomputed from titles.
 */
export function compositeSlug(prefix: string, text: string): string {
  return `${prefix}-${slugify(text)}`;
}
