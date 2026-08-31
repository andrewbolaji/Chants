import { GlobalOptions } from "firebase-functions/v2/options";

// Source contract only. The account and grants need separate live approval.
export const V1_RUNTIME = {
  region: "europe-west2",
  serviceAccount: "chants-v1-runtime@chants-f95b4.iam.gserviceaccount.com",
  cpu: 1,
  memory: "256MiB",
  timeoutSeconds: 60,
  minInstances: 0,
  maxInstances: 3,
  concurrency: 20,
} as const satisfies GlobalOptions;

export const SERIAL_WORKER_RUNTIME = {
  memory: "512MiB", timeoutSeconds: 300, maxInstances: 1, concurrency: 1,
} as const satisfies GlobalOptions;

export const MEDIA_VALIDATION_RUNTIME = {
  memory: "512MiB", timeoutSeconds: 60, maxInstances: 1, concurrency: 1,
} as const satisfies GlobalOptions;

export const MONITOR_RUNTIME = {
  maxInstances: 1, concurrency: 1,
} as const satisfies GlobalOptions;
