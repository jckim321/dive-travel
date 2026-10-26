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
const day = '2026-10-27';

function demand(cond, overrides = {}) {
  const id = `${userKey}_${day}_${cond}`;
  return {
    id,
    data: {
      user_key: userKey,
      day,
      when: 'this_month',
      region_ids: 'palau,cebu',
      party: 2,
      budget_max: 500000,
      last_call: false,
      departing_soon: false,
      at: new Date(),
      ...overrides,
    },
  };
}

describe('seat demand', () => {
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
      await context.firestore().doc('users/customer-1').set({
        is_admin: false,
      });
      await context.firestore().doc('users/admin-1').set({ is_admin: true });
    });
  });

  it('lets a member create once, denies reads, and denies a duplicate', async () => {
    const customer = testEnv.authenticatedContext('customer-1').firestore();
    const first = demand('b'.repeat(64));

    await assertSucceeds(customer.doc(`seat_demand/${first.id}`).set(first.data));
    await assertFails(customer.doc(`seat_demand/${first.id}`).get());
    await assertFails(customer.collection('seat_demand').get());
    await assertFails(customer.doc(`seat_demand/${first.id}`).set(first.data));

    const mailed = demand('c'.repeat(64), { email: 'a@b.c' });
    await assertFails(customer.doc(`seat_demand/${mailed.id}`).set(mailed.data));

    const opened = demand('d'.repeat(64), { unlock_by: 'budget' });
    await assertSucceeds(
      customer.doc(`seat_demand/${opened.id}`).set(opened.data),
    );
    const badUnlock = demand('e'.repeat(64), { unlock_by: 'price' });
    await assertFails(
      customer.doc(`seat_demand/${badUnlock.id}`).set(badUnlock.data),
    );

    const guest = testEnv.unauthenticatedContext().firestore();
    const anon = demand('f'.repeat(64));
    await assertFails(guest.doc(`seat_demand/${anon.id}`).set(anon.data));
  });
});
