# Photography brief

No licensed photography ships with this repository, so every image slot renders
generated placeholder art. This file is the shot list. `src/data/images.mjs`
has the mechanics of swapping a real file in.

## Direction

Realistic professional photography only — modern Indian taxis, real drivers,
real interiors, Indian highways and a Nagpur urban setting where possible.
Avoid illustrations, obviously AI-generated people or vehicles, cars with wrong
proportions, and low-resolution stock.

Shoot or license in landscape for the wide slots and portrait for the tall ones.
Export at roughly 2× the display size, convert to WebP or AVIF with a JPEG
fallback, and keep each file under ~250 KB.

## Slots

| Manifest key | Placeholder | Size | What the shot needs |
| --- | --- | --- | --- |
| `hero` | `placeholder-hero.svg` | 1920 × 1280 | A clean sedan taxi on a Nagpur street. Shot from a low three-quarter angle, daylight or early evening. The left half of the frame carries the headline over a dark scrim, so keep the vehicle right of centre and avoid detail on the left. |
| `whyChooseUs` | `placeholder-driver.svg` | 900 × 1100 | Portrait. A professional driver beside a clean car — uniform or smart casual, door open or holding it for a passenger. Warm, unstaged. |
| `about` | `placeholder-about.svg` | 900 × 1000 | Portrait. A passenger being helped with luggage into the boot, or a comfortable rear-seat interior with a real passenger. |
| `cta` | `placeholder-highway.svg` | 1920 × 900 | An Indian highway at dusk. Sits at 40% opacity behind dark text, so choose something with shape rather than detail. |
| `fleetDzire` | `placeholder-sedan.svg` | 800 × 500 | Maruti Suzuki Dzire, three-quarter front, plain background. |
| `fleetErtiga` | `placeholder-muv.svg` | 800 × 500 | Maruti Suzuki Ertiga, same framing as the Dzire. |
| `fleetCarens` | `placeholder-muv.svg` | 800 × 500 | Kia Carens, same framing. |
| `fleetInnova` | `placeholder-muv.svg` | 800 × 500 | Toyota Innova Crysta, same framing. |
| `fleetSedan` | `placeholder-sedan.svg` | 800 × 500 | The premium sedan actually in the fleet. |
| `fleetTempo` | `placeholder-van.svg` | 800 × 500 | Tempo Traveller, three-quarter front, door side visible. |
| `destTadoba` | `placeholder-wildlife.svg` | 800 × 1000 | Portrait. Tadoba Andhari Tiger Reserve — forest track, safari vehicle or wildlife. |
| `destPench` | `placeholder-wildlife.svg` | 800 × 1000 | Portrait. Pench National Park. |
| `destPachmarhi` | `placeholder-hills.svg` | 800 × 1000 | Portrait. Pachmarhi — a viewpoint, waterfall or the Satpura ridgeline. |
| `destKanha` | `placeholder-wildlife.svg` | 800 × 1000 | Portrait. Kanha National Park — sal forest or grassland. |
| `destChikhaldara` | `placeholder-hills.svg` | 800 × 1000 | Portrait. Chikhaldara — valley viewpoint or coffee plantations. |
| `destRamtek` | `placeholder-heritage.svg` | 800 × 1000 | Portrait. Ramtek temple on its hill. |
| `og` | `placeholder-og.svg` | 1200 × 630 | Social preview card. The hero photo with the business name set over it works well. |

The six fleet slots currently share three placeholder files. Once real photos
arrive, point each of the six at its own file.

## Alt text

Each slot has default alt text in the manifest describing the *intended* shot.
Rewrite it to describe the photo you actually use — alt text should say what is
in the frame, not repeat the vehicle name already printed under the card.

## Regenerating the placeholders

```bash
npm run images
```

Rewrites `public/img/placeholder-*.svg`. Only needed if you change
`tools/gen-placeholders.mjs`; `npm run build` runs it anyway.
