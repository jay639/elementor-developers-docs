/**
 * Material-style line icons, authored in a 24×24 box and drawn with
 * `currentColor` so they inherit type colour. Inlined at build time — no icon
 * font, no runtime request.
 */
import { html, raw, cx } from './html.mjs';

/** Icons drawn as outlines. */
const STROKE = {
  phone:
    'M6.5 3.5h3l2 4.8-2.3 1.4a11.5 11.5 0 0 0 4.9 4.9l1.4-2.3 4.8 2v3a2.2 2.2 0 0 1-2.4 2.2A16.4 16.4 0 0 1 4.3 5.9 2.2 2.2 0 0 1 6.5 3.5z',
  menu: 'M4 7h16 M4 12h16 M4 17h16',
  close: 'M6 6l12 12 M18 6L6 18',
  arrowRight: 'M4 12h14 M13 6.5l5.5 5.5-5.5 5.5',
  arrowUpRight: 'M7 17L17 7 M8.5 7H17v8.5',
  check: 'M4.5 12.5l4.5 4.5L19.5 6.5',
  clock: 'M12 3.5a8.5 8.5 0 1 1 0 17 8.5 8.5 0 0 1 0-17z M12 7.5V12l3 2',
  group:
    'M9 4.5a3.2 3.2 0 1 1 0 6.4 3.2 3.2 0 0 1 0-6.4z M2.5 20v-.8A6.5 6.5 0 0 1 9 12.7a6.5 6.5 0 0 1 6.5 6.5V20 M16 5a3.2 3.2 0 0 1 0 6.3 M17 13a6.2 6.2 0 0 1 4.5 6V20',
  shield:
    'M12 3l7.5 2.8v5.6c0 4.7-3.2 7.6-7.5 8.6-4.3-1-7.5-3.9-7.5-8.6V5.8z M9 12l2.2 2.2L15.2 10',
  flight:
    'M12 2.5a1.4 1.4 0 0 1 1.4 1.4v5.2l7.6 4.3v1.9l-7.6-2.3v4.2l2.5 1.7v1.6L12 19.4l-3.9 1.1v-1.6l2.5-1.7v-4.2L3 15.3v-1.9l7.6-4.3V3.9a1.4 1.4 0 0 1 1.4-1.4z',
  city:
    'M3 20.5h18 M6 20.5V8.2l5.5-3.7v16 M11.5 10.5l6.5 2.6v7.4 M8.5 11h.01 M8.5 14.5h.01 M15 15h.01 M15 18h.01',
  route:
    'M6.5 3.2a2.4 2.4 0 1 1 0 4.8 2.4 2.4 0 0 1 0-4.8z M17.5 16a2.4 2.4 0 1 1 0 4.8 2.4 2.4 0 0 1 0-4.8z M6.5 8v3.8a3.7 3.7 0 0 0 3.7 3.7h3.6a3.7 3.7 0 0 1 3.7 3.7',
  oneWay: 'M3 12h15 M13.5 7l5 5-5 5',
  briefcase:
    'M3.2 7.5h17.6v11.3a1.8 1.8 0 0 1-1.8 1.8H5a1.8 1.8 0 0 1-1.8-1.8z M8.8 7.5V5.8A1.8 1.8 0 0 1 10.6 4h2.8a1.8 1.8 0 0 1 1.8 1.8v1.7 M3.2 12.7h17.6',
  celebration:
    'M8.6 10.5a4.7 4.7 0 1 1 0 9.4 4.7 4.7 0 0 1 0-9.4z M15.4 10.5a4.7 4.7 0 1 1 0 9.4 4.7 4.7 0 0 1 0-9.4z M12 3.2l2.2 3.1h-4.4z',
  train:
    'M7.5 3h9a3 3 0 0 1 3 3v8a3 3 0 0 1-3 3h-9a3 3 0 0 1-3-3V6a3 3 0 0 1 3-3z M4.5 10.2h15 M9 14h.01 M15 14h.01 M8 17l-2.2 4 M16 17l2.2 4',
  map: 'M9 4.2L3.2 6.3v14L9 18.2l6 2.1 5.8-2.1v-14L15 6.3z M9 4.2v14 M15 6.3v14',
  badge:
    'M12 3l2.3 1.6 2.8-.2 1 2.6 2.4 1.5-.9 2.7.9 2.7-2.4 1.5-1 2.6-2.8-.2L12 21l-2.3-1.6-2.8.2-1-2.6L3.5 15.5l.9-2.7-.9-2.7 2.4-1.5 1-2.6 2.8.2z M9.2 12.1l2 2 3.6-3.9',
  sparkle:
    'M11 3.2l1.7 4.6 4.6 1.7-4.6 1.7L11 15.8l-1.7-4.6L4.7 9.5l4.6-1.7z M18 15l.7 1.9 1.9.7-1.9.7-.7 1.9-.7-1.9-1.9-.7 1.9-.7z',
  rupee: 'M7 4.5h10 M7 8.3h10 M9.2 4.5c4 0 6 1.5 6 3.9s-2 3.9-6 3.9H7l7.5 7.2',
  headset:
    'M4 13.2v-1A8 8 0 0 1 20 12v1.2 M4 13.2h1.9a1.1 1.1 0 0 1 1.1 1.1v3.9a1.1 1.1 0 0 1-1.1 1.1H4.9A1.1 1.1 0 0 1 3.8 18v-3.7a1.1 1.1 0 0 1 1.1-1.1z M20 13.2h-1.9a1.1 1.1 0 0 0-1.1 1.1v3.9a1.1 1.1 0 0 0 1.1 1.1h1a1.1 1.1 0 0 0 1.1-1.1v-3.9a1.1 1.1 0 0 0-1.1-1.1z M20.2 19.3v.5a2.2 2.2 0 0 1-2.2 2.2h-3.6',
  chevronDown: 'M6.5 9.5l5.5 5.5 5.5-5.5',
  mail: 'M3.2 5.8h17.6v12.4H3.2z M3.6 6.6l8.4 5.8 8.4-5.8',
  location:
    'M12 21.2s7-5.6 7-11.2a7 7 0 1 0-14 0c0 5.6 7 11.2 7 11.2z M12 7.6a2.5 2.5 0 1 1 0 5 2.5 2.5 0 0 1 0-5z',
  calendar: 'M4 6.2h16v14.3H4z M4 10.4h16 M8.2 3.5v4 M15.8 3.5v4',
  person: 'M12 4.2a3.3 3.3 0 1 1 0 6.6 3.3 3.3 0 0 1 0-6.6z M5 20.5v-1a7 7 0 0 1 14 0v1',
  luggage:
    'M8.5 6.8V5.2a1.8 1.8 0 0 1 1.8-1.8h3.4a1.8 1.8 0 0 1 1.8 1.8v1.6 M5 6.8h14v11.6a2 2 0 0 1-2 2H7a2 2 0 0 1-2-2z M10 10.5v6 M14 10.5v6',
  snow:
    'M12 2.8v18.4 M4.2 7.4l15.6 9 M19.8 7.4l-15.6 9 M12 6.8L9.6 4.4 M12 6.8l2.4-2.4 M12 17.2l-2.4 2.4 M12 17.2l2.4 2.4',
  car:
    'M3.2 16.6v-3.4l1.9-4.8A2.2 2.2 0 0 1 7.2 7h9.6a2.2 2.2 0 0 1 2.1 1.4l1.9 4.8v3.4 M4.6 13h14.8 M5.4 16.6a1.8 1.8 0 1 0 3.6 0 1.8 1.8 0 0 0-3.6 0z M15 16.6a1.8 1.8 0 1 0 3.6 0 1.8 1.8 0 0 0-3.6 0z',
  send: 'M20.5 3.5L3.5 10.2l7 3.1 3.1 7z M20.5 3.5l-10 10.3',
  plus: 'M12 5.5v13 M5.5 12h13',
  swap: 'M7 5.5L3.8 8.8 7 12 M3.8 8.8h13.4 M17 18.5l3.2-3.2L17 12 M20.2 15.3H6.8',
};

