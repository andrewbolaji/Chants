import {
  initializeTestEnvironment,
  assertSucceeds,
  assertFails,
  RulesTestEnvironment,
} from "@firebase/rules-unit-testing";
import { readFileSync } from "fs";
import { resolve } from "path";
import { Timestamp, setDoc, getDoc, doc, collection, addDoc, updateDoc, deleteDoc, deleteField, query, where, getDocs } from "firebase/firestore";

const PROJECT_ID = "chants-test";

let testEnv: RulesTestEnvironment;

before(async () => {
  testEnv = await initializeTestEnvironment({
    projectId: PROJECT_ID,
    firestore: {
      rules: readFileSync(resolve(__dirname, "../firestore.rules"), "utf8"),
      host: "127.0.0.1",
      port: 8080,
    },
  });
});

afterEach(async () => {
  await testEnv.clearFirestore();
});

after(async () => {
  await testEnv.cleanup();
});

// Helper to seed an operator profile via admin context
async function seedOperator(uid: string) {
  const admin = testEnv.unauthenticatedContext();
  // Use admin bypass to seed profile
  await testEnv.withSecurityRulesDisabled(async (context) => {
    const db = context.firestore();
    await setDoc(doc(db, "profiles", uid), {
      displayName: "Operator",
      role: "operator",
      banned: false,
      ageConfirmed17Plus: true,
      userReportCount: 0,
      acceptedPolicyVersion: "v1",
      acceptedPolicyAt: Timestamp.now(),
      createdAt: Timestamp.now(),
      updatedAt: Timestamp.now(),
    });
  });
}

// Fully onboarded: age-confirmed and policy-accepted, same as any real user
// past sign-up. Tests that specifically exercise the age or policy gate use
// seedUserProfileNoPolicyAcceptance or a direct setDoc instead.
async function seedUserProfile(uid: string) {
  await testEnv.withSecurityRulesDisabled(async (context) => {
    const db = context.firestore();
    await setDoc(doc(db, "profiles", uid), {
      displayName: "TestUser",
      role: "user",
      banned: false,
      ageConfirmed17Plus: true,
      userReportCount: 0,
      acceptedPolicyVersion: "v1",
      acceptedPolicyAt: Timestamp.now(),
      createdAt: Timestamp.now(),
      updatedAt: Timestamp.now(),
    });
  });
}

async function seedBannedUser(uid: string) {
  await testEnv.withSecurityRulesDisabled(async (context) => {
    const db = context.firestore();
    await setDoc(doc(db, "profiles", uid), {
      displayName: "BannedUser",
      role: "user",
      banned: true,
      ageConfirmed17Plus: true,
      userReportCount: 0,
      acceptedPolicyVersion: "v1",
      acceptedPolicyAt: Timestamp.now(),
      createdAt: Timestamp.now(),
      updatedAt: Timestamp.now(),
    });
  });
}

async function seedTeam(
  teamId = "t1",
  sportId = "s1",
  competitionId = "c1",
) {
  await testEnv.withSecurityRulesDisabled(async (context) => {
    const db = context.firestore();
    await setDoc(doc(db, "teams", teamId), {
      sportId,
      competitionId,
      name: "Test Team",
      crestImageUrl: null,
    });
  });
}

async function seedPlayer(playerId: string, teamId: string) {
  await testEnv.withSecurityRulesDisabled(async (context) => {
    const db = context.firestore();
    await setDoc(doc(db, "players", playerId), {
      teamId,
      name: "Test Player",
    });
  });
}

// Age-confirmed but never accepted the content policy. Used to test the new
// hasAcceptedPolicy() gate on chants/comments create.
async function seedUserProfileNoPolicyAcceptance(uid: string) {
  await testEnv.withSecurityRulesDisabled(async (context) => {
    const db = context.firestore();
    await setDoc(doc(db, "profiles", uid), {
      displayName: "NoAcceptanceUser",
      role: "user",
      banned: false,
      ageConfirmed17Plus: true,
      userReportCount: 0,
      createdAt: Timestamp.now(),
      updatedAt: Timestamp.now(),
    });
  });
}

async function seedVisibleChant(
  chantId: string,
  createdBy: string,
  options: {
    status?: "canonical" | "community";
    origin?: "alreadySung" | "originalIdea";
    evidence?: { provider: "youtube" | "x"; url: string } | null;
  } = {},
) {
  await testEnv.withSecurityRulesDisabled(async (context) => {
    const db = context.firestore();
    await setDoc(doc(db, "chants", chantId), {
      title: "Test Chant",
      sportId: "s1",
      competitionId: "c1",
      teamId: "t1",
      playerId: null,
      subjectTag: "club",
      lyrics: "La la la",
      tuneName: "Original",
      contextNotes: null,
      coverImageUrl: null,
      mediaUrl: null,
      mediaType: "none",
      status: options.status ?? "community",
      chantType: "sincere",
      ...(options.origin === undefined ? {} : { origin: options.origin }),
      ...(options.evidence === undefined ? {} : { evidence: options.evidence }),
      upvotes: 0,
      downvotes: 0,
      score: 0,
      commentCount: 0,
      createdBy: createdBy,
      createdAt: Timestamp.now(),
      updatedAt: Timestamp.now(),
      flagCount: 0,
      hidden: false,
      removed: false,
      variations: [],
    });
  });
}

async function seedHiddenChant(chantId: string) {
  await testEnv.withSecurityRulesDisabled(async (context) => {
    const db = context.firestore();
    await setDoc(doc(db, "chants", chantId), {
      title: "Hidden Chant",
      sportId: "s1",
      competitionId: "c1",
      teamId: "t1",
      playerId: null,
      subjectTag: "club",
      lyrics: "Hidden",
      tuneName: "Original",
      contextNotes: null,
      coverImageUrl: null,
      mediaUrl: null,
      mediaType: "none",
      status: "community",
      chantType: "sincere",
      origin: "originalIdea",
      evidence: null,
      upvotes: 0,
      downvotes: 0,
      score: 0,
      commentCount: 0,
      createdBy: "someone",
      createdAt: Timestamp.now(),
      updatedAt: Timestamp.now(),
      flagCount: 0,
      hidden: true,
      removed: false,
      variations: [],
    });
  });
}

function validNewChantData(createdBy: string) {
  return {
    title: "New chant",
    sportId: "s1",
    competitionId: "c1",
    teamId: "t1",
    playerId: null,
    subjectTag: "club",
    lyrics: "Sing it loud",
    tuneName: "Original",
    contextNotes: null,
    coverImageUrl: null,
    mediaUrl: null,
    mediaType: "none",
    status: "community",
    chantType: "sincere",
    origin: "originalIdea",
    evidence: null,
    upvotes: 0,
    downvotes: 0,
    score: 0,
    commentCount: 0,
    createdBy,
    createdAt: Timestamp.now(),
    updatedAt: Timestamp.now(),
    flagCount: 0,
    hidden: false,
    removed: false,
    variations: [],
  };
}

async function seedComment(
  commentId: string,
  chantId: string,
  userId: string,
  options: { parentCommentId?: string | null; hidden?: boolean; removed?: boolean } = {},
) {
  await testEnv.withSecurityRulesDisabled(async (context) => {
    const db = context.firestore();
    await setDoc(doc(db, "comments", commentId), {
      chantId,
      userId,
      displayName: "TestUser",
      body: "A comment",
      parentCommentId: options.parentCommentId ?? null,
      createdAt: Timestamp.now(),
      likeCount: 0,
      flagCount: 0,
      hidden: options.hidden ?? false,
      removed: options.removed ?? false,
    });
  });
}

// ===================== SPORTS =====================

describe("sports", () => {
  it("allows public read", async () => {
    await testEnv.withSecurityRulesDisabled(async (context) => {
      const db = context.firestore();
      await setDoc(doc(db, "sports", "s1"), { name: "Football", enabled: true });
    });

    const unauth = testEnv.unauthenticatedContext().firestore();
    await assertSucceeds(getDoc(doc(unauth, "sports", "s1")));
  });

  it("denies write for non-operator", async () => {
    await seedUserProfile("user1");
    const db = testEnv.authenticatedContext("user1").firestore();
    await assertFails(setDoc(doc(db, "sports", "s1"), { name: "Football", enabled: true }));
  });

  it("allows write for operator", async () => {
    await seedOperator("op1");
    const db = testEnv.authenticatedContext("op1").firestore();
    await assertSucceeds(setDoc(doc(db, "sports", "s1"), { name: "Football", enabled: true }));
  });
});

// ===================== COMPETITIONS =====================

describe("competitions", () => {
  it("allows public read", async () => {
    await testEnv.withSecurityRulesDisabled(async (context) => {
      const db = context.firestore();
      await setDoc(doc(db, "competitions", "c1"), { sportId: "s1", name: "PL", enabled: true });
    });

    const unauth = testEnv.unauthenticatedContext().firestore();
    await assertSucceeds(getDoc(doc(unauth, "competitions", "c1")));
  });

  it("denies write for non-operator", async () => {
    await seedUserProfile("user1");
    const db = testEnv.authenticatedContext("user1").firestore();
    await assertFails(setDoc(doc(db, "competitions", "c1"), { sportId: "s1", name: "PL", enabled: true }));
  });

  it("allows write for operator", async () => {
    await seedOperator("op1");
    const db = testEnv.authenticatedContext("op1").firestore();
    await assertSucceeds(setDoc(doc(db, "competitions", "c1"), { sportId: "s1", name: "PL", enabled: true }));
  });
});

// ===================== TEAMS =====================

