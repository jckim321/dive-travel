import { initializeApp } from 'firebase-admin/app';
import { getAuth } from 'firebase-admin/auth';
import { getFirestore } from 'firebase-admin/firestore';
import { onSchedule } from 'firebase-functions/v2/scheduler';

import { purgeDueMembers } from './purgeDeletedMembers.js';

initializeApp();

/** Once a day at midnight in Seoul. Deploy only when asked. */
export const purgeDeletedMembers = onSchedule(
  {
    schedule: '0 0 * * *',
    timeZone: 'Asia/Seoul',
    region: 'asia-northeast3',
  },
  async () => {
    await purgeDueMembers({
      db: getFirestore(),
      auth: getAuth(),
      now: new Date(),
    });
  },
);
