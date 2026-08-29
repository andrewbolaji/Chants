import { pathToFileURL } from "node:url";
import { resolve } from "node:path";

const fingerprintPattern = /^(?:[0-9A-F]{2}:){31}[0-9A-F]{2}$/;

export function buildAssetLinks(fingerprints) {
  const uniqueFingerprints = [...new Set(fingerprints)];
  if (uniqueFingerprints.length === 0) {
    throw new Error("Supply at least one trusted Android SHA-256 fingerprint.");
  }
  for (const fingerprint of uniqueFingerprints) {
    if (!fingerprintPattern.test(fingerprint)) {
      throw new Error("Every Android fingerprint must be uppercase SHA-256.");
    }
  }
  return [
    {
      relation: ["delegate_permission/common.handle_all_urls"],
      target: {
        namespace: "android_app",
        package_name: "com.chants.chants",
        sha256_cert_fingerprints: uniqueFingerprints,
      },
    },
  ];
}

const invokedPath = process.argv[1] ? pathToFileURL(resolve(process.argv[1])).href : "";
if (invokedPath === import.meta.url) {
  try {
    process.stdout.write(`${JSON.stringify(buildAssetLinks(process.argv.slice(2)), null, 2)}\n`);
  } catch (error) {
    process.stderr.write(`${error instanceof Error ? error.message : "Asset Links failed."}\n`);
    process.exitCode = 1;
  }
}
