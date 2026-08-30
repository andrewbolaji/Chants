export function assertServiceAccountProject(
  value: unknown,
  expectedProjectId: string
): asserts value is { project_id: string } {
  if (
    !value ||
    typeof value !== "object" ||
    Array.isArray(value) ||
    typeof (value as { project_id?: unknown }).project_id !== "string"
  ) {
    throw new Error("Service account is missing a project_id.");
  }
  if ((value as { project_id: string }).project_id !== expectedProjectId) {
    throw new Error(
      `Service account project does not match required project "${expectedProjectId}".`
    );
  }
}
