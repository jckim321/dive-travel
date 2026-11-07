import { Editor, Node, mergeAttributes } from '@tiptap/core'
import StarterKit from '@tiptap/starter-kit'
import { TextStyle } from '@tiptap/extension-text-style'
import { Color } from '@tiptap/extension-color'
import TextAlign from '@tiptap/extension-text-align'
import Image from '@tiptap/extension-image'
import {
  createBubbleMenuElement,
  createBubbleMenuExtension,
  createSlashCommandsExtension,
} from './slash_bubble.js'
import {
  addVersion,
  clearDraft,
  getMeta,
  listVersions,
  loadDraft,
  saveDraft,
  setMeta,
} from './story_local_store.js'

const SOURCE = 'dive-travel-editor'
const APP_SOURCE = 'dive-travel-app'
const MAX_STORY_PHOTOS = 30
const MAX_STORY_VIDEOS = 3
const MAX_STORY_MAPS = 5
const MAX_STORY_PHOTO_BYTES = 10 * 1024 * 1024
/** Matches planner `_tipTapNewProductStorageKey` for unsaved new products. */
const NEW_PRODUCT_STORAGE_KEY = 'dive-travel-story:new'

const StoryVideo = Node.create({
  name: 'storyVideo',
  group: 'block',
  atom: true,
  selectable: true,
  draggable: true,
  addAttributes() {
    return {
      src: { default: null },
    }
  },
  parseHTML() {
    return [{ tag: 'video[src]' }]
  },
  renderHTML({ HTMLAttributes }) {
    return [
      'video',
      mergeAttributes(HTMLAttributes, {
        controls: 'controls',
        preload: 'metadata',
      }),
    ]
  },
  addCommands() {
    return {
      setStoryVideo:
        (attrs) =>
        ({ commands }) =>
          commands.insertContent({
            type: this.name,
            attrs,
          }),
    }
  },
})

const COLORS = [
  { label: '기본', value: '' },
  { label: '빨강', value: '#E53935' },
  { label: '주황', value: '#FB8C00' },
  { label: '초록', value: '#43A047' },
  { label: '파랑', value: '#1E88E5' },
  { label: '보라', value: '#8E24AA' },
  { label: '회색', value: '#78909C' },
]

function post(type, extra = {}) {
  parent.postMessage({ source: SOURCE, type, ...extra }, '*')
}

const PASTE_REMOVE_TAGS = new Set([
  'script',
  'style',
  'meta',
  'link',
  'head',
  'title',
  'noscript',
  'iframe',
  'object',
  'embed',
  'video',
  'audio',
  'img',
  'picture',
  'source',
  'svg',
  'canvas',
  'form',
  'input',
  'button',
  'textarea',
  'select',
  'template',
])

const PASTE_BLOCK_TAGS = new Set([
  'p',
  'h1',
  'h2',
  'h3',
  'ul',
  'ol',
  'li',
  'blockquote',
  'hr',
  'table',
  'thead',
  'tbody',
  'tfoot',
  'tr',
  'td',
  'th',
  'div',
  'section',
  'article',
  'header',
  'footer',
  'main',
  'aside',
  'pre',
])

const PASTE_ALIGN = new Set(['left', 'center', 'right', 'justify'])

function unwrapElement(el) {
  const parent = el.parentNode
  if (!parent) {
    el.remove()
    return
  }
  while (el.firstChild) {
    parent.insertBefore(el.firstChild, el)
  }
  parent.removeChild(el)
}

function replaceTag(el, tagName) {
  const next = document.createElement(tagName)
  while (el.firstChild) {
    next.appendChild(el.firstChild)
  }
  el.replaceWith(next)
  return next
}

function clearAttributes(el) {
  while (el.attributes.length > 0) {
    el.removeAttribute(el.attributes[0].name)
  }
}

function extractTextAlign(styleText, alignAttr) {
  const fromAttr = (alignAttr || '').trim().toLowerCase()
  if (PASTE_ALIGN.has(fromAttr)) {
    return fromAttr
  }
  const match = /(?:^|;)\s*text-align\s*:\s*(left|center|right|justify)\b/i.exec(
    styleText || '',
  )
  return match ? match[1].toLowerCase() : ''
}

function rgbToHex(r, g, b) {
  const to = (n) =>
    Math.max(0, Math.min(255, Math.round(n)))
      .toString(16)
      .padStart(2, '0')
  return `#${to(r)}${to(g)}${to(b)}`
}

function parseCssColorChannel(raw) {
  const text = String(raw || '').trim()
  if (!text) {
    return null
  }
  if (text.endsWith('%')) {
    const pct = Number.parseFloat(text.slice(0, -1))
    if (!Number.isFinite(pct)) {
      return null
    }
    return (pct / 100) * 255
  }
  const num = Number.parseFloat(text)
  return Number.isFinite(num) ? num : null
}

function parseCssAlpha(raw) {
  const text = String(raw || '').trim()
  if (!text) {
    return 1
  }
  if (text.endsWith('%')) {
    const pct = Number.parseFloat(text.slice(0, -1))
    if (!Number.isFinite(pct)) {
      return null
    }
    return pct / 100
  }
  const num = Number.parseFloat(text)
  return Number.isFinite(num) ? num : null
}