describe("teams", () => {
  it("allows public read", async () => {
    await testEnv.withSecurityRulesDisabled(async (context) => {
      const db = context.firestore();
      await setDoc(doc(db, "teams", "t1"), { sportId: "s1", competitionId: "c1", name: "Arsenal", crestImageUrl: null });
    });
    const unauth = testEnv.unauthenticatedContext().firestore();
    await assertSucceeds(getDoc(doc(unauth, "teams", "t1")));
  });

  it("denies write for non-operator", async () => {
    await seedUserProfile("user1");
    const db = testEnv.authenticatedContext("user1").firestore();
    await assertFails(setDoc(doc(db, "teams", "t1"), { sportId: "s1", competitionId: "c1", name: "Arsenal", crestImageUrl: null }));
  });
});

// ===================== PLAYERS =====================

describe("players", () => {
  it("allows public read", async () => {
    await testEnv.withSecurityRulesDisabled(async (context) => {
      const db = context.firestore();
      await setDoc(doc(db, "players", "p1"), { teamId: "t1", name: "Saka" });
    });
    const unauth = testEnv.unauthenticatedContext().firestore();
    await assertSucceeds(getDoc(doc(unauth, "players", "p1")));
  });

  it("denies write for non-operator", async () => {
    await seedUserProfile("user1");
    const db = testEnv.authenticatedContext("user1").firestore();
    await assertFails(setDoc(doc(db, "players", "p1"), { teamId: "t1", name: "Saka" }));
  });
});

// ===================== PROFILES =====================

describe("profiles", () => {
  it("denies public read of a profile", async () => {
    await seedUserProfile("user1");
    const unauth = testEnv.unauthenticatedContext().firestore();
    await assertFails(getDoc(doc(unauth, "profiles", "user1")));
  });

  it("allows an owner and an operator to read a profile", async () => {
    await seedUserProfile("user1");
    await seedOperator("op1");
    const ownerDb = testEnv.authenticatedContext("user1").firestore();
    const operatorDb = testEnv.authenticatedContext("op1").firestore();
    await assertSucceeds(getDoc(doc(ownerDb, "profiles", "user1")));
    await assertSucceeds(getDoc(doc(operatorDb, "profiles", "user1")));
  });

  it("allows owner to create own profile", async () => {
    const db = testEnv.authenticatedContext("user1").firestore();
    await assertSucceeds(setDoc(doc(db, "profiles", "user1"), {
      displayName: "Fan",
      role: "user",
      banned: false,
      ageConfirmed17Plus: true,
      userReportCount: 0,
      createdAt: Timestamp.now(),
      updatedAt: Timestamp.now(),
    }));
  });

  it("denies creating another user's profile", async () => {
    const db = testEnv.authenticatedContext("user1").firestore();
    await assertFails(setDoc(doc(db, "profiles", "user2"), {
      displayName: "Impersonator",
      role: "user",
      banned: false,
      createdAt: Timestamp.now(),
      updatedAt: Timestamp.now(),
    }));
  });

  it("allows owner to update displayName", async () => {
    await seedUserProfile("user1");
    const db = testEnv.authenticatedContext("user1").firestore();
    await assertSucceeds(updateDoc(doc(db, "profiles", "user1"), {
      displayName: "NewName",
      updatedAt: Timestamp.now(),
    }));
  });

  it("denies owner changing own role", async () => {
    await seedUserProfile("user1");
    const db = testEnv.authenticatedContext("user1").firestore();
    await assertFails(updateDoc(doc(db, "profiles", "user1"), {
      role: "operator",
    }));
  });

  it("denies create with role 'operator' (privilege escalation)", async () => {
    const db = testEnv.authenticatedContext("user1").firestore();
    await assertFails(setDoc(doc(db, "profiles", "user1"), {
      displayName: "Hacker",
      role: "operator",
      createdAt: Timestamp.now(),
      updatedAt: Timestamp.now(),
    }));
  });

  it("allows create with role 'user' (pinned)", async () => {
    const db = testEnv.authenticatedContext("user2").firestore();
    await assertSucceeds(setDoc(doc(db, "profiles", "user2"), {
      displayName: "LegitFan",
      role: "user",
      banned: false,
      ageConfirmed17Plus: true,
      userReportCount: 0,
      createdAt: Timestamp.now(),
      updatedAt: Timestamp.now(),
    }));
  });

  it("denies create with empty displayName", async () => {
    const db = testEnv.authenticatedContext("user3").firestore();
    await assertFails(setDoc(doc(db, "profiles", "user3"), {
      displayName: "",
      role: "user",
      createdAt: Timestamp.now(),
      updatedAt: Timestamp.now(),
    }));
  });

  it("denies create with displayName over 50 chars", async () => {
    const db = testEnv.authenticatedContext("user4").firestore();
    await assertFails(setDoc(doc(db, "profiles", "user4"), {
      displayName: "x".repeat(51),
      role: "user",
      createdAt: Timestamp.now(),
      updatedAt: Timestamp.now(),
    }));
  });

  it("denies create without ageConfirmed17Plus", async () => {
    const db = testEnv.authenticatedContext("user5").firestore();
    await assertFails(setDoc(doc(db, "profiles", "user5"), {
      displayName: "NoAge",
      role: "user",
      banned: false,
      createdAt: Timestamp.now(),
      updatedAt: Timestamp.now(),
    }));
  });

  it("denies create with ageConfirmed17Plus == false", async () => {
    const db = testEnv.authenticatedContext("user6").firestore();
    await assertFails(setDoc(doc(db, "profiles", "user6"), {
      displayName: "Underage",
      role: "user",
      banned: false,
      ageConfirmed17Plus: false,
      createdAt: Timestamp.now(),
      updatedAt: Timestamp.now(),
    }));
  });

  it("denies create with acceptedPolicyVersion set directly (must be absent, "
      + "only the acceptPolicy Cloud Function may set it)", async () => {
    const db = testEnv.authenticatedContext("user7").firestore();
    await assertFails(setDoc(doc(db, "profiles", "user7"), {
      displayName: "Forger",
      role: "user",
      banned: false,
      ageConfirmed17Plus: true,
      acceptedPolicyVersion: "v1",
      createdAt: Timestamp.now(),
      updatedAt: Timestamp.now(),
    }));
  });

  it("denies create with acceptedPolicyAt set directly", async () => {
    const db = testEnv.authenticatedContext("user8").firestore();
    await assertFails(setDoc(doc(db, "profiles", "user8"), {
      displayName: "Forger2",
      role: "user",
      banned: false,
      ageConfirmed17Plus: true,
      acceptedPolicyAt: Timestamp.now(),
      createdAt: Timestamp.now(),
      updatedAt: Timestamp.now(),
    }));
  });

  it("denies owner updating acceptedPolicyVersion directly (privilege "
      + "escalation: forging consent without going through acceptPolicy)",
      async () => {
    await seedUserProfileNoPolicyAcceptance("user9");
    const db = testEnv.authenticatedContext("user9").firestore();
    await assertFails(updateDoc(doc(db, "profiles", "user9"), {
      acceptedPolicyVersion: "v1",
    }));
  });

  it("denies owner updating acceptedPolicyAt directly", async () => {
    await seedUserProfileNoPolicyAcceptance("user10");
    const db = testEnv.authenticatedContext("user10").firestore();
    await assertFails(updateDoc(doc(db, "profiles", "user10"), {
      acceptedPolicyAt: Timestamp.now(),
    }));
  });

  it("denies owner updating ageConfirmed17Plus", async () => {
    await seedUserProfile("user11");
    const db = testEnv.authenticatedContext("user11").firestore();
    await assertFails(updateDoc(doc(db, "profiles", "user11"), {
      ageConfirmed17Plus: false,
    }));
  });

  it("allows owner to update displayName without disturbing pinned fields",
      async () => {
    await seedUserProfile("user12");
    const db = testEnv.authenticatedContext("user12").firestore();
    await assertSucceeds(updateDoc(doc(db, "profiles", "user12"), {
      displayName: "StillFine",
      updatedAt: Timestamp.now(),
    }));
  });

  it("denies create without userReportCount", async () => {
    const db = testEnv.authenticatedContext("user13").firestore();
    await assertFails(setDoc(doc(db, "profiles", "user13"), {
      displayName: "NoCount",
      role: "user",
      banned: false,
      ageConfirmed17Plus: true,
      createdAt: Timestamp.now(),
      updatedAt: Timestamp.now(),
    }));
  });

  it("denies create with userReportCount != 0 (cannot pre-inflate your "
      + "own count)", async () => {
    const db = testEnv.authenticatedContext("user14").firestore();
    await assertFails(setDoc(doc(db, "profiles", "user14"), {
      displayName: "Inflated",
      role: "user",
      banned: false,
      ageConfirmed17Plus: true,
      userReportCount: 5,
      createdAt: Timestamp.now(),
      updatedAt: Timestamp.now(),
    }));
  });

  it("denies owner updating own userReportCount (cannot erase or inflate "
      + "it, only onUserReportCreated via the Admin SDK may set it)",
      async () => {
    await seedUserProfile("user15");
    const db = testEnv.authenticatedContext("user15").firestore();
    // seedUserProfile sets userReportCount to 0, so the update must target a
    // genuinely different value: diff().affectedKeys() only reports fields
    // that actually changed, and setting a field to its current value would
    // not exercise the block at all.
    await assertFails(updateDoc(doc(db, "profiles", "user15"), {
      userReportCount: 5,
    }));
  });
});

// ===================== CHANTS =====================

