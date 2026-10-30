/** Soft-deleted members stay recoverable for 30 days. */
export const RETENTION_MS = 30 * 24 * 60 * 60 * 1000;

export function deletedAtDate(value) {
  if (!value) return null;
  if (value instanceof Date) return value;
  if (typeof value.toDate === 'function') return value.toDate();
  if (typeof value === 'string' || typeof value === 'number') {
    const date = new Date(value);
    return Number.isNaN(date.getTime()) ? null : date;
  }
  if (typeof value.seconds === 'number') {
    return new Date(value.seconds * 1000);
  }
  return null;
}

/**
 * Due only after 30 days, and never for an admin or a member still linked
 * to a resort. Bookings are not part of this decision.
 */
export function shouldPurgeMember(data, now) {
  const deleted = deletedAtDate(data?.deleted_at);
  if (!deleted) return false;
  if (now.getTime() - deleted.getTime() < RETENTION_MS) return false;
  if (data.is_admin === true) return false;
  const shop = typeof data.owned_shop_id === 'string' ? data.owned_shop_id.trim() : '';
  return shop.length === 0;
}

/**
 * Disable the Auth user first, then delete only the users/{uid} document.
 * A failed disable leaves the document in the trash. Subcollections,
 * including bookings, are not deleted.
 */
export async function purgeDueMembers({ db, auth, now = new Date() }) {
  const cutoff = new Date(now.getTime() - RETENTION_MS);
  const snap = await db.collection('users').where('deleted_at', '<=', cutoff).get();
  for (const doc of snap.docs) {
    if (!shouldPurgeMember(doc.data(), now)) continue;
    try {
      await auth.updateUser(doc.id, { disabled: true });
    } catch (error) {
      if (error?.code !== 'auth/user-not-found') continue;
    }
    await doc.ref.delete();
  }
}
