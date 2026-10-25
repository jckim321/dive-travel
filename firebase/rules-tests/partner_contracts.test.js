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
const SHOP = 'shop-contract-a';
const OTHER = 'shop-contract-b';

function draftDoc(overrides = {}) {
  return {
    shop_id: SHOP,
    kind: 'master',
    title: 'Master',
    version: '1',
    status: 'drafting',
    file_url: 'https://example.test/a.pdf',
    file_sha256: 'abc123',
    file_content_type: 'application/pdf',
    uploaded_by_uid: 'admin-1',
    ...overrides,
  };
}

describe('shops/{shopId}/partner_contracts', () => {
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
    await testEnv.withSecurityRulesDisabled(async (ctx) => {
      const db = ctx.firestore();
      await db.doc(`users/admin-1`).set({ is_admin: true, is_business: false });
      await db.doc(`users/partner-a`).set({
        is_admin: false,
        is_business: true,
        owned_shop_id: SHOP,
      });
      await db.doc(`users/partner-b`).set({
        is_admin: false,
        is_business: true,
        owned_shop_id: OTHER,
      });
      await db.doc(`shops/${SHOP}`).set({ name: 'A' });
      await db.doc(`shops/${OTHER}`).set({ name: 'B' });
    });
  });

  it('hides drafting from partner; admin can read', async () => {
    await testEnv.withSecurityRulesDisabled(async (ctx) => {
      await ctx
        .firestore()
        .doc(`shops/${SHOP}/partner_contracts/d1`)
        .set(draftDoc());
    });
    const partner = testEnv.authenticatedContext('partner-a').firestore();
    await assertFails(
      partner.doc(`shops/${SHOP}/partner_contracts/d1`).get(),
    );
    const admin = testEnv.authenticatedContext('admin-1').firestore();
    await assertSucceeds(
      admin.doc(`shops/${SHOP}/partner_contracts/d1`).get(),
    );
  });

  it('denies other shop partner read of awaiting doc', async () => {
    await testEnv.withSecurityRulesDisabled(async (ctx) => {
      await ctx
        .firestore()
        .doc(`shops/${SHOP}/partner_contracts/d2`)
        .set(draftDoc({ status: 'awaiting_signature' }));
    });
    const other = testEnv.authenticatedContext('partner-b').firestore();
    await assertFails(
      other.doc(`shops/${SHOP}/partner_contracts/d2`).get(),
    );
    const owner = testEnv.authenticatedContext('partner-a').firestore();
    await assertSucceeds(
      owner.doc(`shops/${SHOP}/partner_contracts/d2`).get(),
    );
  });

  it('denies admin update after executed', async () => {
    await testEnv.withSecurityRulesDisabled(async (ctx) => {
      await ctx
        .firestore()
        .doc(`shops/${SHOP}/partner_contracts/d3`)
        .set(
          draftDoc({
            status: 'executed',
            signature: {
              signer_uid: 'partner-a',
              signer_name: 'P',
              signature_png_base64: 'xx',
              signed_at: new Date(),
              doc_sha256: 'abc123',
            },
          }),
        );
    });
    const admin = testEnv.authenticatedContext('admin-1').firestore();
    await assertFails(
      admin.doc(`shops/${SHOP}/partner_contracts/d3`).update({
        title: 'hacked',
      }),
    );
  });

  it('denies forged signature sha on partner execute', async () => {
    await testEnv.withSecurityRulesDisabled(async (ctx) => {
      await ctx
        .firestore()
        .doc(`shops/${SHOP}/partner_contracts/d4`)
        .set(draftDoc({ status: 'awaiting_signature' }));
    });
    const partner = testEnv.authenticatedContext('partner-a').firestore();
    await assertFails(
      partner.doc(`shops/${SHOP}/partner_contracts/d4`).update({
        status: 'executed',
        executed_at: new Date(),
        signature: {
          signer_uid: 'partner-a',
          signer_name: 'P',
          signature_png_base64: 'xx',
          signed_at: new Date(),
          doc_sha256: 'forged',
        },
        updated_at: new Date(),
      }),
    );
  });

  it('denies event create without server time at', async () => {
    await testEnv.withSecurityRulesDisabled(async (ctx) => {
      await ctx
        .firestore()
        .doc(`shops/${SHOP}/partner_contracts/d5`)
        .set(draftDoc({ status: 'awaiting_signature' }));
    });
    const partner = testEnv.authenticatedContext('partner-a').firestore();
    await assertFails(
      partner
        .collection(`shops/${SHOP}/partner_contracts/d5/events`)
        .add({
          type: 'viewed',
          uid: 'partner-a',
          at: new Date('2020-01-01T00:00:00Z'),
          doc_sha256: 'abc123',
        }),
    );
  });

  it('allows partner viewed event with server timestamp', async () => {
    await testEnv.withSecurityRulesDisabled(async (ctx) => {
      await ctx
        .firestore()
        .doc(`shops/${SHOP}/partner_contracts/d6`)
        .set(draftDoc({ status: 'awaiting_signature' }));
    });
    const partner = testEnv.authenticatedContext('partner-a').firestore();
    const { FieldValue } = await import('firebase/firestore');
    await assertSucceeds(
      partner
        .collection(`shops/${SHOP}/partner_contracts/d6/events`)
        .add({
          type: 'viewed',
          uid: 'partner-a',
          at: FieldValue.serverTimestamp(),
          doc_sha256: 'abc123',
        }),
    );
  });
});
