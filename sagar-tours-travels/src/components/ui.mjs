/** Shared primitives every other component is built from. */
import { html, raw, cx } from '../lib/html.mjs';
import { icon } from '../lib/icons.mjs';
import { images } from '../data/images.mjs';

/**
 * Button / link button.
 * variant: 'filled' | 'outlined' | 'text' | 'whatsapp' | 'ghost'
 */
export function Button({
  label,
  href = '#',
  variant = 'filled',
  size = 'md',
  iconName,
  iconAfter,
  className = '',
  attrs = '',
  type,
  block = false,
}) {
  const classes = cx(
    'btn',
    `btn--${variant}`,
    `btn--${size}`,
    block && 'btn--block',
    className
  );
  const content = html`${iconName ? icon(iconName, { size: 20, className: 'btn__icon' }) : ''}<span
      class="btn__label"
      >${label}</span
    >${iconAfter ? icon(iconAfter, { size: 20, className: 'btn__icon btn__icon--after' }) : ''}`;

  if (type) {
    return html`<button type="${type}" class="${classes}" ${raw(attrs)}>${content}</button>`;
  }
  return html`<a href="${href}" class="${classes}" ${raw(attrs)}>${content}</a>`;
}

/** Eyebrow + heading + supporting copy, used at the top of most sections. */
export function SectionHeading({
  eyebrow,
  title,
  subtitle,
  id,
  align = 'center',
  level = 2,
}) {
  const Tag = `h${level}`;
  return html`<header class="${cx('section-heading', `section-heading--${align}`)}">
    ${eyebrow ? html`<p class="eyebrow">${eyebrow}</p>` : ''}
    ${raw(`<${Tag} class="section-heading__title"${id ? ` id="${id}"` : ''}>`)}${title}${raw(
    `</${Tag}>`
  )}
    ${subtitle ? html`<p class="section-heading__subtitle">${subtitle}</p>` : ''}
  </header>`;
}

/** Small chip marking a value the business has not confirmed yet. */
export function PlaceholderChip({ label = 'To be confirmed' } = {}) {
  return html`<span class="chip chip--placeholder" title="Placeholder value — pending confirmation from the business"
    >${label}</span
  >`;
}

/** Quiet footnote used under sections that show placeholder figures. */
export function PlaceholderNote({ text }) {
  return html`<p class="placeholder-note">${icon('shield', { size: 16 })}<span>${text}</span></p>`;
}

/**
 * Renders an image slot from the manifest in `src/data/images.mjs`.
 * Always emits intrinsic width/height so nothing shifts while loading.
 */
export function Img(
  key,
  { className = '', sizes, loading = 'lazy', fetchpriority, alt } = {}
) {
  const source = images[key];
  if (!source) throw new Error(`Unknown image slot: ${key}`);
  const attrs = [
    `src="${source.src}"`,
    source.srcset ? `srcset="${source.srcset}"` : '',
    sizes && source.srcset ? `sizes="${sizes}"` : '',
    `width="${source.width}"`,
    `height="${source.height}"`,
    `alt="${(alt ?? source.alt).replace(/"/g, '&quot;')}"`,
    loading === 'eager' ? '' : 'loading="lazy"',
    'decoding="async"',
    fetchpriority ? `fetchpriority="${fetchpriority}"` : '',
    className ? `class="${className}"` : '',
    source.isPlaceholder ? 'data-placeholder-image="true"' : '',
  ]
    .filter(Boolean)
    .join(' ');
  return raw(`<img ${attrs}>`);
}

/** Star row used by the reviews section. */
export function Stars({ count = 5, label }) {
  return html`<div class="stars" role="img" aria-label="${label || `${count} out of 5 stars`}">
    ${Array.from({ length: count }, () => icon('star', { size: 18 }))}
  </div>`;
}
