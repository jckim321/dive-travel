import { readFileSync } from 'node:fs';
import { dirname, join } from 'node:path';
import { fileURLToPath } from 'node:url';
import { after, before, beforeEach, describe, it } from 'node:test';
import {
  assertFails,
  assertSucceeds,
  initializeTestEnvironment,
} from '@firebase/rules-unit-testing';
import firebase from 'firebase/compat/app';
import 'firebase/compat/firestore';

const __dirname = dirname(fileURLToPath(import.meta.url));
const RULES = readFileSync(join(__dirname, '..', 'firestore.rules'), 'utf8');
const PROJECT_ID = 'dive-travel-rules-test';
const deletedAt = new Date('2026-10-01T00:00:00Z');

function userDoc(overrides = {}) {
  return {
    email: 'member@dive.test',
    display_name: 'Member',
    is_admin: false,
    is_business: false,
    user_role: 'diver',
    member_grade: 'silver',
    owned_shop_id: '',
    ...overrides,
  };
}

describe('member archive closure rules', () => {
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

  async function seed(id, data) {
    await testEnv.withSecurityRulesDisabled(async (context) => {
      await context.firestore().collection('users').doc(id).set(userDoc(data));
    });
  }

  it('denies create that includes deleted_at', async () => {
    const db = testEnv.authenticatedContext('uid-a').firestore();
    await assertFails(
      db.collection('users').doc('uid-a').set(userDoc({
        user_role: 'diver',
        member_grade: 'silver',
        deleted_at: deletedAt,
      })),
    );
  });

  it('denies the owner setting deleted_at', async () => {
    await seed('uid-a');
    const db = testEnv.authenticatedContext('uid-a').firestore();
    await assertFails(
      db.collection('users').doc('uid-a').update({ deleted_at: deletedAt }),
    );
  });

  it('allows an admin to soft-delete another open member', async () => {
    await seed('admin-1', { is_admin: true, email: 'admin@dive.test' });
    await seed('member-1');
    const db = testEnv.authenticatedContext('admin-1').firestore();
    await assertSucceeds(
      db.collection('users').doc('member-1').update({ deleted_at: deletedAt }),
    );
  });

  it('denies an admin blocking, withdrawing, or deleting themselves', async () => {
    await seed('admin-1', { is_admin: true, email: 'admin@dive.test' });
    const db = testEnv.authenticatedContext('admin-1').firestore();
    const self = db.collection('users').doc('admin-1');
    await assertSucceeds(self.update({ display_name: 'Still Admin' }));
    await assertFails(self.update({ account_blocked: true }));
    await assertFails(self.update({ withdrawn_at: deletedAt }));
    await assertFails(self.update({ deleted_at: deletedAt }));
    await assertFails(self.delete());
  });

  it('allows an admin to delete another member document', async () => {
    await seed('admin-1', { is_admin: true, email: 'admin@dive.test' });
    await seed('member-1', { deleted_at: deletedAt });
    const db = testEnv.authenticatedContext('admin-1').firestore();
    await assertSucceeds(db.collection('users').doc('member-1').delete());
  });

  it('denies withdraw and soft-delete while a resort is linked', async () => {
    await seed('admin-1', { is_admin: true, email: 'admin@dive.test' });
    await seed('partner-1', {
      is_business: true,
      user_role: 'business',
      owned_shop_id: 'reef-shop',
    });
    const db = testEnv.authenticatedContext('admin-1').firestore();
    const partner = db.collection('users').doc('partner-1');
    await assertFails(partner.update({ withdrawn_at: deletedAt }));
    await assertFails(partner.update({ deleted_at: deletedAt }));
    await assertSucceeds(partner.update({ account_blocked: true }));
  });

  it('allows soft-delete after the resort link is empty', async () => {
    await seed('admin-1', { is_admin: true, email: 'admin@dive.test' });
    await seed('partner-1', {
      is_business: true,
      user_role: 'business',
      owned_shop_id: '',
    });
    const db = testEnv.authenticatedContext('admin-1').firestore();
    await assertSucceeds(
      db.collection('users').doc('partner-1').update({ deleted_at: deletedAt }),
    );
  });

  it('allows restoring deleted_at while a resort is still linked', async () => {
    await seed('admin-1', { is_admin: true, email: 'admin@dive.test' });
    await seed('partner-1', {
      is_business: true,
      user_role: 'business',
      owned_shop_id: 'reef-shop',
      deleted_at: deletedAt,
    });
    const db = testEnv.authenticatedContext('admin-1').firestore();
    await assertSucceeds(
      db.collection('users').doc('partner-1').update({
        deleted_at: firebase.firestore.FieldValue.delete(),
      }),
    );
  });

  it('denies a deleted member from updating or deleting their document', async () => {
    await seed('gone', { deleted_at: deletedAt });
    const db = testEnv.authenticatedContext('gone').firestore();
    const self = db.collection('users').doc('gone');
    await assertFails(self.update({ display_name: 'Back' }));
    await assertFails(self.delete());
  });

  it('denies a deleted member from changing their booking copy', async () => {
    await testEnv.withSecurityRulesDisabled(async (context) => {
      const db = context.firestore();
      await db.collection('users').doc('gone').set(userDoc({ deleted_at: deletedAt }));
      await db.collection('users').doc('gone').collection('bookings').doc('b1').set({
        shop_id: 'reef-shop',
        status: 'confirmed',
      });
    });
    const db = testEnv.authenticatedContext('gone').firestore();
    await assertFails(
      db.collection('users').doc('gone').collection('bookings').doc('b1')
        .update({ status: 'cancelled' }),
    );
  });
});