describe("chants", () => {
  beforeEach(async () => {
    await seedTeam();
  });

  it("allows public read of visible chants", async () => {
    await seedVisibleChant("ch1", "user1");
    const unauth = testEnv.unauthenticatedContext().firestore();
    await assertSucceeds(getDoc(doc(unauth, "chants", "ch1")));
  });

  it("denies public read of hidden chants", async () => {
    await seedHiddenChant("ch-hidden");
    const unauth = testEnv.unauthenticatedContext().firestore();
    await assertFails(getDoc(doc(unauth, "chants", "ch-hidden")));
  });

  it("allows operator to read hidden chants", async () => {
    await seedHiddenChant("ch-hidden");
    await seedOperator("op1");
    const db = testEnv.authenticatedContext("op1").firestore();
    await assertSucceeds(getDoc(doc(db, "chants", "ch-hidden")));
  });

  it("allows authenticated user to create chant with correct defaults", async () => {
    await seedUserProfile("user1");
    const db = testEnv.authenticatedContext("user1").firestore();
    await assertSucceeds(setDoc(doc(db, "chants", "newchant"), {
      title: "New Song",
      sportId: "s1",
      competitionId: "c1",
      teamId: "t1",
      playerId: null,
      subjectTag: "club",
      lyrics: "Sing it loud",
      tuneName: "Original",
      contextNotes: null,
      coverImageUrl: null,
      mediaUrl: null,
      mediaType: "none",
      status: "community",
      chantType: "sincere",
      origin: "originalIdea",
      evidence: null,
      upvotes: 0,
      downvotes: 0,
      score: 0,
      commentCount: 0,
      createdBy: "user1",
      createdAt: Timestamp.now(),
      updatedAt: Timestamp.now(),
      flagCount: 0,
      hidden: false,
      removed: false,
      variations: [],
    }));
  });

  it("rejects create if status is not community", async () => {
    await seedUserProfile("user1");
    const db = testEnv.authenticatedContext("user1").firestore();
    await assertFails(setDoc(doc(db, "chants", "newchant2"), {
      title: "Cheat",
      sportId: "s1",
      competitionId: "c1",
      teamId: "t1",
      playerId: null,
      subjectTag: "club",
      lyrics: "Nope",
      tuneName: "Original",
      contextNotes: null,
      coverImageUrl: null,
      mediaUrl: null,
      mediaType: "none",
      status: "canonical",
      chantType: "sincere",
      origin: "originalIdea",
      evidence: null,
      upvotes: 0,
      downvotes: 0,
      score: 0,
      commentCount: 0,
      createdBy: "user1",
      createdAt: Timestamp.now(),
      updatedAt: Timestamp.now(),
      flagCount: 0,
      hidden: false,
      removed: false,
      variations: [],
    }));
  });

  it("rejects create if counters are not zero", async () => {
    await seedUserProfile("user1");
    const db = testEnv.authenticatedContext("user1").firestore();
    await assertFails(setDoc(doc(db, "chants", "newchant3"), {
      title: "Inflate",
      sportId: "s1",
      competitionId: "c1",
      teamId: "t1",
      playerId: null,
      subjectTag: "club",
      lyrics: "Nope",
      tuneName: "Original",
      contextNotes: null,
      coverImageUrl: null,
      mediaUrl: null,
      mediaType: "none",
      status: "community",
      chantType: "sincere",
      origin: "originalIdea",
      evidence: null,
      upvotes: 10,
      downvotes: 0,
      score: 10,
      commentCount: 0,
      createdBy: "user1",
      createdAt: Timestamp.now(),
      updatedAt: Timestamp.now(),
      flagCount: 0,
      hidden: false,
      removed: false,
      variations: [],
    }));
  });

  it("allows author to update content fields", async () => {
    await seedVisibleChant("ch1", "user1", { origin: "originalIdea" });
    await seedUserProfile("user1");
    const db = testEnv.authenticatedContext("user1").firestore();
    await assertSucceeds(updateDoc(doc(db, "chants", "ch1"), {
      title: "Updated Title",
      lyrics: "New lyrics",
      updatedAt: Timestamp.now(),
    }));
  });

  it("denies author changing counters", async () => {
    await seedVisibleChant("ch1", "user1");
    await seedUserProfile("user1");
    const db = testEnv.authenticatedContext("user1").firestore();
    await assertFails(updateDoc(doc(db, "chants", "ch1"), {
      upvotes: 999,
    }));
  });

  it("denies author changing status", async () => {
    await seedVisibleChant("ch1", "user1");
    await seedUserProfile("user1");
    const db = testEnv.authenticatedContext("user1").firestore();
    await assertFails(updateDoc(doc(db, "chants", "ch1"), {
      status: "canonical",
    }));
  });

  it("denies author changing hidden/removed", async () => {
    await seedVisibleChant("ch1", "user1");
    await seedUserProfile("user1");
    const db = testEnv.authenticatedContext("user1").firestore();
    await assertFails(updateDoc(doc(db, "chants", "ch1"), {
      hidden: true,
    }));
  });

  it("allows operator moderation fields without changing trust state", async () => {
    await seedVisibleChant("ch1", "user1");
    await seedOperator("op1");
    const db = testEnv.authenticatedContext("op1").firestore();
    await assertSucceeds(updateDoc(doc(db, "chants", "ch1"), {
      hidden: true,
      upvotes: 50,
    }));
  });
});

describe("chant provenance and evidence", () => {
  beforeEach(async () => {
    await seedTeam();
  });

  it("requires a valid origin on every new user chant", async () => {
    await seedUserProfile("user1");
    const db = testEnv.authenticatedContext("user1").firestore();
    const missingOrigin = validNewChantData("user1");
    delete (missingOrigin as Partial<typeof missingOrigin>).origin;
    await assertFails(setDoc(doc(db, "chants", "missing-origin"), missingOrigin));
    await assertFails(setDoc(doc(db, "chants", "invalid-origin"), {
      ...validNewChantData("user1"),
      origin: "copiedFromSomewhere",
    }));
  });

  it("allows Already sung with canonical YouTube evidence", async () => {
    await seedUserProfile("user1");
    const db = testEnv.authenticatedContext("user1").firestore();
    await assertSucceeds(setDoc(doc(db, "chants", "sung-with-proof"), {
      ...validNewChantData("user1"),
      origin: "alreadySung",
      evidence: {
        provider: "youtube",
        url: "https://www.youtube.com/watch?v=dQw4w9WgXcQ",
      },
    }));
  });

  it("rejects malformed, noncanonical, mismatched, and forged evidence", async () => {
    await seedUserProfile("user1");
    const db = testEnv.authenticatedContext("user1").firestore();
    const invalidEvidence = [
      {
        provider: "youtube",
        url: "https://youtube.com.example.test/watch?v=dQw4w9WgXcQ",
      },
      { provider: "youtube", url: "https://youtu.be/dQw4w9WgXcQ" },
      {
        provider: "x",
        url: "https://www.youtube.com/watch?v=dQw4w9WgXcQ",
      },
      { provider: "x", url: "https://x.com/arsenal" },
      {
        provider: "x",
        url: "https://x.com/arsenal/status/12345678901234567890123456",
      },
      {
        provider: "x",
        url: "https://x.com/arsenal/status/1234567890",
        reviewed: true,
      },
    ];

    for (let index = 0; index < invalidEvidence.length; index++) {
      await assertFails(setDoc(doc(db, "chants", `bad-evidence-${index}`), {
        ...validNewChantData("user1"),
        evidence: invalidEvidence[index],
      }));
    }
  });

  it("keeps origin and evidence immutable from the author client", async () => {
    await seedVisibleChant("ch1", "user1", {
      origin: "originalIdea",
      evidence: null,
    });
    await seedUserProfile("user1");
    const db = testEnv.authenticatedContext("user1").firestore();
    await assertFails(updateDoc(doc(db, "chants", "ch1"), {
      origin: "alreadySung",
      updatedAt: Timestamp.now(),
    }));
    await assertFails(updateDoc(doc(db, "chants", "ch1"), {
      evidence: {
        provider: "x",
        url: "https://x.com/arsenal/status/1234567890",
      },
      updatedAt: Timestamp.now(),
    }));
  });

  it("freezes author content edits after Terrace Proven promotion", async () => {
    await seedVisibleChant("ch1", "user1", {
      status: "canonical",
      origin: "alreadySung",
      evidence: {
        provider: "x",
        url: "https://x.com/arsenal/status/1234567890",
      },
    });
    await seedUserProfile("user1");
    const db = testEnv.authenticatedContext("user1").firestore();
    await assertFails(updateDoc(doc(db, "chants", "ch1"), {
      title: "Changed after review",
      updatedAt: Timestamp.now(),
    }));
  });
});

