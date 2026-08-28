import { describe, it } from "mocha";
import * as assert from "assert";
import * as admin from "firebase-admin";
import {
  handleResolvePublicShareDestination,
  handleResolvePublicPerformanceMedia,
  parsePublicShareInput,
  performanceIdFromPublicMediaPath,
  renderPublicPage,
  resolvePublicPage,
} from "../src/public_share";

type Data = Record<string, unknown>;

class FirestoreHarness {
  private readonly store = new Map<string, Map<string, Data>>();

  readonly firestore = {
    collection: (name: string) => this.collection(name),
  } as unknown as admin.firestore.Firestore;

  set(collection: string, id: string, data: Data): void {
    let values = this.store.get(collection);
    if (!values) {
      values = new Map<string, Data>();
      this.store.set(collection, values);
    }
    values.set(id, { ...data });
  }

  private values(collection: string): Array<[string, Data]> {
    return [...(this.store.get(collection)?.entries() ?? [])];
  }

  private collection(name: string) {
    const filters: Array<[string, unknown]> = [];
    const query = {
      where: (field: string, operator: string, value: unknown) => {
        if (operator !== "==") throw new Error("Unsupported query operator.");
        filters.push([field, value]);
        return query;
      },
      limit: (_count: number) => query,
      get: async () => ({
        docs: this.values(name)
          .filter(([, data]) => filters.every(([field, value]) =>
            data[field] === value
          ))
          .map(([id, data]) => ({ id, data: () => ({ ...data }) })),
      }),
    };
    return {
      doc: (id: string) => ({
        get: async () => {
          const data = this.store.get(name)?.get(id);
          return { exists: !!data, data: () => data ? { ...data } : undefined };
        },
      }),
      where: query.where,
    };
  }
}

function visibleChant(overrides: Data = {}): Data {
  return {
    title: "Super <Saka>",
    tuneName: "Traditional & loud",
    teamId: "arsenal",
    status: "community",
    hidden: false,
    removed: false,
    ...overrides,
  };
}

function visiblePerformance(overrides: Data = {}): Data {
  return {
    schemaVersion: 1,
    publicationState: "approved",
    hidden: false,
    removed: false,
    chantTitle: "Super Saka",
    creatorDisplayName: "North Bank Leo",
    teamName: "Arsenal",
    chantStatus: "community",
    mediaPath: "performance-media/performance-1/source",
    ...overrides,
  };
}

