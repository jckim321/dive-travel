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

  it('allows owner delete when the account is open', async () => {
    await testEnv.withSecurityRulesDisabled(async (context) => {
      await context.firestore().collection('users').doc('uid-a').set(
        appSignupPayload(),
      );
    });
    const db = testEnv.authenticatedContext('uid-a').firestore();
    await assertSucceeds(db.collection('users').doc('uid-a').delete());
  });

  it('denies owner delete when blocked or withdrawn', async () => {
    await testEnv.withSecurityRulesDisabled(async (context) => {
      const users = context.firestore().collection('users');
      await users.doc('blocked').set(
        appSignupPayload({ account_blocked: true }),
      );
      await users.doc('withdrawn').set(
        appSignupPayload({ withdrawn_at: new Date('2026-01-01T00:00:00Z') }),
      );
    });
    await assertFails(
      testEnv.authenticatedContext('blocked').firestore()
        .collection('users').doc('blocked').delete(),
    );
    await assertFails(
      testEnv.authenticatedContext('withdrawn').firestore()
        .collection('users').doc('withdrawn').delete(),
    );
  });

  it('allows admin to delete a closed account', async () => {
    await testEnv.withSecurityRulesDisabled(async (context) => {
      const users = context.firestore().collection('users');
      await users.doc('admin-1').set(
        appSignupPayload({ email: 'admin@example.com', is_admin: true }),
      );
      await users.doc('blocked').set(
        appSignupPayload({ account_blocked: true }),
      );
    });
    const db = testEnv.authenticatedContext('admin-1').firestore();
    await assertSucceeds(db.collection('users').doc('blocked').delete());
  });

  it('allows profile fields on an old doc and denies filling member_grade', async () => {
    await testEnv.withSecurityRulesDisabled(async (context) => {
      await context.firestore().collection('users').doc('diver2').set({
        email: 'diver2@dive.test',
        display_name: 'diver2',
        is_admin: false,
      });
    });
    const db = testEnv.authenticatedContext('diver2').firestore();
    await assertSucceeds(
      db.collection('users').doc('diver2').set({
        display_name: '실명',
        phone: '010',
        birth_date: '1990-01-01',
        nationality: 'KR',
      }, { merge: true }),
    );
    await assertFails(
      db.collection('users').doc('diver2').set({
        member_grade: 'silver',
      }, { merge: true }),
    );
  });

  async function seedUser(id, data) {
    await testEnv.withSecurityRulesDisabled(async (context) => {
      await context.firestore().collection('users').doc(id).set({
        email: `${id}@dive.test`,
        display_name: id,
        is_admin: false,
        is_business: false,
        user_role: 'diver',
        member_grade: 'silver',
        member_grade_locked: false,
        paid_purchase_count: 0,
        review_count: 0,
        ...data,
      });
    });
  }

  it('allows a purchase of exactly +1 to raise the matching grade', async () => {
    await seedUser('buyer', { paid_purchase_count: 2, member_grade: 'silver' });
    const db = testEnv.authenticatedContext('buyer').firestore();
    await assertSucceeds(
      db.collection('users').doc('buyer').set({
        paid_purchase_count: 3,
        review_count: 0,
        member_grade: 'gold',
        grade_celebration_pending: true,
        grade_celebration_to: 'gold',
      }, { merge: true }),
    );
  });

  it('denies a purchase of +1 that writes a higher grade than the count', async () => {
    await seedUser('buyer', { paid_purchase_count: 2, member_grade: 'silver' });
    const db = testEnv.authenticatedContext('buyer').firestore();
    await assertFails(
      db.collection('users').doc('buyer').set({
        paid_purchase_count: 3,
        member_grade: 'platinum',
      }, { merge: true }),
    );
  });

  it('denies raising a grade when the purchase count jumps by more than 1', async () => {
    await seedUser('buyer', { paid_purchase_count: 2, member_grade: 'silver' });
    const db = testEnv.authenticatedContext('buyer').firestore();
    await assertFails(
      db.collection('users').doc('buyer').set({
        paid_purchase_count: 4,
        member_grade: 'gold',
      }, { merge: true }),
    );
  });

  it('allows the 10th purchase to raise diamond', async () => {
    await seedUser('buyer', { paid_purchase_count: 9, member_grade: 'gold' });
    const db = testEnv.authenticatedContext('buyer').firestore();
    await assertSucceeds(
      db.collection('users').doc('buyer').set({
        paid_purchase_count: 10,
        member_grade: 'diamond',
      }, { merge: true }),
    );
  });

  it('allows the 20th purchase to raise platinum', async () => {
    await seedUser('buyer', { paid_purchase_count: 19, member_grade: 'diamond' });
    const db = testEnv.authenticatedContext('buyer').firestore();
    await assertSucceeds(
      db.collection('users').doc('buyer').set({
        paid_purchase_count: 20,
        member_grade: 'platinum',
      }, { merge: true }),
    );
  });

  it('denies lowering a grade on the next purchase', async () => {
    await seedUser('buyer', { paid_purchase_count: 20, member_grade: 'platinum' });
    const db = testEnv.authenticatedContext('buyer').firestore();
    await assertFails(
      db.collection('users').doc('buyer').set({
        paid_purchase_count: 21,
        member_grade: 'gold',
      }, { merge: true }),
    );
  });

  it('allows a locked account to increment purchases but not grade', async () => {
    await seedUser('buyer', {
      paid_purchase_count: 2,
      member_grade: 'silver',
      member_grade_locked: true,
    });
    const db = testEnv.authenticatedContext('buyer').firestore();
    await assertSucceeds(
      db.collection('users').doc('buyer').set({
        paid_purchase_count: 3,
      }, { merge: true }),
    );
    await assertFails(
      db.collection('users').doc('buyer').set({
        paid_purchase_count: 4,
        member_grade: 'gold',
      }, { merge: true }),
    );
  });

  it('denies a grade write without a purchase increment', async () => {
    await seedUser('buyer', { paid_purchase_count: 3, member_grade: 'silver' });
    const db = testEnv.authenticatedContext('buyer').firestore();
    await assertFails(
      db.collection('users').doc('buyer').set({
        member_grade: 'gold',
      }, { merge: true }),
    );
  });

  it('denies a grade raise that also sets is_admin', async () => {
    await seedUser('buyer', { paid_purchase_count: 2, member_grade: 'silver' });
    const db = testEnv.authenticatedContext('buyer').firestore();
    await assertFails(
      db.collection('users').doc('buyer').set({
        paid_purchase_count: 3,
        member_grade: 'gold',
        is_admin: true,
      }, { merge: true }),
    );
  });

  it('denies the owner changing member_grade_locked', async () => {
    await seedUser('buyer', { member_grade_locked: true });
    const db = testEnv.authenticatedContext('buyer').firestore();
    await assertFails(
      db.collection('users').doc('buyer').set({
        member_grade_locked: false,
      }, { merge: true }),
    );
  });

  it('allows an admin to set member_grade without a purchase increment', async () => {
    await seedUser('admin-1', { is_admin: true });
    await seedUser('buyer', { member_grade: 'silver', paid_purchase_count: 0 });
    const db = testEnv.authenticatedContext('admin-1').firestore();
    await assertSucceeds(
      db.collection('users').doc('buyer').set({
        member_grade: 'platinum',
        member_grade_locked: true,
      }, { merge: true }),
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