describe("direct chant schema and relationships", () => {
  beforeEach(async () => {
    await seedUserProfile("user1");
    await seedTeam();
  });

  it("allows a Player chant only for a Player on the selected Team", async () => {
    await seedPlayer("p1", "t1");
    const db = testEnv.authenticatedContext("user1").firestore();

    await assertSucceeds(setDoc(doc(db, "chants", "player-chant"), {
      ...validNewChantData("user1"),
      subjectTag: "player",
      playerId: "p1",
    }));
  });

  it("denies malformed fields, forged media, and unknown keys", async () => {
    const db = testEnv.authenticatedContext("user1").firestore();
    const invalidPayloads = [
      { ...validNewChantData("user1"), variations: "not-a-list" },
      {
        ...validNewChantData("user1"),
        variations: [{ label: "Injected", lyric: "Unsafe" }],
      },
      { ...validNewChantData("user1"), playerId: 42 },
      { ...validNewChantData("user1"), sportId: { forged: true } },
      {
        ...validNewChantData("user1"),
        mediaType: "crowdClip",
        mediaUrl: "https://example.test/clip.mp4",
      },
      {
        ...validNewChantData("user1"),
        coverImageUrl: "https://example.test/cover.jpg",
      },
      { ...validNewChantData("user1"), unexpected: "x".repeat(1024) },
    ];

    for (let index = 0; index < invalidPayloads.length; index++) {
      await assertFails(setDoc(
        doc(db, "chants", `invalid-shape-${index}`),
        invalidPayloads[index],
      ));
    }
  });

  it("denies Team hierarchy and Player relationship mismatches", async () => {
    await seedTeam("t2", "s1", "c1");
    await seedPlayer("p-on-t2", "t2");
    const db = testEnv.authenticatedContext("user1").firestore();

    await assertFails(setDoc(doc(db, "chants", "wrong-sport"), {
      ...validNewChantData("user1"),
      sportId: "wrong-sport",
    }));
    await assertFails(setDoc(doc(db, "chants", "wrong-competition"), {
      ...validNewChantData("user1"),
      competitionId: "wrong-competition",
    }));
    await assertFails(setDoc(doc(db, "chants", "missing-team"), {
      ...validNewChantData("user1"),
      teamId: "missing",
    }));
    await assertFails(setDoc(doc(db, "chants", "wrong-player-team"), {
      ...validNewChantData("user1"),
      subjectTag: "player",
      playerId: "p-on-t2",
    }));
    await assertFails(setDoc(doc(db, "chants", "club-with-player"), {
      ...validNewChantData("user1"),
      playerId: "p-on-t2",
    }));
  });

  it("denies stale or future client timestamps", async () => {
    const db = testEnv.authenticatedContext("user1").firestore();
    const twoHours = 2 * 60 * 60 * 1000;

    await assertFails(setDoc(doc(db, "chants", "stale-created"), {
      ...validNewChantData("user1"),
      createdAt: Timestamp.fromMillis(Date.now() - twoHours),
    }));
    await assertFails(setDoc(doc(db, "chants", "future-updated"), {
      ...validNewChantData("user1"),
      updatedAt: Timestamp.fromMillis(Date.now() + twoHours),
    }));
  });

  it("keeps dormant media and schema fields immutable for authors", async () => {
    await seedVisibleChant("ch1", "user1", { origin: "originalIdea" });
    const db = testEnv.authenticatedContext("user1").firestore();

    await assertFails(updateDoc(doc(db, "chants", "ch1"), {
      coverImageUrl: "https://example.test/cover.jpg",
      updatedAt: Timestamp.now(),
    }));
    await assertFails(updateDoc(doc(db, "chants", "ch1"), {
      variations: deleteField(),
      updatedAt: Timestamp.now(),
    }));
  });
});

// ===================== VOTES =====================

describe("votes", () => {
  it("allows create with correct userId and doc ID", async () => {
    await seedUserProfile("user1");
    await seedVisibleChant("ch1", "someone");
    const db = testEnv.authenticatedContext("user1").firestore();
    await assertSucceeds(setDoc(doc(db, "votes", "user1_ch1"), {
      chantId: "ch1",
      userId: "user1",
      value: 1,
      createdAt: Timestamp.now(),
    }));
  });

  it("rejects create with wrong doc ID", async () => {
    await seedUserProfile("user1");
    const db = testEnv.authenticatedContext("user1").firestore();
    await assertFails(setDoc(doc(db, "votes", "wrongid"), {
      chantId: "ch1",
      userId: "user1",
      value: 1,
      createdAt: Timestamp.now(),
    }));
  });

  it("rejects create with value other than 1 or -1", async () => {
    await seedUserProfile("user1");
    const db = testEnv.authenticatedContext("user1").firestore();
    await assertFails(setDoc(doc(db, "votes", "user1_ch1"), {
      chantId: "ch1",
      userId: "user1",
      value: 5,
      createdAt: Timestamp.now(),
    }));
  });

  it("denies unknown and Function-owned fields on create", async () => {
    await seedUserProfile("user1");
    await seedVisibleChant("ch1", "someone");
    const db = testEnv.authenticatedContext("user1").firestore();
    const base = {
      chantId: "ch1",
      userId: "user1",
      value: 1,
      createdAt: Timestamp.now(),
    };

    await assertFails(setDoc(doc(db, "votes", "user1_ch1"), {
      ...base,
      appliedValue: 1,
    }));
    await assertFails(setDoc(doc(db, "votes", "user1_ch1"), {
      ...base,
      unexpected: true,
    }));
  });

  it("allows user to update own vote value", async () => {
    await seedVisibleChant("ch1", "someone");
    await testEnv.withSecurityRulesDisabled(async (context) => {
      const db = context.firestore();
      await setDoc(doc(db, "votes", "user1_ch1"), {
        chantId: "ch1",
        userId: "user1",
        value: 1,
        createdAt: Timestamp.now(),
      });
    });
    await seedUserProfile("user1");
    const db = testEnv.authenticatedContext("user1").firestore();
    await assertSucceeds(updateDoc(doc(db, "votes", "user1_ch1"), { value: -1 }));
  });

  it("denies modifying userId on vote", async () => {
    await testEnv.withSecurityRulesDisabled(async (context) => {
      const db = context.firestore();
      await setDoc(doc(db, "votes", "user1_ch1"), {
        chantId: "ch1",
        userId: "user1",
        value: 1,
        createdAt: Timestamp.now(),
      });
    });
    await seedUserProfile("user1");
    const db = testEnv.authenticatedContext("user1").firestore();
    await assertFails(updateDoc(doc(db, "votes", "user1_ch1"), { userId: "user2" }));
  });

  it("preserves Function-owned appliedValue on owner updates", async () => {
    await seedVisibleChant("ch1", "someone");
    await testEnv.withSecurityRulesDisabled(async (context) => {
      const db = context.firestore();
      await setDoc(doc(db, "votes", "user1_ch1"), {
        chantId: "ch1",
        userId: "user1",
        value: 1,
        createdAt: Timestamp.now(),
        appliedValue: 1,
      });
    });
    await seedUserProfile("user1");
    const db = testEnv.authenticatedContext("user1").firestore();

    await assertSucceeds(updateDoc(doc(db, "votes", "user1_ch1"), {
      value: -1,
    }));
    await assertFails(updateDoc(doc(db, "votes", "user1_ch1"), {
      appliedValue: -1,
    }));
    await assertFails(updateDoc(doc(db, "votes", "user1_ch1"), {
      appliedValue: deleteField(),
    }));
  });

  it("allows user to delete own vote", async () => {
    await testEnv.withSecurityRulesDisabled(async (context) => {
      const db = context.firestore();
      await setDoc(doc(db, "votes", "user1_ch1"), {
        chantId: "ch1",
        userId: "user1",
        value: 1,
        createdAt: Timestamp.now(),
      });
    });
    await seedUserProfile("user1");
    const db = testEnv.authenticatedContext("user1").firestore();
    await assertSucceeds(deleteDoc(doc(db, "votes", "user1_ch1")));
  });
});

// ===================== REPORTS =====================

describe("reports", () => {
  it("allows auth user to create report with correct doc ID", async () => {
    await seedUserProfile("user1");
    await seedVisibleChant("ch1", "someone");
    const db = testEnv.authenticatedContext("user1").firestore();
    await assertSucceeds(setDoc(doc(db, "reports", "user1_ch1"), {
      chantId: "ch1",
      reportedBy: "user1",
      reason: "Offensive content",
      createdAt: Timestamp.now(),
      status: "pending",
    }));
  });

  it("denies non-operator read", async () => {
    await testEnv.withSecurityRulesDisabled(async (context) => {
      const db = context.firestore();
      await setDoc(doc(db, "reports", "r1"), {
        chantId: "ch1",
        reportedBy: "user1",
        reason: "Offensive",
        createdAt: Timestamp.now(),
        status: "pending",
      });
    });
    await seedUserProfile("user1");
    const db = testEnv.authenticatedContext("user1").firestore();
    await assertFails(getDoc(doc(db, "reports", "r1")));
  });

  it("allows operator read", async () => {
    await testEnv.withSecurityRulesDisabled(async (context) => {
      const db = context.firestore();
      await setDoc(doc(db, "reports", "r1"), {
        chantId: "ch1",
        reportedBy: "user1",
        reason: "Offensive",
        createdAt: Timestamp.now(),
        status: "pending",
      });
    });
    await seedOperator("op1");
    const db = testEnv.authenticatedContext("op1").firestore();
    await assertSucceeds(getDoc(doc(db, "reports", "r1")));
  });

  it("denies create with status other than 'pending'", async () => {
    await seedUserProfile("user1");
    const db = testEnv.authenticatedContext("user1").firestore();
    await assertFails(setDoc(doc(db, "reports", "user1_ch1"), {
      chantId: "ch1",
      reportedBy: "user1",
      reason: "Offensive content",
      createdAt: Timestamp.now(),
      status: "reviewed",
    }));
  });
});

// ===================== AUDIT LOG =====================

describe("auditLog", () => {
  it("denies any client write", async () => {
    await seedOperator("op1");
    const db = testEnv.authenticatedContext("op1").firestore();
    await assertFails(setDoc(doc(db, "auditLog", "log1"), {
      actorId: "op1",
      action: "remove",
      targetType: "chant",
      targetId: "ch1",
      detail: "test",
      createdAt: Timestamp.now(),
    }));
  });

  it("allows operator read", async () => {
    await testEnv.withSecurityRulesDisabled(async (context) => {
      const db = context.firestore();
      await setDoc(doc(db, "auditLog", "log1"), {
        actorId: "op1",
        action: "remove",
        targetType: "chant",
        targetId: "ch1",
        detail: "test",
        createdAt: Timestamp.now(),
      });
    });
    await seedOperator("op1");
    const db = testEnv.authenticatedContext("op1").firestore();
    await assertSucceeds(getDoc(doc(db, "auditLog", "log1")));
  });

  it("denies non-operator read", async () => {
    await testEnv.withSecurityRulesDisabled(async (context) => {
      const db = context.firestore();
      await setDoc(doc(db, "auditLog", "log1"), {
        actorId: "op1",
        action: "remove",
        targetType: "chant",
        targetId: "ch1",
        detail: "test",
        createdAt: Timestamp.now(),
      });
    });
    await seedUserProfile("user1");
    const db = testEnv.authenticatedContext("user1").firestore();
    await assertFails(getDoc(doc(db, "auditLog", "log1")));
  });
});

