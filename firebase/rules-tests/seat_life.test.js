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
const userKey = 'a'.repeat(64);

function event(overrides = {}) {
  return {
    kind: 'view',
    seat_id: 'p_prod',
    shop_id: 'shop',
    product_id: 'prod',
    option_id: '',
    region: 'PH',
    resort: 'Reef',
    departure: '2026-11-01',
    price: 1000,
    party_size: 1,
    member_grade: 'silver',
    user_key: userKey,
    at: new Date(),
    ...overrides,
  };
}

function day(field) {
  return {
    opens: field === 'opens' ? 1 : 0,
    views: field === 'views' ? 1 : 0,
    flags: field === 'flags' ? 1 : 0,
    expires: field === 'expires' ? 1 : 0,
    pays: field === 'pays' ? 1 : 0,
    cancels: field === 'cancels' ? 1 : 0,
    closes: field === 'closes' ? 1 : 0,
  };
}

describe('seat life analytics', () => {
  /** @type {import('@firebase/rules-unit-testing').RulesTestEnvironment} */
  let testEnv;

  before(async () => {
    testEnv = await initializeTestEnvironment({
      projectId: PROJECT_ID,
      firestore: { rules: RULES, host: '127.0.0.1', port: 8080 },
    });
  });

  after(async () => {
    await testEnv?.cleanup();
  });

  beforeEach(async () => {
    await testEnv.clearFirestore();
    await testEnv.withSecurityRulesDisabled(async (context) => {
      await context.firestore().doc('users/admin-1').set({ is_admin: true });
    });
  });

  it('lets a customer create an event and add 1, and blocks the rest', async () => {
    const guest = testEnv.authenticatedContext('guest-1').firestore();
    const admin = testEnv.authenticatedContext('admin-1').firestore();

    await assertSucceeds(guest.doc('seat_events/view-1').set(event()));
    await assertFails(
      guest.doc('seat_events/view-mail').set(event({ email: 'a@b.c' })),
    );
    await assertFails(guest.doc('seat_events/view-1').get());
    await assertFails(
      guest.doc('seat_events/view-1').update({ party_size: 2 }),
    );
    await assertSucceeds(admin.collection('seat_events').get());

    await assertSucceeds(guest.doc('seat_daily/2026-10-27').set(day('views')));
    await assertSucceeds(
      guest.doc('seat_daily/2026-10-27').update({ views: 2 }),
    );
    await assertFails(
      guest.doc('seat_daily/2026-10-27').update({ views: 4 }),
    );
    await assertFails(
      guest.doc('seat_daily/2026-10-27').update({ views: 1 }),
    );
    await assertFails(guest.doc('seat_daily/2026-10-27').get());
    await assertSucceeds(admin.collection('seat_daily').get());
  });

  it('lets only an admin read and write the outcome line', async () => {
    const guest = testEnv.authenticatedContext('guest-1').firestore();
    const admin = testEnv.authenticatedContext('admin-1').firestore();
    const line = {
      seat_id: 'p_prod',
      shop_id: 'shop',
      opened_on: '2026-10-01',
      first_flag_minutes: 12,
      close_minutes: 40,
      fill_rate: 50,
      pay_rate: 100,
      expire_count: 1,
      close_reason: 'departed',
    };
    await assertFails(guest.doc('seat_outcomes/p_prod').set(line));
    await assertSucceeds(admin.doc('seat_outcomes/p_prod').set(line));
    await assertFails(guest.doc('seat_outcomes/p_prod').get());
    await assertSucceeds(admin.collection('seat_outcomes').get());
    await assertFails(
      admin.doc('seat_outcomes/p_prod').update({ email: 'a@b.c' }),
    );
  });
});
