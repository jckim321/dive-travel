import { Editor } from '@tiptap/core'
import StarterKit from '@tiptap/starter-kit'
import { TextStyle } from '@tiptap/extension-text-style'
import { Color } from '@tiptap/extension-color'
import TextAlign from '@tiptap/extension-text-align'

const SOURCE = 'dive-travel-editor'
const APP_SOURCE = 'dive-travel-app'

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

function buildToolbar(editor, root) {
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
  )

  root.append(bar)
}

function boot() {
  const root = document.getElementById('app')
  const mount = document.createElement('div')
  mount.className = 'editor-shell'
  const surface = document.createElement('div')
  surface.className = 'editor-surface'
  mount.append(surface)
  root.append(mount)

  const editor = new Editor({
    element: surface,
    extensions: [
      StarterKit.configure({
        codeBlock: false,
        code: false,
      }),
      TextStyle,
      Color,
      TextAlign.configure({
        types: ['heading', 'paragraph'],
      }),
    ],
    content: '<p></p>',
    onUpdate: () => {
      post('contentChanged', { html: editor.getHTML() })
    },
  })

  buildToolbar(editor, mount)
  mount.insertBefore(mount.querySelector('.toolbar'), surface)

  window.addEventListener('message', (event) => {
    const data = event.data
    if (!data || data.source !== APP_SOURCE) {
      return
    }
    if (data.type === 'setContent') {
      editor.commands.setContent(data.html || '<p></p>', { emitUpdate: false })
      return
    }
    if (data.type === 'getContent') {
      post('content', { html: editor.getHTML() })
    }
  })

  post('ready', { html: editor.getHTML() })
}

if (document.readyState === 'loading') {
  document.addEventListener('DOMContentLoaded', boot)
} else {
  boot()
}