// ===================== FEEDBACK =====================

describe("feedback", () => {
  it("allows auth user to create feedback with message <= 1000", async () => {
    const db = testEnv.authenticatedContext("user1").firestore();
    await assertSucceeds(addDoc(collection(db, "feedback"), {
      userId: "user1",
      category: "suggestion",
      message: "Great app!",
      followUpOk: true,
      resolved: false,
      createdAt: Timestamp.now(),
    }));
  });

  it("rejects feedback with message > 1000 chars", async () => {
    const db = testEnv.authenticatedContext("user1").firestore();
    const longMessage = "x".repeat(1001);
    await assertFails(addDoc(collection(db, "feedback"), {
      userId: "user1",
      category: "bug",
      message: longMessage,
      followUpOk: false,
      resolved: false,
      createdAt: Timestamp.now(),
    }));
  });

  it("allows user to read own feedback", async () => {
    await testEnv.withSecurityRulesDisabled(async (context) => {
      const db = context.firestore();
      await setDoc(doc(db, "feedback", "fb1"), {
        userId: "user1",
        category: "suggestion",
        message: "Test",
        followUpOk: false,
        resolved: false,
        createdAt: Timestamp.now(),
      });
    });
    await seedUserProfile("user1");
    const db = testEnv.authenticatedContext("user1").firestore();
    await assertSucceeds(getDoc(doc(db, "feedback", "fb1")));
  });

  it("denies user reading another's feedback", async () => {
    await testEnv.withSecurityRulesDisabled(async (context) => {
      const db = context.firestore();
      await setDoc(doc(db, "feedback", "fb1"), {
        userId: "user2",
        category: "suggestion",
        message: "Test",
        followUpOk: false,
        resolved: false,
        createdAt: Timestamp.now(),
      });
    });
    await seedUserProfile("user1");
    const db = testEnv.authenticatedContext("user1").firestore();
    await assertFails(getDoc(doc(db, "feedback", "fb1")));
  });

  it("allows operator to read any feedback", async () => {
    await testEnv.withSecurityRulesDisabled(async (context) => {
      const db = context.firestore();
      await setDoc(doc(db, "feedback", "fb1"), {
        userId: "user2",
        category: "suggestion",
        message: "Test",
        followUpOk: false,
        resolved: false,
        createdAt: Timestamp.now(),
      });
    });
    await seedOperator("op1");
    const db = testEnv.authenticatedContext("op1").firestore();
    await assertSucceeds(getDoc(doc(db, "feedback", "fb1")));
  });

  it("denies create with resolved true", async () => {
    const db = testEnv.authenticatedContext("user1").firestore();
    await assertFails(addDoc(collection(db, "feedback"), {
      userId: "user1",
      category: "suggestion",
      message: "Trying to pre-resolve",
      followUpOk: false,
      resolved: true,
      createdAt: Timestamp.now(),
    }));
  });

  it("denies update on feedback", async () => {
    await testEnv.withSecurityRulesDisabled(async (context) => {
      const db = context.firestore();
      await setDoc(doc(db, "feedback", "fb1"), {
        userId: "user1",
        category: "suggestion",
        message: "Test",
        followUpOk: false,
        resolved: false,
        createdAt: Timestamp.now(),
      });
    });
    await seedUserProfile("user1");
    const db = testEnv.authenticatedContext("user1").firestore();
    await assertFails(updateDoc(doc(db, "feedback", "fb1"), { resolved: true }));
  });

  it("denies unknown fields, invalid types, categories, and timestamps", async () => {
    const db = testEnv.authenticatedContext("user1").firestore();
    const base = {
      userId: "user1",
      category: "suggestion",
      message: "Useful feedback",
      followUpOk: true,
      resolved: false,
      createdAt: Timestamp.now(),
    };
    const invalidPayloads = [
      { ...base, unexpected: true },
      { ...base, category: "compliment" },
      { ...base, message: "" },
      { ...base, message: 42 },
      { ...base, followUpOk: "yes" },
      { ...base, resolved: 0 },
      {
        ...base,
        createdAt: Timestamp.fromMillis(Date.now() + 2 * 60 * 60 * 1000),
      },
    ];

    for (const payload of invalidPayloads) {
      await assertFails(addDoc(collection(db, "feedback"), payload));
    }
  });
});

describe("exact comment and comment-like schemas", () => {
  beforeEach(async () => {
    await seedUserProfile("user1");
    await seedVisibleChant("ch1", "someone");
  });

  it("allows the shipped top-level comment shape", async () => {
    const db = testEnv.authenticatedContext("user1").firestore();
    await assertSucceeds(addDoc(collection(db, "comments"), {
      chantId: "ch1",
      userId: "user1",
      displayName: "TestUser",
      body: "A useful comment",
      parentCommentId: null,
      createdAt: Timestamp.now(),
      likeCount: 0,
      flagCount: 0,
      hidden: false,
      removed: false,
    }));
  });

  it("denies unknown comment fields and malformed counter or flag types", async () => {
    const db = testEnv.authenticatedContext("user1").firestore();
    const base = {
      chantId: "ch1",
      userId: "user1",
      displayName: "TestUser",
      body: "A useful comment",
      createdAt: Timestamp.now(),
      likeCount: 0,
      flagCount: 0,
      hidden: false,
      removed: false,
    };

    await assertFails(addDoc(collection(db, "comments"), {
      ...base,
      unexpected: "raw-client-field",
    }));
    await assertFails(addDoc(collection(db, "comments"), {
      ...base,
      likeCount: "0",
    }));
    await assertFails(addDoc(collection(db, "comments"), {
      ...base,
      hidden: 0,
    }));
  });

  it("denies Function-owned and unknown comment-like fields", async () => {
    await seedComment("comment1", "ch1", "someone");
    const db = testEnv.authenticatedContext("user1").firestore();
    const base = {
      commentId: "comment1",
      userId: "user1",
      value: 1,
      createdAt: Timestamp.now(),
    };

    await assertFails(setDoc(doc(db, "commentLikes", "user1_comment1"), {
      ...base,
      appliedValue: 1,
    }));
    await assertFails(setDoc(doc(db, "commentLikes", "user1_comment1"), {
      ...base,
      unexpected: true,
    }));
  });

  it("preserves Function-owned comment-like appliedValue", async () => {
    await seedComment("comment1", "ch1", "someone");
    await testEnv.withSecurityRulesDisabled(async (context) => {
      const db = context.firestore();
      await setDoc(doc(db, "commentLikes", "user1_comment1"), {
        commentId: "comment1",
        userId: "user1",
        value: 1,
        createdAt: Timestamp.now(),
        appliedValue: 1,
      });
    });
    const db = testEnv.authenticatedContext("user1").firestore();

    await assertFails(updateDoc(doc(db, "commentLikes", "user1_comment1"), {
      appliedValue: -1,
    }));
    await assertFails(updateDoc(doc(db, "commentLikes", "user1_comment1"), {
      appliedValue: deleteField(),
    }));
  });
});

describe("exact report schemas", () => {
  beforeEach(async () => {
    await seedUserProfile("reporter");
    await seedUserProfile("target");
    await seedVisibleChant("ch1", "someone");
    await seedComment("comment1", "ch1", "target");
  });

  it("allows the current chant, comment, and user report shapes", async () => {
    const db = testEnv.authenticatedContext("reporter").firestore();
    const common = {
      reportedBy: "reporter",
      reason: "Offensive content",
      createdAt: Timestamp.now(),
      status: "pending",
    };

    await assertSucceeds(setDoc(doc(db, "reports", "reporter_ch1"), {
      ...common,
      chantId: "ch1",
    }));
    await assertSucceeds(setDoc(
      doc(db, "commentReports", "reporter_comment1"),
      { ...common, commentId: "comment1" },
    ));
    await assertSucceeds(setDoc(
      doc(db, "userReports", "reporter_target"),
      { ...common, reportedUserId: "target" },
    ));
  });

  it("denies unknown, empty, oversized, nonstring, and stale report data", async () => {
    const db = testEnv.authenticatedContext("reporter").firestore();
    const cases = [
      {
        collectionName: "reports",
        targetField: "chantId",
        targetId: "ch1",
        documentId: "reporter_ch1",
      },
      {
        collectionName: "commentReports",
        targetField: "commentId",
        targetId: "comment1",
        documentId: "reporter_comment1",
      },
      {
        collectionName: "userReports",
        targetField: "reportedUserId",
        targetId: "target",
        documentId: "reporter_target",
      },
    ];

    for (const testCase of cases) {
      const base = {
        [testCase.targetField]: testCase.targetId,
        reportedBy: "reporter",
        reason: "Offensive content",
        createdAt: Timestamp.now(),
        status: "pending",
      };
      const target = doc(db, testCase.collectionName, testCase.documentId);
      await assertFails(setDoc(target, { ...base, unexpected: true }));
      await assertFails(setDoc(target, { ...base, reason: "" }));
      await assertFails(setDoc(target, { ...base, reason: "x".repeat(251) }));
      await assertFails(setDoc(target, { ...base, reason: 42 }));
      await assertFails(setDoc(target, {
        ...base,
        createdAt: Timestamp.fromMillis(Date.now() - 2 * 60 * 60 * 1000),
      }));
    }
  });
});

// ===================== REPORT WRITE CORRECTNESS (Fix D) =====================

