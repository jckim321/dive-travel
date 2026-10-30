import { describe, it } from 'node:test';
import assert from 'node:assert/strict';

import {
  RETENTION_MS,
  purgeDueMembers,
  shouldPurgeMember,
} from './purgeDeletedMembers.js';

const now = new Date('2026-10-30T00:00:00Z');
const due = new Date(now.getTime() - RETENTION_MS - 1000);
const recent = new Date(now.getTime() - RETENTION_MS + 60 * 60 * 1000);

function member(deletedAt, extra = {}) {
  return { deleted_at: deletedAt, is_admin: false, owned_shop_id: '', ...extra };
}

describe('shouldPurgeMember', () => {
  it('purges a member who has been in the trash for 30 days', () => {
    assert.equal(shouldPurgeMember(member(due), now), true);
  });

  it('keeps a member inside the 30 days', () => {
    assert.equal(shouldPurgeMember(member(recent), now), false);
    assert.equal(shouldPurgeMember({}, now), false);
  });

  it('skips admins and members linked to a resort', () => {
    assert.equal(shouldPurgeMember(member(due, { is_admin: true }), now), false);
    assert.equal(
      shouldPurgeMember(member(due, { owned_shop_id: 'reef-shop' }), now),
      false,
    );
    assert.equal(
      shouldPurgeMember(member(due, { owned_shop_id: '  ' }), now),
      true,
    );
  });
});

describe('purgeDueMembers', () => {
  it('disables Auth before deleting the user document and leaves everyone else', async () => {
    const calls = [];
    const docs = [
      { id: 'due-1', data: member(due) },
      { id: 'admin-1', data: member(due, { is_admin: true }) },
      { id: 'linked-1', data: member(due, { owned_shop_id: 'reef-shop' }) },
      { id: 'recent-1', data: member(recent) },
      { id: 'auth-fail', data: member(due) },
      { id: 'missing-auth', data: member(due) },
    ].map((doc) => ({
      id: doc.id,
      data: () => doc.data,
      ref: {
        delete: async () => {
          calls.push({ type: 'delete-doc', uid: doc.id });
        },
      },
    }));

    const db = {
      collection(name) {
        assert.equal(name, 'users');
        return {
          where() {
            return { get: async () => ({ docs }) };
          },
        };
      },
    };
    const auth = {
      updateUser: async (uid, patch) => {
        calls.push({ type: 'disable', uid, patch });
        if (uid === 'auth-fail') {
          const error = new Error('unavailable');
          error.code = 'auth/internal-error';
          throw error;
        }
        if (uid === 'missing-auth') {
          const error = new Error('missing');
          error.code = 'auth/user-not-found';
          throw error;
        }
      },
    };

    await purgeDueMembers({ db, auth, now });

    assert.deepEqual(calls, [
      { type: 'disable', uid: 'due-1', patch: { disabled: true } },
      { type: 'delete-doc', uid: 'due-1' },
      { type: 'disable', uid: 'auth-fail', patch: { disabled: true } },
      { type: 'disable', uid: 'missing-auth', patch: { disabled: true } },
      { type: 'delete-doc', uid: 'missing-auth' },
    ]);
  });
});
