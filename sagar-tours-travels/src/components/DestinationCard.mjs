/** Image-led destination cards + the destinations section. */
import { html } from '../lib/html.mjs';
import { icon } from '../lib/icons.mjs';
import { Img, SectionHeading } from './ui.mjs';
import { destinations } from '../data/content.mjs';

export function DestinationCard({ destination }) {
  return html`<article class="destination">
    <div class="destination__media">
      ${Img(destination.image, { sizes: '(max-width: 720px) 90vw, 30vw' })}
      <span class="destination__overlay" aria-hidden="true"></span>
    </div>
    <div class="destination__body">
      <h3 class="destination__title">${destination.name}</h3>
      <p class="destination__text">${destination.description}</p>
      <a
        class="destination__link"
        href="#booking"
        data-prefill-drop="${destination.name}"
        aria-label="Plan a trip to ${destination.name}"
        >Plan Your Trip ${icon('arrowRight', { size: 18 })}</a
      >
    </div>
  </article>`;
}

export function DestinationsSection() {
  return html`<section class="section" id="destinations" aria-labelledby="destinationsTitle">
    <div class="container">
      ${SectionHeading({
        eyebrow: 'Tour & Travel',
        title: 'Explore Popular Destinations from Nagpur',
        subtitle:
          'Wildlife parks, hill stations and heritage towns, all within comfortable driving distance.',
        id: 'destinationsTitle',
      })}
      <div class="grid grid--destinations" data-reveal>
        ${destinations.map((destination) => DestinationCard({ destination }))}
      </div>
    </div>
  </section>`;
}
