import { strict as assert } from "assert";
import * as endpoints from "../src/index";
import { ENDPOINT_ADMISSION } from "../src/operational_control";

describe("compiled production runtime contract", () => {
  it("pins every deployed endpoint, with only the seven approved resource exceptions", () => {
    const workers = new Set(["cleanupAbandonedPerformanceDraftsJob", "onAccountDeletionJobWritten",
      "onPerformanceMediaDeletionJobWritten", "onPerformanceDraftDeleted"]);
    const uploads = new Set(["submitPerformanceDraft", "moderatePerformance"]);
    const names: string[] = [];
    for (const [name, handler] of Object.entries(endpoints)) {
      if (!("__endpoint" in handler)) continue;
      names.push(name);
      const value = handler.__endpoint;
      const serial = workers.has(name) || uploads.has(name) || name === "monitorOperationalBacklogsJob";
      assert.equal(value.serviceAccountEmail, "chants-v1-runtime@chants-f95b4.iam.gserviceaccount.com", name);
      assert.deepEqual(value.region, ["europe-west2"], name);
      assert.equal(value.platform, "gcfv2", name);
      assert.equal(value.cpu, 1, name);
      assert.equal(value.availableMemoryMb, workers.has(name) || uploads.has(name) ? 512 : 256, name);
      assert.equal(value.timeoutSeconds, workers.has(name) ? 300 : 60, name);
      assert.equal(value.minInstances, 0, name);
      assert.equal(value.maxInstances, serial ? 1 : 3, name);
      assert.equal(value.concurrency, serial ? 1 : 20, name);
    }
    assert.deepEqual(names.sort(), Object.keys(ENDPOINT_ADMISSION).sort());
    assert.equal(names.length, 48);
  });

  it("preserves event routing, retry semantics and the two schedules", () => {
    const expected: Record<string, [string, string, boolean]> = {
      onPerformanceDraftDeleted: ["deleted", "performanceDrafts/{draftId}", true],
      onPerformanceLikeWritten: ["written", "performanceLikes/{likeId}", false],
      onPerformanceViewWritten: ["written", "performanceViews/{viewId}", false],
      onPerformanceShareWritten: ["written", "performanceShares/{shareId}", false],
      onPerformanceCommentWritten: ["written", "performanceComments/{commentId}", false],
      onPerformanceWritten: ["written", "performances/{performanceId}", false],
      onChantWrittenForPerformances: ["written", "chants/{chantId}", false],
      onProfileAuthorityWrittenForPerformances: ["written", "profiles/{userId}", false],
      onPerformanceMediaDeletionJobWritten: ["written", "performanceMediaDeletionJobs/{performanceId}", true],
      onCreatorFollowWritten: ["written", "creatorFollows/{followId}", false],
      onReportCreated: ["written", "reports/{reportId}", false],
      onChantCreated: ["created", "chants/{chantId}", false],
      onVoteWritten: ["written", "votes/{voteId}", false],
      onAccountDeletionJobWritten: ["written", "accountDeletionJobs/{uid}", true],
      onCommentLikeWritten: ["written", "commentLikes/{likeId}", false],
      onCommentWritten: ["written", "comments/{commentId}", false],
      onCommentReportCreated: ["written", "commentReports/{reportId}", false],
      onUserReportCreated: ["created", "userReports/{reportId}", false],
      onUserReportDeleted: ["deleted", "userReports/{reportId}", false],
    };
    const actual: typeof expected = {};
    for (const [name, handler] of Object.entries(endpoints)) {
      if (!("__endpoint" in handler) || !("eventTrigger" in handler.__endpoint)) continue;
      const event = handler.__endpoint.eventTrigger;
      assert.ok(event, name);
      assert.deepEqual(event.eventFilters, { database: "(default)", namespace: "(default)" }, name);
      actual[name] = [event.eventType.replace("google.cloud.firestore.document.v1.", ""),
        event.eventFilterPathPatterns!.document as string, event.retry as boolean];
    }
    assert.deepEqual(actual, expected);
    const cleanup = endpoints.cleanupAbandonedPerformanceDraftsJob.__endpoint.scheduleTrigger;
    const monitor = endpoints.monitorOperationalBacklogsJob.__endpoint.scheduleTrigger;
    assert.ok(cleanup); assert.ok(monitor);
    assert.equal(cleanup.schedule, "every day 03:00");
    assert.equal(cleanup.timeZone, "UTC");
    assert.equal(cleanup.retryConfig?.retryCount, 3);
    assert.equal(monitor.schedule, "every 15 minutes");
    assert.equal(monitor.timeZone, "UTC");
  });
});
