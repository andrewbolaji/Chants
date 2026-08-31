// The operator repair and live triggers share the exact pending definition.
export function pendingReportCount(reports: Iterable<{ status?: unknown }>): number {
  let count = 0;
  for (const report of reports) if (report.status === "pending") count++;
  return count;
}

export function reportAutoHide(count: number, hidden: unknown): boolean {
  return count >= 3 && hidden === false;
}
