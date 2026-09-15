/** Hero: full-bleed photograph, headline stack and the floating booking card. */
import { html } from '../lib/html.mjs';
import { icon } from '../lib/icons.mjs';
import { Button, Img } from './ui.mjs';
import { BookingForm } from './BookingForm.mjs';
import { site } from '../data/site.mjs';

const TRUST_POINTS = ['24/7 Service', 'Professional Drivers', 'Clean & Comfortable Cars'];

export function Hero() {
  return html`<section class="hero" id="home">
    <div class="hero__media">
      ${Img('hero', {
        className: 'hero__image',
        loading: 'eager',
        fetchpriority: 'high',
        sizes: '100vw',
      })}
      <div class="hero__scrim" aria-hidden="true"></div>
    </div>

    <div class="container hero__inner">
      <div class="hero__copy">
        <p class="eyebrow eyebrow--onDark">Nagpur's Trusted Taxi Service</p>
        <h1 class="hero__title">
          Reliable Taxi Service in Nagpur, <span>Whenever You Need a Ride</span>
        </h1>
        <p class="hero__lead">
          Comfortable local, airport and outstation taxi services with professional drivers, clean
          cars and transparent pricing.
        </p>

        <div class="hero__actions">
          ${Button({
            label: 'Book Your Taxi',
            href: '#booking',
            variant: 'filled',
            size: 'lg',
            iconAfter: 'arrowRight',
          })}
          ${Button({
            label: 'Call Now',
            href: site.contact.phoneHref,
            variant: 'ghost',
            size: 'lg',
            iconName: 'phone',
          })}
        </div>

        <ul class="hero__trust">
          ${TRUST_POINTS.map(
            (point) => html`<li>${icon('check', { size: 18 })}<span>${point}</span></li>`
          )}
        </ul>
      </div>

      <div class="hero__form">${BookingForm()}</div>
    </div>
  </section>`;
}
