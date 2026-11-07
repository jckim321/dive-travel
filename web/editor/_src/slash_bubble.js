import { Extension } from '@tiptap/core'
import { PluginKey } from '@tiptap/pm/state'
import Suggestion from '@tiptap/suggestion'
import BubbleMenu from '@tiptap/extension-bubble-menu'

const slashPluginKey = new PluginKey('diveTravelSlash')

function filterSlashItems(items, query) {
  const q = String(query || '')
    .trim()
    .toLowerCase()
  if (!q) {
    return items
  }
  return items.filter((item) => {
    const hay = [item.title, ...(item.keywords || [])].join(' ').toLowerCase()
    return hay.includes(q)
  })
}

function buildSlashItems(actions) {
  return [
    {
      title: '제목',
      keywords: ['제목', 'heading', 'h2'],
      command: ({ editor, range }) => {
        editor.chain().focus().deleteRange(range).setHeading({ level: 2 }).run()
      },
    },
    {
      title: '목록',
      keywords: ['목록', '글머리', 'bullet', 'ul'],
      command: ({ editor, range }) => {
        editor.chain().focus().deleteRange(range).toggleBulletList().run()
      },
    },
    {
      title: '번호 목록',
      keywords: ['번호', 'ordered', 'ol', 'numbered'],
      command: ({ editor, range }) => {
        editor.chain().focus().deleteRange(range).toggleOrderedList().run()
      },
    },
    {
      title: '인용',
      keywords: ['인용', 'quote', 'blockquote'],
      command: ({ editor, range }) => {
        editor.chain().focus().deleteRange(range).toggleBlockquote().run()
      },
    },
    {
      title: '구분선',
      keywords: ['구분선', 'hr', 'divider'],
      command: ({ editor, range }) => {
        editor.chain().focus().deleteRange(range).setHorizontalRule().run()
      },
    },
    {
      title: '일차 일정',
      keywords: ['일차', '일정', 'day', 'schedule', 'itinerary'],
      command: ({ editor, range }) => {
        editor.chain().focus().deleteRange(range).run()
        actions.insertDaySchedule()
      },
    },
    {
      title: '사진',
      keywords: ['사진', 'photo', 'image', 'img'],
      command: ({ editor, range }) => {
        editor.chain().focus().deleteRange(range).run()
        actions.pickPhoto()
      },
    },
    {
      title: '동영상',
      keywords: ['동영상', 'video', 'mp4'],
      command: ({ editor, range }) => {
        editor.chain().focus().deleteRange(range).run()
        actions.pickVideo()
      },
    },
    {
      title: '지도',
      keywords: ['지도', 'map', '장소'],
      command: ({ editor, range }) => {
        editor.chain().focus().deleteRange(range).run()
        actions.pickMap()
      },
    },
  ]
}

function renderSlashList(container, items, selectedIndex, onPick) {
  container.textContent = ''
  if (!items.length) {
    const empty = document.createElement('div')
    empty.className = 'slash-menu-empty'
    empty.textContent = '일치하는 항목 없음'
    container.appendChild(empty)
    return
  }
  items.forEach((item, index) => {
    const row = document.createElement('button')
    row.type = 'button'
    row.className =
      'slash-menu-item' + (index === selectedIndex ? ' is-selected' : '')
    row.textContent = item.title
    row.addEventListener('mousedown', (event) => {
      event.preventDefault()
      onPick(item)
    })
    container.appendChild(row)
  })
}

/** Slash `/` command menu via @tiptap/suggestion (MIT). */
export function createSlashCommandsExtension(actions) {
  const allItems = buildSlashItems(actions)

  return Extension.create({
    name: 'slashCommands',
    addOptions() {
      return {
        suggestion: {
          char: '/',
          pluginKey: slashPluginKey,
          startOfLine: true,
          allowSpaces: false,
          allowedPrefixes: null,
          items: ({ query }) => filterSlashItems(allItems, query),
          command: ({ editor, range, props }) => {
            props.command({ editor, range })
          },
          render: () => {
            let popup
            let list
            let unmount = null
            let selectedIndex = 0
            let currentProps = null

            const refresh = () => {
              if (!list || !currentProps) {
                return
              }
              const items = currentProps.items || []
              if (selectedIndex >= items.length) {
                selectedIndex = Math.max(0, items.length - 1)
              }
              renderSlashList(list, items, selectedIndex, (item) => {
                currentProps.command(item)
              })
            }

            return {
              onStart(props) {
                currentProps = props
                selectedIndex = 0
                popup = document.createElement('div')
                popup.className = 'slash-menu'
                list = document.createElement('div')
                list.className = 'slash-menu-list'
                popup.appendChild(list)
                refresh()
                unmount = props.mount(popup)
              },
              onUpdate(props) {
                currentProps = props
                selectedIndex = 0
                refresh()
              },
              onKeyDown({ event }) {
                const items = currentProps?.items || []
                if (event.key === 'Escape') {
                  return true
                }
                if (!items.length) {
                  return false
                }
                if (event.key === 'ArrowUp') {
                  selectedIndex = (selectedIndex + items.length - 1) % items.length
                  refresh()
                  return true
                }
                if (event.key === 'ArrowDown') {
                  selectedIndex = (selectedIndex + 1) % items.length
                  refresh()
                  return true
                }
                if (event.key === 'Enter') {
                  const item = items[selectedIndex]
                  if (item) {
                    currentProps.command(item)
                  }
                  return true
                }
                return false
              },
              onExit() {
                unmount?.()
                unmount = null
                popup = null
                list = null
                currentProps = null
              },
            }
          },
        },
      }
    },
    addProseMirrorPlugins() {
      return [
        Suggestion({
          editor: this.editor,
          ...this.options.suggestion,
        }),
      ]
    },
  })
}