/** Keep #hex; convert rgb/rgba to #rrggbb. Drop transparent or unparsable colors. */
function normalizeColorValue(raw) {
  const value = (raw || '').trim()
  if (!value) {
    return ''
  }
  if (/^#(?:[0-9a-f]{3}|[0-9a-f]{6})$/i.test(value)) {
    return value.toLowerCase()
  }
  if (/^#(?:[0-9a-f]{8})$/i.test(value)) {
    const hex = value.slice(1)
    const alpha = Number.parseInt(hex.slice(6, 8), 16) / 255
    if (!Number.isFinite(alpha) || alpha <= 0) {
      return ''
    }
    return `#${hex.slice(0, 6).toLowerCase()}`
  }
  const fn = /^rgba?\(\s*(.+)\s*\)$/i.exec(value)
  if (!fn) {
    return ''
  }
  const inner = fn[1].trim()
  let parts
  if (inner.includes(',')) {
    parts = inner.split(',').map((part) => part.trim())
  } else {
    const slash = inner.split('/')
    const rgbParts = slash[0]
      .trim()
      .split(/\s+/)
      .filter(Boolean)
    parts = [...rgbParts]
    if (slash.length > 1) {
      parts.push(slash[1].trim())
    }
  }
  if (parts.length < 3) {
    return ''
  }
  const r = parseCssColorChannel(parts[0])
  const g = parseCssColorChannel(parts[1])
  const b = parseCssColorChannel(parts[2])
  if (r == null || g == null || b == null) {
    return ''
  }
  const alpha = parts.length >= 4 ? parseCssAlpha(parts[3]) : 1
  if (alpha == null || alpha <= 0) {
    return ''
  }
  return rgbToHex(r, g, b)
}

function extractColor(styleText, colorAttr) {
  const fromAttr = normalizeColorValue(colorAttr || '')
  if (fromAttr) {
    return fromAttr
  }
  const match = /(?:^|;)\s*color\s*:\s*([^;]+)/i.exec(styleText || '')
  if (!match) {
    return ''
  }
  return normalizeColorValue(match[1])
}

function hasBlockChild(el) {
  for (const child of el.children) {
    if (PASTE_BLOCK_TAGS.has(child.tagName.toLowerCase())) {
      return true
    }
  }
  return false
}

function applyAlign(el, align) {
  if (PASTE_ALIGN.has(align)) {
    el.setAttribute('style', `text-align: ${align}`)
  }
}

function applyColor(el, color) {
  if (color) {
    el.setAttribute('style', `color: ${color}`)
  }
}

function cleanPasteElement(el) {
  const tag = el.tagName.toLowerCase()
  const styleText = el.getAttribute('style') || ''
  const align = extractTextAlign(styleText, el.getAttribute('align'))
  const color = extractColor(styleText, el.getAttribute('color'))

  if (tag === 'b') {
    cleanPasteElement(replaceTag(el, 'strong'))
    return
  }
  if (tag === 'i') {
    cleanPasteElement(replaceTag(el, 'em'))
    return
  }
  if (tag === 'del' || tag === 'strike') {
    cleanPasteElement(replaceTag(el, 's'))
    return
  }
  if (tag === 'h4' || tag === 'h5' || tag === 'h6') {
    const heading = replaceTag(el, 'h3')
    clearAttributes(heading)
    applyAlign(heading, align)
    return
  }
  if (tag === 'font') {
    if (color) {
      const span = replaceTag(el, 'span')
      clearAttributes(span)
      applyColor(span, color)
      return
    }
    unwrapElement(el)
    return
  }
  if (
    tag === 'div' ||
    tag === 'section' ||
    tag === 'article' ||
    tag === 'header' ||
    tag === 'footer' ||
    tag === 'main' ||
    tag === 'aside' ||
    tag === 'center'
  ) {
    const blockAlign = tag === 'center' ? 'center' : align
    if (hasBlockChild(el)) {
      unwrapElement(el)
      return
    }
    const p = replaceTag(el, 'p')
    clearAttributes(p)
    applyAlign(p, blockAlign)
    return
  }
  if (tag === 'p' || tag === 'h1' || tag === 'h2' || tag === 'h3') {
    clearAttributes(el)
    applyAlign(el, align)
    return
  }
  if (
    tag === 'strong' ||
    tag === 'em' ||
    tag === 'u' ||
    tag === 's' ||
    tag === 'br' ||
    tag === 'hr' ||
    tag === 'ul' ||
    tag === 'ol' ||
    tag === 'li' ||
    tag === 'blockquote'
  ) {
    clearAttributes(el)
    return
  }
  if (tag === 'a') {
    const href = (el.getAttribute('href') || '').trim()
    const openBlank = el.getAttribute('target') === '_blank'
    clearAttributes(el)
    if (/^https?:\/\//i.test(href)) {
      el.setAttribute('href', href)
      if (openBlank) {
        el.setAttribute('target', '_blank')
        el.setAttribute('rel', 'noopener noreferrer')
      }
      return
    }
    unwrapElement(el)
    return
  }
  if (tag === 'span') {
    clearAttributes(el)
    if (color) {
      applyColor(el, color)
      return
    }
    unwrapElement(el)
    return
  }
  unwrapElement(el)
}

function isVisuallyEmptyBlock(el) {
  const tag = el.tagName.toLowerCase()
  if (tag !== 'p' && tag !== 'h1' && tag !== 'h2' && tag !== 'h3') {
    return false
  }
  const text = (el.textContent || '').replace(/\u00a0/g, ' ').trim()
  return text.length === 0
}