describe("report write correctness", () => {
  it("allows well-formed report create with status pending and correct doc ID", async () => {
    await seedUserProfile("user1");
    await seedVisibleChant("ch1", "someone");
    const db = testEnv.authenticatedContext("user1").firestore();
    await assertSucceeds(setDoc(doc(db, "reports", "user1_ch1"), {
      chantId: "ch1",
      reportedBy: "user1",
      reason: "Hate speech or slurs: offensive language",
      createdAt: Timestamp.now(),
      status: "pending",
    }));
  });

  it("denies report create by unauthenticated user", async () => {
    const db = testEnv.unauthenticatedContext().firestore();
    await assertFails(setDoc(doc(db, "reports", "anon_ch1"), {
      chantId: "ch1",
      reportedBy: "anon",
      reason: "Test",
      createdAt: Timestamp.now(),
      status: "pending",
    }));
  });

  it("denies report create with reportedBy != auth uid", async () => {
    await seedUserProfile("user1");
    const db = testEnv.authenticatedContext("user1").firestore();
    await assertFails(setDoc(doc(db, "reports", "user1_ch1"), {
      chantId: "ch1",
      reportedBy: "someone_else",
      reason: "Test",
      createdAt: Timestamp.now(),
      status: "pending",
    }));
  });
});

// ===================== CHANT LIST QUERY BOUNDARY (Fix D) =====================

describe("chant list query boundary", () => {
  beforeEach(async () => {
    // Seed one visible and one hidden chant
    await seedVisibleChant("ch-visible", "user1");
    await seedHiddenChant("ch-hidden");
  });

  it("allows list query WITH hidden==false and removed==false filters", async () => {
    const db = testEnv.unauthenticatedContext().firestore();
    const q = query(
      collection(db, "chants"),
      where("hidden", "==", false),
      where("removed", "==", false)
    );
    await assertSucceeds(getDocs(q));
  });

  it("denies list query WITHOUT hidden/removed filters", async () => {
    const db = testEnv.unauthenticatedContext().firestore();
    const q = query(collection(db, "chants"));
    await assertFails(getDocs(q));
  });

  it("denies list query with only hidden filter (missing removed)", async () => {
    const db = testEnv.unauthenticatedContext().firestore();
    const q = query(
      collection(db, "chants"),
      where("hidden", "==", false)
    );
    await assertFails(getDocs(q));
  });
});

// ===================== BLOCK 3: BAN ENFORCEMENT =====================

describe("ban enforcement", () => {
  const validChantData = {
    title: "Test",
    sportId: "s1",
    competitionId: "c1",
    teamId: "t1",
    playerId: null,
    subjectTag: "club",
    lyrics: "La la la",
    tuneName: "Original",
    contextNotes: null,
    coverImageUrl: null,
    mediaUrl: null,
    mediaType: "none",
    status: "community",
    chantType: "sincere",
    origin: "originalIdea",
    evidence: null,
    upvotes: 0,
    downvotes: 0,
    score: 0,
    commentCount: 0,
    createdBy: "banned1",
    createdAt: Timestamp.now(),
    updatedAt: Timestamp.now(),
    flagCount: 0,
    hidden: false,
    removed: false,
    variations: [],
  };

  beforeEach(async () => {
    await seedTeam();
  });

  it("denies chant create by banned user", async () => {
    await seedBannedUser("banned1");
    const db = testEnv.authenticatedContext("banned1").firestore();
    await assertFails(setDoc(doc(db, "chants", "test-chant"), validChantData));
  });

  it("allows chant create by non-banned user", async () => {
    await seedUserProfile("user1");
    const db = testEnv.authenticatedContext("user1").firestore();
    await assertSucceeds(setDoc(doc(db, "chants", "test-chant"), {
      ...validChantData,
      createdBy: "user1",
    }));
  });

  it("denies vote create by banned user", async () => {
    await seedBannedUser("banned1");
    const db = testEnv.authenticatedContext("banned1").firestore();
    await assertFails(setDoc(doc(db, "votes", "banned1_ch1"), {
      chantId: "ch1",
      userId: "banned1",
      value: 1,
      createdAt: Timestamp.now(),
    }));
  });

  it("denies report create by banned user", async () => {
    await seedBannedUser("banned1");
    const db = testEnv.authenticatedContext("banned1").firestore();
    await assertFails(setDoc(doc(db, "reports", "banned1_ch1"), {
      chantId: "ch1",
      reportedBy: "banned1",
      reason: "test",
      createdAt: Timestamp.now(),
      status: "pending",
    }));
  });

  it("denies banned user setting own banned to false (Fix 1)", async () => {
    await seedBannedUser("banned1");
    const db = testEnv.authenticatedContext("banned1").firestore();
    await assertFails(updateDoc(doc(db, "profiles", "banned1"), {
      banned: false,
    }));
  });

  it("denies user changing own role (re-confirmed with banned field)", async () => {
    await seedUserProfile("user1");
    const db = testEnv.authenticatedContext("user1").firestore();
    await assertFails(updateDoc(doc(db, "profiles", "user1"), {
      role: "operator",
    }));
  });
});

// ===================== POLICY ACCEPTANCE GATE =====================

describe("policy acceptance gate", () => {
  const validChantData = {
    title: "Test",
    sportId: "s1",
    competitionId: "c1",
    teamId: "t1",
    playerId: null,
    subjectTag: "club",
    lyrics: "La la la",
    tuneName: "Original",
    contextNotes: null,
    coverImageUrl: null,
    mediaUrl: null,
    mediaType: "none",
    status: "community",
    chantType: "sincere",
    origin: "originalIdea",
    evidence: null,
    upvotes: 0,
    downvotes: 0,
    score: 0,
    commentCount: 0,
    createdAt: Timestamp.now(),
    updatedAt: Timestamp.now(),
    flagCount: 0,
    hidden: false,
    removed: false,
    variations: [],
  };

  beforeEach(async () => {
    await seedTeam();
  });

  const validCommentData = {
    displayName: "TestUser",
    body: "Great chant",
    likeCount: 0,
    flagCount: 0,
    hidden: false,
    removed: false,
    createdAt: Timestamp.now(),
  };

  it("denies chant create when the user has never accepted the policy",
      async () => {
    await seedUserProfileNoPolicyAcceptance("noaccept1");
    const db = testEnv.authenticatedContext("noaccept1").firestore();
    await assertFails(setDoc(doc(db, "chants", "gated-chant"), {
      ...validChantData,
      createdBy: "noaccept1",
    }));
  });

  it("allows chant create once the policy is accepted", async () => {
    await seedUserProfile("accepted1");
    const db = testEnv.authenticatedContext("accepted1").firestore();
    await assertSucceeds(setDoc(doc(db, "chants", "gated-chant-2"), {
      ...validChantData,
      createdBy: "accepted1",
    }));
  });

  it("denies comment create when the user has never accepted the policy",
      async () => {
    await seedUserProfileNoPolicyAcceptance("noaccept2");
    const db = testEnv.authenticatedContext("noaccept2").firestore();
    await assertFails(addDoc(collection(db, "comments"), {
      ...validCommentData,
      chantId: "ch1",
      userId: "noaccept2",
    }));
  });

  it("allows comment create once the policy is accepted", async () => {
    await seedUserProfile("accepted2");
    await seedVisibleChant("ch1", "someone");
    const db = testEnv.authenticatedContext("accepted2").firestore();
    await assertSucceeds(addDoc(collection(db, "comments"), {
      ...validCommentData,
      chantId: "ch1",
      userId: "accepted2",
    }));
  });

  it("denies comment create by a banned user even if they accepted the "
      + "policy (isNotBanned and hasAcceptedPolicy both apply)", async () => {
    await seedBannedUser("banned-accepted");
    const db = testEnv.authenticatedContext("banned-accepted").firestore();
    await assertFails(addDoc(collection(db, "comments"), {
      ...validCommentData,
      chantId: "ch1",
      userId: "banned-accepted",
    }));
  });
});

// ===================== USER REPORTS =====================

