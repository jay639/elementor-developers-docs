/**
 * A very small HTML templating helper.
 *
 * `html` escapes every interpolated value by default and returns a marked
 * object, so nested `html` fragments and arrays of fragments compose without
 * being double-escaped. Use `raw()` only for markup you control.
 */

const RAW = Symbol('raw');

export const raw = (value) => ({ [RAW]: true, value: String(value) });

export function escapeHtml(value) {
  return String(value)
    .replace(/&/g, '&amp;')
    .replace(/</g, '&lt;')
    .replace(/>/g, '&gt;')
    .replace(/"/g, '&quot;')
    .replace(/'/g, '&#39;');
}

function stringify(value) {
  if (value === null || value === undefined || value === false || value === true) {
    return '';
  }
  if (Array.isArray(value)) return value.map(stringify).join('');
  if (typeof value === 'object' && value[RAW]) return value.value;
  return escapeHtml(value);
}

export function html(strings, ...values) {
  let out = strings[0];
  for (let i = 0; i < values.length; i += 1) {
    out += stringify(values[i]) + strings[i + 1];
  }
  return raw(out);
}

/** Flattens a fragment (or anything else) to a plain string. */
export const render = (node) => stringify(node);

/** Joins a list of class names, dropping falsy entries. */
export const cx = (...names) => names.filter(Boolean).join(' ');

/** Turns a heading into a URL-safe id. */
export const slugify = (text) =>
  String(text)
    .toLowerCase()
    .replace(/[^a-z0-9]+/g, '-')
    .replace(/^-|-$/g, '');