function collapseEmptyBlocks(root) {
  const blocks = [...root.querySelectorAll('p, h1, h2, h3')]
  let prevEmpty = false
  for (const el of blocks) {
    if (!isVisuallyEmptyBlock(el)) {
      prevEmpty = false
      continue
    }
    if (prevEmpty) {
      el.remove()
      continue
    }
    el.innerHTML = ''
    clearAttributes(el)
    prevEmpty = true
  }

  for (const el of [...root.querySelectorAll('p, h1, h2, h3, li, blockquote')]) {
    const kids = [...el.childNodes]
    let brRun = 0
    for (const node of kids) {
      const isBr =
        node.nodeType === 1 && node.tagName && node.tagName.toLowerCase() === 'br'
      if (isBr) {
        brRun += 1
        if (brRun > 1) {
          node.remove()
        }
      } else if (node.nodeType === 3 && !(node.textContent || '').replace(/\u00a0/g, ' ').trim()) {
        continue
      } else {
        brRun = 0
      }
    }
  }
}

function parseYouTubeOrVimeo(raw) {
  const text = String(raw || '').trim()
  if (!text) {
    return null
  }
  let url
  try {
    url = new URL(text)
  } catch (_) {
    return null
  }
  if (url.protocol !== 'http:' && url.protocol !== 'https:') {
    return null
  }
  const host = url.hostname.replace(/^www\./i, '').toLowerCase()

  if (host === 'youtu.be') {
    const id = url.pathname.split('/').filter(Boolean)[0] || ''
    if (!id || id.includes('.')) {
      return null
    }
    return {
      provider: 'youtube',
      href: `https://www.youtube.com/watch?v=${encodeURIComponent(id)}`,
      label: '▶ 영상 보기 · 유튜브',
    }
  }
  if (
    host === 'youtube.com' ||
    host === 'm.youtube.com' ||
    host === 'music.youtube.com' ||
    host === 'youtube-nocookie.com'
  ) {
    let id = url.searchParams.get('v') || ''
    const parts = url.pathname.split('/').filter(Boolean)
    if (!id && parts[0] === 'embed' && parts[1]) {
      id = parts[1]
    }
    if (!id && parts[0] === 'shorts' && parts[1]) {
      id = parts[1]
    }
    if (!id && parts[0] === 'live' && parts[1]) {
      id = parts[1]
    }
    if (!id) {
      return null
    }
    return {
      provider: 'youtube',
      href: `https://www.youtube.com/watch?v=${encodeURIComponent(id)}`,
      label: '▶ 영상 보기 · 유튜브',
    }
  }
  if (host === 'vimeo.com' || host === 'player.vimeo.com') {
    const parts = url.pathname.split('/').filter(Boolean)
    let id = ''
    if (parts[0] === 'video' && parts[1]) {
      id = parts[1]
    } else if (parts[0]) {
      id = parts[0]
    }
    if (!/^\d+$/.test(id)) {
      return null
    }
    return {
      provider: 'vimeo',
      href: `https://vimeo.com/${id}`,
      label: '▶ 영상 보기 · 비메오',
    }
  }
  return null
}

function makeVideoViewParagraph(href, label) {
  const p = document.createElement('p')
  const a = document.createElement('a')
  a.setAttribute('href', href)
  a.setAttribute('target', '_blank')
  a.setAttribute('rel', 'noopener noreferrer')
  a.textContent = label
  p.appendChild(a)
  return p
}

function rewriteVideoAnchor(anchor) {
  const converted = parseYouTubeOrVimeo(anchor.getAttribute('href') || '')
  if (!converted) {
    return false
  }
  anchor.setAttribute('href', converted.href)
  anchor.setAttribute('target', '_blank')
  anchor.setAttribute('rel', 'noopener noreferrer')
  anchor.textContent = converted.label
  return true
}

function replacePlainVideoUrlNodes(root) {
  const texts = []
  const walker = document.createTreeWalker(root, NodeFilter.SHOW_TEXT)
  while (walker.nextNode()) {
    texts.push(walker.currentNode)
  }
  for (const textNode of texts) {
    const raw = textNode.nodeValue || ''
    const trimmed = raw.trim()
    if (!trimmed) {
      continue
    }
    const converted = parseYouTubeOrVimeo(trimmed)
    if (!converted) {
      continue
    }
    // Whole text node is a single video URL (optional surrounding whitespace).
    if (!/^https?:\/\/\S+$/i.test(trimmed)) {
      continue
    }
    if (raw.trim() !== trimmed) {
      // Keep only when non-URL characters are whitespace.
      if (raw.replace(/\s+/g, '') !== trimmed) {
        continue
      }
    }
    const parent = textNode.parentNode
    if (!parent) {
      continue
    }
    const link = document.createElement('a')
    link.setAttribute('href', converted.href)
    link.setAttribute('target', '_blank')
    link.setAttribute('rel', 'noopener noreferrer')
    link.textContent = converted.label
    if (
      parent.childNodes.length === 1 &&
      parent.nodeType === 1 &&
      ['P', 'LI', 'H1', 'H2', 'H3', 'DIV', 'SPAN'].includes(parent.tagName)
    ) {
      parent.textContent = ''
      parent.appendChild(link)
    } else {
      parent.replaceChild(link, textNode)
    }
  }
}

/**
 * Keep headings, paragraphs, marks, links, lists, quotes, hr, color, align.
 * Collects data:image imgs for upload; counts other imgs as skipped externals.
 * Turns YouTube/Vimeo URLs and embeds into 「영상 보기」 links.
 */