describe("user reports", () => {
  it("allows auth user to create a report with the correct doc ID", async () => {
    await seedUserProfile("reporter1");
    await seedUserProfile("baduser");
    const db = testEnv.authenticatedContext("reporter1").firestore();
    await assertSucceeds(setDoc(doc(db, "userReports", "reporter1_baduser"), {
      reportedUserId: "baduser",
      reportedBy: "reporter1",
      reason: "Hate speech or slurs",
      createdAt: Timestamp.now(),
      status: "pending",
    }));
  });

  it("denies reporting yourself", async () => {
    await seedUserProfile("user1");
    const db = testEnv.authenticatedContext("user1").firestore();
    await assertFails(setDoc(doc(db, "userReports", "user1_user1"), {
      reportedUserId: "user1",
      reportedBy: "user1",
      reason: "test",
      createdAt: Timestamp.now(),
      status: "pending",
    }));
  });

  it("denies a second report from the same reporter against the same "
      + "target (doc ID dedup, same mechanism as reports/commentReports)",
      async () => {
    await seedUserProfile("reporter2");
    await seedUserProfile("baduser2");
    const db = testEnv.authenticatedContext("reporter2").firestore();
    await assertSucceeds(setDoc(doc(db, "userReports", "reporter2_baduser2"), {
      reportedUserId: "baduser2",
      reportedBy: "reporter2",
      reason: "Tragedy chanting",
      createdAt: Timestamp.now(),
      status: "pending",
    }));
    // Second create attempt on the SAME doc ID: Firestore create semantics
    // reject a write to a path that already exists, same as reports/
    // commentReports today.
    await assertFails(setDoc(doc(db, "userReports", "reporter2_baduser2"), {
      reportedUserId: "baduser2",
      reportedBy: "reporter2",
      reason: "Trying again",
      createdAt: Timestamp.now(),
      status: "pending",
    }, { merge: false }));
  });

  it("denies create with status other than pending", async () => {
    await seedUserProfile("reporter3");
    const db = testEnv.authenticatedContext("reporter3").firestore();
    await assertFails(setDoc(doc(db, "userReports", "reporter3_baduser3"), {
      reportedUserId: "baduser3",
      reportedBy: "reporter3",
      reason: "test",
      createdAt: Timestamp.now(),
      status: "dismissed",
    }));
  });

  it("denies report create with reportedBy != auth uid (cannot forge the "
      + "reporter identity)", async () => {
    await seedUserProfile("reporter4");
    const db = testEnv.authenticatedContext("reporter4").firestore();
    await assertFails(setDoc(doc(db, "userReports", "reporter4_baduser4"), {
      reportedUserId: "baduser4",
      reportedBy: "someone-else",
      reason: "test",
      createdAt: Timestamp.now(),
      status: "pending",
    }));
  });

  it("denies report create by a banned user", async () => {
    await seedBannedUser("banned-reporter");
    const db = testEnv.authenticatedContext("banned-reporter").firestore();
    await assertFails(setDoc(doc(db, "userReports", "banned-reporter_baduser5"), {
      reportedUserId: "baduser5",
      reportedBy: "banned-reporter",
      reason: "test",
      createdAt: Timestamp.now(),
      status: "pending",
    }));
  });

  it("denies non-operator read", async () => {
    await testEnv.withSecurityRulesDisabled(async (context) => {
      const db = context.firestore();
      await setDoc(doc(db, "userReports", "r1_baduser"), {
        reportedUserId: "baduser",
        reportedBy: "r1",
        reason: "test",
        createdAt: Timestamp.now(),
        status: "pending",
      });
    });
    await seedUserProfile("reader1");
    const db = testEnv.authenticatedContext("reader1").firestore();
    await assertFails(getDoc(doc(db, "userReports", "r1_baduser")));
  });

  it("allows operator read", async () => {
    await testEnv.withSecurityRulesDisabled(async (context) => {
      const db = context.firestore();
      await setDoc(doc(db, "userReports", "r2_baduser"), {
        reportedUserId: "baduser",
        reportedBy: "r2",
        reason: "test",
        createdAt: Timestamp.now(),
        status: "pending",
      });
    });
    await seedOperator("op1");
    const db = testEnv.authenticatedContext("op1").firestore();
    await assertSucceeds(getDoc(doc(db, "userReports", "r2_baduser")));
  });
});

// ===================== COMMENT REPLIES AND BLOCKS =====================

describe("one-level comment replies", () => {
  function commentData(
    userId: string,
    chantId: string,
    parentCommentId: string | null,
  ) {
    return {
      chantId,
      userId,
      displayName: "TestUser",
      body: "A direct reply",
      parentCommentId,
      createdAt: Timestamp.now(),
      likeCount: 0,
      flagCount: 0,
      hidden: false,
      removed: false,
    };
  }

  it("allows a valid direct reply", async () => {
    await seedUserProfile("author");
    await seedUserProfile("replier");
    await seedVisibleChant("ch1", "author");
    await seedComment("parent", "ch1", "author");
    const db = testEnv.authenticatedContext("replier").firestore();

    await assertSucceeds(setDoc(
      doc(db, "comments", "reply"),
      commentData("replier", "ch1", "parent"),
    ));
  });

  it("denies reply-to-reply and invented parents", async () => {
    await seedUserProfile("author");
    await seedUserProfile("replier");
    await seedVisibleChant("ch1", "author");
    await seedComment("parent", "ch1", "author");
    await seedComment("existing-reply", "ch1", "replier", {
      parentCommentId: "parent",
    });
    const db = testEnv.authenticatedContext("replier").firestore();

    await assertFails(setDoc(
      doc(db, "comments", "nested"),
      commentData("replier", "ch1", "existing-reply"),
    ));
    await assertFails(setDoc(
      doc(db, "comments", "invented"),
      commentData("replier", "ch1", "missing-parent"),
    ));
  });

  it("denies cross-chant, hidden-parent, and removed-parent replies", async () => {
    await seedUserProfile("author");
    await seedUserProfile("replier");
    await seedVisibleChant("ch1", "author");
    await seedVisibleChant("ch2", "author");
    await seedComment("other-chant", "ch2", "author");
    await seedComment("hidden-parent", "ch1", "author", { hidden: true });
    await seedComment("removed-parent", "ch1", "author", { removed: true });
    const db = testEnv.authenticatedContext("replier").firestore();

    await assertFails(setDoc(
      doc(db, "comments", "cross-chant"),
      commentData("replier", "ch1", "other-chant"),
    ));
    await assertFails(setDoc(
      doc(db, "comments", "under-hidden"),
      commentData("replier", "ch1", "hidden-parent"),
    ));
    await assertFails(setDoc(
      doc(db, "comments", "under-removed"),
      commentData("replier", "ch1", "removed-parent"),
    ));
  });

  it("keeps chantId and parentCommentId immutable", async () => {
    await seedUserProfile("replier");
    await seedVisibleChant("ch1", "author");
    await seedVisibleChant("ch2", "author");
    await seedComment("parent", "ch1", "author");
    await seedComment("reply", "ch1", "replier", {
      parentCommentId: "parent",
    });
    const db = testEnv.authenticatedContext("replier").firestore();

    await assertFails(updateDoc(doc(db, "comments", "reply"), {
      parentCommentId: null,
    }));
    await assertFails(updateDoc(doc(db, "comments", "reply"), {
      chantId: "ch2",
    }));
    await assertSucceeds(updateDoc(doc(db, "comments", "reply"), {
      removed: true,
    }));
  });
});

describe("blocks and interaction privacy", () => {
  async function block(blockerId: string, blockedUserId: string) {
    const db = testEnv.authenticatedContext(blockerId).firestore();
    await assertSucceeds(setDoc(
      doc(db, "blocks", `${blockerId}_${blockedUserId}`),
      {
        blockerId,
        blockedUserId,
        blockedDisplayName: "BlockedFan",
        createdAt: Timestamp.now(),
      },
    ));
  }

  it("lets the blocker create, read, and delete a block but hides it from the target", async () => {
    await seedUserProfile("blocker");
    await seedUserProfile("target");
    await block("blocker", "target");
    const blockerDb = testEnv.authenticatedContext("blocker").firestore();
    const targetDb = testEnv.authenticatedContext("target").firestore();

    await assertSucceeds(getDoc(doc(blockerDb, "blocks", "blocker_target")));
    await assertFails(getDoc(doc(targetDb, "blocks", "blocker_target")));
    await assertSucceeds(deleteDoc(doc(blockerDb, "blocks", "blocker_target")));
  });

  it("denies self-blocks and forged block IDs", async () => {
    await seedUserProfile("blocker");
    await seedUserProfile("target");
    const db = testEnv.authenticatedContext("blocker").firestore();

    await assertFails(setDoc(doc(db, "blocks", "blocker_blocker"), {
      blockerId: "blocker",
      blockedUserId: "blocker",
      blockedDisplayName: "Self",
      createdAt: Timestamp.now(),
    }));
    await assertFails(setDoc(doc(db, "blocks", "wrong-id"), {
      blockerId: "blocker",
      blockedUserId: "target",
      blockedDisplayName: "Target",
      createdAt: Timestamp.now(),
    }));
  });

  it("prevents replies and likes in either direction after a block", async () => {
    await seedUserProfile("blocker");
    await seedUserProfile("target");
    await seedVisibleChant("ch1", "blocker");
    await seedComment("blocker-comment", "ch1", "blocker");
    await seedComment("target-comment", "ch1", "target");
    await block("blocker", "target");
    const blockerDb = testEnv.authenticatedContext("blocker").firestore();
    const targetDb = testEnv.authenticatedContext("target").firestore();

    await assertFails(setDoc(doc(blockerDb, "comments", "blocked-reply"), {
      chantId: "ch1",
      userId: "blocker",
      displayName: "TestUser",
      body: "No interaction",
      parentCommentId: "target-comment",
      createdAt: Timestamp.now(),
      likeCount: 0,
      flagCount: 0,
      hidden: false,
      removed: false,
    }));
    await assertFails(setDoc(doc(targetDb, "comments", "reverse-reply"), {
      chantId: "ch1",
      userId: "target",
      displayName: "TestUser",
      body: "No reverse interaction",
      parentCommentId: "blocker-comment",
      createdAt: Timestamp.now(),
      likeCount: 0,
      flagCount: 0,
      hidden: false,
      removed: false,
    }));
    await assertFails(setDoc(
      doc(blockerDb, "commentLikes", "blocker_target-comment"),
      {
        commentId: "target-comment",
        userId: "blocker",
        value: 1,
        createdAt: Timestamp.now(),
      },
    ));
  });

  it("keeps vote and comment-like history private", async () => {
    await seedUserProfile("owner");
    await seedUserProfile("stranger");
    await seedVisibleChant("ch1", "owner");
    await seedComment("comment", "ch1", "stranger");
    const ownerDb = testEnv.authenticatedContext("owner").firestore();
    const strangerDb = testEnv.authenticatedContext("stranger").firestore();

    await assertSucceeds(setDoc(doc(ownerDb, "votes", "owner_ch1"), {
      chantId: "ch1",
      userId: "owner",
      value: 1,
      createdAt: Timestamp.now(),
    }));
    await assertFails(getDoc(doc(strangerDb, "votes", "owner_ch1")));
    await assertSucceeds(setDoc(
      doc(ownerDb, "commentLikes", "owner_comment"),
      {
        commentId: "comment",
        userId: "owner",
        value: 1,
        createdAt: Timestamp.now(),
      },
    ));
    await assertFails(getDoc(doc(strangerDb, "commentLikes", "owner_comment")));
  });
});

// ===================== BLOCK 3: PROFILE CREATE PINS BANNED =====================