/** Selection bubble menu element for BubbleMenu.configure({ element }). */
export function createBubbleMenuElement(getEditor, colors) {
  const root = document.createElement('div')
  root.className = 'bubble-menu'
  root.style.display = 'none'

  const addBtn = (label, title, onClick) => {
    const btn = document.createElement('button')
    btn.type = 'button'
    btn.textContent = label
    btn.title = title
    btn.addEventListener('mousedown', (event) => {
      event.preventDefault()
      onClick()
    })
    root.appendChild(btn)
    return btn
  }

  addBtn('B', '굵게', () => getEditor()?.chain().focus().toggleBold().run())
  addBtn('I', '기울임', () => getEditor()?.chain().focus().toggleItalic().run())
  addBtn('U', '밑줄', () => getEditor()?.chain().focus().toggleUnderline().run())
  addBtn('링크', '링크', () => {
    const editor = getEditor()
    if (!editor) {
      return
    }
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
  })

  const color = document.createElement('select')
  color.title = '글자 색'
  color.className = 'bubble-menu-color'
  for (const opt of colors) {
    const o = document.createElement('option')
    o.value = opt.value
    o.textContent = opt.label
    color.appendChild(o)
  }
  color.addEventListener('mousedown', (event) => {
    event.stopPropagation()
  })
  color.addEventListener('change', () => {
    const editor = getEditor()
    if (!editor) {
      return
    }
    const value = color.value
    const chain = editor.chain().focus()
    if (!value) {
      chain.unsetColor().run()
      return
    }
    chain.setColor(value).run()
  })
  root.appendChild(color)

  return root
}

export function createBubbleMenuExtension(element) {
  return BubbleMenu.configure({
    element,
    options: {
      placement: 'top',
      offset: 8,
      flip: true,
      shift: true,
    },
    shouldShow: ({ editor, state }) => {
      const { selection } = state
      if (!editor.isEditable || selection.empty) {
        return false
      }
      if (selection.node) {
        return false
      }
      return true
    },
  })
}

/** Preset image widths (px). Matches sanitizeStoryHtml digit width attrs. */
const IMAGE_SIZE_PRESETS = [
  { label: '작게', width: 160 },
  { label: '중간', width: 320 },
  { label: '크게', width: 480 },
  { label: '원본', width: null },
]

/** Floating controls when an image node is selected. */
export function createImageBubbleMenuElement(getEditor) {
  const root = document.createElement('div')
  root.className = 'bubble-menu image-bubble-menu'
  root.style.display = 'none'

  const addBtn = (label, title, onClick) => {
    const btn = document.createElement('button')
    btn.type = 'button'
    btn.textContent = label
    btn.title = title
    btn.addEventListener('mousedown', (event) => {
      event.preventDefault()
      onClick()
    })
    root.appendChild(btn)
    return btn
  }

  for (const preset of IMAGE_SIZE_PRESETS) {
    addBtn(preset.label, `사진 크기: ${preset.label}`, () => {
      const editor = getEditor()
      if (!editor?.isActive('image')) {
        return
      }
      if (preset.width == null) {
        editor
          .chain()
          .focus()
          .updateAttributes('image', { width: null, height: null })
          .run()
        return
      }
      editor
        .chain()
        .focus()
        .updateAttributes('image', { width: preset.width, height: null })
        .run()
    })
  }

  addBtn('좌', '사진 왼쪽 정렬', () => {
    getEditor()?.chain().focus().setTextAlign('left').run()
  })
  addBtn('중', '사진 가운데 정렬', () => {
    getEditor()?.chain().focus().setTextAlign('center').run()
  })
  addBtn('우', '사진 오른쪽 정렬', () => {
    getEditor()?.chain().focus().setTextAlign('right').run()
  })

  return root
}

export function createImageBubbleMenuExtension(element) {
  return BubbleMenu.configure({
    element,
    pluginKey: new PluginKey('diveTravelImageBubble'),
    options: {
      placement: 'top',
      offset: 8,
      flip: true,
      shift: true,
    },
    shouldShow: ({ editor }) => {
      if (!editor.isEditable) {
        return false
      }
      return editor.isActive('image')
    },
  })
}
