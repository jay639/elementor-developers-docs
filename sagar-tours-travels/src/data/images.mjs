/**
 * Image manifest — one entry per photo slot on the site.
 *
 * ──────────────────────────────────────────────────────────────────────────
 * HOW TO DROP IN REAL PHOTOGRAPHY
 *
 * No licensed photography ships with this repository, so every slot currently
 * points at a generated placeholder in `public/img/`. To use a real photo:
 *
 *   1. Put the file in `public/img/` (e.g. `hero-taxi.jpg`).
 *   2. Change that slot's `src` to `img/hero-taxi.jpg`.
 *   3. Set `width`/`height` to the file's real pixel dimensions so the browser
 *      reserves the right space and the layout does not shift.
 *   4. Optionally add `srcset` for responsive variants, e.g.
 *        srcset: 'img/hero-taxi-800.jpg 800w, img/hero-taxi-1600.jpg 1600w'
 *        sizes: '100vw'
 *   5. Write a real `alt` describing what is in the photo.
 *   6. Run `npm run build`.
 *
 * `IMAGES.md` has the shot brief for each slot.
 * ──────────────────────────────────────────────────────────────────────────
 */

/** Marks a slot as still needing real photography. */
const slot = (file, width, height, alt) => ({
  src: `img/${file}`,
  width,
  height,
  alt,
  isPlaceholder: true,
});

export const images = {
  hero: slot(
    'placeholder-hero.svg',
    1920,
    1280,
    'Sedan taxi waiting on a Nagpur street'
  ),
  whyChooseUs: slot(
    'placeholder-driver.svg',
    900,
    1100,
    'Professional driver standing beside a clean taxi'
  ),
  about: slot(
    'placeholder-about.svg',
    900,
    1000,
    'Passenger being helped into a taxi with luggage'
  ),
  cta: slot(
    'placeholder-highway.svg',
    1920,
    900,
    'Highway at dusk on an outstation route from Nagpur'
  ),

  fleetDzire: slot('placeholder-sedan.svg', 800, 500, 'Maruti Suzuki Dzire sedan'),
  fleetErtiga: slot('placeholder-muv.svg', 800, 500, 'Maruti Suzuki Ertiga MUV'),
  fleetCarens: slot('placeholder-muv.svg', 800, 500, 'Kia Carens premium MUV'),
  fleetInnova: slot('placeholder-muv.svg', 800, 500, 'Toyota Innova Crysta premium MUV'),
  fleetSedan: slot('placeholder-sedan.svg', 800, 500, 'Premium sedan'),
  fleetTempo: slot('placeholder-van.svg', 800, 500, 'Tempo Traveller group vehicle'),

  destTadoba: slot('placeholder-wildlife.svg', 800, 1000, 'Tadoba Andhari Tiger Reserve'),
  destPench: slot('placeholder-wildlife.svg', 800, 1000, 'Pench National Park'),
  destPachmarhi: slot('placeholder-hills.svg', 800, 1000, 'Pachmarhi hill station'),
  destKanha: slot('placeholder-wildlife.svg', 800, 1000, 'Kanha National Park'),
  destChikhaldara: slot('placeholder-hills.svg', 800, 1000, 'Chikhaldara hill station'),
  destRamtek: slot('placeholder-heritage.svg', 800, 1000, 'Ramtek temple town'),

  /** Open Graph / social preview card. */
  og: slot('placeholder-og.svg', 1200, 630, 'Sagar Tours and Travels'),
};

/** True while any slot still uses generated placeholder art. */
export const hasPlaceholderImages = Object.values(images).some(
  (i) => i.isPlaceholder
);