/** Icons drawn as solid shapes. */
const FILL = {
  star: 'M12 2.6l2.9 5.9 6.5.9-4.7 4.6 1.1 6.5-5.8-3-5.8 3 1.1-6.5L2.6 9.4l6.5-.9z',
  whatsapp:
    'M12.03 2A9.94 9.94 0 0 0 3.5 17.1L2.05 22l5.03-1.32A9.94 9.94 0 1 0 12.03 2zm0 1.8a8.14 8.14 0 1 1-4.15 15.14l-.3-.18-3 .79.8-2.92-.19-.3A8.14 8.14 0 0 1 12.03 3.8zm-3.3 4c-.17 0-.44.06-.67.31-.23.25-.88.86-.88 2.1 0 1.24.9 2.44 1.03 2.6.13.17 1.75 2.79 4.32 3.8 2.13.84 2.57.67 3.03.63.46-.04 1.49-.6 1.7-1.19.21-.58.21-1.08.15-1.19-.06-.1-.23-.17-.48-.29-.25-.13-1.49-.73-1.72-.82-.23-.08-.4-.12-.56.13-.17.25-.65.82-.79.98-.15.17-.29.19-.54.06-.25-.12-1.06-.39-2.02-1.24-.75-.66-1.25-1.48-1.4-1.73-.14-.25-.01-.38.11-.5.11-.11.25-.29.38-.44.12-.15.16-.25.25-.42.08-.17.04-.31-.02-.44-.06-.12-.56-1.36-.77-1.86-.2-.48-.4-.42-.56-.42z',
  quote:
    'M9.6 5.4v3.2c-1.5.3-2.4 1.3-2.6 2.8h2.6v7.2H3V13c0-4.1 2.2-6.9 6.6-7.6zm11 0v3.2c-1.5.3-2.4 1.3-2.6 2.8H20.6v7.2H14V13c0-4.1 2.2-6.9 6.6-7.6z',
};

