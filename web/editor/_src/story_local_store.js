const DB_NAME = 'dive-travel-story-editor'
const DB_VERSION = 1
const DRAFT_STORE = 'drafts'
const VERSION_STORE = 'versions'
const META_STORE = 'meta'
const MAX_VERSIONS = 20

let dbPromise = null
let unavailable = false

function openDb() {
  if (unavailable) {
    return Promise.resolve(null)
  }
  if (dbPromise) {
    return dbPromise
  }
  if (typeof indexedDB === 'undefined') {
    unavailable = true
    return Promise.resolve(null)
  }
  dbPromise = new Promise((resolve) => {
    let request
    try {
      request = indexedDB.open(DB_NAME, DB_VERSION)
    } catch (_) {
      unavailable = true
      resolve(null)
      return
    }
    request.onerror = () => {
      unavailable = true
      dbPromise = null
      resolve(null)
    }
    request.onupgradeneeded = () => {
      const db = request.result
      if (!db.objectStoreNames.contains(DRAFT_STORE)) {
        db.createObjectStore(DRAFT_STORE, { keyPath: 'key' })
      }
      if (!db.objectStoreNames.contains(VERSION_STORE)) {
        const store = db.createObjectStore(VERSION_STORE, {
          keyPath: 'id',
          autoIncrement: true,
        })
        store.createIndex('byKey', 'key', { unique: false })
      }
      if (!db.objectStoreNames.contains(META_STORE)) {
        db.createObjectStore(META_STORE, { keyPath: 'key' })
      }
    }
    request.onsuccess = () => {
      resolve(request.result)
    }
  })
  return dbPromise
}

function requestToPromise(request) {
  return new Promise((resolve, reject) => {
    request.onsuccess = () => resolve(request.result)
    request.onerror = () => reject(request.error || new Error('idb failed'))
  })
}

function transactionDone(tx) {
  return new Promise((resolve, reject) => {
    tx.oncomplete = () => resolve()
    tx.onerror = () => reject(tx.error || new Error('idb tx failed'))
    tx.onabort = () => reject(tx.error || new Error('idb tx aborted'))
  })
}

export async function saveDraft(key, html) {
  const k = String(key || '').trim()
  if (!k) {
    return false
  }
  const db = await openDb()
  if (!db) {
    return false
  }
  try {
    const tx = db.transaction(DRAFT_STORE, 'readwrite')
    tx.objectStore(DRAFT_STORE).put({
      key: k,
      html: String(html || ''),
      updatedAt: Date.now(),
    })
    await transactionDone(tx)
    return true
  } catch (_) {
    return false
  }
}

export async function loadDraft(key) {
  const k = String(key || '').trim()
  if (!k) {
    return null
  }
  const db = await openDb()
  if (!db) {
    return null
  }
  try {
    const tx = db.transaction(DRAFT_STORE, 'readonly')
    const row = await requestToPromise(tx.objectStore(DRAFT_STORE).get(k))
    await transactionDone(tx)
    if (!row || typeof row.html !== 'string') {
      return null
    }
    return {
      html: row.html,
      updatedAt: Number(row.updatedAt) || 0,
    }
  } catch (_) {
    return null
  }
}

export async function clearDraft(key) {
  const k = String(key || '').trim()
  if (!k) {
    return false
  }
  const db = await openDb()
  if (!db) {
    return false
  }
  try {
    const tx = db.transaction(DRAFT_STORE, 'readwrite')
    tx.objectStore(DRAFT_STORE).delete(k)
    await transactionDone(tx)
    return true
  } catch (_) {
    return false
  }
}

export async function getMeta(key) {
  const k = String(key || '').trim()
  if (!k) {
    return null
  }
  const db = await openDb()
  if (!db) {
    return null
  }
  try {
    const tx = db.transaction(META_STORE, 'readonly')
    const row = await requestToPromise(tx.objectStore(META_STORE).get(k))
    await transactionDone(tx)
    return row || null
  } catch (_) {
    return null
  }
}

export async function setMeta(key, patch) {
  const k = String(key || '').trim()
  if (!k) {
    return false
  }
  const db = await openDb()
  if (!db) {
    return false
  }
  try {
    const prev = (await getMeta(k)) || { key: k }
    const tx = db.transaction(META_STORE, 'readwrite')
    tx.objectStore(META_STORE).put({ ...prev, ...patch, key: k })
    await transactionDone(tx)
    return true
  } catch (_) {
    return false
  }
}

export async function listVersions(key) {
  const k = String(key || '').trim()
  if (!k) {
    return []
  }
  const db = await openDb()
  if (!db) {
    return []
  }
  try {
    const tx = db.transaction(VERSION_STORE, 'readonly')
    const rows = await requestToPromise(tx.objectStore(VERSION_STORE).index('byKey').getAll(k))
    await transactionDone(tx)
    const list = Array.isArray(rows) ? rows : []
    list.sort((a, b) => (b.savedAt || 0) - (a.savedAt || 0))
    return list.map((row) => ({
      id: row.id,
      html: row.html || '',
      savedAt: Number(row.savedAt) || 0,
    }))
  } catch (_) {
    return []
  }
}

export async function addVersion(key, html) {
  const k = String(key || '').trim()
  if (!k) {
    return false
  }
  const db = await openDb()
  if (!db) {
    return false
  }
  const savedAt = Date.now()
  try {
    const tx = db.transaction(VERSION_STORE, 'readwrite')
    tx.objectStore(VERSION_STORE).add({
      key: k,
      html: String(html || ''),
      savedAt,
    })
    await transactionDone(tx)
    const rows = await listVersions(k)
    if (rows.length > MAX_VERSIONS) {
      const drop = rows.slice(MAX_VERSIONS)
      const prune = db.transaction(VERSION_STORE, 'readwrite')
      for (const row of drop) {
        prune.objectStore(VERSION_STORE).delete(row.id)
      }
      await transactionDone(prune)
    }
    await setMeta(k, { lastSavedAt: savedAt })
    return true
  } catch (_) {
    return false
  }
}
