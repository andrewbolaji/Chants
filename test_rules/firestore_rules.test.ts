import {
  initializeTestEnvironment,
  assertSucceeds,
  assertFails,
  RulesTestEnvironment,
} from "@firebase/rules-unit-testing";
import { readFileSync } from "fs";
import { resolve } from "path";
import { Timestamp, setDoc, getDoc, doc, collection, addDoc, updateDoc, deleteDoc } from "firebase/firestore";

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
      await setDoc(doc(db, "players", "p1"), { teamId: "t1", name: "Saka", position: "RW" });
    });
    const unauth = testEnv.unauthenticatedContext().firestore();
    await assertSucceeds(getDoc(doc(unauth, "players", "p1")));
  });

  it("denies write for non-operator", async () => {
    await seedUserProfile("user1");
    const db = testEnv.authenticatedContext("user1").firestore();
    await assertFails(setDoc(doc(db, "players", "p1"), { teamId: "t1", name: "Saka", position: "RW" }));
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
      createdAt: Timestamp.now(),
      updatedAt: Timestamp.now(),
    }));
  });

  it("denies creating another user's profile", async () => {
    const db = testEnv.authenticatedContext("user1").firestore();
    await assertFails(setDoc(doc(db, "profiles", "user2"), {
      displayName: "Impersonator",
      role: "user",
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
  it("allows auth user to create report", async () => {
    const db = testEnv.authenticatedContext("user1").firestore();
    await assertSucceeds(addDoc(collection(db, "reports"), {
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
    const db = testEnv.authenticatedContext("user1").firestore();
    await assertFails(addDoc(collection(db, "reports"), {
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
