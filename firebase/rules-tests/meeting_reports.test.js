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

function report(extra = {}) {
  return {
    shop_id: 'palau-dive',
    recipe: {
      shop_id: 'palau-dive',
      product_ids: ['palau-live'],
      region_id: 'palau',
      period_start: '2026-10-21',
      period_end: '2026-10-27',
      compare: false,
      sections: {
        conclusion: true,
        funnel: true,
        scorecard: true,
        demand: true,
        proposals: true,
      },
    },
    snapshot: {
      conclusion: '기록이 더 쌓이면 알려 드릴게요',
      funnel: { opens: 0, views: 1, flags: 0, pays: 0 },
      fill_percent: 80,
      score_rows: [
        {
          product_id: 'palau-live',
          title: '펀다이빙',
          views: 1,
          flags: 0,
          pays: 0,
          fill_percent: 80,
          badge: 'selling',
        },
      ],
    },
    shared: false,
    created_at: '2026-10-27T06:00:00.000Z',
    ...extra,
  };
}

describe('meeting reports', () => {
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
      const db = context.firestore();
      await db.doc('users/admin-1').set({ is_admin: true });
      await db.doc('users/partner-palau').set({
        is_admin: false,
        is_business: true,
        owned_shop_id: 'palau-dive--fundive',
      });
      await db.doc('users/partner-cebu').set({
        is_admin: false,
        is_business: true,
        owned_shop_id: 'cebu-dive',
      });
      await db.doc('meeting_reports/shared-one').set({
        ...report(),
        shared: true,
        shared_at: '2026-10-27T07:00:00.000Z',
      });
      await db.doc('meeting_reports/draft-one').set(report());
    });
  });

  it('다른 샵 주인은 못 읽고, 상품 id가 붙은 같은 샵 주인은 읽는다', async () => {
    const other = testEnv.authenticatedContext('partner-cebu').firestore();
    const owner = testEnv.authenticatedContext('partner-palau').firestore();
    await assertFails(other.doc('meeting_reports/shared-one').get());
    await assertSucceeds(owner.doc('meeting_reports/shared-one').get());
  });

  it('보내지 않은 문서는 그 샵 주인도 못 읽는다', async () => {
    const owner = testEnv.authenticatedContext('partner-palau').firestore();
    await assertFails(owner.doc('meeting_reports/draft-one').get());
  });

  it('비로그인은 읽지도 만들지도 못한다', async () => {
    const guest = testEnv.unauthenticatedContext().firestore();
    await assertFails(guest.doc('meeting_reports/shared-one').get());
    await assertFails(guest.doc('meeting_reports/guest').set(report()));
  });

  it('금지 키가 있으면 만들지 못한다', async () => {
    const admin = testEnv.authenticatedContext('admin-1').firestore();
    await assertFails(
      admin.doc('meeting_reports/with-email').set({
        ...report(),
        email: 'a@b.c',
      }),
    );
    const nested = report();
    nested.snapshot = { ...nested.snapshot, user_key: 'a'.repeat(64) };
    await assertFails(admin.doc('meeting_reports/with-key').set(nested));
  });

  it('관리자는 만들고 읽고 보내기 상태를 바꾸지만 지우지는 못한다', async () => {
    const admin = testEnv.authenticatedContext('admin-1').firestore();
    const partner = testEnv.authenticatedContext('partner-palau').firestore();
    await assertFails(partner.doc('meeting_reports/admin-made').set(report()));
    await assertSucceeds(admin.doc('meeting_reports/admin-made').set(report()));
    await assertSucceeds(admin.doc('meeting_reports/admin-made').get());
    await assertSucceeds(
      admin.doc('meeting_reports/admin-made').update({
        shared: true,
        shared_at: '2026-10-27T07:00:00.000Z',
      }),
    );
    await assertSucceeds(
      admin.doc('meeting_reports/admin-made').update({
        shared: false,
        shared_at: firebase.firestore.FieldValue.delete(),
      }),
    );
    await assertFails(admin.doc('meeting_reports/admin-made').delete());
  });
});
