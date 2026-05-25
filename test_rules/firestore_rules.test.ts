import {
  initializeTestEnvironment,
  assertSucceeds,
  assertFails,
  RulesTestEnvironment,
} from "@firebase/rules-unit-testing";
import { readFileSync } from "fs";
import { resolve } from "path";
import { Timestamp, setDoc, getDoc, doc, collection, addDoc, updateDoc, deleteDoc, query, where, getDocs } from "firebase/firestore";

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
      createdAt: Timestamp.now(),
      updatedAt: Timestamp.now(),
    });
  });
}

async function seedUserProfile(uid: string) {
  await testEnv.withSecurityRulesDisabled(async (context) => {
    const db = context.firestore();
    await setDoc(doc(db, "profiles", uid), {
      displayName: "TestUser",
      role: "user",
      banned: false,
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
      createdAt: Timestamp.now(),
      updatedAt: Timestamp.now(),
    });
  });
}

async function seedVisibleChant(chantId: string, createdBy: string) {
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
      status: "community",
      realOrParody: "real",
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
      realOrParody: "real",
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
  it("allows public read of any profile", async () => {
    await seedUserProfile("user1");
    const unauth = testEnv.unauthenticatedContext().firestore();
    await assertSucceeds(getDoc(doc(unauth, "profiles", "user1")));
  });

  it("allows owner to create own profile", async () => {
    const db = testEnv.authenticatedContext("user1").firestore();
    await assertSucceeds(setDoc(doc(db, "profiles", "user1"), {
      displayName: "Fan",
      role: "user",
      banned: false,
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
});

// ===================== CHANTS =====================

describe("chants", () => {
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
      realOrParody: "real",
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
      realOrParody: "real",
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
      realOrParody: "real",
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
    }));
  });

  it("allows author to update content fields", async () => {
    await seedVisibleChant("ch1", "user1");
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

  it("allows operator to update anything", async () => {
    await seedVisibleChant("ch1", "user1");
    await seedOperator("op1");
    const db = testEnv.authenticatedContext("op1").firestore();
    await assertSucceeds(updateDoc(doc(db, "chants", "ch1"), {
      status: "canonical",
      hidden: true,
      upvotes: 50,
    }));
  });
});

// ===================== VOTES =====================

describe("votes", () => {
  it("allows create with correct userId and doc ID", async () => {
    await seedUserProfile("user1");
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

  it("allows user to update own vote value", async () => {
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
});

// ===================== REPORT WRITE CORRECTNESS (Fix D) =====================

describe("report write correctness", () => {
  it("allows well-formed report create with status pending and correct doc ID", async () => {
    await seedUserProfile("user1");
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
    realOrParody: "real",
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
  };

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

// ===================== BLOCK 3: PROFILE CREATE PINS BANNED =====================

describe("profile create pins banned", () => {
  it("allows create with banned == false", async () => {
    const db = testEnv.authenticatedContext("newuser").firestore();
    await assertSucceeds(setDoc(doc(db, "profiles", "newuser"), {
      displayName: "NewFan",
      role: "user",
      banned: false,
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
      realOrParody: "real",
      upvotes: 0, downvotes: 0, score: 0, commentCount: 0,
      createdBy: "user1",
      createdAt: Timestamp.now(),
      updatedAt: Timestamp.now(),
      flagCount: 0,
      hidden: false,
      removed: false,
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
      realOrParody: "real",
      upvotes: 0, downvotes: 0, score: 0, commentCount: 0,
      createdBy: "user1",
      createdAt: Timestamp.now(),
      updatedAt: Timestamp.now(),
      flagCount: 0,
      hidden: false,
      removed: false,
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
      realOrParody: "real",
      upvotes: 0, downvotes: 0, score: 0, commentCount: 0,
      createdBy: "user1",
      createdAt: Timestamp.now(),
      updatedAt: Timestamp.now(),
      flagCount: 0,
      hidden: false,
      removed: false,
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
      realOrParody: "real",
      upvotes: 0, downvotes: 0, score: 0, commentCount: 0,
      createdBy: "user1",
      createdAt: Timestamp.now(),
      updatedAt: Timestamp.now(),
      flagCount: 0,
      hidden: false,
      removed: false,
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

  it("allows operator to set status to canonical", async () => {
    await seedVisibleChant("ch1", "user1");
    await seedOperator("op1");
    const db = testEnv.authenticatedContext("op1").firestore();
    await assertSucceeds(updateDoc(doc(db, "chants", "ch1"), {
      status: "canonical",
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
