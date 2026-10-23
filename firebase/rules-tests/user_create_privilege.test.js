import { readFileSync } from 'node:fs';
import { dirname, join } from 'node:path';
import { fileURLToPath } from 'node:url';
import { after, before, beforeEach, describe, it } from 'node:test';
import {
  assertFails,
  assertSucceeds,
  initializeTestEnvironment,
} from '@firebase/rules-unit-testing';

const __dirname = dirname(fileURLToPath(import.meta.url));
const RULES = readFileSync(join(__dirname, '..', 'firestore.rules'), 'utf8');
const PROJECT_ID = 'dive-travel-rules-test';

/** Payload shape from ensureUserDocument on first create. */
function appSignupPayload(overrides = {}) {
  return {
    email: 'diver@example.com',
    display_name: 'Diver',
    user_role: 'diver',
    member_grade: 'silver',
    is_instructor: false,
    is_verified_pro: false,
    c_card_agency: '',
    c_card_photo_url: '',
    total_log_count: 0,
    unique_regions_count: 0,
    visited_regions: [],
    region_log_counts: {},
    ...overrides,
  };
}

describe('users/{userId} create privilege lock', () => {
  /** @type {import('@firebase/rules-unit-testing').RulesTestEnvironment} */
  let testEnv;

  before(async () => {
    testEnv = await initializeTestEnvironment({
      projectId: PROJECT_ID,
      firestore: {
        rules: RULES,
        host: '127.0.0.1',
        port: 8080,
      },
    });
  });

  after(async () => {
    await testEnv?.cleanup();
  });

  beforeEach(async () => {
    await testEnv.clearFirestore();
  });

  it('allows owner create with ensureUserDocument defaults', async () => {
    const db = testEnv.authenticatedContext('uid-a').firestore();
    await assertSucceeds(
      db.collection('users').doc('uid-a').set(appSignupPayload()),
    );
  });

  it('denies create with is_admin true', async () => {
    const db = testEnv.authenticatedContext('uid-a').firestore();
    await assertFails(
      db.collection('users').doc('uid-a').set(
        appSignupPayload({ is_admin: true }),
      ),
    );
  });

  it('denies create with is_business and owned_shop_id', async () => {
    const db = testEnv.authenticatedContext('uid-a').firestore();
    await assertFails(
      db.collection('users').doc('uid-a').set(
        appSignupPayload({
          is_business: true,
          owned_shop_id: 'shop-x',
        }),
      ),
    );
  });

  it('denies create with elevated member_grade or user_role', async () => {
    const db = testEnv.authenticatedContext('uid-a').firestore();
    await assertFails(
      db.collection('users').doc('uid-a').set(
        appSignupPayload({ member_grade: 'platinum' }),
      ),
    );
    await assertFails(
      db.collection('users').doc('uid-a').set(
        appSignupPayload({ user_role: 'business' }),
      ),
    );
  });

  it('denies create for another user id', async () => {
    const db = testEnv.authenticatedContext('uid-a').firestore();
    await assertFails(
      db.collection('users').doc('uid-b').set(appSignupPayload()),
    );
  });

  it('allows owner display_name update; denies is_admin update', async () => {
    await testEnv.withSecurityRulesDisabled(async (context) => {
      await context.firestore().collection('users').doc('uid-a').set(
        appSignupPayload({ is_admin: false }),
      );
    });

    const db = testEnv.authenticatedContext('uid-a').firestore();
    await assertSucceeds(
      db.collection('users').doc('uid-a').update({ display_name: 'New Name' }),
    );
    await assertFails(
      db.collection('users').doc('uid-a').update({ is_admin: true }),
    );
  });

  it('denies create with camelCase isAdmin', async () => {
    const db = testEnv.authenticatedContext('uid-a').firestore();
    await assertFails(
      db.collection('users').doc('uid-a').set(
        appSignupPayload({ isAdmin: true }),
      ),
    );
  });
});
