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
    storage: {
      rules: fs.readFileSync(
        path.resolve(__dirname, "../../storage.rules"),
        "utf8",
      ),
    },
  });
});

afterAll(async () => {
  await testEnv.cleanup();
});

afterEach(async () => {
  await testEnv.clearStorage();
});

function getStorage(uid) {
  return testEnv.authenticatedContext(uid).storage();
}

function getUnauthenticatedStorage() {
  return testEnv.unauthenticatedContext().storage();
}

function createImageBlob(sizeInBytes = 1024) {
  return new Uint8Array(sizeInBytes);
}

describe("Storage rules - /users/{uid}/avatar.jpg", () => {
  describe("read", () => {
    test("authenticated user can read own avatar", async () => {
      const storage = getStorage("user1");
      const ref = storage.ref("users/user1/avatar.jpg");
      // Reading a non-existent file returns a storage error, not a permission error.
      // We test that the rules don't block the read attempt.
      await assertSucceeds(
        ref.getDownloadURL().catch((e) => {
          if (e.code === "storage/object-not-found") return; // expected
          throw e;
        }),
      );
    });

    test("authenticated user can read another user's avatar", async () => {
      const storage = getStorage("user1");
      const ref = storage.ref("users/user2/avatar.jpg");
      await assertSucceeds(
        ref.getDownloadURL().catch((e) => {
          if (e.code === "storage/object-not-found") return;
          throw e;
        }),
      );
    });

    test("unauthenticated user cannot read avatar", async () => {
      const storage = getUnauthenticatedStorage();
      const ref = storage.ref("users/user1/avatar.jpg");
      await assertFails(ref.getDownloadURL());
    });
  });

  describe("write", () => {
    test("authenticated user can upload own avatar with valid content type", async () => {
      const storage = getStorage("user1");
      const ref = storage.ref("users/user1/avatar.jpg");
      const data = createImageBlob(1024);
      await assertSucceeds(ref.put(data, { contentType: "image/jpeg" }));
    });

    test("authenticated user cannot upload to another user's path", async () => {
      const storage = getStorage("user1");
      const ref = storage.ref("users/user2/avatar.jpg");
      const data = createImageBlob(1024);
      await assertFails(ref.put(data, { contentType: "image/jpeg" }));
    });

    test("unauthenticated user cannot upload", async () => {
      const storage = getUnauthenticatedStorage();
      const ref = storage.ref("users/user1/avatar.jpg");
      const data = createImageBlob(1024);
      await assertFails(ref.put(data, { contentType: "image/jpeg" }));
    });

    test("rejects non-image content type", async () => {
      const storage = getStorage("user1");
      const ref = storage.ref("users/user1/avatar.jpg");
      const data = createImageBlob(1024);
      await assertFails(ref.put(data, { contentType: "application/pdf" }));
    });

    test("rejects files over 5MB", async () => {
      const storage = getStorage("user1");
      const ref = storage.ref("users/user1/avatar.jpg");
      const data = createImageBlob(6 * 1024 * 1024); // 6MB
      await assertFails(ref.put(data, { contentType: "image/jpeg" }));
    });
  });

  describe("delete", () => {
    test("authenticated user can delete own avatar", async () => {
      const storage = getStorage("user1");
      const ref = storage.ref("users/user1/avatar.jpg");
      // Upload first, then delete
      await ref.put(createImageBlob(1024), { contentType: "image/jpeg" });
      await assertSucceeds(ref.delete());
    });

    test("authenticated user cannot delete another user's avatar", async () => {
      const storage = getStorage("user1");
      // Upload as user2
      const storage2 = getStorage("user2");
      await storage2
        .ref("users/user2/avatar.jpg")
        .put(createImageBlob(1024), { contentType: "image/jpeg" });
      // Try to delete as user1
      const ref = storage.ref("users/user2/avatar.jpg");
      await assertFails(ref.delete());
    });
  });
});
