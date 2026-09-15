/** Service cards + the "Taxi Services for Every Journey" section. */
import { html } from '../lib/html.mjs';
import { icon } from '../lib/icons.mjs';
import { SectionHeading } from './ui.mjs';
import { services } from '../data/content.mjs';

export function ServiceCard({ service }) {
  return html`<article class="card card--service" id="service-${service.id}">
    <span class="card__icon">${icon(service.icon, { size: 26 })}</span>
    <h3 class="card__title">${service.title}</h3>
    <p class="card__text">${service.description}</p>
    <a
      class="card__link"
      href="#booking"
      data-prefill-service="${service.title}"
      aria-label="Book ${service.title}"
      >Book Now ${icon('arrowRight', { size: 18 })}</a
    >
  </article>`;
}

export function ServicesSection() {
  return html`<section class="section" id="services" aria-labelledby="servicesTitle">
    <div class="container">
      ${SectionHeading({
        eyebrow: 'Our Services',
        title: 'Taxi Services for Every Journey',
        subtitle:
          'Whether you need a quick city ride or a comfortable outstation journey, Sagar Tours and Travels is ready to get you there.',
        id: 'servicesTitle',
      })}
      <div class="grid grid--services" data-reveal>
        ${services.map((service) => ServiceCard({ service }))}
      </div>
    </div>
  </section>`;
}