describe("public share destinations", () => {
  it("accepts only exact safe target requests", () => {
    assert.deepStrictEqual(parsePublicShareInput({
      targetType: "performance",
      targetId: "performance-1",
    }), {
      targetType: "performance",
      targetId: "performance-1",
    });
    for (const payload of [
      { targetType: "unknown", targetId: "one" },
      { targetType: "chant", targetId: "bad/path" },
      { targetType: "chant", targetId: "one", uid: "private" },
    ]) {
      assert.throws(
        () => parsePublicShareInput(payload),
        (error: { code?: string }) => error.code === "invalid-argument"
      );
    }
  });

  it("resolves only a currently visible target to the stable domain", async () => {
    const db = new FirestoreHarness();
    db.set("chants", "chant-1", visibleChant());
    db.set("performances", "performance-1", visiblePerformance());
    db.set("creatorProfiles", "creator-1", {
      handle: "northbankleo",
      displayName: "North Bank Leo",
      hidden: false,
      removed: false,
    });

    assert.deepStrictEqual(await handleResolvePublicShareDestination({
      data: { targetType: "chant", targetId: "chant-1" },
      firestore: db.firestore,
    }), { url: "https://chantsfc.com/chants/chant-1" });
    assert.deepStrictEqual(await handleResolvePublicShareDestination({
      data: { targetType: "performance", targetId: "performance-1" },
      firestore: db.firestore,
    }), { url: "https://chantsfc.com/performances/performance-1" });
    assert.deepStrictEqual(await handleResolvePublicShareDestination({
      data: { targetType: "creator", targetId: "creator-1" },
      firestore: db.firestore,
    }), { url: "https://chantsfc.com/creators/northbankleo" });

    db.set("performances", "performance-1", visiblePerformance({ hidden: true }));
    await assert.rejects(handleResolvePublicShareDestination({
      data: { targetType: "performance", targetId: "performance-1" },
      firestore: db.firestore,
    }), (error: { code?: string }) => error.code === "not-found");
  });

  it("renders escaped social metadata without lyrics, bio, or private IDs", async () => {
    const db = new FirestoreHarness();
    db.set("chants", "chant-1", visibleChant({
      lyrics: "Do not place me in social metadata.",
      createdBy: "private-user-id",
    }));
    db.set("teams", "arsenal", { name: 'Arsenal "Women"' });

    const page = await resolvePublicPage({
      path: "/chants/chant-1",
      firestore: db.firestore,
    });
    const html = renderPublicPage(page);

    assert.strictEqual(page.status, 200);
    assert.ok(html.includes("Super &lt;Saka&gt;"));
    assert.ok(html.includes("Arsenal &quot;Women&quot;"));
    assert.ok(html.includes("og:title"));
    assert.ok(html.includes("https://chantsfc.com/share/og-default.png"));
    assert.strictEqual(html.includes("Do not place me"), false);
    assert.strictEqual(html.includes("private-user-id"), false);
  });

  it("returns the same non-identifying 404 for missing and hidden content", async () => {
    const db = new FirestoreHarness();
    db.set("chants", "hidden", visibleChant({ hidden: true }));

    const hidden = await resolvePublicPage({
      path: "/chants/hidden",
      firestore: db.firestore,
    });
    const missing = await resolvePublicPage({
      path: "/chants/missing",
      firestore: db.firestore,
    });

    assert.strictEqual(hidden.status, 404);
    assert.deepStrictEqual(hidden, missing);
  });

  it("renders a controlled public performance player without autoplay", async () => {
    const db = new FirestoreHarness();
    db.set("performances", "performance-1", visiblePerformance());

    const page = await resolvePublicPage({
      path: "/performances/performance-1",
      firestore: db.firestore,
    });
    const html = renderPublicPage(page);

    assert.strictEqual(page.status, 200);
    assert.ok(html.includes("<video controls playsinline"));
    assert.ok(html.includes(
      "https://chantsfc.com/media/performances/performance-1"
    ));
    assert.strictEqual(html.includes("autoplay"), false);
    assert.strictEqual(html.includes("performance-media/"), false);
  });

  it("mints short public media only after a current visibility check", async () => {
    const db = new FirestoreHarness();
    db.set("performances", "performance-1", visiblePerformance());
    const signed: Array<[string, number]> = [];

    assert.strictEqual(
      performanceIdFromPublicMediaPath("/media/performances/performance-1"),
      "performance-1"
    );
    assert.strictEqual(
      performanceIdFromPublicMediaPath("/media/performances/bad/path"),
      ""
    );
    const result = await handleResolvePublicPerformanceMedia({
      performanceId: "performance-1",
      firestore: db.firestore,
      media: {
        signReadUrl: async (path, expiresAtMs) => {
          signed.push([path, expiresAtMs]);
          return "https://signed.example.test/public-performance";
        },
      },
      nowMs: () => 1_000,
    });
    assert.deepStrictEqual(result, {
      url: "https://signed.example.test/public-performance",
      expiresAtMs: 121_000,
    });
    assert.deepStrictEqual(signed, [[
      "performance-media/performance-1/source",
      121_000,
    ]]);

    db.set("performances", "performance-1", visiblePerformance({ removed: true }));
    await assert.rejects(handleResolvePublicPerformanceMedia({
      performanceId: "performance-1",
      firestore: db.firestore,
      media: { signReadUrl: async () => "https://should-not-run.test" },
      nowMs: () => 1_000,
    }), (error: { code?: string }) => error.code === "not-found");
  });
});
