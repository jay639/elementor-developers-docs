/** Route cards + the "Popular Taxi Routes from Nagpur" section. */
import { html } from '../lib/html.mjs';
import { icon } from '../lib/icons.mjs';
import { SectionHeading, PlaceholderNote } from './ui.mjs';
import { routes } from '../data/content.mjs';

export function RouteCard({ route }) {
  return html`<article class="card card--route">
    <p class="route__path">
      <span class="route__city">${route.from}</span>
      ${icon('arrowRight', { size: 18, className: 'route__arrow' })}
      <span class="route__city route__city--dest">${route.to}</span>
    </p>
    <p class="route__blurb">${route.blurb}</p>
    <dl class="route__meta">
      <div>
        <dt>${icon('route', { size: 16 })} Distance</dt>
        <dd class="${route.isPlaceholder ? 'is-placeholder' : ''}">${route.distance}</dd>
      </div>
      <div>
        <dt>${icon('clock', { size: 16 })} Approx. time</dt>
        <dd class="${route.isPlaceholder ? 'is-placeholder' : ''}">${route.duration}</dd>
      </div>
    </dl>
    <a
      class="card__link"
      href="#booking"
      data-prefill-pickup="${route.from}"
      data-prefill-drop="${route.to}"
      aria-label="Get a fare for a taxi from ${route.from} to ${route.to}"
      >Get Fare ${icon('arrowRight', { size: 18 })}</a
    >
  </article>`;
}

export function RoutesSection() {
  return html`<section class="section section--alt" id="routes" aria-labelledby="routesTitle">
    <div class="container">
      ${SectionHeading({
        eyebrow: 'Outstation Travel',
        title: 'Popular Taxi Routes from Nagpur',
        subtitle: 'Comfortable and convenient taxi travel from Nagpur to popular destinations.',
        id: 'routesTitle',
      })}
      <div class="grid grid--routes" data-reveal>
        ${routes.map((route) => RouteCard({ route }))}
      </div>
      ${PlaceholderNote({
        text: 'Distances and travel times are placeholders. Verified figures will replace them before the site goes live.',
      })}
    </div>
  </section>`;
}