/**
 * Icons are emitted as `<use>` references into a single sprite so a glyph that
 * appears thirty times on the page is defined once. `usedIcons` records which
 * symbols a render actually needed; `spriteMarkup()` emits just those.
 */
const usedIcons = new Set();

const LOGO_SYMBOL = `<symbol id="i-logo" viewBox="0 0 48 48">
    <linearGradient id="stt-mark" x1="0" y1="0" x2="1" y2="1">
      <stop offset="0" stop-color="#E03A3A"/>
      <stop offset="1" stop-color="#8E1B1B"/>
    </linearGradient>
    <rect width="48" height="48" rx="13" fill="url(#stt-mark)"/>
    <path d="M31.5 15.5H20.8c-2.6 0-4.3 1.4-4.3 3.4 0 1.9 1.3 2.9 4.2 3.5l4.4 1c1 .2 1.4.6 1.4 1.2 0 .8-.8 1.3-2.2 1.3H14v3.6h11c2.9 0 4.8-1.5 4.8-3.7 0-1.9-1.2-3-4-3.6l-4.5-1c-1-.2-1.5-.6-1.5-1.2 0-.7.7-1.1 2-1.1h9.7z" fill="#FFFFFF"/>
    <path d="M14 33.5h20" stroke="#FFFFFF" stroke-opacity="0.55" stroke-width="2.4" stroke-linecap="round" stroke-dasharray="4 4"/>
  </symbol>`;

function symbolFor(name) {
  if (name === 'logo') return LOGO_SYMBOL;
  const fillPath = FILL[name];
  const body = fillPath
    ? `<path d="${fillPath}" fill="currentColor"/>`
    : `<path d="${STROKE[name]}" fill="none" stroke="currentColor" stroke-width="1.7" stroke-linecap="round" stroke-linejoin="round"/>`;
  return `<symbol id="i-${name}" viewBox="0 0 24 24">${body}</symbol>`;
}

export function icon(name, { size = 24, className = '', title = '' } = {}) {
  if (!STROKE[name] && !FILL[name]) {
    throw new Error(`Unknown icon: ${name}`);
  }
  usedIcons.add(name);
  return html`<svg
    class="${cx('icon', className)}"
    viewBox="0 0 24 24"
    width="${size}"
    height="${size}"
    ${title ? raw('role="img"') : raw('aria-hidden="true" focusable="false"')}
  >${title ? raw(`<title>${title}</title>`) : ''}${raw(`<use href="#i-${name}"/>`)}</svg>`;
}

/** The brand mark: a red tile carrying an abstract road-and-motion glyph. */
export function logoMark({ size = 40 } = {}) {
  usedIcons.add('logo');
  return html`<svg
    class="brand__mark"
    viewBox="0 0 48 48"
    width="${size}"
    height="${size}"
    aria-hidden="true"
    focusable="false"
  >${raw('<use href="#i-logo"/>')}</svg>`;
}

/**
 * The sprite for everything rendered so far. Call this after the page body has
 * been rendered, and inline the result at the top of <body>.
 */
export function spriteMarkup() {
  if (!usedIcons.size) return '';
  const symbols = Array.from(usedIcons).sort().map(symbolFor).join('');
  return `<svg class="icon-sprite" aria-hidden="true" focusable="false" width="0" height="0" style="position:absolute;width:0;height:0;overflow:hidden">${symbols}</svg>`;
}

/** Clears the sprite registry. The build calls this before each page render. */
export function resetIcons() {
  usedIcons.clear();
}