function cleanPastedHtml(html) {
  const empty = {
    html: html || '',
    externalImageCount: 0,
    dataImages: [],
    skippedVideoCount: 0,
  }
  if (!html || !String(html).trim()) {
    return empty
  }
  let raw = String(html)
    .replace(/<!--[\s\S]*?-->/g, '')
    .replace(/<script\b[\s\S]*?<\/script>/gi, '')
    .replace(/<style\b[\s\S]*?<\/style>/gi, '')
    .replace(/<\/?(?:xml|o|w|v|m):[^>]*>/gi, '')

  const holder = document.createElement('div')
  holder.innerHTML = raw

  let externalImageCount = 0
  let skippedVideoCount = 0
  const dataImages = []
  for (const img of [...holder.querySelectorAll('img')]) {
    const src = (img.getAttribute('src') || '').trim()
    if (/^data:image\//i.test(src)) {
      dataImages.push({
        dataUrl: src,
        fileName: fileNameFromDataUrl(src),
        contentType: contentTypeFromDataUrl(src),
      })
    } else if (src) {
      externalImageCount += 1
    }
    img.remove()
  }

  for (const iframe of [...holder.querySelectorAll('iframe')]) {
    const src = (iframe.getAttribute('src') || '').trim()
    const converted = parseYouTubeOrVimeo(src)
    if (converted) {
      iframe.replaceWith(makeVideoViewParagraph(converted.href, converted.label))
      continue
    }
    if (/^https:\/\//i.test(src)) {
      iframe.replaceWith(makeVideoViewParagraph(src, '▶ 영상 보기'))
      continue
    }
    iframe.remove()
    skippedVideoCount += 1
  }

  for (const anchor of [...holder.querySelectorAll('a[href]')]) {
    rewriteVideoAnchor(anchor)
  }
  replacePlainVideoUrlNodes(holder)

  for (const el of [...holder.querySelectorAll('*')]) {
    if (PASTE_REMOVE_TAGS.has(el.tagName.toLowerCase())) {
      el.remove()
    }
  }

  const elements = [...holder.querySelectorAll('*')].reverse()
  for (const el of elements) {
    if (!el.isConnected) {
      continue
    }
    cleanPasteElement(el)
  }

  collapseEmptyBlocks(holder)

  for (const anchor of [...holder.querySelectorAll('a[href]')]) {
    const label = (anchor.textContent || '').trim()
    if (label.startsWith('▶ 영상 보기')) {
      anchor.setAttribute('target', '_blank')
      anchor.setAttribute('rel', 'noopener noreferrer')
    }
  }

  return {
    html: holder.innerHTML,
    externalImageCount,
    dataImages,
    skippedVideoCount,
  }
}

function fileNameFromDataUrl(dataUrl) {
  const mime = contentTypeFromDataUrl(dataUrl)
  if (mime.includes('png')) {
    return 'paste.png'
  }
  if (mime.includes('webp')) {
    return 'paste.webp'
  }
  if (mime.includes('gif')) {
    return 'paste.gif'
  }
  return 'paste.jpg'
}

function contentTypeFromDataUrl(dataUrl) {
  const match = /^data:([^;,]+)/i.exec(dataUrl || '')
  return match ? match[1].toLowerCase() : 'image/jpeg'
}

function button(label, title, onClick) {
  const el = document.createElement('button')
  el.type = 'button'
  el.textContent = label
  el.title = title
  el.addEventListener('click', (e) => {
    e.preventDefault()
    onClick()
  })
  return el
}

function select(options, onChange) {
  const el = document.createElement('select')
  for (const opt of options) {
    const o = document.createElement('option')
    o.value = opt.value
    o.textContent = opt.label
    el.appendChild(o)
  }
  el.addEventListener('change', () => onChange(el.value))
  return el
}

function buildToolbar(editor, root, actions) {
  const bar = document.createElement('div')
  bar.className = 'toolbar'
  bar.append(
    button('↶', '실행 취소', () => editor.chain().focus().undo().run()),
    button('↷', '다시 실행', () => editor.chain().focus().redo().run()),
  )

  const style = select(
    [
      { label: '문단', value: 'paragraph' },
      { label: '제목 1', value: 'h1' },
      { label: '제목 2', value: 'h2' },
      { label: '제목 3', value: 'h3' },
    ],
    (value) => {
      const chain = editor.chain().focus()
      if (value === 'paragraph') {
        chain.setParagraph().run()
        return
      }
      const level = Number(value.slice(1))
      chain.toggleHeading({ level }).run()
    },
  )
  bar.append(style)

  bar.append(
    button('B', '굵게', () => editor.chain().focus().toggleBold().run()),
    button('I', '기울임', () => editor.chain().focus().toggleItalic().run()),
    button('U', '밑줄', () => editor.chain().focus().toggleUnderline().run()),
    button('S', '취소선', () => editor.chain().focus().toggleStrike().run()),
  )

  const color = select(COLORS, (value) => {
    const chain = editor.chain().focus()
    if (!value) {
      chain.unsetColor().run()
      return
    }
    chain.setColor(value).run()
  })
  color.title = '글자 색'
  bar.append(color)

  bar.append(
    button('링크', '링크', () => {
      const prev = editor.getAttributes('link').href || ''
      const url = window.prompt('링크 주소 (https://)', prev)
      if (url === null) {
        return
      }
      if (url.trim() === '') {
        editor.chain().focus().extendMarkRange('link').unsetLink().run()
        return
      }
      editor
        .chain()
        .focus()
        .extendMarkRange('link')
        .setLink({ href: url.trim() })
        .run()
    }),
    button('사진', '사진', () => actions.pickPhoto()),
    button('동영상', '동영상', () => actions.pickVideo()),
    button('지도', '지도', () => actions.pickMap()),
    button('일차 일정', '일차 일정', () => actions.insertDaySchedule()),
    button('• 목록', '글머리 목록', () =>
      editor.chain().focus().toggleBulletList().run(),
    ),
    button('1. 목록', '번호 목록', () =>
      editor.chain().focus().toggleOrderedList().run(),
    ),
    button('인용', '인용', () => editor.chain().focus().toggleBlockquote().run()),
    button('―', '구분선', () =>
      editor.chain().focus().setHorizontalRule().run(),
    ),
    button('좌', '왼쪽 정렬', () =>
      editor.chain().focus().setTextAlign('left').run(),
    ),
    button('중', '가운데 정렬', () =>
      editor.chain().focus().setTextAlign('center').run(),
    ),
    button('우', '오른쪽 정렬', () =>
      editor.chain().focus().setTextAlign('right').run(),
    ),
    button('이전 저장본', '이전 저장본', () => actions.showVersions()),
  )

  root.append(bar)
}

