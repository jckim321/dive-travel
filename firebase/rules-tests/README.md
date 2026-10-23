# Firestore rules unit tests

Requires Node 20+, Java 21+ (Firestore emulator), and Firebase CLI.

From repo root:

```bash
firebase emulators:exec --only firestore --project dive-travel-rules-test "node --test firebase/rules-tests/user_create_privilege.test.js"
```

Or with deps installed under this folder (`npm install`):

```bash
# from repo root, with node on PATH
firebase emulators:exec --only firestore --project dive-travel-rules-test "npm --prefix firebase/rules-tests test"
```
