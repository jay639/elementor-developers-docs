/** Vehicle cards + the "Our Fleet" section. */
import { html } from '../lib/html.mjs';
import { icon } from '../lib/icons.mjs';
import { Img, PlaceholderChip, SectionHeading, PlaceholderNote } from './ui.mjs';
import { fleet, FARE_PLACEHOLDER } from '../data/content.mjs';

export function FleetCard({ vehicle }) {
  const specs = [
    { icon: 'person', label: vehicle.seats },
    { icon: 'luggage', label: vehicle.bags },
    ...vehicle.features.map((feature) => ({ icon: 'snow', label: feature })),
  ];

  return html`<article class="card card--fleet">
    <div class="card__media">
      ${Img(vehicle.image, { sizes: '(max-width: 720px) 100vw, 33vw' })}
      <span class="card__badge">${vehicle.category}</span>
    </div>
    <div class="card__body">
      <h3 class="card__title">${vehicle.name}</h3>
      <ul class="spec-list">
        ${specs.map(
          (spec) => html`<li class="spec">${icon(spec.icon, { size: 18 })}<span>${spec.label}</span></li>`
        )}
      </ul>
      <div class="card__foot">
        <p class="price">
          <span class="price__value">${FARE_PLACEHOLDER}</span>
          ${PlaceholderChip({ label: 'Rate pending' })}
        </p>
        <a class="card__link" href="#booking" data-prefill-vehicle="${vehicle.name}"
          >Book Now ${icon('arrowRight', { size: 18 })}</a
        >
      </div>
    </div>
  </article>`;
}

export function FleetSection() {
  return html`<section class="section" id="fleet" aria-labelledby="fleetTitle">
    <div class="container">
      ${SectionHeading({
        eyebrow: 'Our Vehicles',
        title: 'Our Fleet',
        subtitle: 'Choose a comfortable vehicle that fits your journey and group size.',
        id: 'fleetTitle',
      })}
      <div class="grid grid--fleet" data-reveal>
        ${fleet.map((vehicle) => FleetCard({ vehicle }))}
      </div>
      ${PlaceholderNote({
        text: 'Vehicle availability and per-kilometre rates are placeholders. Confirmed fares will be published once the business supplies its rate card.',
      })}
    </div>
  </section>`;
}