function formatSavedAt(ms) {
  const d = new Date(ms)
  if (Number.isNaN(d.getTime())) {
    return ''
  }
  const pad = (n) => String(n).padStart(2, '0')
  return `${d.getFullYear()}.${pad(d.getMonth() + 1)}.${pad(d.getDate())} ${pad(d.getHours())}:${pad(d.getMinutes())}:${pad(d.getSeconds())}`
}

function normalizeStoryHtml(html) {
  return String(html || '').trim()
}

function countStoryImages(html) {
  const matches = String(html || '').match(/<img\b/gi)
  return matches ? matches.length : 0
}

function countStoryVideos(html) {
  const matches = String(html || '').match(/<video\b/gi)
  return matches ? matches.length : 0
}

function countStoryMaps(html) {
  const matches = String(html || '').match(
    /https:\/\/www\.google\.com\/maps\/search\//gi,
  )
  return matches ? matches.length : 0
}

function escapeAttr(value) {
  return String(value)
    .replace(/&/g, '&amp;')
    .replace(/"/g, '&quot;')
    .replace(/</g, '&lt;')
    .replace(/>/g, '&gt;')
}

function escapeText(value) {
  return String(value)
    .replace(/&/g, '&amp;')
    .replace(/</g, '&lt;')
    .replace(/>/g, '&gt;')
}

function boot() {
  const root = document.getElementById('app')
  const mount = document.createElement('div')
  mount.className = 'editor-shell'
  const surface = document.createElement('div')
  surface.className = 'editor-surface'
  mount.append(surface)
  root.append(mount)

  let uploadSeq = 0
  const pendingUploads = new Map()
  let pendingPasteDataImages = []
  let pendingExternalImageCount = 0
  let pendingSkippedVideoCount = 0
  let storageKey = ''
  /** Serializes key migrate / clear so saveSucceeded cannot race a stale draft copy. */
  let storageKeyChain = Promise.resolve()
  let draftTimer = null
  let suppressDraftSave = false
  let applyingContent = false
  let versionOverlay = null

  function placeholderText(id) {
    // Zero-width space keeps the visible label as 「올리는 중」 while ids stay unique.
    return `올리는 중\u200b${id}`
  }

  function findPlaceholder(id) {
    const needle = placeholderText(id)
    let found = null
    editor.state.doc.descendants((node, pos) => {
      if (found) {
        return false
      }
      if (node.type.name === 'paragraph' && node.textContent === needle) {
        found = { pos, size: node.nodeSize }
        return false
      }
      return undefined
    })
    return found
  }

  function removePlaceholder(id) {
    const found = findPlaceholder(id)
    if (!found) {
      return
    }
    editor
      .chain()
      .command(({ tr, dispatch }) => {
        tr.delete(found.pos, found.pos + found.size)
        if (dispatch) {
          dispatch(tr)
        }
        return true
      })
      .run()
  }

  function replacePlaceholderWithImage(id, url) {
    const found = findPlaceholder(id)
    if (!found) {
      if (countStoryImages(editor.getHTML()) >= MAX_STORY_PHOTOS) {
        window.alert('사진은 30장까지 올릴 수 있습니다.')
        return
      }
      editor.chain().focus().setImage({ src: url }).run()
      return
    }
    const imageType = editor.schema.nodes.image
    if (!imageType) {
      return
    }
    editor
      .chain()
      .command(({ tr, dispatch }) => {
        tr.replaceWith(
          found.pos,
          found.pos + found.size,
          imageType.create({ src: url }),
        )
        if (dispatch) {
          dispatch(tr)
        }
        return true
      })
      .run()
  }

  function photoSlotsLeft() {
    return Math.max(
      0,
      MAX_STORY_PHOTOS -
        countStoryImages(editor.getHTML()) -
        pendingUploads.size,
    )
  }

  function dataUrlByteLength(dataUrl) {
    const comma = String(dataUrl || '').indexOf(',')
    if (comma < 0) {
      return 0
    }
    let raw = dataUrl.slice(comma + 1).replace(/\s/g, '')
    const isBase64 = /;base64/i.test(dataUrl.slice(0, comma))
    if (!isBase64) {
      try {
        return decodeURIComponent(raw).length
      } catch (_) {
        return raw.length
      }
    }
    const padding = raw.endsWith('==') ? 2 : raw.endsWith('=') ? 1 : 0
    return Math.max(0, Math.floor((raw.length * 3) / 4) - padding)
  }

  function rejectIfPhotoTooLarge(bytes) {
    if (bytes > MAX_STORY_PHOTO_BYTES) {
      window.alert('사진은 10MB 이하만 올릴 수 있어요')
      return true
    }
    return false
  }

  function queueDataUrlUpload(dataUrl, fileName, contentType) {
    if (!dataUrl || !/^data:image\//i.test(dataUrl)) {
      return
    }
    if (rejectIfPhotoTooLarge(dataUrlByteLength(dataUrl))) {
      return
    }
    if (photoSlotsLeft() <= 0) {
      window.alert('사진은 30장까지 올릴 수 있습니다.')
      return
    }
    const id = `u${++uploadSeq}`
    const marker = placeholderText(id)
    pendingUploads.set(id, true)
    editor.chain().focus().insertContent(`<p>${escapeText(marker)}</p>`).run()
    post('uploadPhoto', {
      id,
      dataUrl,
      fileName: fileName || fileNameFromDataUrl(dataUrl),
      contentType: contentType || contentTypeFromDataUrl(dataUrl),
    })
  }

  function fileToDataUrl(file) {
    return new Promise((resolve, reject) => {
      const reader = new FileReader()
      reader.onload = () => resolve(String(reader.result || ''))
      reader.onerror = () => reject(reader.error || new Error('read failed'))
      reader.readAsDataURL(file)
    })
  }

  function collectImageFiles(fileList) {
    const out = []
    if (!fileList) {
      return out
    }
    for (const file of fileList) {
      if (file && typeof file.type === 'string' && file.type.startsWith('image/')) {
        out.push(file)
      }
    }
    return out
  }

  async function queueImageFiles(files) {
    const list = [...files]
    if (!list.length) {
      return
    }
    let slots = photoSlotsLeft()
    if (slots <= 0) {
      window.alert('사진은 30장까지 올릴 수 있습니다.')
      return
    }
    if (list.length > slots) {
      window.alert('사진은 30장까지 올릴 수 있습니다.')
    }
    for (const file of list.slice(0, slots)) {
      if (rejectIfPhotoTooLarge(file.size || 0)) {
        continue
      }
      try {
        const dataUrl = await fileToDataUrl(file)
        queueDataUrlUpload(
          dataUrl,
          file.name || fileNameFromDataUrl(dataUrl),
          file.type || contentTypeFromDataUrl(dataUrl),
        )
      } catch (_) {
        window.alert('사진을 올리지 못했습니다.')
      }
    }
  }

  function flushPasteImageSideEffects() {
    const external = pendingExternalImageCount
    pendingExternalImageCount = 0
    const skippedVideo = pendingSkippedVideoCount
    pendingSkippedVideoCount = 0
    const dataImages = pendingPasteDataImages
    pendingPasteDataImages = []
    if (external > 0) {
      window.alert(
        `붙여넣은 글의 사진 ${external}장은 가져오지 못했습니다. 사진 버튼으로 올려 주세요`,
      )
    }
    if (skippedVideo > 0) {
      window.alert(
        `붙여넣은 글의 동영상 ${skippedVideo}개는 가져오지 못했습니다`,
      )
    }
    for (const item of dataImages) {
      queueDataUrlUpload(item.dataUrl, item.fileName, item.contentType)
    }
  }

  function insertVideoViewLink(converted) {
    editor
      .chain()
      .focus()
      .insertContent(
        `<p><a href="${escapeAttr(converted.href)}" target="_blank" rel="noopener noreferrer">${escapeText(converted.label)}</a></p>`,
      )
      .run()
  }

  function nextDayScheduleNumber() {
    let max = 0
    editor.state.doc.descendants((node) => {
      if (node.type.name !== 'heading' || node.attrs.level !== 3) {
        return
      }
      const match = /^(\d+)\s*일차/.exec((node.textContent || '').trim())
      if (match) {
        max = Math.max(max, Number(match[1]))
      }
    })
    return max + 1
  }

  function insertDaySchedule() {
    const day = nextDayScheduleNumber()
    editor
      .chain()
      .focus()
      .insertContent(
        `<hr><h3>${day}일차 · (장소 입력)</h3><ul><li>09:00 · 내용</li></ul>`,
      )
      .run()
  }

  function applyEditorHtml(html, { emitUpdate = false } = {}) {
    applyingContent = true
    suppressDraftSave = true
    try {
      editor.commands.setContent(html || '<p></p>', { emitUpdate })
      if (emitUpdate) {
        post('contentChanged', { html: editor.getHTML() })
      }
    } finally {
      applyingContent = false
      queueMicrotask(() => {
        suppressDraftSave = false
      })
    }
  }

  function scheduleDraftSave(html) {
    if (!storageKey || suppressDraftSave || applyingContent) {
      return
    }
    if (draftTimer) {
      clearTimeout(draftTimer)
    }
    draftTimer = setTimeout(() => {
      draftTimer = null
      void saveDraft(storageKey, html)
    }, 500)
  }

  async function handleSetContent(serverHtml) {
    const incoming = serverHtml || '<p></p>'
    if (!storageKey) {
      applyEditorHtml(incoming, { emitUpdate: false })
      return
    }
    let draft = null
    let meta = null
    try {
      draft = await loadDraft(storageKey)
      meta = await getMeta(storageKey)
    } catch (_) {
      applyEditorHtml(incoming, { emitUpdate: false })
      return
    }
    const serverNorm = normalizeStoryHtml(incoming)
    const draftNorm = draft ? normalizeStoryHtml(draft.html) : ''
    const lastSavedAt = Number(meta?.lastSavedAt) || 0
    const draftNewer =
      !!draft &&
      draftNorm !== serverNorm &&
      Number(draft.updatedAt) > lastSavedAt
    if (draftNewer) {
      const restore = window.confirm(
        '저장되지 않은 글이 있습니다. 복원할까요?',
      )
      if (restore) {
        applyEditorHtml(draft.html || '<p></p>', { emitUpdate: true })
        return
      }
      void clearDraft(storageKey)
    }
    applyEditorHtml(incoming, { emitUpdate: false })
  }

  async function migrateStorageKey(fromKey, toKey) {
    const from = String(fromKey || '').trim()
    const to = String(toKey || '').trim()
    if (!from || !to || from === to) {
      return
    }
    try {
      const draft = await loadDraft(from)
      if (draft && typeof draft.html === 'string') {
        await saveDraft(to, draft.html)
      }
      await clearDraft(from)
    } catch (_) {
      // IndexedDB unavailable — skip quietly.
    }
  }

  async function handleSaveSucceeded(html) {
    await storageKeyChain
    if (!storageKey) {
      return
    }
    const body = html || '<p></p>'
    try {
      await addVersion(storageKey, body)
      await saveDraft(storageKey, body)
      await setMeta(storageKey, { lastSavedAt: Date.now() })
      if (storageKey !== NEW_PRODUCT_STORAGE_KEY) {
        await clearDraft(NEW_PRODUCT_STORAGE_KEY)
      }
    } catch (_) {
      // IndexedDB unavailable — skip quietly.
    }
  }

  function closeVersionOverlay() {
    if (versionOverlay) {
      versionOverlay.remove()
      versionOverlay = null
    }
  }

  async function showVersions() {
    if (!storageKey) {
      window.alert('이 글은 아직 로컬 저장본을 쓸 수 없습니다.')
      return
    }
    closeVersionOverlay()
    let versions = []
    try {
      versions = await listVersions(storageKey)
    } catch (_) {
      versions = []
    }
    const overlay = document.createElement('div')
    overlay.className = 'version-overlay'
    const panel = document.createElement('div')
    panel.className = 'version-panel'
    const title = document.createElement('div')
    title.className = 'version-panel-title'
    title.textContent = '이전 저장본'
    panel.appendChild(title)
    if (!versions.length) {
      const empty = document.createElement('div')
      empty.className = 'version-empty'
      empty.textContent = '저장된 기록이 없습니다.'
      panel.appendChild(empty)
    } else {
      const list = document.createElement('div')
      list.className = 'version-list'
      for (const row of versions) {
        const item = document.createElement('button')
        item.type = 'button'
        item.className = 'version-item'
        item.textContent = formatSavedAt(row.savedAt)
        item.addEventListener('click', () => {
          applyEditorHtml(row.html || '<p></p>', { emitUpdate: true })
          closeVersionOverlay()
        })
        list.appendChild(item)
      }
      panel.appendChild(list)
    }
    const closeBtn = document.createElement('button')
    closeBtn.type = 'button'
    closeBtn.className = 'version-close'
    closeBtn.textContent = '닫기'
    closeBtn.addEventListener('click', () => closeVersionOverlay())
    panel.appendChild(closeBtn)
    overlay.appendChild(panel)
    overlay.addEventListener('click', (event) => {
      if (event.target === overlay) {
        closeVersionOverlay()
      }
    })
    versionOverlay = overlay
    document.body.appendChild(overlay)
  }

  const storyActions = {
    insertDaySchedule,
    showVersions,
    pickPhoto() {
      if (countStoryImages(editor.getHTML()) >= MAX_STORY_PHOTOS) {
        window.alert('사진은 30장까지 올릴 수 있습니다.')
        return
      }
      post('pickPhoto')
    },
    pickVideo() {
      if (countStoryVideos(editor.getHTML()) >= MAX_STORY_VIDEOS) {
        window.alert('동영상은 3개까지 올릴 수 있습니다.')
        return
      }
      post('pickVideo')
    },
    pickMap() {
      if (countStoryMaps(editor.getHTML()) >= MAX_STORY_MAPS) {
        window.alert('지도는 5개까지 넣을 수 있습니다.')
        return
      }
      post('pickMap')
    },
  }

  let editor
  const bubbleMenuEl = createBubbleMenuElement(() => editor, COLORS)

  editor = new Editor({
    element: surface,
    extensions: [
      StarterKit.configure({
        codeBlock: false,
        code: false,
      }),
      TextStyle,
      Color,
      TextAlign.configure({
        types: ['heading', 'paragraph', 'image'],
      }),
      Image.configure({
        allowBase64: false,
        resize: {
          enabled: true,
          alwaysPreserveAspectRatio: true,
          minWidth: 48,
          minHeight: 48,
        },
      }),
      StoryVideo,
      createSlashCommandsExtension(storyActions),
      createBubbleMenuExtension(bubbleMenuEl),
    ],
    content: '<p></p>',
    editorProps: {
      transformPastedHTML(html) {
        const cleaned = cleanPastedHtml(html)
        pendingPasteDataImages = cleaned.dataImages
        pendingExternalImageCount = cleaned.externalImageCount
        pendingSkippedVideoCount = cleaned.skippedVideoCount
        queueMicrotask(flushPasteImageSideEffects)
        return cleaned.html
      },
      handlePaste(_view, event) {
        const files = collectImageFiles(event.clipboardData?.files)
        if (!files.length && event.clipboardData?.items) {
          for (const item of event.clipboardData.items) {
            if (item.kind === 'file' && item.type.startsWith('image/')) {
              const file = item.getAsFile()
              if (file) {
                files.push(file)
              }
            }
          }
        }
        if (files.length) {
          event.preventDefault()
          void queueImageFiles(files)
          return true
        }
        const html = event.clipboardData?.getData('text/html') || ''
        const plain = (event.clipboardData?.getData('text/plain') || '').trim()
        if (!html.trim() && plain) {
          const converted = parseYouTubeOrVimeo(plain)
          if (converted) {
            event.preventDefault()
            insertVideoViewLink(converted)
            return true
          }
        }
        return false
      },
      handleDrop(view, event, _slice, moved) {
        if (moved) {
          return false
        }
        const files = collectImageFiles(event.dataTransfer?.files)
        if (!files.length) {
          return false
        }
        event.preventDefault()
        const coords = view.posAtCoords({
          left: event.clientX,
          top: event.clientY,
        })
        if (coords) {
          editor.chain().focus().setTextSelection(coords.pos).run()
        }
        void queueImageFiles(files)
        return true
      },
    },
    onUpdate: () => {
      const html = editor.getHTML()
      post('contentChanged', { html })
      scheduleDraftSave(html)
    },
  })

  buildToolbar(editor, mount, storyActions)
  mount.insertBefore(mount.querySelector('.toolbar'), surface)
  mount.appendChild(bubbleMenuEl)

  window.addEventListener('message', (event) => {
    const data = event.data
    if (!data || data.source !== APP_SOURCE) {
      return
    }
    if (data.type === 'setStorageKey') {
      const next = typeof data.key === 'string' ? data.key.trim() : ''
      const prev = storageKey
      storageKey = next
      if (prev && next && prev !== next) {
        storageKeyChain = storageKeyChain
          .then(() => migrateStorageKey(prev, next))
          .catch(() => {})
      } else if (prev && !next) {
        storageKeyChain = storageKeyChain
          .then(() => clearDraft(prev))
          .catch(() => {})
      }
      return
    }
    if (data.type === 'setContent') {
      void handleSetContent(data.html || '<p></p>')
      return
    }
    if (data.type === 'saveSucceeded') {
      void handleSaveSucceeded(data.html || editor.getHTML())
      return
    }
    if (data.type === 'getContent') {
      post('content', { html: editor.getHTML() })
      return
    }
    if (data.type === 'uploadPhotoResult') {
      const id = typeof data.id === 'string' ? data.id : ''
      if (!id || !pendingUploads.has(id)) {
        return
      }
      pendingUploads.delete(id)
      const url = typeof data.url === 'string' ? data.url.trim() : ''
      if (/^https:\/\//i.test(url)) {
        replacePlaceholderWithImage(id, url)
        return
      }
      removePlaceholder(id)
      window.alert('사진을 올리지 못했습니다.')
      return
    }
    if (data.type === 'insertPhoto') {
      const url = typeof data.url === 'string' ? data.url.trim() : ''
      if (!/^https:\/\//i.test(url)) {
        return
      }
      if (countStoryImages(editor.getHTML()) >= MAX_STORY_PHOTOS) {
        window.alert('사진은 30장까지 올릴 수 있습니다.')
        return
      }
      editor.chain().focus().setImage({ src: url }).run()
      return
    }
    if (data.type === 'insertVideo') {
      const url = typeof data.url === 'string' ? data.url.trim() : ''
      if (!/^https:\/\//i.test(url)) {
        return
      }
      if (countStoryVideos(editor.getHTML()) >= MAX_STORY_VIDEOS) {
        window.alert('동영상은 3개까지 올릴 수 있습니다.')
        return
      }
      editor.chain().focus().setStoryVideo({ src: url }).run()
      return
    }
    if (data.type === 'insertMap') {
      const href = typeof data.href === 'string' ? data.href.trim() : ''
      const name = typeof data.name === 'string' ? data.name.trim() : ''
      const address = typeof data.address === 'string' ? data.address.trim() : ''
      if (!/^https:\/\//i.test(href) || (!name && !address)) {
        return
      }
      if (countStoryMaps(editor.getHTML()) >= MAX_STORY_MAPS) {
        window.alert('지도는 5개까지 넣을 수 있습니다.')
        return
      }
      const label = [name, address].filter(Boolean).join(' · ')
      const text = `${label} — 지도에서 보기`
      editor
        .chain()
        .focus()
        .insertContent(
          `<p><a href="${escapeAttr(href)}">${escapeText(text)}</a></p>`,
        )
        .run()
    }
  })

  post('ready', { html: editor.getHTML() })
}

if (document.readyState === 'loading') {
  document.addEventListener('DOMContentLoaded', boot)
} else {
  boot()
}
