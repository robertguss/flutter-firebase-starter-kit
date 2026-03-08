const {
  initializeTestEnvironment,
  assertSucceeds,
  assertFails,
} = require("@firebase/rules-unit-testing");
const fs = require("fs");
const path = require("path");

const PROJECT_ID = "test-project";

let testEnv;

beforeAll(async () => {
  testEnv = await initializeTestEnvironment({
    projectId: PROJECT_ID,
    firestore: {
      rules: fs.readFileSync(
        path.resolve(__dirname, "../../firestore.rules"),
        "utf8",
      ),
    },
  });
});

afterAll(async () => {
  await testEnv.cleanup();
});

afterEach(async () => {
  await testEnv.clearFirestore();
});

function getFirestore(uid, email = "test@example.com") {
  return testEnv.authenticatedContext(uid, { email }).firestore();
}

function getUnauthenticatedFirestore() {
  return testEnv.unauthenticatedContext().firestore();
}

function validProfile(overrides = {}) {
  return {
    email: "test@example.com",
    displayName: "Test User",
    photoUrl: "https://example.com/photo.jpg",
    onboardingComplete: false,
    createdAt: new Date(),
    ...overrides,
  };
}

describe("Firestore rules - /users/{uid}", () => {
  describe("read", () => {
    test("authenticated user can read own document", async () => {
      const db = getFirestore("user1");
      await testEnv.withSecurityRulesDisabled(async (context) => {
        await context.firestore().doc("users/user1").set(validProfile());
      });
      await assertSucceeds(db.doc("users/user1").get());
    });

    test("authenticated user cannot read other user's document", async () => {
      const db = getFirestore("user1");
      await testEnv.withSecurityRulesDisabled(async (context) => {
        await context.firestore().doc("users/user2").set(validProfile());
      });
      await assertFails(db.doc("users/user2").get());
    });

    test("unauthenticated user cannot read any document", async () => {
      const db = getUnauthenticatedFirestore();
      await testEnv.withSecurityRulesDisabled(async (context) => {
        await context.firestore().doc("users/user1").set(validProfile());
      });
      await assertFails(db.doc("users/user1").get());
    });
  });

  describe("create", () => {
    test("authenticated user can create own document with valid fields", async () => {
      const db = getFirestore("user1");
      await assertSucceeds(db.doc("users/user1").set(validProfile()));
    });

    test("email must match auth token email", async () => {
      const db = getFirestore("user1", "test@example.com");
      await assertFails(
        db.doc("users/user1").set(validProfile({ email: "wrong@example.com" })),
      );
    });

    test("cannot create another user's document", async () => {
      const db = getFirestore("user1");
      await assertFails(db.doc("users/user2").set(validProfile()));
    });

    test("rejects disallowed fields", async () => {
      const db = getFirestore("user1");
      await assertFails(
        db.doc("users/user1").set(validProfile({ admin: true })),
      );
    });
  });

  describe("update", () => {
    test("can update own displayName", async () => {
      const db = getFirestore("user1");
      await testEnv.withSecurityRulesDisabled(async (context) => {
        await context.firestore().doc("users/user1").set(validProfile());
      });
      await assertSucceeds(
        db.doc("users/user1").update({ displayName: "New Name" }),
      );
    });

    test("can update own photoUrl", async () => {
      const db = getFirestore("user1");
      await testEnv.withSecurityRulesDisabled(async (context) => {
        await context.firestore().doc("users/user1").set(validProfile());
      });
      await assertSucceeds(
        db
          .doc("users/user1")
          .update({ photoUrl: "https://new-url.com/pic.jpg" }),
      );
    });

    test("cannot change createdAt", async () => {
      const db = getFirestore("user1");
      const profile = validProfile();
      await testEnv.withSecurityRulesDisabled(async (context) => {
        await context.firestore().doc("users/user1").set(profile);
      });
      await assertFails(
        db.doc("users/user1").update({ createdAt: new Date() }),
      );
    });

    test("cannot change email to non-auth email", async () => {
      const db = getFirestore("user1", "test@example.com");
      await testEnv.withSecurityRulesDisabled(async (context) => {
        await context.firestore().doc("users/user1").set(validProfile());
      });
      await assertFails(
        db.doc("users/user1").update({ email: "hacked@evil.com" }),
      );
    });

    test("displayName limited to 100 chars", async () => {
      const db = getFirestore("user1");
      await testEnv.withSecurityRulesDisabled(async (context) => {
        await context.firestore().doc("users/user1").set(validProfile());
      });
      await assertFails(
        db.doc("users/user1").update({ displayName: "x".repeat(101) }),
      );
    });

    test("email limited to 254 chars", async () => {
      const db = getFirestore("user1", "test@example.com");
      await testEnv.withSecurityRulesDisabled(async (context) => {
        await context.firestore().doc("users/user1").set(validProfile());
      });
      await assertFails(
        db.doc("users/user1").update({ email: "a".repeat(255) }),
      );
    });

    test("fcmToken limited to 500 chars", async () => {
      const db = getFirestore("user1");
      await testEnv.withSecurityRulesDisabled(async (context) => {
        await context.firestore().doc("users/user1").set(validProfile());
      });
      await assertFails(
        db.doc("users/user1").update({ fcmToken: "t".repeat(501) }),
      );
    });
  });

  describe("delete", () => {
    test("can delete own document", async () => {
      const db = getFirestore("user1");
      await testEnv.withSecurityRulesDisabled(async (context) => {
        await context.firestore().doc("users/user1").set(validProfile());
      });
      await assertSucceeds(db.doc("users/user1").delete());
    });

    test("cannot delete other user's document", async () => {
      const db = getFirestore("user1");
      await testEnv.withSecurityRulesDisabled(async (context) => {
        await context.firestore().doc("users/user2").set(validProfile());
      });
      await assertFails(db.doc("users/user2").delete());
    });
  });
});
