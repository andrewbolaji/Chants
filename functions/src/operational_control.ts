// Pure shared policy: importing this module performs no Firebase access.
export type OperationalControl = {
  schemaVersion: 1;
  generation: number;
  mode: "maintenance" | "core" | "media";
  destructiveWorkersEnabled: boolean;
};

export function parseOperationalControl(value: unknown): OperationalControl | null {
  if (!value || typeof value !== "object" || Array.isArray(value)) return null;
  const data = value as Record<string, unknown>;
  const keys = Object.keys(data).sort().join(",");
  if (keys !== "destructiveWorkersEnabled,generation,mode,schemaVersion" ||
      data.schemaVersion !== 1 || !Number.isSafeInteger(data.generation) ||
      (data.generation as number) < 1 ||
      !["maintenance", "core", "media"].includes(data.mode as string) ||
      typeof data.destructiveWorkersEnabled !== "boolean" ||
      (data.mode === "media" && !data.destructiveWorkersEnabled)) return null;
  return data as OperationalControl;
}

export type AdmissionClass = "core" | "media" | "workers" | "public-target" |
  "reconciler" | "monitor" | "disabled";

// Exact exported endpoint population. Tests compare compiled __endpoint values.
export const ENDPOINT_ADMISSION = {
  cleanupAbandonedPerformanceDraftsJob: "workers",
  monitorOperationalBacklogsJob: "monitor",
  submitReport: "public-target",
  submitFeedback: "core",
  submitChantUpdateSuggestion: "core",
  moderateChantUpdateSuggestion: "core",
  updateCreatorProfile: "core",
  setCreatorFollow: "core",
  markCreatorNotificationRead: "core",
  moderatePublishedPerformance: "media",
  resolvePublicShareDestination: "public-target",
  publicSharePage: "public-target",
  publicPerformanceMedia: "media",
  createPerformanceDraft: "media",
  submitPerformanceDraft: "media",
  cancelPerformanceDraft: "media",
  moderatePerformance: "media",
  resolvePerformancePlayback: "media",
  setPerformanceLike: "media",
  recordPerformanceShare: "media",
  recordQualifiedPerformanceView: "media",
  createPerformanceComment: "media",
  deletePerformanceComment: "media",
  resolvePerformanceDraftPlayback: "media",
  onPerformanceDraftDeleted: "workers",
  onPerformanceLikeWritten: "reconciler",
  onPerformanceViewWritten: "reconciler",
  onPerformanceShareWritten: "reconciler",
  onPerformanceCommentWritten: "reconciler",
  onPerformanceWritten: "reconciler",
  onChantWrittenForPerformances: "reconciler",
  onProfileAuthorityWrittenForPerformances: "reconciler",
  onPerformanceMediaDeletionJobWritten: "workers",
  onCreatorFollowWritten: "reconciler",
  onReportCreated: "reconciler",
  onModerationAction: "core",
  onChantCreated: "reconciler",
  onVoteWritten: "reconciler",
  deleteAccount: "workers",
  onAccountDeletionJobWritten: "workers",
  acceptPolicy: "core",
  completeOnboarding: "core",
  mergeChants: "disabled",
  onCommentLikeWritten: "reconciler",
  onCommentWritten: "reconciler",
  onCommentReportCreated: "reconciler",
  onUserReportCreated: "reconciler",
  onUserReportDeleted: "reconciler",
} as const satisfies Record<string, AdmissionClass>;

export type EndpointName = keyof typeof ENDPOINT_ADMISSION;

export function admissionAllowed(
  classification: AdmissionClass,
  control: OperationalControl | null,
  performanceTarget = false,
): boolean {
  if (classification === "monitor" || classification === "reconciler") return true;
  if (classification === "disabled" || !control || control.mode === "maintenance") return false;
  if (classification === "workers") return control.destructiveWorkersEnabled;
  if (classification === "media" || (classification === "public-target" && performanceTarget)) {
    return control.mode === "media";
  }
  return true;
}
