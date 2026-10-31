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

function productDoc(overrides = {}) {
  return {
    id: 'fun-dive',
    name: '펀다이빙',
    consumer_price: 100000,
    professional_price: 80000,
    creator_uid: 'not-a-writer',
    ...overrides,
  };
}

describe('shops/{shopId}/products/{productId}', { concurrency: 1 }, () => {
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

  function productRef(db, shopId = 'shop-a', productId = 'fun-dive') {
    return db.collection('shops').doc(shopId).collection('products').doc(productId);
  }

  async function seedShopAndPeople() {
    await seed('shops/shop-a', {
      name: '보홀',
      creator_uid: 'captain-a',
      products: [{ id: 'fun-dive', consumer_price: 100000, professional_price: 80000 }],
    });
    await seed('users/admin-a', diverDoc({ is_admin: true, email: 'admin@example.com' }));
    await seed('users/owner-a', diverDoc({
      is_business: true,
      owned_shop_id: 'shop-a',
      email: 'owner@example.com',
    }));
    await seed('users/owner-b', diverDoc({
      is_business: true,
      owned_shop_id: 'shop-b',
      email: 'other@example.com',
    }));
    await seed('users/captain-a', diverDoc({ email: 'captain@example.com' }));
    await seed('users/stranger', diverDoc({ email: 'stranger@example.com' }));
    await seed('shops/shop-a/products/fun-dive', productDoc());
  }

  it('lets anyone read a product the same way as the shop', async () => {
    await seedShopAndPeople();
    const db = testEnv.unauthenticatedContext().firestore();
    await assertSucceeds(productRef(db).get());
  });

  it('lets an admin create and change the price', async () => {
    await seedShopAndPeople();
    const db = testEnv.authenticatedContext('admin-a').firestore();
    await assertSucceeds(productRef(db, 'shop-a', 'night').set(productDoc({
      id: 'night',
      consumer_price: 120000,
    })));
    await assertSucceeds(productRef(db).set({ consumer_price: 90000 }, { merge: true }));
  });

  it('lets the shop owner create and change the price', async () => {
    await seedShopAndPeople();
    const db = testEnv.authenticatedContext('owner-a').firestore();
    await assertSucceeds(productRef(db, 'shop-a', 'night').set(productDoc({ id: 'night' })));
    await assertSucceeds(
      productRef(db).set({ professional_price: 70000 }, { merge: true }),
    );
  });

  it('lets the parent shop creator write even when the product claims another uid', async () => {
    await seedShopAndPeople();
    const db = testEnv.authenticatedContext('captain-a').firestore();
    await assertSucceeds(productRef(db, 'shop-a', 'night').set(productDoc({
      id: 'night',
      creator_uid: 'stranger',
    })));
    await assertSucceeds(productRef(db).set({
      consumer_price: 50000,
      creator_uid: 'stranger',
    }, { merge: true }));
  });

  it('denies a stranger who forges creator_uid on the product', async () => {
    await seedShopAndPeople();
    const db = testEnv.authenticatedContext('stranger').firestore();
    await assertFails(productRef(db, 'shop-a', 'forged').set(productDoc({
      id: 'forged',
      creator_uid: 'stranger',
    })));
    await assertFails(productRef(db).set({
      consumer_price: 1,
      creator_uid: 'stranger',
    }, { merge: true }));
    await assertFails(productRef(db).set({ name: '바꿔치기' }, { merge: true }));
  });

  it('denies the owner of a different shop', async () => {
    await seedShopAndPeople();
    const db = testEnv.authenticatedContext('owner-b').firestore();
    await assertFails(productRef(db).set({ consumer_price: 1 }, { merge: true }));
  });

  it('still lets a signed-in stranger rewrite the parent products array', async () => {
    await seedShopAndPeople();
    const db = testEnv.authenticatedContext('stranger').firestore();
    await assertSucceeds(
      db.collection('shops').doc('shop-a').set({
        products: [{ id: 'fun-dive', consumer_price: 1, professional_price: 1 }],
      }, { merge: true }),
    );
  });
});
