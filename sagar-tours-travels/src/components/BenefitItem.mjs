/** Benefit rows + the "Why Choose Sagar Tours and Travels?" split section. */
import { html } from '../lib/html.mjs';
import { icon } from '../lib/icons.mjs';
import { Button, Img } from './ui.mjs';
import { benefits } from '../data/content.mjs';

export function BenefitItem({ benefit }) {
  return html`<li class="benefit">
    <span class="benefit__icon">${icon(benefit.icon, { size: 22 })}</span>
    <div>
      <h3 class="benefit__title">${benefit.title}</h3>
      <p class="benefit__text">${benefit.description}</p>
    </div>
  </li>`;
}

export function WhyChooseUs() {
  return html`<section class="section section--alt" id="why-us" aria-labelledby="whyTitle">
    <div class="container split">
      <div class="split__media" data-reveal>
        <div class="media-frame media-frame--tall">
          ${Img('whyChooseUs', { sizes: '(max-width: 960px) 100vw, 45vw' })}
        </div>
      </div>
      <div class="split__body" data-reveal>
        <p class="eyebrow">Why Choose Us</p>
        <h2 class="split__title" id="whyTitle">Travel with Comfort. Ride with Confidence.</h2>
        <p class="split__lead">
          Every booking with Sagar Tours and Travels comes down to the same things: the right
          vehicle, a driver who knows the road, and a fare you agreed to before the trip started.
        </p>
        <ul class="benefit-list">
          ${benefits.map((benefit) => BenefitItem({ benefit }))}
        </ul>
        ${Button({
          label: 'Book Your Ride',
          href: '#booking',
          variant: 'filled',
          size: 'lg',
          iconAfter: 'arrowRight',
          className: 'split__cta',
        })}
      </div>
    </div>
  </section>`;
}