describe("profile create pins banned", () => {
  it("allows create with banned == false", async () => {
    const db = testEnv.authenticatedContext("newuser").firestore();
    await assertSucceeds(setDoc(doc(db, "profiles", "newuser"), {
      displayName: "NewFan",
      role: "user",
      banned: false,
      ageConfirmed17Plus: true,
      userReportCount: 0,
      createdAt: Timestamp.now(),
      updatedAt: Timestamp.now(),
    }));
  });

  it("denies create with banned == true", async () => {
    const db = testEnv.authenticatedContext("newuser2").firestore();
    await assertFails(setDoc(doc(db, "profiles", "newuser2"), {
      displayName: "Hacker",
      role: "user",
      banned: true,
      createdAt: Timestamp.now(),
      updatedAt: Timestamp.now(),
    }));
  });
});

// ===================== BLOCK 3: REPORT DEDUP (doc ID) =====================

describe("report dedup", () => {
  it("allows report with correct doc ID convention", async () => {
    await seedUserProfile("user1");
    await seedVisibleChant("ch1", "someone");
    const db = testEnv.authenticatedContext("user1").firestore();
    await assertSucceeds(setDoc(doc(db, "reports", "user1_ch1"), {
      chantId: "ch1",
      reportedBy: "user1",
      reason: "Hate speech",
      createdAt: Timestamp.now(),
      status: "pending",
    }));
  });

  it("denies report with wrong doc ID", async () => {
    await seedUserProfile("user1");
    const db = testEnv.authenticatedContext("user1").firestore();
    await assertFails(setDoc(doc(db, "reports", "wrong-id"), {
      chantId: "ch1",
      reportedBy: "user1",
      reason: "test",
      createdAt: Timestamp.now(),
      status: "pending",
    }));
  });
});

// ===================== BLOCK 3: SERVER-SIDE LENGTH LIMITS (Fix 3) =====================

describe("server-side length limits", () => {
  beforeEach(async () => {
    await seedTeam();
  });

  it("denies chant with title > 200 chars", async () => {
    await seedUserProfile("user1");
    const db = testEnv.authenticatedContext("user1").firestore();
    await assertFails(setDoc(doc(db, "chants", "long-title"), {
      title: "x".repeat(201),
      sportId: "s1",
      competitionId: "c1",
      teamId: "t1",
      playerId: null,
      subjectTag: "club",
      lyrics: "test",
      tuneName: "test",
      contextNotes: null,
      coverImageUrl: null,
      mediaUrl: null,
      mediaType: "none",
      status: "community",
      chantType: "sincere",
      origin: "originalIdea",
      evidence: null,
      upvotes: 0, downvotes: 0, score: 0, commentCount: 0,
      createdBy: "user1",
      createdAt: Timestamp.now(),
      updatedAt: Timestamp.now(),
      flagCount: 0,
      hidden: false,
      removed: false,
      variations: [],
    }));
  });

  it("denies chant with lyrics > 5000 chars", async () => {
    await seedUserProfile("user1");
    const db = testEnv.authenticatedContext("user1").firestore();
    await assertFails(setDoc(doc(db, "chants", "long-lyrics"), {
      title: "test",
      sportId: "s1",
      competitionId: "c1",
      teamId: "t1",
      playerId: null,
      subjectTag: "club",
      lyrics: "x".repeat(5001),
      tuneName: "test",
      contextNotes: null,
      coverImageUrl: null,
      mediaUrl: null,
      mediaType: "none",
      status: "community",
      chantType: "sincere",
      origin: "originalIdea",
      evidence: null,
      upvotes: 0, downvotes: 0, score: 0, commentCount: 0,
      createdBy: "user1",
      createdAt: Timestamp.now(),
      updatedAt: Timestamp.now(),
      flagCount: 0,
      hidden: false,
      removed: false,
      variations: [],
    }));
  });

  it("allows chant with fields at max length", async () => {
    await seedUserProfile("user1");
    const db = testEnv.authenticatedContext("user1").firestore();
    await assertSucceeds(setDoc(doc(db, "chants", "max-len"), {
      title: "x".repeat(200),
      sportId: "s1",
      competitionId: "c1",
      teamId: "t1",
      playerId: null,
      subjectTag: "club",
      lyrics: "x".repeat(5000),
      tuneName: "x".repeat(200),
      contextNotes: "x".repeat(500),
      coverImageUrl: null,
      mediaUrl: null,
      mediaType: "none",
      status: "community",
      chantType: "sincere",
      origin: "originalIdea",
      evidence: null,
      upvotes: 0, downvotes: 0, score: 0, commentCount: 0,
      createdBy: "user1",
      createdAt: Timestamp.now(),
      updatedAt: Timestamp.now(),
      flagCount: 0,
      hidden: false,
      removed: false,
      variations: [],
    }));
  });

  it("denies chant with contextNotes > 500 chars", async () => {
    await seedUserProfile("user1");
    const db = testEnv.authenticatedContext("user1").firestore();
    await assertFails(setDoc(doc(db, "chants", "long-context"), {
      title: "test",
      sportId: "s1",
      competitionId: "c1",
      teamId: "t1",
      playerId: null,
      subjectTag: "club",
      lyrics: "test",
      tuneName: "test",
      contextNotes: "x".repeat(501),
      coverImageUrl: null,
      mediaUrl: null,
      mediaType: "none",
      status: "community",
      chantType: "sincere",
      origin: "originalIdea",
      evidence: null,
      upvotes: 0, downvotes: 0, score: 0, commentCount: 0,
      createdBy: "user1",
      createdAt: Timestamp.now(),
      updatedAt: Timestamp.now(),
      flagCount: 0,
      hidden: false,
      removed: false,
      variations: [],
    }));
  });
});

// ===================== BLOCK 4: CANONICAL PROMOTION (Fix C) =====================

describe("canonical promotion rules", () => {
  it("denies non-operator setting status to canonical via client write", async () => {
    await seedVisibleChant("ch1", "user1");
    await seedUserProfile("user1");
    const db = testEnv.authenticatedContext("user1").firestore();
    await assertFails(updateDoc(doc(db, "chants", "ch1"), {
      status: "canonical",
    }));
  });

  it("denies raw operator promotion without evidence", async () => {
    await seedVisibleChant("ch1", "user1");
    await seedOperator("op1");
    const db = testEnv.authenticatedContext("op1").firestore();
    await assertFails(updateDoc(doc(db, "chants", "ch1"), {
      status: "canonical",
    }));
  });

  it("allows raw operator promotion with canonical evidence", async () => {
    await seedVisibleChant("ch1", "user1", {
      origin: "alreadySung",
      evidence: {
        provider: "youtube",
        url: "https://www.youtube.com/watch?v=dQw4w9WgXcQ",
      },
    });
    await seedOperator("op1");
    const db = testEnv.authenticatedContext("op1").firestore();
    await assertSucceeds(updateDoc(doc(db, "chants", "ch1"), {
      status: "canonical",
    }));
  });

  it("allows the sourcing-ledger exception for a system chant", async () => {
    await seedVisibleChant("seed-chant", "system");
    await seedOperator("op1");
    const db = testEnv.authenticatedContext("op1").firestore();
    await assertSucceeds(updateDoc(doc(db, "chants", "seed-chant"), {
      status: "canonical",
    }));
  });

  it("cannot strip evidence while leaving a user chant canonical", async () => {
    await seedVisibleChant("ch1", "user1", {
      status: "canonical",
      origin: "alreadySung",
      evidence: {
        provider: "x",
        url: "https://x.com/arsenal/status/1234567890",
      },
    });
    await seedOperator("op1");
    const db = testEnv.authenticatedContext("op1").firestore();
    await assertFails(updateDoc(doc(db, "chants", "ch1"), {
      evidence: deleteField(),
    }));
    await assertSucceeds(updateDoc(doc(db, "chants", "ch1"), {
      evidence: deleteField(),
      status: "community",
    }));
  });

  it("still allows moderation of a legacy user canonical chant", async () => {
    await seedVisibleChant("legacy", "user1", { status: "canonical" });
    await seedOperator("op1");
    const db = testEnv.authenticatedContext("op1").firestore();
    await assertSucceeds(updateDoc(doc(db, "chants", "legacy"), {
      hidden: true,
    }));
  });

  it("allows moderation when malformed legacy evidence stays untouched", async () => {
    await testEnv.withSecurityRulesDisabled(async (context) => {
      const db = context.firestore();
      await setDoc(doc(db, "chants", "legacy-malformed"), {
        ...validNewChantData("user1"),
        status: "canonical",
        evidence: {
          provider: "youtube",
          url: "https://youtube.com.example.test/watch?v=dQw4w9WgXcQ",
        },
      });
    });
    await seedOperator("op1");
    const db = testEnv.authenticatedContext("op1").firestore();
    await assertSucceeds(updateDoc(doc(db, "chants", "legacy-malformed"), {
      hidden: true,
    }));
    await assertFails(updateDoc(doc(db, "chants", "legacy-malformed"), {
      status: "canonical",
      evidence: {
        provider: "youtube",
        url: "https://youtube.com.example.test/watch?v=aaaaaaaaaaa",
      },
    }));
  });

  it("keeps origin immutable for raw operator writes", async () => {
    await seedVisibleChant("ch1", "user1", {
      origin: "originalIdea",
    });
    await seedOperator("op1");
    const db = testEnv.authenticatedContext("op1").firestore();
    await assertFails(updateDoc(doc(db, "chants", "ch1"), {
      origin: "alreadySung",
    }));
  });

  it("denies author self-promoting their own chant", async () => {
    await seedVisibleChant("ch1", "user1");
    await seedUserProfile("user1");
    const db = testEnv.authenticatedContext("user1").firestore();
    // Author update rule blocks status changes
    await assertFails(updateDoc(doc(db, "chants", "ch1"), {
      status: "canonical",
    }));
  });
});
