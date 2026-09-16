/**
 * Generates the placeholder art used by every image slot until real
 * photography is supplied. See `src/data/images.mjs` for the swap procedure.
 *
 * These are deliberately neutral "photo slot" plates — charcoal, quiet, and
 * clearly labelled — so an unfinished site still reads as a finished design
 * rather than a page full of broken images.
 */
import { mkdir, writeFile } from 'node:fs/promises';
import { dirname, join } from 'node:path';
import { fileURLToPath } from 'node:url';

const OUT = join(dirname(fileURLToPath(import.meta.url)), '..', 'public', 'img');

/** Minimal line glyphs, drawn in a 48×48 box. */
const GLYPHS = {
  camera:
    'M6 16h6l3-4h18l3 4h6a3 3 0 0 1 3 3v17a3 3 0 0 1-3 3H6a3 3 0 0 1-3-3V19a3 3 0 0 1 3-3z M24 22a7 7 0 1 1 0 14 7 7 0 0 1 0-14z',
  sedan:
    'M4 30l4-10a5 5 0 0 1 5-3h22a5 5 0 0 1 5 3l4 10v7a2 2 0 0 1-2 2h-4a2 2 0 0 1-2-2v-2H12v2a2 2 0 0 1-2 2H6a2 2 0 0 1-2-2v-7z M8 30h32 M13 34h3 M32 34h3',
  muv:
    'M4 30l3-11a5 5 0 0 1 5-4h24a5 5 0 0 1 5 4l3 11v7a2 2 0 0 1-2 2h-4a2 2 0 0 1-2-2v-2H12v2a2 2 0 0 1-2 2H6a2 2 0 0 1-2-2v-7z M8 30h32 M24 15v12 M13 34h3 M32 34h3',
  van:
    'M4 18a3 3 0 0 1 3-3h26l8 9h2a3 3 0 0 1 3 3v9a2 2 0 0 1-2 2h-3 M13 38H7a2 2 0 0 1-2-2V18z M10 38a4 4 0 1 0 8 0 4 4 0 0 0-8 0z M32 38a4 4 0 1 0 8 0 4 4 0 0 0-8 0z M12 22h10v6H12z M26 22h6l4 6h-10z',
  driver:
    'M24 8a8 8 0 1 1 0 16 8 8 0 0 1 0-16z M8 42a16 16 0 0 1 32 0 M17 27l7 6 7-6',
  hills: 'M3 38l12-18 8 11 6-8 16 15z M17 14a3 3 0 1 1 0 6 3 3 0 0 1 0-6z',
  wildlife:
    'M24 12c7 0 12 6 12 13s-5 11-12 11-12-4-12-11 5-13 12-13z M16 17l-4-6 6 2 M32 17l4-6-6 2 M20 25h.1 M28 25h.1 M24 29l-3 2h6z',
  heritage:
    'M24 5l14 12H10z M13 17v20 M24 14v23 M35 17v20 M6 37h36 M6 43h36 M19 37v-8a5 5 0 0 1 10 0v8',
  highway:
    'M3 42L18 6h12l15 36z M24 12v5 M24 22v6 M24 33v6 M8 42h32',
};

/** width, height, glyph, label */
const PLATES = [
  ['placeholder-hero.svg', 1920, 1280, 'sedan', 'Hero — taxi in Nagpur'],
  ['placeholder-driver.svg', 900, 1100, 'driver', 'Professional driver'],
  ['placeholder-about.svg', 900, 1000, 'camera', 'About — passenger pickup'],
  ['placeholder-highway.svg', 1920, 900, 'highway', 'Outstation highway'],
  ['placeholder-sedan.svg', 800, 500, 'sedan', 'Sedan'],
  ['placeholder-muv.svg', 800, 500, 'muv', 'MUV'],
  ['placeholder-van.svg', 800, 500, 'van', 'Tempo Traveller'],
  ['placeholder-wildlife.svg', 800, 1000, 'wildlife', 'Wildlife destination'],
  ['placeholder-hills.svg', 800, 1000, 'hills', 'Hill station'],
  ['placeholder-heritage.svg', 800, 1000, 'heritage', 'Heritage town'],
  ['placeholder-og.svg', 1200, 630, 'sedan', 'Sagar Tours and Travels'],
];

function plate(w, h, glyph, label) {
  // Scale the centre-piece with the plate so small cards stay legible.
  const unit = Math.min(w, h);
  const icon = Math.round(unit * 0.16);
  const titleSize = Math.max(13, Math.round(unit * 0.036));
  const metaSize = Math.max(10, Math.round(unit * 0.024));
  const cx = w / 2;
  const cy = h / 2;
  const iconTop = cy - icon * 0.95;
  const gap = Math.round(unit * 0.012);

  return `<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 ${w} ${h}" width="${w}" height="${h}" role="img" aria-label="${label} photo placeholder">
  <defs>
    <linearGradient id="bg" x1="0" y1="0" x2="1" y2="1">
      <stop offset="0" stop-color="#232B38"/>
      <stop offset="0.55" stop-color="#1A212C"/>
      <stop offset="1" stop-color="#11161F"/>
    </linearGradient>
    <radialGradient id="glow" cx="0.5" cy="0.42" r="0.6">
      <stop offset="0" stop-color="#C62828" stop-opacity="0.18"/>
      <stop offset="1" stop-color="#C62828" stop-opacity="0"/>
    </radialGradient>
    <pattern id="grid" width="${Math.round(unit * 0.08)}" height="${Math.round(unit * 0.08)}" patternUnits="userSpaceOnUse">
      <path d="M${Math.round(unit * 0.08)} 0H0V${Math.round(unit * 0.08)}" fill="none" stroke="#FFFFFF" stroke-opacity="0.035" stroke-width="1"/>
    </pattern>
  </defs>
  <rect width="${w}" height="${h}" fill="url(#bg)"/>
  <rect width="${w}" height="${h}" fill="url(#grid)"/>
  <rect width="${w}" height="${h}" fill="url(#glow)"/>
  <g transform="translate(${cx - icon / 2} ${iconTop}) scale(${(icon / 48).toFixed(4)})">
    <path d="${GLYPHS[glyph]}" fill="none" stroke="#9AA4B2" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"/>
  </g>
  <rect x="${cx - icon * 0.28}" y="${iconTop + icon + gap * 2}" width="${icon * 0.56}" height="2" rx="1" fill="#C62828"/>
  <text x="${cx}" y="${iconTop + icon + gap * 2 + titleSize * 1.9}" text-anchor="middle" font-family="Inter, Segoe UI, Helvetica, Arial, sans-serif" font-size="${titleSize}" font-weight="600" fill="#E5E7EB">${label}</text>
  <text x="${cx}" y="${iconTop + icon + gap * 2 + titleSize * 1.9 + metaSize * 2}" text-anchor="middle" font-family="Inter, Segoe UI, Helvetica, Arial, sans-serif" font-size="${metaSize}" font-weight="500" letter-spacing="${(metaSize * 0.16).toFixed(2)}" fill="#6B7280">PHOTO SLOT · ${w} × ${h}</text>
</svg>
`;
}

await mkdir(OUT, { recursive: true });
for (const [file, w, h, glyph, label] of PLATES) {
  await writeFile(join(OUT, file), plate(w, h, glyph, label), 'utf8');
}
console.log(`placeholders: ${PLATES.length} written to public/img/`);
