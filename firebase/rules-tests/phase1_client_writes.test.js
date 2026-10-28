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

function diverDoc(overrides = {}) {
  return {
    email: 'diver@example.com',
    display_name: 'Diver',
    user_role: 'diver',
    member_grade: 'silver',
    is_admin: false,
    is_business: false,
    is_instructor: false,
    is_verified_pro: false,
    ...overrides,
  };
}

function loiPayload(overrides = {}) {
  return {
    shop_id: 'bohol-hideout',
    shop_name: '보홀',
    partner_uid: 'partner-a',
    company_name: '보홀 다이브',
    contact_name: '김',
    signature_png_base64: 'iVBORw0KGgo=',
    ...overrides,
  };
}

function postPayload(overrides = {}) {
  return {
    type: 'buddy',
    title: '보홀 같이 타요',
    subtitle: '2탱크',
    author_uid: 'uid-a',
    author_name: 'Diver',
    hidden: false,
    language: 'ko',
    created_at: new Date(),
    ...overrides,
  };
}

describe('phase 1 client write locks', { concurrency: 1 }, () => {
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

  async function seed(path, data) {
    await testEnv.withSecurityRulesDisabled(async (context) => {
      await context.firestore().doc(path).set(data);
    });
  }

  it('lets the owner submit instructor verification as pending', async () => {
    await seed('users/uid-a', diverDoc());
    const db = testEnv.authenticatedContext('uid-a').firestore();
    await assertSucceeds(
      db.collection('users').doc('uid-a').set({
        is_verified_pro: 'pending',
        is_instructor: false,
        c_card_agency: 'PADI',
        c_card_photo_url: 'https://example.com/card.jpg',
        c_card_submitted_at: new Date(),
      }, { merge: true }),
    );
  });

  it('denies the owner writing an approved pro status or instructor flag', async () => {
    await seed('users/uid-a', diverDoc());
    const db = testEnv.authenticatedContext('uid-a').firestore();
    await assertFails(
      db.collection('users').doc('uid-a').update({ is_verified_pro: true }),
    );
    await assertFails(
      db.collection('users').doc('uid-a').update({ is_instructor: true }),
    );
    await assertFails(
      db.collection('users').doc('uid-a').update({ is_verified_pro: 'rejected' }),
    );
  });

  it('lets an admin approve an instructor', async () => {
    await seed('users/admin-1', diverDoc({
      email: 'admin@example.com',
      is_admin: true,
    }));
    await seed('users/uid-a', diverDoc({ is_verified_pro: 'pending' }));
    const db = testEnv.authenticatedContext('admin-1').firestore();
    await assertSucceeds(
      db.collection('users').doc('uid-a').set({
        is_instructor: true,
        is_verified_pro: true,
      }, { merge: true }),
    );
  });

  it('lets the author create a post and denies another uid', async () => {
    await seed('users/uid-a', diverDoc());
    const db = testEnv.authenticatedContext('uid-a').firestore();
    await assertSucceeds(db.collection('posts').add(postPayload()));
    await assertFails(
      db.collection('posts').add(postPayload({ author_uid: 'uid-b' })),
    );
    await assertFails(
      db.collection('posts').add(postPayload({ title: 'x'.repeat(121) })),
    );
    await assertFails(
      db.collection('posts').add(postPayload({ subtitle: 'x'.repeat(2001) })),
    );
  });

  it('lets a partner file a dive star application only for their shop', async () => {
    await seed('users/partner-a', diverDoc({
      is_business: true,
      owned_shop_id: 'bohol-hideout',
    }));
    const db = testEnv.authenticatedContext('partner-a').firestore();
    await assertSucceeds(
      db.collection('dive_star_applications').add(loiPayload()),
    );
    await assertFails(
      db.collection('dive_star_applications').add(
        loiPayload({ shop_id: 'other-shop' }),
      ),
    );
  });
});
