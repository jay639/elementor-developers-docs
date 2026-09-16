# Sagar Tours and Travels — website

Marketing site for **Sagar Tours and Travels**, a taxi and tour & travel service
based in Nagpur, Maharashtra. Static, dependency-free, and built from reusable
components.

```bash
npm run build     # render dist/
npm start         # build, then preview at http://localhost:4173
```

There is nothing to `npm install` — the build uses Node's standard library only
(Node 18+).

---

## What ships

| Page | File | Notes |
| --- | --- | --- |
| Home | `dist/index.html` | Every section, one `<h1>` |
| Privacy Policy | `dist/privacy.html` | Draft template, `noindex` |
| Terms & Conditions | `dist/terms.html` | Draft template, `noindex` |

Plus `robots.txt`, `sitemap.xml`, the stylesheet, one JavaScript file and the
image folder. Deploy the contents of `dist/` to any static host.

---

## Before this goes live

Five things are placeholders. The site renders them with a visible
"to be confirmed" treatment so nothing reads as a verified claim, and it will
keep doing so until you change the values below.

### 1. Contact details — `src/data/site.mjs`

Replace `PHONE_E164`, `WHATSAPP_E164`, the display numbers, the email address
and the address lines, point `origin` at the real domain, set `mapEmbed` and
`mapLink` to the Google Business Profile listing, and set
`googleReviewsUrl` to the public reviews link. Then set:

```js
contact: { isPlaceholder: false, ... }
```

That one flag removes every "TO BE CONFIRMED" chip and lets the phone number,
email and street address into the page's structured data. While it is `true`,
those values are deliberately kept **out** of the JSON-LD — publishing an
unverified phone number as structured data tells Google something nobody has
confirmed.

### 2. Statistics — `src/data/content.mjs` → `stats`

The Google rating, customer count and years of experience carry an asterisk and
a footnote. Confirm the real figures, then set `stats.isPlaceholder = false`.

### 3. Reviews — `src/data/content.mjs` → `reviews`

The testimonial cards contain **no review text**, by design. Inventing customer
reviews for a real business is not acceptable, so they render as labelled
placeholders with greyed-out stars. Import the real reviews from the Google
Business Profile into `reviews.items` (`name`, `body`, `service`), then set
`reviews.isPlaceholder = false`.

### 4. Fares, distances and travel times — `src/data/content.mjs`

`FARE_PLACEHOLDER`, `ROUTE_DISTANCE_PLACEHOLDER` and
`ROUTE_DURATION_PLACEHOLDER` render as `₹XX/km`, `Approx. XXX km` and
`Approx. XX hrs`. Replace them with the rate card and verified route figures,
and drop `isPlaceholder` from the route entries.

### 5. Photography — `src/data/images.mjs`

Every photo slot currently points at generated placeholder art. `IMAGES.md` has
the shot brief for each slot and `src/data/images.mjs` has the swap procedure.

---

## Wiring up the booking form

With no backend, **Get a Quote** validates the form and hands the trip details
to WhatsApp as a pre-filled message. To post to a real endpoint instead, define
a global before `js/app.js` runs:

```html
<script>window.SAGAR_BOOKING_ENDPOINT = 'https://example.com/api/bookings';</script>
```

The form then `POST`s JSON (`pickup`, `drop`, `date`, `time`, `vehicle`,
`mobile`) to that URL, shows a success message and resets. On failure it tells
the visitor to call or use WhatsApp. **Book on WhatsApp** always goes to
WhatsApp regardless.

---

## Project layout

```
build.mjs                 renders every page into dist/
tools/gen-placeholders.mjs generates the placeholder art
tools/serve.mjs           local preview server
src/data/                 site config, editorial content, image manifest
src/lib/                  html templating helper, icon sprite
src/components/           one file per component
src/pages/                home + legal pages
public/                   css, js, img, favicon — copied into dist/ as-is
```

### Components

`Layout` · `Header` · `Hero` · `BookingForm` · `TrustStats` · `ServiceCard` ·
`BenefitItem` · `FleetCard` · `RouteCard` · `DestinationCard` · `HowItWorks` ·
`About` · `ReviewCard` · `FAQAccordion` · `CTASection` · `ContactCard` ·
`Footer` · `MobileActionBar`, plus the shared primitives in
`src/components/ui.mjs` (`Button`, `SectionHeading`, `Img`, `Stars`,
`PlaceholderChip`, `PlaceholderNote`).

Each component takes plain data and returns an `html` fragment. Content lives in
`src/data/`, never in a component — adding a service or a route means editing an
array, not markup.

---

## Design system

| Token | Value | Used for |
| --- | --- | --- |
| Primary red | `#C62828` | CTAs, icons, active nav, links, focus rings |
| Dark red | `#8E1B1B` | Hover states, brand mark gradient |
| Light red | `#FDECEC` | Icon tiles, hover backgrounds |
| Soft grey | `#F8F9FA` | Alternating section backgrounds |
| Charcoal | `#1F2937` | Body text, dark sections |
| Secondary text | `#6B7280` | Supporting copy |
| Border | `#E5E7EB` | Card and field outlines |

Spacing runs on an 8px scale (`--s-1` … `--s-12`), cards use 14–24px radii,
elevation has four steps, and transitions sit between 150ms and 300ms. Red is
used for emphasis only — the interface stays white, soft grey and charcoal.

Typography is Inter, loaded from Google Fonts asynchronously with a system
sans-serif fallback, so text renders immediately even if the font request is
slow.

---

## Performance and accessibility notes

- **No frameworks, no icon font.** The 200-odd icons on the page are `<use>`
  references into a single inline SVG sprite, so each glyph is defined once.
- Every `<img>` carries intrinsic `width`/`height` and lazy-loads except the
  hero, which is marked `fetchpriority="high"`.
- The page works with JavaScript disabled: navigation, the FAQ accordion
  (native `<details>`), and every call/WhatsApp link are plain HTML. JavaScript
  adds the drawer, scroll reveal, scrollspy, form validation and prefill.
- Skip link, focus-visible outlines, labelled landmarks, `aria-expanded` on the
  menu toggle, `aria-invalid` + inline error text on invalid fields.
- All motion is disabled under `prefers-reduced-motion: reduce`.
- Touch targets are at least 44px; the mobile action bar respects
  `env(safe-area-inset-bottom)`.
